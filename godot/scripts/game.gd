# Núcleo: bucle, entrada, estado, guardado y utilidades de guion para los capítulos.
class_name Game extends Node

signal frame(dt)
signal talk_started(id)
signal all_done

const SAVE := "user://planilandia.json"
const KEEP := &"__keep"

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
var _fwd := 0.0

static func fresh() -> Dictionary:
	return {chapter = 0, max = 0, rep = {sac = 0, ciu = 0, aut = 0}, her = 0, know = {}, frags = {}, flags = {}}

func _init() -> void:
	state = fresh(); load_state()
	var f := FileAccess.open("res://data/book.json", FileAccess.READ)
	book = JSON.parse_string(f.get_as_text())
	world = World.new(); add_child(world)
	eye = Eye.new(); add_child(eye)

func _ready() -> void:
	ui = App.ui
	ui.add_child(eye.view); ui.move_child(eye.view, 0)
	world.load_map({bounds = {x0 = -10, y0 = -10, x1 = 10, y1 = 10}})

# ---------- estado ----------
func load_state() -> void:
	if not FileAccess.file_exists(SAVE): return
	var f := FileAccess.open(SAVE, FileAccess.READ)
	if f == null: return
	var s = JSON.parse_string(f.get_as_text())
	if s is Dictionary:
		for k in s: state[k] = s[k]
		state.chapter = int(state.chapter); state.max = int(state.max)

func save() -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(state))

func reset() -> void:
	state = fresh(); save()

func frag(n: int) -> void:
	if state.frags.has(str(n)): return
	state.frags[str(n)] = 1; ui.last_frag = n; ui.new_pages = true; save(); Snd.sfx("frag")
	ui.toast("frag", "Manuscrito · sección %d de 22" % n, "«%s»" % book.fragments[n - 1].title)

func learn(id: String) -> void:
	if state.know.has(id): return
	state.know[id] = 1; ui.new_pages = true; save(); Snd.sfx("know")
	ui.toast("", "Nuevo saber", book.knowledge[id].title)
	if id == "vista": eye.trace = 1.0

func knows(id: String) -> bool:
	return state.know.has(id)

func rep(f: String, d: int) -> void:
	state.rep[f] = clampf(state.rep[f] + d, -5, 5); save(); Snd.sfx("good" if d > 0 else "bad")
	ui.toast("good" if d > 0 else "bad", "Posición social", "%s: %s" % [{sac = "Sacerdocio", ciu = "Ciudadanía", aut = "Autoridad"}[f], "sube" if d > 0 else "baja"])

func her(d: int) -> void:
	state.her = clampf(state.her + d, -5, 5); save()
	if d > 0: Snd.sfx("her")
	ui.toast("her", "Tu pensamiento", "Hacia la herejía" if d > 0 else "Hacia la ortodoxia")

func flag(k: String, v = KEEP):
	if v is StringName and v == KEEP: return state.flags.get(k)
	state.flags[k] = v; save()

# ---------- entrada ----------
func _unhandled_key_input(ev: InputEvent) -> void:
	if not ev.pressed or ev.echo: return
	var k: int = ev.physical_keycode
	if not running: return
	if k == KEY_J and not ui.choosing and not ui.picking and not ui.dlg_open and not busy:
		ui.toggle_journal(); return
	if k == KEY_ESCAPE:
		if ui.journal_open: ui.toggle_journal()
		elif on_menu.is_valid(): on_menu.call()
		return
	if k == KEY_M:
		ui.toast("", "Sonido", "silenciado" if Snd.toggle_mute() else "activado"); return
	if ui.journal_open: return
	if k >= KEY_1 and k <= KEY_9:
		if ui.pick_key(k - KEY_1): return
	if k >= KEY_KP_1 and k <= KEY_KP_9:
		if ui.pick_key(k - KEY_KP_1): return
	if k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER:
		if ui.advance(): get_viewport().set_input_as_handled(); return
	if k == KEY_E: press_act()
	elif k == KEY_V or k == KEY_TAB: toggle_view()

func press_act() -> void:
	if busy or locked or near == null or not is_instance_valid(near): return
	run_handler(near)

func toggle_view() -> void:
	if view_lock or player == null or world.cam_mode != "follow" or busy: return
	set_view("eye" if view == "top" else "top"); Snd.sfx("door")

func set_view(v: String) -> void:
	view = v

static func _key(a: int, b := 0) -> bool:
	return Input.is_physical_key_pressed(a) or (b != 0 and Input.is_physical_key_pressed(b))

# dirección de movimiento (y = Norte) con magnitud 0..1; teclado o palanca
func axis() -> Vector2:
	var v := Vector2(float(_key(KEY_D, KEY_RIGHT)) - float(_key(KEY_A, KEY_LEFT)), float(_key(KEY_W, KEY_UP)) - float(_key(KEY_S, KEY_DOWN)))
	if v != Vector2.ZERO: return v.normalized() * (1.0 if _key(KEY_SHIFT) else 0.68)
	var s: Vector2 = ui.pad.stick
	return Vector2(s.x, -s.y)

func act_held() -> bool:
	return _key(KEY_E) or ui.pad.held("act")

func up_held() -> bool:
	return _key(KEY_R, KEY_SPACE) or ui.pad.held("up")

func down_held() -> bool:
	return _key(KEY_F) or ui.pad.held("down")

# cualquier tecla «de más» (para las escenas en que no existe la dirección pedida)
func other_held() -> bool:
	return act_held() or up_held() or down_held() or _key(KEY_V)

# ---------- utilidades de guion ----------
var player: Ent:
	get: return world.ents.get("yo")

func set_map(map: Dictionary) -> void:
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
	Input.vibrate_handheld(10)
	if not o.is_spot and player != null and o.mv == null:
		o.frozen = true
		if not o.fixed_rot: o.rot = atan2(player.y - o.y, player.x - o.x)
	if h.has("talk"):
		handlers.erase(o.id); world.unmark(o.id); objective("", null)
		talk_started.emit(o.id)
		return
	await _call(h.fn, o)
	ui.close_dlg()
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
	ui.close_dlg()
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
		if p != null and running: move_player(dt, p)
		for tk in tickers.duplicate():
			if tk[0].call(dt) == true: tickers.erase(tk)
		W.eye_t = clampf(W.eye_t + (1.0 if view == "eye" else -1.0) * dt * 1.25, 0.0, 1.0)
		W.shift = 0.0
		W.shift_y = -W.zoom_cur * 0.12 if (ui.dlg_open or ui.picking) and W.cam_mode == "follow" else 0.0
		W.update(dt, p)
		frame.emit(dt)
	var e := W.eye_t; var free := W.cam_mode == "free"
	var bg: Color = W.pal.bg
	if not free: bg = bg.lerp(Color("03070a"), e)
	RenderingServer.set_default_clear_color(bg)
	W.visible = e < 0.995 or free
	var strip := show_strip and p != null and not free and running
	var eye_on := p != null and (strip or e > 0.0) and not free
	eye.set_active(eye_on)
	if eye_on:
		var fx: float = p.local[0].x * 0.9
		eye.cast(W, p, p.x + cos(p.rot) * fx, p.y + sin(p.rot) * fx, p.rot, W.fog)
		eye.layout(e, ui.size, W.time, strip)
	hud(p, e, strip, free)

func move_player(dt: float, p: Ent) -> void:
	var W := world
	var can := not busy and not locked and not ui.journal_open
	if need_stick: can = false
	var ax := axis(); var m := ax.length()
	var sp := (2.2 + 7.6 * m) * speed_mul if m > 0.01 else 0.0   # inclinar más = correr
	var dir := ax / m if m > 0.01 else Vector2.ZERO
	if can and p.mv == null:
		if W.cam_mode == "free":
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
			p.rot -= ax.x * 2.3 * dt
			_fwd = lerpf(_fwd, ax.y * (2.0 + 5.6 * absf(ax.y)) * speed_mul, 1.0 - exp(-dt * 10.0))
			vel = Vector2(cos(p.rot), sin(p.rot)) * _fwd
			p.x += vel.x * dt; p.y += vel.y * dt
			W.collide(p)
		else:
			var want := dir * sp
			vel = vel.lerp(want, 1.0 - exp(-dt * (13.0 if m > 0.01 else 9.0)))
			if m <= 0.01 and vel.length() < 0.08: vel = Vector2.ZERO
			p.x += vel.x * dt; p.y += vel.y * dt
			if m > 0.01: p.rot += App.ang_diff(p.rot, atan2(dir.y, dir.x)) * minf(1.0, dt * 12.0)
			moved += vel.length() * dt
			W.collide(p)
	else:
		vel = vel.lerp(Vector2.ZERO, minf(1.0, dt * 10.0)); _fwd = 0.0
	# objeto interactuable cercano
	near = null
	if not busy and not locked and not ui.journal_open:
		near = W.nearest(p.x, p.y, 2.0 if ui.touch else 1.5, func(o): return o != p and handlers.has(o.id) and absf(o.alt - p.alt) < 0.5)
	if near != null:
		near_label = handlers[near.id].label
		var who: String = near.nm if near.nm != "" else near.label
		ui.prompt("[color=#e6bd6e][b]E[/b][/color]   %s%s" % [near_label, (" — " + who) if who != "" else ""])
	else:
		near_label = ""; ui.prompt(null)

func hud(p, e: float, strip: bool, free: bool) -> void:
	ui.eye_frame.visible = strip and e < 0.5
	ui.compass.visible = running and not free and e < 0.5 and not ui.touch
	ui.keys_l.visible = running and not ui.touch and not ui.dlg_open and ui.size.x > 900
	ui.keys_l.text = "ratón mirar  ·  WASD volar  ·  R / F subir y bajar  ·  J inventario" if free else "V vista  ·  J inventario  ·  M sonido  ·  Esc menú"
	ui.eye_hint.visible = e > 0.9 and running and not busy and not hide_eye_hint and not ui.dlg.visible
	ui.eye_hint.text = "VISTA DEL PLANO  —  palanca: girar y avanzar  ·  ojo: volver a la lámina" if ui.touch else "VISTA DEL PLANO  —  A/D girar  ·  W/S avanzar  ·  V volver a la lámina"
	var T = world.target_obj()
	if p != null and T != null and e > 0.9:
		var tp := World.pos_of(T)
		var u := eye.bearing(p.x, p.y, p.rot, tp.x, tp.y)
		ui.bearing_l.visible = true
		ui.bearing_l.text = "<" if u < 0.0 else (">" if u > 1.0 else "v")
		ui.bearing_l.position = Vector2(clampf(u, 0.03, 0.97) * ui.size.x - 5.0, ui.size.y * 0.5 - 58.0)
	else: ui.bearing_l.visible = false
