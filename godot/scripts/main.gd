# Arranque: construye interfaz y juego, muestra el menú y encadena los capítulos sin pantallas de carga.
extends Node

var g: Game
var ui: UIRoot
var chapters := []       # [nombre, Callable]
var _back_t := 0
var _bot_t := 0.0
var _shot_t := 0.0
var _shot_n := 0

func _ready() -> void:
	_parse_args()
	get_window().size_changed.connect(_fit); _fit()
	ui = UIRoot.new(); App.ui = ui; add_child(ui)
	g = Game.new(); App.g = g; add_child(g)
	g.auto = App.args.has("auto"); ui.auto = g.auto; g.bot = App.args.has("bot")
	if App.args.has("touch") or DisplayServer.is_touchscreen_available(): ui.set_touch(true)
	if App.args.has("speed"): Engine.time_scale = float(App.args.speed)
	if App.args.has("mute"): AudioServer.set_bus_mute(0, true)
	var a := ChA.new(g, ui); var b := ChB.new(g, ui); var c := ChC.new(g, ui); var d := ChD.new(g, ui)
	b.a = a; c.a = a; d.a = a
	ui.cast(Ch.CAST)
	chapters = [
		["Prólogo · La celda", a.prologue], ["I · La casa de cinco lados", a.ch1], ["II · La Calle Mayor", a.ch2],
		["III · La Puerta Oeste", a.ch3], ["IV · El tiempo de los colores", b.ch4], ["V · Atiende a tu Configuración", b.ch5],
		["VI · El Rey de la Línea", c.ch6], ["VII · El Forastero", c.ch7], ["VIII · Espaciolandia", d.ch8],
		["IX · Hacia Arriba, no hacia el Norte", d.ch9], ["X · El juicio", d.ch10],
	]
	set_meta("keep", [a, b, c, d])
	var start := App.pending_start
	App.pending_start = -1
	if start < 0 and App.args.has("ch"): start = int(App.args.ch); App.args.erase("ch")
	if start >= 0: run(start)
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

# la interfaz se escala según la orientación: horizontal 1280×720, vertical 620×1100
func _fit() -> void:
	var px := DisplayServer.window_get_size()
	var want := Vector2i(1280, 720) if px.x >= px.y else Vector2i(620, 1100)
	if get_window().content_scale_size != want: get_window().content_scale_size = want

# fondo vivo del menú: la ciudad vista desde arriba, a la deriva
func _menu() -> void:
	var a: Ch = get_meta("keep")[0]
	g.set_map(a.town()); g.world.rain = 0.6; g.world.zoom = 60; g.world.zoom_cur = 60
	var kinds := [a.F_tri, a.F_cuad, a.F_penta, a.F_hexa, a.F_circ, a.F_mujer]
	for i in 16:
		var d: Dictionary = kinds[i % 6].call("m%d" % i, -50.0 + randf() * 100.0, -4.0 + randf() * 8.0)
		d.ai = {type = "wander", home = Vector2(-40 + i * 6, 0), r = 5.0, sx = 3.0}; d.speed = 1.5
		g.add(d)
	g.world.focus = Vector2(-20, 4); g.world.cam_x = -20; g.world.cam_y = 4
	var st := {t = 0.0}
	g.tick(func(dt): st.t += dt; g.world.focus = Vector2(-10 + sin(st.t * 0.05) * 30.0, 6 + cos(st.t * 0.07) * 5.0))
	Snd.drone("flat")
	ui.fade(false, 0.6)
	var S: Dictionary = g.state
	var items := []
	if S.chapter > 0 or not S.frags.is_empty():
		items.append(["Continuar — " + chapters[mini(S.chapter, chapters.size() - 1)][0], func(_b): _start(S.chapter)])
	var sure := {on = false}
	var newgame := func(b: Button):
		if S.max > 0 and not sure.on:
			sure.on = true; b.text = "¿BORRAR EL MANUSCRITO Y EMPEZAR? PULSA OTRA VEZ"; return
		g.reset(); _start(0)
	items.append(["Nueva partida", newgame])
	if S.max > 0: items.append(["Capítulos", "chapters"])
	var names := []
	for c in chapters: names.append(c[0])
	ui.show_menu(items, names, S.max, _start)

func _start(i: int) -> void:
	App.pending_start = i
	get_tree().reload_current_scene()

func run(i: int) -> void:
	ui.hide_menu(); ui.fade_r.color.a = 1.0; ui._fade_to = 1.0
	g.tickers.clear(); g.running = true
	if g.knows("vista"): g.eye.trace = 1.0
	g.on_menu = func():
		var now := Time.get_ticks_msec()
		if now - _back_t < 2500: App.pending_start = -1; get_tree().reload_current_scene()
		else:
			_back_t = now
			ui.toast("", "Menú", "Pulsa otra vez para volver al menú. El progreso se guarda por capítulos.")
	while i < chapters.size():
		g.state.chapter = i; g.state.max = maxi(g.state.max, i); g.save()
		g.locked = false; g.view_lock = false; g.busy = false; g.speed_mul = 1.0; g.hide_eye_hint = false
		g.need_act = ""; g.need_stick = false
		if App.args.has("log"): print("== capítulo ", i, " ", chapters[i][0])
		await chapters[i][1].call()
		g.tickers.clear(); g.handlers.clear(); g.epoch += 1
		i += 1
	g.state.chapter = 0; g.state.max = chapters.size() - 1; g.save()
	if App.args.has("quit"):
		print("FIN OK frags=", g.state.frags.size()); get_tree().quit(); return
	App.pending_start = -1; get_tree().reload_current_scene()

func _process(dt: float) -> void:
	# autómata de pruebas: avanza textos, elige al azar y salta a los objetivos
	if g.bot and g.running:
		_bot_t += dt / maxf(Engine.time_scale, 0.01)
		if _bot_t > 0.05:
			_bot_t = 0.0
			if (ui.choosing or ui.picking) and App.args.has("nopick"): pass
			elif ui.choosing or ui.picking:
				var ok := []
				for k in ui._n_opts:
					if ui.picking or not ui._opt_lock[k]: ok.append(k)
				ui._adv_ok = 0; ui._pick(ok.pick_random())
			elif ui.waiting() or ui._title_on: ui._adv_ok = 0; ui.advance()
			else: g.assist()
	if App.args.has("open") and g.running and not ui.journal_open and Time.get_ticks_msec() > 5000 and not has_meta("opened"):
		set_meta("opened", true); ui.toggle_journal(App.args.open)
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
