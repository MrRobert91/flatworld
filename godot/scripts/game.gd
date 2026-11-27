# Núcleo: bucle, entrada, estado, guardado y utilidades de guion para los capítulos.
class_name Game extends Node

signal frame(dt)
signal talk_started(id)
signal all_done
signal hurt_taken(sev)

const KEEP := &"__keep"
# día del año de cada bloque (el expediente fecha sus anotaciones); el X ocurre en el año 2000
const DAY := [358, 358, 359, 360, 361, 363, 364, 365, 365, 365, 330]

var world: World
var eye: Eye
var ui: UIRoot
var state := {}
var book := {}
var view := "top"
var view_lock := false
var show_strip := true
var busy := false
var locked := false
var paused := false
var hide_eye_hint := false
var speed_mul := 1.0
var alt_min := 3.0
var alt_max := 40.0
var handlers := {}
var tickers := []
var running := false
var auto := false
var bot := false
var near = null
var near_label := ""
var vel := Vector2.ZERO
var moved := 0.0
var on_line := false
var need_act := ""       # un minijuego pide el botón de acción (con esta etiqueta) aunque haya escena
var need_stick := false  # ídem para la palanca
var on_menu := Callable()
var epoch := 0
var actors := {}         # quién habla → Ent o Node3D, cuando no coincide con el id de una figura
var talk_ent = null      # la figura con la que se conversa ahora
var hurt_cd := 0.0
var stun := 0.0
var _fwd := 0.0
var slot := 1            # hueco de partida (1–3)
var script_policy := ""  # --script=heretic|orthodox: política de elección del autómata
var pull := Vector2.ZERO # deriva por segundo mientras se anda (el tirón del Sur, C3-05)
var no_guides := false   # sin brújula, flecha ni rumbo del objetivo (orientarse a ciegas)
var force_world := false # el mundo se dibuja aunque el ojo ocupe la pantalla (plano partido)

static func fresh() -> Dictionary:
	return Profile.fresh_state()

func _init() -> void:
	slot = int(Profile.data.last_slot)
	state = fresh()
	if not App.args.has("auto"): load_state()   # las pruebas empiezan siempre de cero
	book = I18n.book()
	world = World.new(); add_child(world)
	eye = Eye.new(); add_child(eye)

func _ready() -> void:
	ui = App.ui
	ui.add_child(eye.view); ui.move_child(eye.view, 0)
	world.load_map({bounds = {x0 = -10, y0 = -10, x1 = 10, y1 = 10}})

# ---------- estado ----------
func load_state() -> void:
	var s := Profile.read_slot(slot)
	if s.is_empty(): return
	for k in s: state[k] = s[k]

func save() -> void:
	if auto and not App.args.has("save"): return   # las pruebas no tocan las partidas del jugador
	Profile.write_slot(slot, state)
	Profile.unlock_chapter(int(state.max))

func reset() -> void:
	state = fresh(); save()

func frag(n: int) -> void:
	if state.frags.has(str(n)): return
	state.frags[str(n)] = 1; ui.last_frag = n; ui.new_pages = true; save(); Snd.sfx("frag")
	# celebración: destello cálido, ondas de tinta dorada y un leve latido de cámara
	ui.flash(0.22, Color("e8c36a"))
	var p := player
	if p != null and not auto:
		var gold := Color("c9962e")
		world.fx_add("puff", p.x, p.y, 0.9, 1.3, gold); world.fx_add("puff", p.x, p.y, 1.3, 2.2, gold)
		world.fx_add("spark", p.x, p.y, 0.7, 1.6, gold)
		world.kick = 1.0
	ui.toast("frag", tr("Manuscrito · sección %d de 22") % n, "«%s»" % book.fragments[n - 1].title)

func learn(id: String) -> void:
	if state.know.has(id): return
	state.know[id] = 1; ui.new_pages = true; save(); Snd.sfx("know")
	ui.toast("", "Nuevo saber", book.knowledge[id].title)
	if id == "vista": eye.trace = 1.0

func knows(id: String) -> bool:
	return state.know.has(id)

# reputaciones y herejía: siguen contando por dentro (el epílogo las usa), pero ya no se anuncian (T-01)
func rep(f: String, d: int) -> void:
	state.rep[f] = clampf(state.rep[f] + d, -5, 5); save()

func her(d: int) -> void:
	state.her = clampf(state.her + d, -5, 5); save()

# ---------- expediente y relaciones (S-03) ----------
# Anotación del expediente: idempotente por id. Quien la escribe, si está en escena, hace el gesto
# (late una vez) y suena el punzón. No hay aviso en pantalla: el jugador lo descubrirá en el juicio.
func note(id: String, w := 1) -> void:
	for r in state.record:
		if r.id == id: return
	var who: String = book.get("record", {}).get(id, {}).get("who", "")
	state.record.append({id = id, ch = int(state.chapter), day = DAY[clampi(int(state.chapter), 0, DAY.size() - 1)], who = who, w = w})
	save()
	if App.args.has("log"): print("  expediente: ", id, " (", who, ", peso ", w, ")")
	var e = null
	if actors.has(who) and is_instance_valid(actors[who]): e = actors[who]
	elif world.ents.has(who): e = world.ents[who]
	if e is Ent:
		e.talk = maxf(e.talk, 0.8)
		Snd.sfx_at("chalk", e.x, e.y, 4.0)

# las anotaciones de más peso; a igualdad, por orden de llegada
func record_top(n := 5) -> Array:
	var idx := range(state.record.size())
	idx.sort_custom(func(a, b):
		var wa: int = state.record[a].w; var wb: int = state.record[b].w
		return wa > wb or (wa == wb and a < b))
	var out := []
	for i in idx.slice(0, n): out.append(state.record[i])
	return out

# texto de una anotación en el idioma actual (no se guarda: se resuelve por id)
func record_text(r: Dictionary) -> String:
	var t: String = book.get("record", {}).get(r.id, {}).get("text", r.id)
	return tr("Día %d.") % int(r.day) + " " + t

# notas al margen (S-04): sonido de pluma y la nota del narrador; sin aviso. Se guardan en la partida y
# en la galería del perfil
func margin(id: String) -> void:
	var M := margin_def(id)
	Snd.sfx("quill"); world.remove_spot(id); off(id)
	if not state.margins.has(id):
		state.margins[id] = 1; Profile.unlock_gallery(id); ui.new_pages = true; save()
	if M.has("text"): await ui.narrate(M.text)

func margin_def(id: String) -> Dictionary:
	for m in book.get("margins", []):
		if m.id == id: return m
	return {}

# logros (Steam en M6): por ahora, el perfil los recuerda y un aviso discreto los anuncia
func achieve(id: String) -> void:
	if auto or Profile.data.ach.has(id): return
	Profile.data.ach[id] = 1; Profile.touch(0.0)
	ui.toast("frag", tr("Logro"), tr(book.get("achievements", {}).get(id, id)))

# dificultad de las deducciones: relaxed | normal | expert (T-11)
func difficulty() -> String:
	return String(App.cfg.get("difficulty", "normal"))

# relaciones con nombre, de −2 a 2, sin aviso (T-02)
func rel(who: String, d: int) -> void:
	if not state.rel.has(who): state.rel[who] = 0
	state.rel[who] = clampi(int(state.rel[who]) + d, -2, 2); save()

func rel_of(who: String) -> int:
	return int(state.rel.get(who, 0))

func flag(k: String, v = KEEP):
	if v is StringName and v == KEEP: return state.flags.get(k)
	state.flags[k] = v; save()

# ---------- entrada (S-01) ----------
var _axis_hot := {}   # ejes del mando ya inclinados: un stick mantenido cuenta como una sola pulsación

func _unhandled_input(ev: InputEvent) -> void:
	if not running: return
	if ev is InputEventJoypadMotion:
		var hot := absf(ev.axis_value) >= 0.5
		var was: bool = _axis_hot.get(ev.axis, false)
		_axis_hot[ev.axis] = hot
		if not hot or was: return
	if ev.is_echo() or not ev.is_pressed(): return
	if ev is InputEventMouseMotion: return
	if ev.is_action_pressed("journal") and (ui.journal_open or (not ui.pause_open and not ui.settings_open and not ui.choosing and not ui.picking and not ui.dlg_open and not busy)):
		ui.toggle_journal(); _done(); return
	if ev.is_action_pressed("history") and not ui.pause_open and not ui.settings_open:
		if ui.journal_open and ui._tab == "log": ui.toggle_journal()
		elif ui.journal_open: ui.j_tab("log")
		else: ui.toggle_journal("log")
		_done(); return
	if ev.is_action_pressed("pause") or (ev.is_action_pressed("ui_cancel") and ui.modal()):
		if ui.settings_open: ui.close_settings()
		elif ui.journal_open: ui.toggle_journal()
		elif ui.pause_open: ui.toggle_pause()
		elif ev.is_action_pressed("pause") and on_menu.is_valid(): on_menu.call()
		_done(); return
	if ev.is_action_pressed("mute"):
		ui.toast("", tr("Sonido"), tr("silenciado") if Snd.toggle_mute() else tr("activado")); _done(); return
	if ui.journal_open:
		if ev.is_action_pressed("tab_prev"): ui.j_cycle(-1); _done()
		elif ev.is_action_pressed("tab_next"): ui.j_cycle(1); _done()
		return
	if ui.modal(): return
	if ev is InputEventKey:
		var k: int = ev.physical_keycode
		if k >= KEY_1 and k <= KEY_9 and ui.pick_key(k - KEY_1): _done(); return
		if k >= KEY_KP_1 and k <= KEY_KP_9 and ui.pick_key(k - KEY_KP_1): _done(); return
	# elegir respuesta con el mando o las flechas: arriba/abajo (o izquierda/derecha en los paneles) y aceptar
	if ui.choosing or ui.picking:
		var step := 0
		if ev.is_action_pressed("move_up") or ev.is_action_pressed("ui_up"): step = -1
		elif ev.is_action_pressed("move_down") or ev.is_action_pressed("ui_down"): step = 1
		elif ui.picking and (ev.is_action_pressed("move_left") or ev.is_action_pressed("ui_left")): step = -1
		elif ui.picking and (ev.is_action_pressed("move_right") or ev.is_action_pressed("ui_right")): step = 1
		if step != 0: ui.sel_move(step); _done(); return
		if ev.is_action_pressed("advance") or ev.is_action_pressed("act"):
			if ui.sel_accept(): _done(); return
	if ev.is_action_pressed("advance"):
		if ui.advance(): _done(); return
	if ev.is_action_pressed("act"):
		press_act()
	elif ev.is_action_pressed("view"): toggle_view()

func _done() -> void:
	get_viewport().set_input_as_handled()

func press_act() -> void:
	if busy or locked or near == null or not is_instance_valid(near): return
	run_handler(near)

func toggle_view() -> void:
	if view_lock or player == null or world.cam_mode != "follow" or busy: return
	set_view("eye" if view == "top" else "top"); Snd.sfx("whoosh")

func set_view(v: String) -> void:
	view = v

# dirección de movimiento (y = Norte) con magnitud 0..1: teclado, mando o palanca táctil
func axis() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_down", "move_up")
	if v != Vector2.ZERO:
		if Glyphs.pad(): return v   # el stick es analógico: inclinar más es correr
		return v.normalized() * (1.0 if Input.is_action_pressed("run") else 0.68)
	var s: Vector2 = ui.pad.stick
	return Vector2(s.x, -s.y)

# mirada libre (stick derecho), por segundo
func look_axis() -> Vector2:
	return Input.get_vector("look_left", "look_right", "look_up", "look_down")

func act_held() -> bool:
	return Input.is_action_pressed("act") or ui.pad.held("act")

func up_held() -> bool:
	return Input.is_action_pressed("rise") or ui.pad.held("up")

func down_held() -> bool:
	return Input.is_action_pressed("sink") or ui.pad.held("down")

# cualquier tecla «de más» (para las escenas en que no existe la dirección pedida)
func other_held() -> bool:
	return act_held() or up_held() or down_held() or Input.is_action_pressed("view")

# ---------- utilidades de guion ----------
var player: Ent:
	get: return world.ents.get("yo")

# ---------- quién habla ----------
# La interfaz avisa de cada parlamento: la figura que habla late y emite ondas, las demás se vuelven
# hacia ella y la cámara se le acerca. who = "" cuando calla todo el mundo.
func speaking(who: String) -> void:
	var W := world
	var e = null
	if who == "yo": e = player
	elif who == "voces":
		# la multitud: todos los que rodean al jugador laten a la vez
		var p := player
		if p != null:
			for o in W.ents.values():
				if o != p and not o.hid and Vector2(o.x - p.x, o.y - p.y).length() < 18.0: o.talk = 1.6 + randf() * 0.8
	elif who != "" and who != "narr" and not (ui.SPEAKERS.get(who, {}).get("cls", "") == "inner"):
		if actors.has(who) and is_instance_valid(actors[who]): e = actors[who]
		elif W.ents.has(who): e = W.ents[who]
		elif talk_ent != null and is_instance_valid(talk_ent): e = talk_ent
	W.talker = e
	# el jugador mira a quien le habla
	var p := player
	if p != null and e != null and e != p and busy and W.cam_mode == "follow" and view == "top" and not p.fixed_rot and p.mv == null:
		var tp = W.talker_pos()
		if tp != null and (tp as Vector2).distance_to(Vector2(p.x, p.y)) > 0.5:
			var want := atan2(tp.y - p.y, tp.x - p.x); var from := p.rot; var ep := epoch
			tween(0.35, func(t):
				var q := player   # se consulta cada vez: el jugador puede cambiar con el mapa
				if ep == epoch and q != null: q.rot = from + App.ang_diff(from, want) * App.ease(t))

# un pinchazo: retroceso, sacudida y chispas. sev 1 = punta de mujer o de Isósceles
func hurt(sev: float, at: Vector2) -> void:
	var p := player
	if p == null or hurt_cd > 0.0: return
	hurt_cd = 0.9
	hurt_taken.emit(sev)
	state.stats.pricks = int(state.stats.get("pricks", 0)) + 1
	var away := Vector2(p.x - at.x, p.y - at.y)
	away = away.normalized() if away.length() > 0.01 else Vector2(0, -1)
	vel = away * (3.5 + 6.5 * sev); stun = 0.12 + 0.3 * sev
	p.shake = maxf(p.shake, 0.35 + 0.65 * sev)
	world.fx_add("spark", at.x, at.y, 0.3 + 0.25 * sev, 0.55 + 0.65 * sev)
	world.shake = maxf(world.shake, 0.5 * sev)
	Snd.spike(0.25 + 0.3 * sev)
	if sev >= 0.8:
		Snd.sfx("hurt"); Snd.sfx("stab"); App.rumble(0.5, 0.8, 0.09); ui.flash(0.24)
		world.fx_add("puff", p.x, p.y, 0.5, 0.6)
	else:
		Snd.tone(520.0 - 180.0 * sev, 0.09, "square", 0.05 + 0.06 * sev); App.rumble(0.3, 0.0, 0.025)
		if sev >= 0.4: ui.flash(0.12)

func _check_pricks(p: Ent, hits: Array) -> void:
	if hurt_cd > 0.0 or vel.length() < 1.2 or p.no_collide: return
	var pr := p.rad * p.sc
	var pc := Vector2(p.x, p.y)
	for o in hits:
		if o == p or o.hid or o.dying >= 0.0: continue
		for sp in o.sharp_points():
			var q: Vector2 = sp[0]
			var d := q.distance_to(pc)
			# hay que ir hacia la punta, no rozarla de lado
			if d < pr + 0.14 and vel.normalized().dot((q - pc).normalized() if d > 0.01 else vel.normalized()) > 0.35:
				hurt(sp[1], q); return

func set_map(map: Dictionary) -> void:
	actors.clear(); talk_ent = null
	handlers.clear(); world.load_map(map); near = null; ui.prompt(null); vel = Vector2.ZERO

func spawn_player(x: float, y: float, rot := PI / 2, extra := {}) -> Ent:
	var d := {id = "yo", n = 4, r = 0.78, solid = true, x = x, y = y, rot = rot, name = "Tú"}
	d.merge(extra, true)
	var p := world.add(d)
	world.cam_x = x; world.cam_y = y; vel = Vector2.ZERO
	return p

func add(d: Dictionary) -> Ent:
	return world.add(d)

func npc(id: String) -> Ent:
	return world.obj(id)

func on(id: String, label: String, fn: Callable) -> void:
	handlers[id] = {label = label, fn = fn}

func off(id: String) -> void:
	handlers.erase(id); world.unmark(id)

func _call(fn: Callable, o) -> void:
	if fn.get_argument_count() >= 1: await fn.call(o)
	else: await fn.call()

func run_handler(o: Ent) -> void:
	var h = handlers.get(o.id)
	if h == null: return
	busy = true; ui.prompt(null); vel = Vector2.ZERO
	App.rumble(0.15, 0.0, 0.01)
	talk_ent = null if o.is_spot else o
	if not o.is_spot and player != null and o.mv == null:
		o.frozen = true
		if not o.fixed_rot: o.rot = atan2(player.y - o.y, player.x - o.x)
	if h.has("talk"):
		handlers.erase(o.id); world.unmark(o.id); objective("", null)
		talk_started.emit(o.id)
		return
	await _call(h.fn, o)
	ui.close_dlg(); talk_ent = null
	if is_instance_valid(o): o.frozen = false
	busy = false

func until(fn: Callable, auto_fn := Callable()) -> void:
	if (auto or bot) and auto_fn.is_valid():
		auto_fn.call(); return
	while not fn.call(): await frame

func wait(sec: float) -> void:
	if auto: return
	var t := sec
	while t > 0.0: t -= await frame

# tarea por fotograma; devuelve una función para detenerla (o se detiene sola si fn devuelve true)
func tick(fn: Callable) -> Callable:
	var entry := [fn]
	tickers.append(entry)
	return func(): tickers.erase(entry)

# repite fn(dt) cada fotograma hasta que devuelva true
func tick_until(fn: Callable) -> void:
	while true:
		var dt: float = await frame
		if fn.call(dt): return

# animación 0→1 en `sec` segundos de tiempo de juego
func tween(sec: float, fn: Callable) -> void:
	if auto: fn.call(1.0); return
	var t := 0.0; var ep := epoch
	while t < 1.0:
		t += (await frame) / sec
		if ep != epoch: return   # el capítulo terminó: la animación suelta se abandona
		fn.call(minf(1.0, t))

func after(sec: float, fn: Callable) -> void:
	var ep := epoch
	await wait(sec)
	if ep == epoch: fn.call()

# lanza varios movimientos a la vez y espera a que terminen todos: [[ent, x, y, velocidad], ...]
func moves(list: Array) -> void:
	for m in list: m[0].move_to(m[1], m[2], m[3])
	while true:
		var all_ok := true
		for m in list:
			if is_instance_valid(m[0]) and m[0].mv != null: all_ok = false
		if all_ok: return
		await frame

func objective(t: String, target = KEEP) -> void:
	ui.objective(t)
	if not (target is StringName and target == KEEP): world.target = target

func go_to(x: float, y: float, r: float, text: String) -> void:
	world.add_spot({id = "_goal", x = x, y = y}); world.mark("_goal"); objective(text, Vector2(x, y))
	if auto: player.x = x; player.y = y
	else: await until(func(): return Vector2(player.x - x, player.y - y).length() < r)
	world.remove_spot("_goal"); objective("", null); Snd.sfx("pick")

# espera a que el jugador hable con `id`; la escena sigue en línea y termina con talk_end(o)
func talk_begin(id: String, text: String, label := "Hablar") -> Ent:
	world.mark(id); objective(text, id)
	var o: Ent = world.obj(id)
	if auto:
		player.x = o.x - 1.6; player.y = o.y; busy = true
		off(id); objective("", null)
		return o
	handlers[id] = {label = label, talk = true}
	while true:
		var got = await talk_started
		if got == id: break
	return o

func talk_end(o) -> void:
	ui.close_dlg(); talk_ent = null
	if o != null and is_instance_valid(o): o.frozen = false; off(o.id)
	busy = false; objective("", null)

# escena guionizada: bloquea al jugador mientras dura
func begin_scene() -> void:
	busy = true; ui.prompt(null); vel = Vector2.ZERO

func end_scene() -> void:
	ui.close_dlg(); busy = false

# varias conversaciones en cualquier orden: {id: {label, fn, again}}
func all(targets: Dictionary, text: String, need := -1) -> void:
	var ids: Array = targets.keys()
	if need < 0: need = ids.size()
	objective(text, ids[0])
	if auto:
		for id in ids: await _call(targets[id].fn, world.obj(id))
		ui.close_dlg(); objective("", null)
		return
	var st := {done = 0}
	for id in ids:
		var T: Dictionary = targets[id]
		world.mark(id)
		var h := func(o):
			await _call(T.fn, o)
			world.unmark(id); st.done += 1
			if T.has("again"): on(id, T.get("label", "Hablar"), T.again)
			else: handlers.erase(id)
			var rest := ids.filter(func(i): return world.marks.has(i))
			world.target = rest[0] if not rest.is_empty() else null
			if st.done >= need:
				for i in rest: world.unmark(i)
				all_done.emit()
		on(id, T.get("label", "Hablar"), h)
	await all_done
	objective("", null)

# ayuda de desarrollo: salta al objetivo actual y lo activa
func assist() -> void:
	if busy or player == null: return
	var T = world.target_obj()
	if T == null: return
	var p := player
	if T is Vector2: p.x = T.x; p.y = T.y
	else:
		p.x = T.x - (0.0 if T.is_spot else 1.4); p.y = T.y
	if world.cam_mode == "free": p.alt = maxf(p.alt, 4.0)
	if T is Ent and handlers.has(T.id): run_handler(T)

func teleport(x: float, y: float, rot = null) -> void:
	var p := player
	p.x = x; p.y = y
	if rot != null: p.rot = rot
	world.cam_x = x; world.cam_y = y

# ---------- bucle ----------
func _process(delta: float) -> void:
	var dt := minf(0.05, delta)
	var W := world; var p := player
	if not paused:
		if running: state.stats.play_s = float(state.stats.get("play_s", 0.0)) + delta
		if p != null and running: move_player(dt, p)
		for tk in tickers.duplicate():
			if tk[0].call(dt) == true: tickers.erase(tk)
		W.eye_t = clampf(W.eye_t + (1.0 if view == "eye" else -1.0) * dt * 1.25, 0.0, 1.0)
		W.shift = 0.0
		W.shift_y = -W.zoom_cur * 0.12 if (ui.dlg_open or ui.picking) and W.cam_mode == "follow" else 0.0
		W.update(dt, p)
		frame.emit(dt)
	var e := W.eye_t; var free := W.cam_mode == "free"
	Snd.muffle(e if not free else 0.0)
	var bg: Color = W.pal.bg
	RenderingServer.set_default_clear_color(bg)
	W.visible = e < 0.995 or free or force_world
	var strip := show_strip and p != null and not free and running
	var eye_on := p != null and (strip or e > 0.0) and not free
	eye.set_active(eye_on)
	if eye_on:
		var fx: float = p.local[0].x * 0.9
		eye.cast(W, p, p.x + cos(p.rot) * fx, p.y + sin(p.rot) * fx, p.rot, W.fog)
		eye.layout(e, ui.size, W.time, strip, ui.strip_rect)
	hud(p, e, strip, free)

func move_player(dt: float, p: Ent) -> void:
	var W := world
	hurt_cd = maxf(0.0, hurt_cd - dt); stun = maxf(0.0, stun - dt)
	var can := not busy and not locked and not ui.journal_open
	if stun > 0.0 and can and W.cam_mode != "free":
		# aturdido por el pinchazo: sólo el retroceso
		vel = vel.lerp(Vector2.ZERO, 1.0 - exp(-dt * 7.0)); p.x += vel.x * dt; p.y += vel.y * dt; W.collide(p); can = false
	if need_stick: can = false
	var ax := axis(); var m := ax.length()
	var sp := (2.2 + 7.6 * m) * speed_mul if m > 0.01 else 0.0   # inclinar más = correr
	var dir := ax / m if m > 0.01 else Vector2.ZERO
	if can and p.mv == null:
		if W.cam_mode == "free":
			var lk := look_axis() * float(App.cfg.get("look_sens", 1.0))
			if lk != Vector2.ZERO:
				W.free.yaw = float(W.free.yaw) - lk.x * 2.2 * dt
				W.free.pitch = clampf(float(W.free.pitch) + lk.y * 1.6 * dt, 0.12, 1.45)
			var yaw: float = W.free.yaw
			var f := Vector2(-sin(yaw), cos(yaw)); var r := Vector2(cos(yaw), sin(yaw))
			var want := (f * dir.y + r * dir.x) * sp * 1.6
			vel = vel.lerp(want, 1.0 - exp(-dt * 7.0))
			p.x += vel.x * dt; p.y += vel.y * dt
			if vel.length() > 0.4: p.rot += App.ang_diff(p.rot, vel.angle()) * minf(1.0, dt * 8.0)
			p.alt = clampf(p.alt + (float(up_held()) - float(down_held())) * 9.0 * dt, alt_min, alt_max)
			var b: Dictionary = W.map.bounds
			p.x = clampf(p.x, b.x0, b.x1); p.y = clampf(p.y, b.y0, b.y1)
		elif view == "eye":
			p.rot -= (ax.x + look_axis().x) * 2.3 * dt
			_fwd = lerpf(_fwd, ax.y * (2.0 + 5.6 * absf(ax.y)) * speed_mul, 1.0 - exp(-dt * 10.0))
			vel = Vector2(cos(p.rot), sin(p.rot)) * _fwd
			p.x += vel.x * dt; p.y += vel.y * dt
			if pull != Vector2.ZERO and absf(_fwd) > 0.2: p.x += pull.x * dt; p.y += pull.y * dt
			_check_pricks(p, W.collide(p))
		else:
			var want := dir * sp
			vel = vel.lerp(want, 1.0 - exp(-dt * (13.0 if m > 0.01 else 9.0)))
			if m <= 0.01 and vel.length() < 0.08: vel = Vector2.ZERO
			p.x += vel.x * dt; p.y += vel.y * dt
			if pull != Vector2.ZERO and m > 0.01: p.x += pull.x * dt; p.y += pull.y * dt
			if m > 0.01: p.rot += App.ang_diff(p.rot, atan2(dir.y, dir.x)) * minf(1.0, dt * 12.0)
			moved += vel.length() * dt
			_check_pricks(p, W.collide(p))
	elif stun <= 0.0:
		vel = vel.lerp(Vector2.ZERO, minf(1.0, dt * 10.0)); _fwd = 0.0
	# objeto interactuable cercano
	near = null
	if not busy and not locked and not ui.journal_open:
		near = W.nearest(p.x, p.y, 2.0 if ui.touch else 1.5, func(o): return o != p and handlers.has(o.id) and absf(o.alt - p.alt) < 0.5)
	if near != null:
		near_label = handlers[near.id].label
		var who: String = near.nm if near.nm != "" else near.label
		ui.prompt("%s   %s%s" % [Glyphs.of("act"), tr(near_label), (" — " + tr(who)) if who != "" else ""])
	else:
		near_label = ""; ui.prompt(null)

func hud(p, e: float, strip: bool, free: bool) -> void:
	ui.eye_frame.visible = strip and e < 0.5
	ui.compass.visible = running and not free and e < 0.5 and not ui.touch and not no_guides
	ui.keys_box.visible = running and not ui.touch and not ui.dlg_open and not ui.dlg.visible and ui.size.x > 900 and not ui.modal()
	ui.keys_l.text = Glyphs.fill(tr("{look} mirar  ·  {move} volar  ·  {rise} / {sink} subir y bajar  ·  {journal} inventario") if free else tr("{view} vista  ·  {journal} inventario  ·  {history} historial  ·  {pause} menú"))
	ui.eye_hint.visible = e > 0.9 and running and not busy and not hide_eye_hint and not ui.dlg.visible
	if ui.touch: ui.eye_hint.text = tr("VISTA DEL PLANO  —  palanca: girar y avanzar  ·  ojo: volver a la lámina")
	elif Glyphs.pad(): ui.eye_hint.text = Glyphs.fill(tr("VISTA DEL PLANO  —  stick: girar y avanzar  ·  {view} volver a la lámina"))
	else: ui.eye_hint.text = Glyphs.fill(tr("VISTA DEL PLANO  —  {move_left}/{move_right} girar  ·  {move_up}/{move_down} avanzar  ·  {view} volver a la lámina"))
	var T = world.target_obj()
	if p != null and T != null and e > 0.9 and not no_guides:
		var tp := World.pos_of(T)
		var u := eye.bearing(p.x, p.y, p.rot, tp.x, tp.y)
		ui.bearing_l.visible = true
		ui.bearing_l.text = "<" if u < 0.0 else (">" if u > 1.0 else "v")
		ui.bearing_l.position = Vector2(clampf(u, 0.03, 0.97) * ui.size.x, ui.size.y * 0.5 - 40.0)
	else: ui.bearing_l.visible = false
