# Pizarra: dibujo a tinta, animado, sobre una hoja milimetrada de 640×420.
class_name SlateBoard extends Control

var painter := Callable()
var t := 0.0
var font: Font
var k := 1.0

func paint(p: Callable, tt: float) -> void:
	painter = p; t = tt; queue_redraw()

func _draw() -> void:
	k = size.x / 640.0
	draw_rect(Rect2(Vector2.ZERO, size), Color("fbf7ea"))
	var gc := Color("6d93b0")
	for i in range(0, 641, 20):
		draw_line(Vector2(i, 0) * k, Vector2(i, 420) * k, Color(gc, 0.34 if i % 100 == 0 else 0.14), 1.0)
	for j in range(0, 421, 20):
		draw_line(Vector2(0, j) * k, Vector2(640, j) * k, Color(gc, 0.34 if j % 100 == 0 else 0.14), 1.0)
	if painter.is_valid(): painter.call(self, t)

func line(x1: float, y1: float, x2: float, y2: float, a := 1.0) -> void:
	draw_line(Vector2(x1, y1) * k, Vector2(x2, y2) * k, Color(App.INK, a), maxf(1.0, 2.0 * k), true)

func dot(x: float, y: float, r := 5.0) -> void:
	draw_circle(Vector2(x, y) * k, r * k, App.INK)

func box(x: float, y: float, w: float, h: float) -> void:
	draw_rect(Rect2(x * k, y * k, w * k, h * k), App.INK, false, maxf(1.0, 2.0 * k))

func text(s: String, x: float, y: float, fs := 22) -> void:
	draw_string(font, Vector2(x, y) * k, s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs * k), App.INK)
