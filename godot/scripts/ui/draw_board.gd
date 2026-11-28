# Pizarra de dibujo (S-11): el jugador traza segmentos de tiza entre puntos de anclaje.
# Ratón o dedo: se aprieta sobre un anclaje, se arrastra y se suelta sobre otro. Mando o teclado: el
# cursor se mueve con el stick (420 px/s, con imán a 18 px del anclaje más cercano); {act} empieza y
# termina el trazo y {view} deshace el último.
# En modo «reject» ningún trazo se queda: la tiza chirría, la pizarra tiembla y el trazo se borra (C7-01:
# todo lo que dibujas cae en el mismo plano).
class_name DrawBoard extends SlateBoard

signal stroke(a: int, b: int)
signal rejected

const SNAP := 18.0
const GRAB := 30.0
const SPEED := 420.0

var anchors := PackedVector2Array()   # en coordenadas de la pizarra (640×420)
var segs: Array = []                  # Vector2i: pares de anclajes
var mode := "draw"
var cursor := Vector2(320, 210)
var hint := Callable()                # dibujo guía bajo los trazos: hint.call(board)
var _from := -1
var _mouse := false
var _shake := 0.0
var _fade := []                       # trazos rechazados que se borran: [a, b, t]
var _act_was := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func reset(pts: PackedVector2Array, m := "draw") -> void:
	anchors = pts; segs = []; mode = m; _from = -1; _fade = []; _shake = 0.0
	cursor = Vector2(320, 210); queue_redraw()

func nearest(p: Vector2, maxd: float) -> int:
	var best := -1; var bd := maxd
	for i in anchors.size():
		var d := anchors[i].distance_to(p)
		if d < bd: bd = d; best = i
	return best

func _begin() -> void:
	_from = nearest(cursor, GRAB)
	if _from >= 0: Snd.sfx("chalk")

func _end() -> void:
	if _from < 0: return
	var to := nearest(cursor, GRAB)
	var a := _from; _from = -1
	if to < 0 or to == a: return
	if mode == "reject":
		_fade.append([a, to, 0.0]); _shake = 1.0
		Snd.sfx("chalk_break"); App.rumble(0.2, 0.5, 0.25)
		rejected.emit(); return
	segs.append(Vector2i(a, to)); Snd.sfx("chalk")
	stroke.emit(a, to)

func undo() -> void:
	if not segs.is_empty(): segs.pop_back(); Snd.sfx("chalk"); queue_redraw()

func _gui_input(ev: InputEvent) -> void:
	if k <= 0.0: return
	if ev is InputEventMouseMotion:
		_mouse = true; cursor = ev.position / k; queue_redraw()
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		_mouse = true; cursor = ev.position / k
		if ev.pressed: _begin()
		else: _end()
		accept_event(); queue_redraw()

func _process(dt: float) -> void:
	if not is_visible_in_tree(): return
	var ax := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if App.ui != null and ax == Vector2.ZERO: ax = App.ui.pad.stick
	if ax.length() > 0.05:
		_mouse = false
		cursor += ax * SPEED * dt
		cursor = cursor.clamp(Vector2(10, 10), Vector2(630, 410))
	elif not _mouse:
		# imán: el cursor quieto se pega al anclaje más cercano
		var i := nearest(cursor, SNAP)
		if i >= 0: cursor = cursor.lerp(anchors[i], minf(1.0, dt * 14.0))
	var act := Input.is_action_pressed("act") or (App.ui != null and App.ui.pad.held("act"))
	if act and not _act_was: _begin()
	elif not act and _act_was: _end()
	_act_was = act
	if Input.is_action_just_pressed("view"): undo()
	_shake = maxf(0.0, _shake - dt * 2.2)
	for f in _fade: f[2] += dt
	_fade = _fade.filter(func(f): return f[2] < 0.9)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(sin(Time.get_ticks_msec() * 0.06) * 7.0 * _shake * k, 0.0))
	super._draw()
	if hint.is_valid(): hint.call(self)
	for p in anchors: draw_circle(p * k, 3.2 * k, Color(App.INK, 0.35))
	for s in segs: line(anchors[s.x].x, anchors[s.x].y, anchors[s.y].x, anchors[s.y].y)
	for f in _fade:
		var a: Vector2 = anchors[f[0]]; var b: Vector2 = anchors[f[1]]
		draw_line(a * k, b * k, Color(App.ACC, 1.0 - f[2] / 0.9), maxf(1.0, 2.0 * k), true)
	if _from >= 0:
		draw_line(anchors[_from] * k, cursor * k, Color(App.INK, 0.55), maxf(1.0, 2.0 * k), true)
	var hot := nearest(cursor, GRAB)
	if hot >= 0: draw_arc(anchors[hot] * k, 9.0 * k, 0, TAU, 24, Color(App.ACC, 0.8), maxf(1.0, 1.5 * k), true)
	draw_line((cursor + Vector2(-7, 0)) * k, (cursor + Vector2(7, 0)) * k, App.ACC, maxf(1.0, 1.5 * k))
	draw_line((cursor + Vector2(0, -7)) * k, (cursor + Vector2(0, 7)) * k, App.ACC, maxf(1.0, 1.5 * k))
