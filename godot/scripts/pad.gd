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
	if g == null or not g.running or g.player == null or ui.journal_open or ui.menu_open: return false
	if ui.choosing or ui.picking: return false
	if g.need_stick or g.need_act != "": return true
	return not ui.dlg_open and not g.busy

func free_mode() -> bool:
	return _g() != null and _g().world.cam_mode == "free"

# botones visibles ahora mismo: nombre → [centro, radio]
func buttons() -> Dictionary:
	var s := ui.size; var out := {}
	var g := _g()
	if g == null or not g.running or ui.journal_open or ui.menu_open: return out
	out.menu = [Vector2(s.x - 34, 34), 20.0]
	if not ui.dlg_open and not ui.choosing and not ui.picking and not g.busy:
		out.inv = [Vector2(s.x - 86, 34), 20.0]
	if not ui.touch or not controls_on(): return out
	if free_mode():
		out.up = [Vector2(s.x - 76, s.y - 150), 40.0]
		out.down = [Vector2(s.x - 76, s.y - 58), 40.0]
	else:
		out.act = [Vector2(s.x - 76, s.y - 82), 46.0]
		if not g.view_lock and not g.busy: out.view = [Vector2(s.x - 164, s.y - 50), 28.0]
	return out

func _hit(pos: Vector2) -> String:
	var b := buttons()
	for k in b:
		if pos.distance_to(b[k][0]) <= b[k][1] + 8.0: return k
	return ""

func _input(ev: InputEvent) -> void:
	if ui.journal_open or ui.menu_open: return
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

func _circle(c: Vector2, r: float, col: Color, fill: Color) -> void:
	draw_circle(c, r, fill)
	draw_arc(c, r, 0, TAU, 48, col, 1.2, true)

func _draw() -> void:
	var g := _g()
	if g == null: return
	var b := buttons()
	for k in b:
		var c: Vector2 = b[k][0]; var r: float = b[k][1]
		var on := _held.has(k)
		var fill := Color(App.GAS, 0.25) if on else Color(0.031, 0.063, 0.075, 0.55)
		match k:
			"menu":
				_circle(c, r, App.LINE, fill)
				for i in 3: draw_line(c + Vector2(-8, -6 + i * 6), c + Vector2(8, -6 + i * 6), App.DIM, 1.4)
			"inv":
				_circle(c, r, Color(App.GAS, 0.7) if ui.new_pages else App.LINE, fill)
				var col := App.GAS if ui.new_pages else App.DIM
				draw_rect(Rect2(c + Vector2(-9, -7), Vector2(8.5, 14)), col, false, 1.3)
				draw_rect(Rect2(c + Vector2(0.5, -7), Vector2(8.5, 14)), col, false, 1.3)
				for i in 3:
					draw_line(c + Vector2(-7, -3 + i * 3.5), c + Vector2(-2.5, -3 + i * 3.5), col, 1.0)
					draw_line(c + Vector2(2.5, -3 + i * 3.5), c + Vector2(7, -3 + i * 3.5), col, 1.0)
				if ui.new_pages: draw_circle(c + Vector2(14, -14), 4.0, App.GAS)
			"act":
				var label: String = g.need_act if g.need_act != "" else (g.near_label if g.near != null else "")
				var live := label != ""
				_circle(c, r, App.GAS if live else App.LINE, fill)
				if live:
					var fs := 15 if label.length() <= 8 else 12
					var w := ui.caps.get_string_size(label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
					draw_string(ui.caps, c + Vector2(-w / 2.0, fs * 0.35), label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, App.GAS)
				else: draw_arc(c, 7, 0, TAU, 24, App.FAINT, 1.2, true)
			"view":
				_circle(c, r, App.LINE, fill)
				var pts := PackedVector2Array()
				for i in 17: pts.append(c + Vector2(-13 + i * 26.0 / 16.0, -7.0 * sin(PI * i / 16.0)))
				for i in 17: pts.append(c + Vector2(13 - i * 26.0 / 16.0, 7.0 * sin(PI * i / 16.0)))
				pts.append(pts[0])
				if g.view == "eye": draw_line(c + Vector2(-13, 0), c + Vector2(13, 0), App.BONE, 1.6)
				else:
					draw_polyline(pts, App.BONE, 1.2, true); draw_circle(c, 3.2, App.BONE)
			"up", "down":
				_circle(c, r, App.LINE, fill)
				var s := -1.0 if k == "up" else 1.0
				draw_colored_polygon(PackedVector2Array([c + Vector2(-11, -6 * s), c + Vector2(11, -6 * s), c + Vector2(0, 9 * s)]), App.BONE)
	if ui.touch and controls_on():
		if _stick_id != -99:
			draw_arc(_origin, R, 0, TAU, 64, App.LINE, 1.2, true)
			draw_circle(_origin, R, Color(0.031, 0.063, 0.075, 0.28))
			_circle(_origin + stick * R, 25, App.BONE, Color(App.BONE, 0.14))
		else:
			var c := Vector2(104, ui.size.y - 104)
			draw_arc(c, R, 0, TAU, 64, Color(App.BONE, 0.10), 1.0, true)
			draw_arc(c, 25, 0, TAU, 32, Color(App.BONE, 0.16), 1.0, true)
