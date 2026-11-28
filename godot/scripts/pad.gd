# Controles en pantalla. Gestiona a mano los punteros (multitáctil): palanca flotante analógica,
# botones de acción, cámara libre con arrastre/pellizco, toques para continuar, e iconos superiores
# (inventario y menú). El ratón de escritorio usa el mismo camino.
class_name Pad extends Control

const R := 62.0           # radio de la palanca
var ui: UIRoot
var stick := Vector2.ZERO  # -1..1, y hacia abajo de pantalla
var _stick_id := -99
var _origin := Vector2.ZERO
var _ptrs := {}            # id → {start, pos, t, moved, role}
var _held := {}            # botón → id de puntero
var _pinch := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func held(b: String) -> bool:
	return _held.has(b)

func _g() -> Game:
	return App.g

func controls_on() -> bool:
	var g := _g()
	if g == null or not g.running or g.player == null or ui.modal(): return false
	if ui.choosing or ui.picking: return false
	if g.need_stick or g.need_act != "": return true
	return not ui.dlg_open and not g.busy

func free_mode() -> bool:
	return _g() != null and _g().world.cam_mode == "free"

# botones visibles ahora mismo: nombre → [centro, radio]
func buttons() -> Dictionary:
	var s := ui.size; var out := {}
	var g := _g()
	if g == null or not g.running or ui.modal(): return out
	out.menu = [Vector2(s.x - 36, 36), 24.0]
	if not ui.dlg_open and not ui.choosing and not ui.picking and not g.busy:
		out.inv = [Vector2(s.x - 94, 36), 24.0]
	if not ui.touch or not controls_on(): return out
	if free_mode():
		out.up = [Vector2(s.x - 74, s.y - 158), 40.0]
		out.down = [Vector2(s.x - 74, s.y - 64), 40.0]
		# en vuelo, coger y soltar figuras (Carry) o una acción pedida
		if g.carry_label != "" or g.need_act != "": out.act = [Vector2(s.x - 178, s.y - 92), 42.0]
	else:
		out.act = [Vector2(s.x - 74, s.y - 80), 46.0]
		if not g.view_lock and not g.busy and not ui.dlg.visible: out.view = [Vector2(s.x - 166, s.y - 52), 30.0]
	return out

func _hit(pos: Vector2) -> String:
	var b := buttons()
	for k in b:
		if pos.distance_to(b[k][0]) <= b[k][1] + 8.0: return k
	return ""

func _input(ev: InputEvent) -> void:
	if ui.modal(): return
	if ev is InputEventScreenTouch:
		ui.set_touch(true)
		if ev.pressed: _down(ev.index, ev.position)
		else: _up(ev.index, ev.position)
	elif ev is InputEventScreenDrag:
		_move(ev.index, ev.position, ev.relative)
	elif ev is InputEventMouseButton and ev.device != InputEvent.DEVICE_ID_EMULATION:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed: _down(-1, ev.position)
			else: _up(-1, ev.position)
		elif ev.pressed and free_mode() and ev.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var f: Dictionary = _g().world.free
			f.dist = clampf(f.dist * (0.92 if ev.button_index == MOUSE_BUTTON_WHEEL_UP else 1.08), 8.0, 90.0)
	elif ev is InputEventMouseMotion and ev.device != InputEvent.DEVICE_ID_EMULATION and _ptrs.has(-1):
		_move(-1, ev.position, ev.relative)

func _down(id: int, pos: Vector2) -> void:
	var g := _g()
	var b := _hit(pos)
	if b != "":
		_held[b] = id
		_ptrs[id] = {start = pos, pos = pos, t = Time.get_ticks_msec(), moved = true, role = "btn", btn = b}
		match b:
			"act": g.press_act()
			"view": g.toggle_view()
			"inv": ui.toggle_journal()
			"menu": if g.on_menu.is_valid(): g.on_menu.call()
		if b != "inv": Input.vibrate_handheld(12)
		queue_redraw()
		return
	var role := "tap"
	if controls_on():
		if ui.touch and _stick_id == -99 and pos.x < ui.size.x * 0.5 and pos.y > 70.0:
			role = "stick"; _stick_id = id; _origin = pos; stick = Vector2.ZERO
		elif free_mode(): role = "look"
	_ptrs[id] = {start = pos, pos = pos, t = Time.get_ticks_msec(), moved = false, role = role}
	queue_redraw()

func _move(id: int, pos: Vector2, rel: Vector2) -> void:
	if not _ptrs.has(id): return
	var p: Dictionary = _ptrs[id]
	p.pos = pos
	if pos.distance_to(p.start) > 12.0: p.moved = true
	if p.role == "stick":
		var d := pos - _origin; var l := d.length()
		if l > R: _origin += d.normalized() * (l - R); d = pos - _origin; l = R   # la base sigue al dedo
		var m := clampf((l / R - 0.12) / 0.88, 0.0, 1.0)
		stick = d.normalized() * m if l > 0.001 else Vector2.ZERO
		queue_redraw()
	elif p.role == "look" and free_mode():
		var looks := []
		for q in _ptrs.values():
			if q.role == "look": looks.append(q)
		var f: Dictionary = _g().world.free
		if looks.size() >= 2:
			var d: float = (looks[0].pos as Vector2).distance_to(looks[1].pos)
			if _pinch > 0.0: f.dist = clampf(f.dist * _pinch / maxf(d, 1.0), 8.0, 90.0)
			_pinch = d
		else:
			f.yaw -= rel.x * 0.006; f.pitch = clampf(f.pitch + rel.y * 0.005, 0.12, 1.5)

func _up(id: int, pos: Vector2) -> void:
	if not _ptrs.has(id): return
	var p: Dictionary = _ptrs[id]
	_ptrs.erase(id)
	_pinch = 0.0
	if p.role == "btn":
		_held.erase(p.btn); queue_redraw(); return
	if p.role == "stick":
		_stick_id = -99; stick = Vector2.ZERO; queue_redraw()
	if not p.moved and Time.get_ticks_msec() - p.t < 450:
		ui.advance()

func _process(_dt: float) -> void:
	# si los controles se ocultan con un dedo puesto, se suelta todo
	if _stick_id != -99 and not controls_on():
		_stick_id = -99; stick = Vector2.ZERO
	queue_redraw()

# botón de papel: sombra, relleno y filete de tinta
func _circle(c: Vector2, r: float, col: Color, on: bool, w := 2.0) -> void:
	draw_circle(c + Vector2(0, 2.5), r + 1.0, Color(0.05, 0.07, 0.09, 0.16))
	draw_circle(c, r, Color("ead9c8") if on else Color(App.CARD, 0.94))
	draw_arc(c, r, 0, TAU, 56, col, w, true)

func _draw() -> void:
	var g := _g()
	if g == null: return
	var b := buttons()
	for k in b:
		var c: Vector2 = b[k][0]; var r: float = b[k][1]
		var on := _held.has(k)
		match k:
			"menu":
				_circle(c, r, App.INK, on)
				for i in 3: draw_line(c + Vector2(-9, -7 + i * 7), c + Vector2(9, -7 + i * 7), App.INK, 2.0)
			"inv":
				var col := App.ACC if ui.new_pages else App.INK
				_circle(c, r, col, on)
				draw_rect(Rect2(c + Vector2(-11, -8), Vector2(10.5, 16)), col, false, 1.8)
				draw_rect(Rect2(c + Vector2(0.5, -8), Vector2(10.5, 16)), col, false, 1.8)
				for i in 3:
					draw_line(c + Vector2(-8, -3.5 + i * 4), c + Vector2(-3, -3.5 + i * 4), col, 1.2)
					draw_line(c + Vector2(3.5, -3.5 + i * 4), c + Vector2(8.5, -3.5 + i * 4), col, 1.2)
				if ui.new_pages:
					draw_circle(c + Vector2(17, -17), 6.5, App.CARD); draw_circle(c + Vector2(17, -17), 5.0, App.ACC)
			"act":
				var label: String = g.need_act if g.need_act != "" else (g.carry_label if free_mode() else (g.near_label if g.near != null else ""))
				var live := label != ""
				_circle(c, r, App.ACC if live else App.FAINT, on, 3.0 if live else 1.6)
				if live:
					draw_arc(c, r - 5.0, 0, TAU, 56, Color(App.ACC, 0.35), 1.0, true)
					var fs := 16 if label.length() <= 7 else (13 if label.length() <= 10 else 11)
					var w := ui.caps.get_string_size(label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
					draw_string(ui.caps, c + Vector2(-w / 2.0, fs * 0.35), label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, App.ACC)
				else: draw_arc(c, 8, 0, TAU, 24, App.FAINT, 1.6, true)
			"view":
				_circle(c, r, App.INK, on)
				var pts := PackedVector2Array()
				for i in 17: pts.append(c + Vector2(-15 + i * 30.0 / 16.0, -8.0 * sin(PI * i / 16.0)))
				for i in 17: pts.append(c + Vector2(15 - i * 30.0 / 16.0, 8.0 * sin(PI * i / 16.0)))
				pts.append(pts[0])
				if g.view == "eye":
					# en la vista del plano el botón devuelve a la lámina: un cuadrado visto desde arriba
					draw_rect(Rect2(c - Vector2(8, 8), Vector2(16, 16)), App.INK, false, 2.0)
				else:
					draw_polyline(pts, App.INK, 1.8, true); draw_circle(c, 3.6, App.INK)
			"up", "down":
				_circle(c, r, App.INK, on)
				var s := -1.0 if k == "up" else 1.0
				draw_colored_polygon(PackedVector2Array([c + Vector2(-12, -6 * s), c + Vector2(12, -6 * s), c + Vector2(0, 10 * s)]), App.INK)
	if ui.touch and controls_on():
		var c := _origin if _stick_id != -99 else Vector2(100, ui.size.y - 100)
		var act := _stick_id != -99
		draw_circle(c, R, Color(App.CARD, 0.55 if act else 0.30))
		draw_arc(c, R, 0, TAU, 64, Color(App.INK, 0.9 if act else 0.45), 2.0, true)
		# marcas de transportador en la base
		for i in 8:
			var d := Vector2(cos(TAU * i / 8.0), sin(TAU * i / 8.0))
			draw_line(c + d * (R - 7.0), c + d * R, Color(App.INK, 0.7 if act else 0.35), 1.5, true)
		var kc := c + stick * R
		draw_circle(kc + Vector2(0, 2), 27, Color(0.05, 0.07, 0.09, 0.16))
		draw_circle(kc, 26, Color(App.CARD, 0.96 if act else 0.7))
		draw_arc(kc, 26, 0, TAU, 40, Color(App.INK, 1.0 if act else 0.55), 2.2, true)
		draw_circle(kc, 4, Color(App.ACC, 1.0 if act else 0.6))
