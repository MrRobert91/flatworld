# Arranque: construye interfaz y juego, muestra el menú y encadena los capítulos sin pantallas de carga.
extends Node

var g: Game
var ui: UIRoot
var chapters := []       # [nombre, Callable]
var _bot_t := 0.0
var _shot_t := 0.0
var _shot_n := 0
var _ov_t := 0.0

func _ready() -> void:
	_parse_args()
	if App.args.has("test"): add_child(load("res://tests/run.gd").new()); return
	App.load_cfg(); Keys.setup()
	# idioma: el elegido; en el primer arranque, el del sistema si está traducido (S-10)
	var lang: String = App.args.get("lang", Profile.data.get("lang", ""))
	if lang == "" and not (App.args.has("auto") or App.args.has("test") or App.args.has("bot") or App.args.has("try") or App.args.has("shots")):
		var os_l := OS.get_locale_language()
		if os_l in I18n.LANGS: lang = os_l
	I18n.setup(lang)
	get_window().size_changed.connect(_fit); _fit()
	ui = UIRoot.new(); App.ui = ui; add_child(ui)
	g = Game.new(); App.g = g; add_child(g)
	g.auto = App.args.has("auto"); ui.auto = g.auto; g.bot = App.args.has("bot")
	if App.args.has("script"): ui.auto_pick = _policy(App.args.script)
	if App.args.has("touch") or DisplayServer.is_touchscreen_available(): ui.set_touch(true)
	if App.args.has("speed"): Engine.time_scale = float(App.args.speed)
	if App.args.has("mute"): AudioServer.set_bus_mute(0, true)
	var a := ChA.new(g, ui); var b := ChB.new(g, ui); var c := ChC.new(g, ui); var d := ChD.new(g, ui)
	var fr := ChFrame.new(g, ui)
	b.a = a; c.a = a; d.a = a; fr.a = a
	ui.cast(Ch.CAST)
	chapters = [
		["Prólogo · La celda", a.prologue], ["I · La casa de cinco lados", a.ch1], ["II · La Calle Mayor", a.ch2],
		["III · La Puerta Oeste", a.ch3], ["IV · El tiempo de los colores", b.ch4], ["V · Atiende a tu Configuración", b.ch5],
		["VI · El Rey de la Línea", c.ch6], ["VII · El Forastero", c.ch7], ["VIII · Espaciolandia", d.ch8],
		["IX · Hacia Arriba, no hacia el Norte", d.ch9], ["X · El juicio", d.ch10],
	]
	set_meta("keep", [a, b, c, d, fr])
	var start := App.pending_start
	App.pending_start = -1
	if start < 0 and App.args.has("ch"): start = int(App.args.ch); App.args.erase("ch")
	if App.args.has("try"): _try(App.args.try)
	elif start == -2 or App.args.has("college"): _college()
	elif start >= 0: run(start)
	else: _menu()

func _parse_args() -> void:
	if not App.args.is_empty(): return
	var list := Array(OS.get_cmdline_user_args())
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search.substring(1)", true)
		if q is String and q != "": list = Array(q.split("&"))
	for s in list:
		var kv: PackedStringArray = (s as String).trim_prefix("--").split("=")
		App.args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	App.args["_"] = 1

func _fit() -> void:
	App.fit(get_window())

# fondo vivo del menú: la ciudad vista desde arriba, a la deriva
func _menu() -> void:
	var a: Ch = get_meta("keep")[0]
	g.set_map(a.town()); g.world.rain = 0.6; g.world.zoom = 60; g.world.zoom_cur = 60
	var kinds := [a.F_tri, a.F_cuad, a.F_penta, a.F_hexa, a.F_circ, a.F_mujer]
	for i in 16:
		var d: Dictionary = kinds[i % 6].call("m%d" % i, -50.0 + randf() * 100.0, -4.0 + randf() * 8.0)
		d.ai = {type = "stroll", pts = [Vector2(-56, 6), Vector2(-42, 2.5), Vector2(-28, -3), Vector2(-14, -9), Vector2(-4, 6.5), Vector2(7, -8.5), Vector2(18, 7), Vector2(30, -7), Vector2(40, 8)], jit = 3.0}; d.speed = 1.3 + randf() * 0.9
		g.add(d)
	g.world.focus = Vector2(-20, 4); g.world.cam_x = -20; g.world.cam_y = 4
	var st := {t = 0.0}
	g.tick(func(dt): st.t += dt; g.world.focus = Vector2(-10 + sin(st.t * 0.05) * 30.0, 6 + cos(st.t * 0.07) * 5.0))
	Snd.drone("flat")
	ui.fade(false, 0.6)
	_menu_main()

func _menu_main() -> void:
	var S: Dictionary = g.state
	var items := []
	if S.chapter > 0 or not S.frags.is_empty():
		items.append(["Continuar" + "\n" + ui.T(chapters[mini(S.chapter, chapters.size() - 1)][0]), func(_b): _start(S.chapter)])
	items.append(["Nueva partida", func(_b): _menu_slots(true)])
	var used := Profile.list_slots().filter(func(x): return not x.empty)
	if used.size() > 1 or (used.size() == 1 and used[0].n != g.slot): items.append(["Cargar partida", func(_b): _menu_slots(false)])
	var mx := maxi(int(Profile.data.max_chapter), int(S.max))
	if Platform.is_demo(): mx = mini(mx, 3)
	if mx > 0: items.append(["Capítulos", "chapters"])
	if not (Profile.data.get("gallery", {}) as Dictionary).is_empty(): items.append(["Galería", func(_b): _menu_gallery()])
	if Profile.data.get("modes", {}).has("college"): items.append(["Modo Colegio", func(_b): App.pending_start = -2; get_tree().reload_current_scene()])
	var names := []
	for c in chapters: names.append(c[0])
	ui.show_menu(items, names, mx, _start)

# la galería (S-16): láminas vistas, notas al margen recogidas y, tras el final, el Prefacio del Editor
func _menu_gallery() -> void:
	var G: Dictionary = Profile.data.get("gallery", {})
	var items := []
	for i in chapters.size():
		var id := "lam_%d" % i
		if G.has(id): items.append([ui.T("Lámina") + " · " + ui.T(chapters[i][0]), func(_b): await ui.lamina(id), "sub"])
	for m in g.book.get("margins", []):
		if G.has(m.id): items.append([m.title, func(_b): await ui.show_doc(m.title, [m.text]), "sub"])
	if G.has("prefacio"):
		var P: Dictionary = g.book.get("prefacio", {})
		items.append([P.get("title", "Prefacio"), func(_b): await ui.show_doc(P.title, P.text), "sub"])
	items.append(["Volver", func(_b): _menu_main(), "sub"])
	ui.show_menu(items, [], -1, _start)

# los tres huecos (T-12): «Nueva partida» pide hueco y nunca borra sin confirmar dos veces
func _menu_slots(new_game: bool) -> void:
	var items := []
	for sl in Profile.list_slots():
		var n: int = sl.n
		var label := ui.T("Partida %d") % n + "  ·  "
		if sl.empty: label += ui.T("vacía")
		else: label += tr("%s  ·  %d min") % [ui.T(chapters[mini(sl.chapter, chapters.size() - 1)][0]).split(" · ")[0], int(sl.play_s / 60.0)]
		if new_game:
			var sure := {on = false}
			var empty: bool = sl.empty
			items.append([label, func(b: Button):
				if not empty and not sure.on:
					sure.on = true; b.text = ui.T("¿BORRAR LA PARTIDA %d Y EMPEZAR? PULSA OTRA VEZ") % n; return
				Profile.data.last_slot = n; Profile.save(); Profile.clear_slot(n)
				g.slot = n; g.reset(); _start(0), "sub"])
		elif not sl.empty:
			var ch: int = sl.chapter
			items.append([label, func(_b): Profile.data.last_slot = n; Profile.save(); _start(ch), "sub"])
	items.append(["Volver", func(_b): _menu_main(), "sub"])
	ui.show_menu(items, [], -1, _start)

func _start(i: int) -> void:
	App.pending_start = i
	get_tree().reload_current_scene()

# --try=cross|voices|orient|rain|angles|count: un minijuego suelto, para probarlo y capturarlo
func _try(name: String) -> void:
	ui.hide_menu(); ui.fade_r.color.a = 0.0; ui._fade_to = 0.0
	g.running = true
	g.on_menu = func(): ui.toggle_pause(func(): get_tree().quit())
	if name in ["exam", "woman", "hymn", "mend", "bridge"]: await (get_meta("keep")[1] as ChB).try_mini(name)
	elif name in ["ascent", "sections", "shadow", "carry", "tess", "lamina", "restraint", "brother", "closing", "treatise"]: await (get_meta("keep")[3] as ChD).try_mini(name)
	elif name in ["kingview", "section", "ear", "harmony", "square", "cube", "sphere", "table", "cupboard"]: await (get_meta("keep")[2] as ChC).try_mini(name)
	else: await (get_meta("keep")[0] as ChA).try_mini(name)
	print("TRY OK ", name)
	if App.args.has("quit"): get_tree().quit()

# el modo Colegio (§7.2): fuera de la historia, sin partida
func _college() -> void:
	ui.hide_menu(); ui.fade_r.color.a = 1.0; ui._fade_to = 1.0
	g.running = true
	g.on_menu = func(): ui.toggle_pause(func(): App.pending_start = -1; get_tree().reload_current_scene())
	var col := College.new(g, ui); col.a = get_meta("keep")[0]
	await col.run()
	if App.args.has("quit"): print("COLEGIO OK"); get_tree().quit(); return
	App.pending_start = -1; get_tree().reload_current_scene()

func run(i: int) -> void:
	ui.hide_menu(); ui.fade_r.color.a = 1.0; ui._fade_to = 1.0
	g.tickers.clear(); g.running = true
	if g.knows("vista"): g.eye.trace = 1.0
	g.on_menu = func(): ui.toggle_pause(func(): App.pending_start = -1; get_tree().reload_current_scene())
	# la mesa del lector (P-01): antes del Prólogo, al empezar una partida
	if i == 0 and not g.auto and not App.args.has("noframe"):
		await (get_meta("keep")[4] as ChFrame).opening()
	while i < chapters.size():
		g.state.chapter = i; g.state.max = maxi(g.state.max, i); g.save(); Profile.unlock_chapter(i)
		g.locked = false; g.view_lock = false; g.busy = false; g.speed_mul = 1.0; g.hide_eye_hint = false
		g.need_act = ""; g.need_stick = false; Snd.tension(0.0)
		if App.args.has("log"): print("== capítulo ", i, " ", chapters[i][0])
		await chapters[i][1].call()
		g.tickers.clear(); g.handlers.clear(); g.epoch += 1
		i += 1
		# demo (§7): termina con el bloque III
		if Platform.is_demo() and i > 3:
			if App.args.has("log"): print("== fin de la demo")
			if not g.auto:
				await ui.show_doc("Fin de la demostración", ["Aquí termina la demostración de *Planilandia*: el Prólogo y la Parte I.",
					"En el juego completo, el Cuadrado conoce el tiempo de los colores, el Templo, Linealandia y al Forastero de Espaciolandia, y el Consejo le pregunta hacia dónde cae Arriba.",
					"Si quieres seguirlo, añádelo a tu lista de deseos."])
				App.pending_start = -1; get_tree().reload_current_scene()
				return
			break
		if App.args.has("until") and i > int(App.args.until): break
	g.state.chapter = 0; g.state.max = chapters.size() - 1; g.save()
	if App.args.has("quit"):
		var out := "FIN OK frags=%d margins=%d record=%d" % [g.state.frags.size(), g.state.margins.size(), g.state.record.size()]  # notr
		if App.args.has("log"):
			for r in g.record_top(5): print("  ", g.record_text(r))
			if I18n.lang != I18n.SOURCE:
				print("  sin traducir: ", I18n.missing.size())
				if App.args.has("missing"):
					for m in I18n.missing: print("    · ", m)
		print(out); Profile.save(); get_tree().quit(); return
	App.pending_start = -1; get_tree().reload_current_scene()

func _cinetest() -> void:
	var p := g.player; var W := g.world
	await Cine.orbit(W, Vector2(p.x, p.y), PI / 2 - 0.01, 0.08, 3.0, 12.0)
	await g.wait(0.6); Cine.orbit_end(W)
	await Cine.play(W, [{t = 0.0, focus = Vector2(p.x, p.y), zoom = 40.0}, {t = 2.0, focus = Vector2(p.x + 6, p.y), zoom = 18.0}, {t = 3.0, zoom = 18.0}])
	W.focus = null; W.zoom = W.base_zoom

var _inj_t := 0.0
var _inj := []
func _inject(dt: float) -> void:
	if _inj.is_empty() and not has_meta("inj"):
		set_meta("inj", true)
		for part in String(App.args.inject).split(","):
			var f := part.split(":")
			if f.size() >= 3: _inj.append(f)
	_inj_t += dt / maxf(Engine.time_scale, 0.01)
	while not _inj.is_empty() and float(_inj[0][0]) <= _inj_t:
		var f: PackedStringArray = _inj.pop_front()
		var ev: InputEvent
		var up: InputEvent
		match f[1]:
			"joy":
				var e := InputEventJoypadButton.new(); e.button_index = int(f[2]) as JoyButton; e.pressed = true; ev = e
				var u := InputEventJoypadButton.new(); u.button_index = e.button_index; u.pressed = false; up = u
			"axis":
				var e := InputEventJoypadMotion.new(); e.axis = int(f[2]) as JoyAxis; e.axis_value = float(f[3]); ev = e
				var u := InputEventJoypadMotion.new(); u.axis = e.axis; u.axis_value = 0.0; up = u
			_:
				var e := InputEventKey.new(); e.physical_keycode = OS.find_keycode_from_string(f[2]); e.keycode = e.physical_keycode; e.pressed = true; ev = e
				var u := InputEventKey.new(); u.physical_keycode = e.physical_keycode; u.keycode = e.keycode; u.pressed = false; up = u
		# segundo:hold:TECLA:duración mantiene la tecla pulsada
		var hold := float(f[3]) if f[1] == "hold" and f.size() > 3 else 0.12
		Input.parse_input_event(ev)
		get_tree().create_timer(hold, true, false, true).timeout.connect(func(): Input.parse_input_event(up))

# --script=heretic|orthodox: el autómata elige por política (S-03, pruebas del expediente)
const HERETIC := ["Herejía", "Cuestionar", "Osadía", "Atreverse", "La verdad", "Apelar"]
const ORTHODOX := ["Obedecer", "Ortodoxia", "La mentira", "Callar", "Humildad"]
func _policy(name: String) -> Callable:
	return func(opts: Array) -> int:
		var free := []
		for k in opts.size():
			if not ui._locked(opts[k]): free.append(k)
		if free.is_empty(): return 0
		if name == "heretic":
			for k in free:
				if opts[k].get("tag", "") in HERETIC: return k
			for k in free:
				if str(opts[k].get("id", "")) == "h": return k
		elif name == "orthodox":
			for k in free:
				if opts[k].get("tag", "") in ORTHODOX: return k
			for k in free:
				if str(opts[k].get("id", "")) == "o": return k
			for k in free:
				if opts[k].get("tag", "") == "": return k
		return free[0]

func _process(dt: float) -> void:
	if g == null: return
	# el overlay de Steam pausa la partida (§7)
	if Platform.overlay_active() and g.running and not ui.pause_open and g.on_menu.is_valid(): g.on_menu.call()
	# autómata de pruebas: avanza textos, elige al azar y salta a los objetivos
	if g.bot and g.running:
		_bot_t += dt / maxf(Engine.time_scale, 0.01)
		if _bot_t > float(App.args.get("botdt", "0.05")):
			_bot_t = 0.0
			if (ui.choosing or ui.picking) and App.args.has("nopick"): pass
			elif ui.choosing or ui.picking:
				var ok := []
				for k in ui._n_opts:
					if ui.picking or not ui._opt_lock[k]: ok.append(k)
				ui._adv_ok = 0; ui._pick(ok.pick_random())
			elif ui.waiting() or ui._title_on: ui._adv_ok = 0; ui.advance()
			else: g.assist()
	# prueba de pinchazos: --prick=iso|mujer|tri|cuad|penta pone una figura delante y camina hacia ella
	if App.args.has("prick") and g.running and g.player != null and not g.busy and Time.get_ticks_msec() > 6000 and not has_meta("pricked"):
		set_meta("pricked", true)
		var a: Ch = get_meta("keep")[0]; var p := g.player
		var d: Dictionary = {iso = a.F_iso("pk", p.x + 4, p.y, 12.0), mujer = a.F_mujer("pk", p.x + 4, p.y), tri = a.F_tri("pk", p.x + 4, p.y), cuad = a.F_cuad("pk", p.x + 4, p.y), penta = a.F_penta("pk", p.x + 4, p.y)}[App.args.prick]
		d.rot = PI; g.add(d)
		var ev := InputEventKey.new(); ev.physical_keycode = KEY_D; ev.keycode = KEY_D; ev.pressed = true; Input.parse_input_event(ev)
	# prueba de choques: --overlap informa cada segundo del mayor solape entre figuras
	if App.args.has("overlap"):
		_ov_t += dt
		if _ov_t > 1.0:
			_ov_t = 0.0
			var W := g.world; var L := []
			for e in W.ents.values():
				if not e.hid and not e.no_collide and not e.is_spot and e.dying < 0.0: L.append(e)
			var worst := 0.0; var who := ""
			for i in L.size():
				for j in range(i + 1, L.size()):
					var a: Ent = L[i]; var b: Ent = L[j]
					if W._give(a) + W._give(b) <= 0.0: continue
					var gg: Array = W._gap(W.shape(a), W.shape(b), Vector2(a.x, a.y), Vector2(b.x, b.y))
					if -gg[0] > worst: worst = -gg[0]; who = a.id + "/" + b.id
			print("overlap ", snappedf(worst, 0.001), " ", who, " n=", L.size())
	# --inject=t:joy:6,t:key:J,t:axis:1:1.0 → pulsaciones simuladas (prueba de mando y paneles con --shots)
	if App.args.has("inject"): _inject(dt)
	# --cinetest: prueba de raíles (S-08): órbita de la cámara y un plano de foco y zoom con franjas
	if App.args.has("cinetest") and g.running and g.player != null and Time.get_ticks_msec() > 4000 and not has_meta("cine"):
		set_meta("cine", true); _cinetest()
	if App.args.has("open") and g.running and not ui.journal_open and Time.get_ticks_msec() > 5000 and not has_meta("opened"):
		set_meta("opened", true)
		# --open=pause|settings|<pestaña del inventario>: capturas de los paneles
		if App.args.open == "pause": g.on_menu.call()
		elif String(App.args.open).begins_with("settings"):
			ui.open_settings()
			var pg := String(App.args.open).trim_prefix("settings").trim_prefix(":")
			if pg != "": ui.settings.call("_" + pg)
		else: ui.toggle_journal(App.args.open)
	if App.args.has("shots"):
		_shot_t -= dt / maxf(Engine.time_scale, 0.01)
		if _shot_t <= 0.0:
			_shot_t = float(App.args.get("every", "2"))
			var img := get_viewport().get_texture().get_image()
			if App.args.has("crop"):
				var c: PackedStringArray = App.args.crop.split(",")
				img = img.get_region(Rect2i(int(c[0]), int(c[1]), int(c[2]), int(c[3])))
				img.resize(int(c[2]) * 3, int(c[3]) * 3, Image.INTERPOLATE_NEAREST)
			img.save_png("%s/s%03d.png" % [App.args.shots, _shot_n]); _shot_n += 1
			if App.args.has("max") and _shot_n >= int(App.args.max): get_tree().quit()
