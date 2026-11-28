# Franjas de cine (S-08, T-07): dos bandas de tinta que entran en 0,4 s en las escenas sin control, y un
# anillo que se llena mientras se mantiene pulsado «saltar» (1 s) junto a su glifo.
class_name Letterbox extends Control

const BAND := 0.09
var ui: UIRoot
var on := false
var t := 0.0              # 0..1: cuánto han entrado las bandas
var hold := 0.0           # 0..1: progreso de «mantén para saltar»
var skippable := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_bands(v: bool, can_skip := true) -> void:
	on = v; skippable = can_skip and v; hold = 0.0

func _process(dt: float) -> void:
	var want := 1.0 if on else 0.0
	if t != want:
		t = move_toward(t, want, dt / 0.4); queue_redraw()
	elif on and skippable: queue_redraw()
	visible = t > 0.0

func _draw() -> void:
	var s := size
	var h := s.y * BAND * App.ease(t)
	draw_rect(Rect2(0, 0, s.x, h), App.INK)
	draw_rect(Rect2(0, s.y - h, s.x, h), App.INK)
	if not skippable or t < 1.0 or ui == null: return
	var txt := (ui.T("mantén el dedo para saltar") if ui.touch else "%s %s  %s" % [ui.T("mantén"), Glyphs.name_of("advance"), ui.T("para saltar")]).to_upper()
	var fs := 12
	var w := ui.caps.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := Vector2(s.x - w - 46, s.y - h / 2.0 + 4)
	draw_string(ui.caps, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(App.CARD, 0.75))
	var c := Vector2(s.x - 26, s.y - h / 2.0)
	draw_arc(c, 9, 0, TAU, 28, Color(App.CARD, 0.35), 2.0, true)
	if hold > 0.0: draw_arc(c, 9, -PI / 2, -PI / 2 + TAU * hold, 28, App.ACC, 2.4, true)
