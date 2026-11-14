# Interfaz: HUD, bloques de diálogo, narrador, avisos, inventario (manuscrito, saberes, posición), paneles y menú.
class_name UIRoot extends CanvasLayer

signal tick(dt)
signal advanced
signal picked(i)

const F_SERIF := preload("res://assets/fonts/CormorantGaramond.ttf")
const F_SERIF_IT := preload("res://assets/fonts/CormorantGaramond-Italic.ttf")
const F_CAPS := preload("res://assets/fonts/IMFeENsc28P.ttf")
const F_FELL := preload("res://assets/fonts/IMFeENrm28P.ttf")
const F_FELL_IT := preload("res://assets/fonts/IMFeENit28P.ttf")

var SPEAKERS := {
	yo = {name = "Tú", cls = "you", voice = "yo"},
	narr = {name = "", cls = "narr", voice = "narr"},
	logica = {name = "Lógica", cls = "inner", color = "#8fc7d8", voice = "inner"},
	decoro = {name = "Decoro", cls = "inner", color = "#d8b48f", voice = "inner"},
	asombro = {name = "Asombro", cls = "inner", color = "#b79cf0", voice = "inner"},
	recelo = {name = "Recelo", cls = "inner", color = "#e08a7a", voice = "inner"},
}

var auto := false
var serif: FontVariation
var serif_it: FontVariation
var caps: FontVariation
var size := Vector2(1280, 720)
var touch := false

# nodos
var hud: Control
var chapter_tag_l: Label
var objective_l: Label
var eye_frame: Panel
var compass: Control
var prompt_l: RichTextLabel
var prompt_box: PanelContainer
var bearing_l: Label
var eye_hint: Label
var keys_l: Label
var pad: Pad
var note_l: RichTextLabel
var toasts: VBoxContainer
var fade_r: ColorRect
var dock: VBoxContainer
var dock_margin: MarginContainer
var dlg: PanelContainer
var dlg_who: Label
var dlg_text: RichTextLabel
var dlg_choices: VBoxContainer
var dlg_more: Label
var pick: PanelContainer
var pick_title: Label
var pick_text: RichTextLabel
var pick_opts: HFlowContainer
var info: PanelContainer
var info_title: Label
var info_text: RichTextLabel
var slate_box: PanelContainer
var slate_board: SlateBoard
var slate_cap: Label
var title_box: Control
var title_veil: ColorRect
var t_num: Label
var t_title: Label
var t_sub: Label
var journal: Control
var j_tabs := {}
var j_list: VBoxContainer
var j_body: VBoxContainer
var j_split: BoxContainer
var menu: Control
var menu_btns: VBoxContainer
var menu_foot: Label

# estado
var dlg_open := false
var choosing := false
var picking := false
var journal_open := false
var menu_open := false
var auto_pick := Callable()
var last_frag := 0
var new_pages := false
var _adv_wait := false
var _adv_ok := 0
var _title_on := false
var _title_skip := false
var _fade_to := 1.0
var _fade_sp := 1.0
var _note_t := 0.0
var _tab := "ms"
var _n_opts := 0
var _opt_lock := []
var _block_tw: Tween
var _re := RegEx.new()

# ---------- construcción ----------
func _init() -> void:
	layer = 5
	_re.compile("\\*(.+?)\\*")
	var ts := TextServerManager.get_primary_interface()
	serif = FontVariation.new(); serif.base_font = F_SERIF; serif.variation_opentype = {ts.name_to_tag("wght"): 500}
	serif_it = FontVariation.new(); serif_it.base_font = F_SERIF_IT; serif_it.variation_opentype = {ts.name_to_tag("wght"): 500}
	caps = FontVariation.new(); caps.base_font = F_CAPS; caps.spacing_glyph = 2

func _ready() -> void:
	_build_hud()
	pad = Pad.new(); pad.ui = self; _full(pad); add_child(pad)
	note_l = _rich(22, App.BONE, F_FELL_IT, F_FELL)
	note_l.set_anchors_preset(Control.PRESET_CENTER_TOP); note_l.visible = false
	note_l.add_theme_constant_override("outline_size", 6); note_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	add_child(note_l)
	toasts = VBoxContainer.new(); toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_theme_constant_override("separation", 6); add_child(toasts)
	fade_r = ColorRect.new(); fade_r.color = Color("030607"); fade_r.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(fade_r); add_child(fade_r)
	_build_dock()
	_build_info()
	_build_slate()
	_build_title()
	_build_journal()
	_build_menu()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _full(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)

func _lbl(text: String, font: Font, fsize: int, color: Color) -> Label:
	var l := Label.new(); l.text = text; l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", font); l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	return l

func _rich(fsize: int, color: Color, font: Font = null, em_font: Font = null) -> RichTextLabel:
	var r := RichTextLabel.new(); r.bbcode_enabled = true; r.fit_content = true; r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", font if font else serif)
	r.add_theme_font_override("italics_font", em_font if em_font else serif_it)
	r.add_theme_font_override("bold_font", caps)
	for k in ["normal_font_size", "italics_font_size", "bold_font_size"]: r.add_theme_font_size_override(k, fsize)
	r.add_theme_color_override("default_color", color)
	r.add_theme_constant_override("line_separation", 2)
	return r

func _box(bg: Color, border := App.LINE, mx := 22, my := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = border; s.set_border_width_all(1)
	s.content_margin_left = mx; s.content_margin_right = mx; s.content_margin_top = my; s.content_margin_bottom = my
	return s

func _flat_btn(text: String, font: Font, fsize: int, color: Color) -> Button:
	var b := Button.new(); b.text = text; b.flat = true; b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font); b.add_theme_font_size_override("font_size", fsize)
	b.add_theme_color_override("font_color", color); b.add_theme_color_override("font_hover_color", App.GAS)
	b.add_theme_color_override("font_pressed_color", App.GAS); b.add_theme_color_override("font_disabled_color", App.FAINT)
	b.add_theme_color_override("font_focus_color", color)
	var e := StyleBoxEmpty.new(); e.content_margin_left = 10; e.content_margin_right = 10; e.content_margin_top = 5; e.content_margin_bottom = 5
	for k in ["normal", "hover", "pressed", "disabled", "focus"]: b.add_theme_stylebox_override(k, e)
	return b

func fmt(t: String, em := "i") -> String:
	return _re.sub(t, "[%s]$1[/%s]" % [em, em.split("=")[0]], true)

func _build_hud() -> void:
	hud = Control.new(); hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(hud); hud.visible = false; add_child(hud)
	chapter_tag_l = _lbl("", caps, 14, App.DIM); chapter_tag_l.position = Vector2(26, 16); hud.add_child(chapter_tag_l)
	objective_l = _lbl("", serif_it, 20, App.GAS); objective_l.position = Vector2(26, 38)
	objective_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; objective_l.custom_minimum_size.x = 330
	objective_l.add_theme_constant_override("outline_size", 5); objective_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	hud.add_child(objective_l)
	eye_frame = Panel.new(); eye_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := StyleBoxFlat.new(); fs.bg_color = Color(0, 0, 0, 0); fs.border_color = App.LINE; fs.set_border_width_all(1)
	eye_frame.add_theme_stylebox_override("panel", fs); hud.add_child(eye_frame)
	compass = Compass.new(); compass.ui = self; compass.size = Vector2(46, 46); compass.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(compass)
	prompt_box = PanelContainer.new(); prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_box.add_theme_stylebox_override("panel", _box(App.PANEL, App.LINE, 18, 6)); prompt_box.visible = false
	prompt_l = _rich(19, App.BONE); prompt_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	prompt_box.add_child(prompt_l); hud.add_child(prompt_box)
	bearing_l = _lbl("v", caps, 15, App.GAS); bearing_l.visible = false; hud.add_child(bearing_l)
	eye_hint = _lbl("VISTA DEL PLANO", caps, 12, App.FAINT); eye_hint.visible = false
	eye_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hud.add_child(eye_hint)
	keys_l = _lbl("V vista  ·  J inventario  ·  M sonido  ·  Esc menú", caps, 13, App.FAINT); hud.add_child(keys_l)

func _build_dock() -> void:
	dock_margin = MarginContainer.new(); dock_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(dock_margin); add_child(dock_margin)
	dock = VBoxContainer.new(); dock.mouse_filter = Control.MOUSE_FILTER_IGNORE; dock.alignment = BoxContainer.ALIGNMENT_END
	dock.add_theme_constant_override("separation", 10); dock_margin.add_child(dock)
	# panel de minijuego (elección con iconos)
	pick = PanelContainer.new(); pick.add_theme_stylebox_override("panel", _box(App.PANEL)); pick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pick.visible = false; dock.add_child(pick)
	var pv := VBoxContainer.new(); pv.add_theme_constant_override("separation", 6); pick.add_child(pv)
	pick_title = _lbl("", caps, 15, App.DIM); pick_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; pv.add_child(pick_title)
	pick_text = _rich(20, App.BONE, serif_it, serif); pick_text.text = ""; pv.add_child(pick_text)
	pick_opts = HFlowContainer.new(); pick_opts.alignment = FlowContainer.ALIGNMENT_CENTER
	pick_opts.add_theme_constant_override("h_separation", 8); pick_opts.add_theme_constant_override("v_separation", 8); pv.add_child(pick_opts)
	# bloque de diálogo
	dlg = PanelContainer.new(); dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg.add_theme_stylebox_override("panel", _box(App.PANEL, App.LINE, 26, 16)); dlg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dlg.visible = false; dock.add_child(dlg)
	var dv := VBoxContainer.new(); dv.mouse_filter = Control.MOUSE_FILTER_IGNORE; dv.add_theme_constant_override("separation", 4); dlg.add_child(dv)
	dlg_who = _lbl("", caps, 14, App.DIM); dv.add_child(dlg_who)
	dlg_text = _rich(23, App.BONE); dv.add_child(dlg_text)
	dlg_choices = VBoxContainer.new(); dlg_choices.add_theme_constant_override("separation", 0); dlg_choices.visible = false; dv.add_child(dlg_choices)
	dlg_more = _lbl("continuar", caps, 12, App.GAS); dlg_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; dlg_more.visible = false; dv.add_child(dlg_more)

func _build_info() -> void:
	info = PanelContainer.new(); info.mouse_filter = Control.MOUSE_FILTER_IGNORE; info.add_theme_stylebox_override("panel", _box(App.PANEL, App.LINE, 20, 10))
	info.visible = false; add_child(info)
	var v := VBoxContainer.new(); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; info.add_child(v)
	info_title = _lbl("", caps, 14, App.DIM); info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(info_title)
	info_text = _rich(19, App.BONE, serif_it, serif); v.add_child(info_text)

func _build_slate() -> void:
	slate_box = PanelContainer.new(); slate_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slate_box.add_theme_stylebox_override("panel", _box(Color("0a1215"), App.LINE, 14, 12)); slate_box.visible = false; add_child(slate_box)
	var v := VBoxContainer.new(); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; slate_box.add_child(v)
	slate_board = SlateBoard.new(); slate_board.font = serif_it; slate_board.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_child(slate_board)
	slate_cap = _lbl("", caps, 12, App.FAINT); slate_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(slate_cap)

func _build_title() -> void:
	title_box = Control.new(); title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(title_box); title_box.visible = false; add_child(title_box)
	title_veil = ColorRect.new(); title_veil.color = Color(0.012, 0.024, 0.028, 0.86); title_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(title_veil); title_box.add_child(title_veil)
	var c := CenterContainer.new(); c.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(c); title_box.add_child(c)
	var v := VBoxContainer.new(); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_theme_constant_override("separation", 8); c.add_child(v)
	t_num = _lbl("", caps, 16, App.GAS); t_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t_num)
	t_title = _lbl("", F_FELL, 64, App.BONE); t_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(t_title)
	var rule := ColorRect.new(); rule.color = Color(App.BONE, 0.5); rule.custom_minimum_size = Vector2(120, 1); rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; v.add_child(rule)
	t_sub = _lbl("", serif_it, 22, App.DIM); t_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(t_sub)

func _build_journal() -> void:
	journal = Control.new(); _full(journal); journal.visible = false; add_child(journal)
	var bg := ColorRect.new(); bg.color = Color(0.016, 0.031, 0.039, 0.96); _full(bg); journal.add_child(bg)
	var m := MarginContainer.new(); _full(m); journal.add_child(m)
	for k in ["margin_left", "margin_right"]: m.add_theme_constant_override(k, 28)
	m.add_theme_constant_override("margin_top", 18); m.add_theme_constant_override("margin_bottom", 18)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 8); m.add_child(v)
	var head := HBoxContainer.new(); head.add_theme_constant_override("separation", 6); v.add_child(head)
	for t in [["ms", "El Manuscrito"], ["know", "Saberes"], ["pos", "Posición social"]]:
		var b := _flat_btn(t[1], caps, 16, App.FAINT); b.pressed.connect(j_tab.bind(t[0])); head.add_child(b); j_tabs[t[0]] = b
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(sp)
	var cl := _flat_btn("cerrar", caps, 16, App.DIM); cl.pressed.connect(func(): toggle_journal()); head.add_child(cl)
	var rule := ColorRect.new(); rule.color = App.LINE; rule.custom_minimum_size.y = 1; v.add_child(rule)
	j_split = BoxContainer.new(); j_split.size_flags_vertical = Control.SIZE_EXPAND_FILL; j_split.add_theme_constant_override("separation", 30); v.add_child(j_split)
	var ls := ScrollContainer.new(); ls.custom_minimum_size = Vector2(300, 210); ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; j_split.add_child(ls)
	j_list = VBoxContainer.new(); j_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; j_list.add_theme_constant_override("separation", 0); ls.add_child(j_list)
	var ts := ScrollContainer.new(); ts.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ts.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ts.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; j_split.add_child(ts)
	var tm := MarginContainer.new(); tm.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tm.add_theme_constant_override("margin_right", 16); ts.add_child(tm)
	j_body = VBoxContainer.new(); j_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; j_body.add_theme_constant_override("separation", 10); tm.add_child(j_body)

func _build_menu() -> void:
	menu = Control.new(); _full(menu); menu.visible = false; add_child(menu)
	var veil := ColorRect.new(); veil.color = Color(0.012, 0.024, 0.028, 0.72); veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(veil); menu.add_child(veil)
	var sc := ScrollContainer.new(); _full(sc); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; menu.add_child(sc)
	var c := CenterContainer.new(); c.size_flags_horizontal = Control.SIZE_EXPAND_FILL; c.size_flags_vertical = Control.SIZE_EXPAND_FILL; sc.add_child(c)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 2); c.add_child(v)
	var over := _lbl("EDWIN A. ABBOTT  ·  1884", caps, 13, App.DIM); over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(over)
	var ft := FontVariation.new(); ft.base_font = F_FELL; ft.spacing_glyph = 10
	var h := _lbl("PLANILANDIA", ft, 96, App.BONE); h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; h.name = "Title"; v.add_child(h)
	var sub := _lbl("Un romance de muchas dimensiones", serif_it, 26, App.GAS); sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(sub)
	var gap := Control.new(); gap.custom_minimum_size.y = 22; v.add_child(gap)
	menu_btns = VBoxContainer.new(); menu_btns.add_theme_constant_override("separation", 0); menu_btns.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; v.add_child(menu_btns)
	var gap2 := Control.new(); gap2.custom_minimum_size.y = 18; v.add_child(gap2)
	menu_foot = _lbl("", serif_it, 15, App.FAINT); menu_foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(menu_foot)

# ---------- disposición ----------
func _layout() -> void:
	size = get_viewport().get_visible_rect().size
	var port := size.x < size.y
	var narrow := size.x < 760
	objective_l.custom_minimum_size.x = minf(330, size.x * 0.5)
	objective_l.size.x = objective_l.custom_minimum_size.x
	var sw := 0.7 if port and size.x < 820 else 0.44
	eye_frame.size = Vector2(size.x * sw, 44); eye_frame.position = Vector2((size.x - eye_frame.size.x) / 2.0, 14)
	if port: chapter_tag_l.position = Vector2(14, 66); objective_l.position = Vector2(14, 86)
	else: chapter_tag_l.position = Vector2(26, 16); objective_l.position = Vector2(26, 38)
	compass.position = Vector2(size.x - 176, 12)
	eye_hint.size.x = size.x; eye_hint.position = Vector2(0, 70)
	keys_l.reset_size(); keys_l.position = Vector2(size.x - keys_l.size.x - 24, size.y - 34)
	toasts.position = Vector2(14 if narrow else 26, 150 if port else 120)
	var side := 16.0
	if touch and not port: side = 170.0
	var w := clampf(size.x - side * 2.0, 280.0, 800.0)
	dlg.custom_minimum_size.x = w; pick.custom_minimum_size.x = minf(size.x - 24.0, 860.0)
	dock_margin.add_theme_constant_override("margin_left", 12); dock_margin.add_theme_constant_override("margin_right", 12)
	_dock_bottom()
	info.custom_minimum_size.x = minf(size.x - 40.0, 620.0)
	note_l.custom_minimum_size.x = minf(size.x - 40.0, 860.0)
	t_title.custom_minimum_size.x = minf(size.x - 40.0, 1000.0); t_sub.custom_minimum_size.x = minf(size.x - 60.0, 680.0)
	t_title.add_theme_font_size_override("font_size", int(clampf(size.x * 0.06, 34, 72)))
	var sbw := minf(640.0, size.x - 60.0)
	slate_board.custom_minimum_size = Vector2(sbw, sbw * 420.0 / 640.0)
	j_split.vertical = port or size.x < 820
	var mt := menu.find_child("Title", true, false) as Label
	if mt: mt.add_theme_font_size_override("font_size", int(clampf(size.x * 0.085, 40, 118)))
	pad.queue_redraw()

func _dock_bottom() -> void:
	var port := size.x < size.y
	var b := 14.0
	if touch and port and not dlg_open and not picking: b = 176.0
	dock_margin.add_theme_constant_override("margin_bottom", int(b))

func _process(dt: float) -> void:
	tick.emit(dt)
	if fade_r.color.a != _fade_to:
		fade_r.color.a = move_toward(fade_r.color.a, _fade_to, dt * _fade_sp)
	fade_r.visible = fade_r.color.a > 0.001
	if note_l.visible and _note_t > 0.0:
		_note_t -= dt
		if _note_t <= 0.0: note_l.visible = false
	if note_l.visible:
		note_l.reset_size(); note_l.position = Vector2((size.x - note_l.size.x) / 2.0, 96 if not info.visible else info.position.y + info.size.y + 8)
	if info.visible:
		info.reset_size(); info.position = Vector2((size.x - info.size.x) / 2.0, 74)
	if slate_box.visible:
		slate_box.reset_size(); slate_box.position = Vector2((size.x - slate_box.size.x) / 2.0, maxf(8.0, (size.y - slate_box.size.y) * 0.3))
	if prompt_box.visible:
		prompt_box.reset_size(); prompt_box.position = Vector2((size.x - prompt_box.size.x) / 2.0, size.y * 0.80 - prompt_box.size.y)
	if dlg_more.visible: dlg_more.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.004)
	_dock_bottom()

func sleep(sec: float) -> void:
	if auto: return
	var t := sec
	while t > 0.0: t -= await tick

func set_touch(on: bool) -> void:
	if touch == on: return
	touch = on; _layout()

# ---------- avisos y HUD ----------
func toast(kind: String, small: String, text: String) -> void:
	var p := PanelContainer.new(); p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := _box(App.PANEL, Color(0, 0, 0, 0), 14, 6); s.set_border_width_all(0); s.border_width_left = 2
	s.border_color = {frag = App.BONE, her = App.HERESY, bad = App.BAD, good = App.GOOD}.get(kind, App.GAS)
	p.add_theme_stylebox_override("panel", s)
	var v := VBoxContainer.new(); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_theme_constant_override("separation", -2); p.add_child(v)
	v.add_child(_lbl(small.to_upper(), caps, 11, App.DIM)); v.add_child(_lbl(text, serif, 18, App.BONE))
	toasts.add_child(p)
	while toasts.get_child_count() > 4: toasts.get_child(0).free()
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.3); tw.tween_interval(3.6); tw.tween_property(p, "modulate:a", 0.0, 0.6); tw.tween_callback(p.queue_free)

func objective(t: String) -> void:
	objective_l.text = t; objective_l.visible = t != ""

func chapter_tag(t: String) -> void:
	chapter_tag_l.text = t.to_upper()

func prompt(text) -> void:
	if text == null or touch: prompt_box.visible = false; return
	if prompt_l.text != text: prompt_l.text = text
	prompt_box.visible = true

func fade(on: bool, sec := 0.3) -> void:
	_fade_to = 1.0 if on else 0.0
	if auto: fade_r.color.a = _fade_to; return
	_fade_sp = 1.0 / maxf(sec, 0.01)
	await sleep(sec + 0.03)

# rótulo de capítulo: breve, sobre un velo, y se puede saltar con un toque
func title(num: String, title_text: String, sub := "", dur := 2.6) -> void:
	if auto: return
	t_num.text = num.to_upper(); t_title.text = title_text; t_sub.text = sub
	title_box.visible = true; title_box.modulate.a = 0.0; _title_on = true; _title_skip = false
	Snd.sfx("bell")
	var t := 0.0
	while t < dur and not (_title_skip and t > 0.45):
		t += await tick
		title_box.modulate.a = minf(1.0, t / 0.35)
	var a := 1.0
	_title_on = false
	while a > 0.0:
		a -= (await tick) / 0.3
		title_box.modulate.a = maxf(a, 0.0)
	title_box.visible = false

# ---------- avance ----------
func advance() -> bool:
	if _title_on: _title_skip = true; return true
	if _adv_wait:
		if Time.get_ticks_msec() >= _adv_ok:
			_adv_wait = false; advanced.emit()
		return true
	return false

func wait_advance() -> void:
	_adv_wait = true; _adv_ok = Time.get_ticks_msec() + 160
	await advanced

func waiting() -> bool:
	return _adv_wait

# ---------- bloques de texto ----------
func cast(map: Dictionary) -> void:
	SPEAKERS.merge(map, true)

func _show_block(who: String, text: String) -> void:
	var sp: Dictionary = SPEAKERS.get(who, {name = who, voice = "yo"})
	var cls: String = sp.get("cls", "")
	var col: Color = Color(sp.color) if sp.has("color") else App.DIM
	dlg_who.text = (sp.name as String).to_upper(); dlg_who.visible = sp.name != ""
	dlg_who.add_theme_color_override("font_color", App.FAINT if cls == "you" else col)
	var body := fmt(text)
	var tc := App.BONE
	if cls == "narr":
		body = "[center]" + fmt(text, "color=#fff6dc") + "[/center]"; tc = Color("cfc8b2")
		dlg_text.add_theme_font_override("normal_font", F_FELL_IT)
	elif cls == "inner":
		body = fmt(text, "color=#ffffff"); tc = col
		dlg_text.add_theme_font_override("normal_font", serif_it)
	else:
		if cls == "you": tc = Color("b9c7c2")
		dlg_text.add_theme_font_override("normal_font", serif)
	dlg_text.add_theme_color_override("default_color", tc)
	dlg_text.text = body; dlg_text.visible = true
	dlg_choices.visible = false; dlg.visible = true
	if _block_tw: _block_tw.kill()
	dlg.modulate.a = 0.0
	_block_tw = create_tween(); _block_tw.tween_property(dlg, "modulate:a", 1.0, 0.16)
	Snd.blip(sp.get("voice", "yo"))

func open_dlg() -> void:
	if not dlg_open: dlg_open = true; _layout()

func close_dlg() -> void:
	dlg_open = false; dlg.visible = false; dlg_more.visible = false; _layout()

func say(who: String, text: String) -> void:
	if auto: return
	open_dlg()
	_show_block(who, text)
	dlg_more.visible = true
	await wait_advance()
	dlg_more.visible = false; Snd.sfx("ui")

# Narración del preso (bloqueante: espera a que el jugador continúe)
func narrate(text: String, _wide := false) -> void:
	if auto: return
	_show_block("narr", text)
	dlg_more.visible = true
	await wait_advance()
	dlg_more.visible = false; Snd.sfx("ui")
	if not dlg_open: dlg.visible = false

# Apunte no bloqueante
func note(text: String, sec := 6.0) -> void:
	if auto: return
	note_l.text = "[center]" + fmt(text, "color=#e6bd6e") + "[/center]"; note_l.visible = true; _note_t = sec

# opts: [{t, id, tag, lock}] → devuelve id (o índice)
func choose(opts: Array, _echo := true):
	if auto:
		var i := 0
		if auto_pick.is_valid(): i = auto_pick.call(opts)
		else:
			for k in opts.size():
				if not _locked(opts[k]): i = k; break
		return opts[i].get("id", i)
	open_dlg()
	for c in dlg_choices.get_children(): c.free()
	_opt_lock = []
	for i in opts.size():
		var o: Dictionary = opts[i]
		var lock := _locked(o)
		_opt_lock.append(lock)
		var bb := "[color=#4b605f][b]%d[/b][/color]   " % (i + 1)
		if o.get("tag", "") != "": bb += "[color=%s][b]%s[/b][/color]  " % ["#4b605f" if lock else "#b79cf0", (o.tag as String).to_upper()]
		bb += fmt(o.t)
		if lock and o.lock is String: bb += "  [color=#4b605f][i]— %s[/i][/color]" % o.lock
		var row := ChoiceRow.new(); row.setup(self, bb, lock, i == 0)
		if not lock: row.chosen.connect(_pick.bind(i))
		dlg_choices.add_child(row)
	_n_opts = opts.size()
	if not dlg.visible:
		dlg_who.visible = false; dlg_text.visible = false; dlg.visible = true; dlg.modulate.a = 1.0
	dlg_choices.visible = true; dlg_more.visible = false; choosing = true
	_adv_ok = Time.get_ticks_msec() + 260
	var p: int = await picked
	choosing = false; _n_opts = 0
	dlg_choices.visible = false
	Snd.sfx("pick")
	return opts[p].get("id", p)

func _locked(o: Dictionary) -> bool:
	var l = o.get("lock", null)
	return l != null and not (l is bool and l == false) and not (l is String and l == "") and not (l is int and l == 0)

func _pick(i: int) -> void:
	if Time.get_ticks_msec() < _adv_ok: return
	if choosing or picking: picked.emit(i)

func pick_key(n: int) -> bool:
	if choosing:
		if n < _n_opts and not _opt_lock[n]: _pick(n)
		return true
	if picking:
		if n < _n_opts: _pick(n)
		return true
	return false

# ---------- panel de minijuego ----------
func panel(title_text: String, text: String, options: Array):
	if auto: return options[0].get("id", 0)
	for c in pick_opts.get_children(): c.free()
	pick_title.text = title_text.to_upper(); pick_text.text = "[center]" + fmt(text, "color=#fff6dc") + "[/center]"
	for i in options.size():
		var o: Dictionary = options[i]
		var card := OptCard.new(); card.setup(self, o, i)
		card.chosen.connect(_pick.bind(i)); pick_opts.add_child(card)
	_n_opts = options.size(); picking = true; pick.visible = true
	_adv_ok = Time.get_ticks_msec() + 260
	_layout()
	var p: int = await picked
	picking = false; pick.visible = false; _n_opts = 0
	Snd.sfx("pick"); _layout()
	return options[p].get("id", p)

func panel_info(title_text, text := "") -> void:
	if title_text == null: info.visible = false; return
	if auto: return
	info_title.text = (title_text as String).to_upper(); info_text.text = "[center]" + fmt(text, "color=#fff6dc") + "[/center]"; info.visible = true

func slate(show: bool, cap := "") -> SlateBoard:
	slate_box.visible = show and not auto; slate_cap.text = cap.to_upper()
	return slate_board

# ---------- inventario: manuscrito, saberes, posición ----------
func toggle_journal(tab := "") -> void:
	journal_open = not journal_open; journal.visible = journal_open
	App.g.paused = journal_open
	if journal_open:
		new_pages = false
		j_tab(tab if tab != "" else _tab); Snd.sfx("ui")

func _j_head(t: String) -> void:
	var l := _lbl(t.to_upper(), caps, 12, App.GAS); j_list.add_child(l)

func _j_item(text: String, have: bool, cb: Callable) -> Button:
	var b := _flat_btn(text, serif if have else serif_it, 18, App.BONE if have else App.FAINT)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; b.clip_text = true
	b.pressed.connect(cb); j_list.add_child(b)
	return b

func _j_clear(c: Node) -> void:
	for k in c.get_children(): k.free()

func _j_text(sec: String, head: String, paras: Array, missing := "") -> void:
	_j_clear(j_body)
	j_body.add_child(_lbl(sec.to_upper(), caps, 12, App.GAS))
	if head != "":
		var h := _lbl(head, F_FELL, 32, App.BONE); h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; j_body.add_child(h)
	for p in paras:
		var r := _rich(21, App.BONE); r.text = fmt(p); r.add_theme_constant_override("line_separation", 5); j_body.add_child(r)
	if missing != "":
		var r := _rich(20, App.FAINT, serif_it); r.text = missing; j_body.add_child(r)

func j_tab(tab: String) -> void:
	_tab = tab
	var S: Dictionary = App.g.state
	for k in j_tabs: j_tabs[k].add_theme_color_override("font_color", App.BONE if k == tab else App.FAINT)
	_j_clear(j_list); _j_clear(j_body)
	if tab == "ms":
		var F: Array = App.g.book.fragments
		var show := func(n: int):
			var f: Dictionary = F[n - 1]
			var sec := ("Parte I · Este mundo" if n <= 12 else "Parte II · Otros mundos") + " — § %d" % n
			if S.frags.has(str(n)): _j_text(sec, f.title, f.text)
			else: _j_text(sec, f.title, [], "Esta sección aún no ha sido escrita. " + f.hint)
		var info_l := _lbl("%d de 22 secciones recuperadas" % S.frags.size(), serif_it, 16, App.DIM); j_list.add_child(info_l)
		for i in F.size():
			if i == 0: _j_head("Parte I — Este mundo")
			if i == 12: _j_head("Parte II — Otros mundos")
			var have: bool = S.frags.has(str(i + 1))
			_j_item("§%d   %s" % [i + 1, F[i].title if have else "· · ·"], have, show.bind(i + 1))
		var first := 1
		if last_frag > 0 and S.frags.has(str(last_frag)): first = last_frag
		elif not S.frags.is_empty(): first = int(S.frags.keys()[0])
		show.call(first)
	elif tab == "know":
		var K: Dictionary = App.g.book.knowledge
		var show := func(id: String):
			if S.know.has(id): _j_text("Saber", K[id].title, [K[id].text])
			else: _j_text("Saber", "", [], "Aún ignoras esto.")
		_j_head("Lo que sabes del mundo")
		var first := ""
		for id in K:
			var have: bool = S.know.has(id)
			if have and first == "": first = id
			_j_item(K[id].title if have else "· · ·", have, show.bind(id))
		show.call(first if first != "" else K.keys()[0])
	else:
		_j_head("Tu figura")
		var r := _rich(18, App.BONE)
		r.text = "Un [b]Cuadrado[/b]: cuatro lados iguales, cuatro ángulos rectos. Clase profesional. Tus hijos son Pentágonos; tus nietos, Hexágonos.\n\n[color=#8fa3a0][i]Mujeres (líneas) · Isósceles · Equiláteros · [/i][/color][b]Cuadrados[/b][color=#8fa3a0][i] · Pentágonos · Hexágonos… · Círculos[/i][/color]"
		j_list.add_child(r)
		j_body.add_child(_lbl("POSICIÓN SOCIAL", caps, 12, App.GAS))
		j_body.add_child(_lbl("Cómo te ven", F_FELL, 32, App.BONE))
		var d := func(v: float, a: String, b: String, c: String) -> String: return a if v <= -2 else (c if v >= 2 else b)
		var bars := [
			["Sacerdocio", S.rep.sac, "sospechoso", "devoto", d.call(S.rep.sac, "Los Círculos te observan de reojo.", "Para los Círculos eres un Cuadrado más.", "Los Círculos te tienen por hijo fiel de la Configuración.")],
			["Ciudadanía", S.rep.ciu, "altivo", "apreciado", d.call(S.rep.ciu, "En la calle se apartan a tu paso, y no por respeto.", "Tus vecinos te saludan con la cortesía debida.", "Hasta los Isósceles pronuncian tu nombre con afecto.")],
			["Autoridad", S.rep.aut, "díscolo", "fiable", d.call(S.rep.aut, "El Prefecto guarda una tablilla con tu nombre.", "La autoridad no tiene queja de ti.", "La autoridad te considera un instrumento seguro.")],
			["Tu pensamiento", S.her, "ortodoxia", "herejía", d.call(S.her, "Crees lo que te enseñaron, y duermes bien.", "Dudas, pero en voz baja.", "Has empezado a preguntar lo que no se pregunta.")],
		]
		for b in bars:
			var row := HBoxContainer.new(); j_body.add_child(row)
			var l1 := _lbl((b[0] as String).to_upper(), caps, 13, App.DIM); l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(l1)
			row.add_child(_lbl("%s  /  %s" % [b[2], b[3]], caps, 13, App.DIM))
			var bar := Bar.new(); bar.v = clampf(b[1], -5, 5); bar.custom_minimum_size.y = 16; j_body.add_child(bar)
			var ds := _lbl(b[4], serif_it, 17, App.DIM); ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; j_body.add_child(ds)

# ---------- menú ----------
func show_menu(items: Array, chapters: Array, max_ch: int, on_chapter: Callable) -> void:
	menu.visible = true; menu_open = true; hud.visible = false
	for c in menu_btns.get_children(): c.free()
	var chs := GridContainer.new(); chs.columns = 1 if size.x < 720 else 2; chs.visible = false
	chs.add_theme_constant_override("h_separation", 20); chs.add_theme_constant_override("v_separation", -4)
	for it in items:
		var b := _flat_btn((it[0] as String).to_upper(), caps, 19, App.BONE)
		if it[1] is String and it[1] == "chapters": b.pressed.connect(func(): Snd.sfx("pick"); chs.visible = not chs.visible)
		else: b.pressed.connect(func(): Snd.sfx("pick"); it[1].call(b))
		menu_btns.add_child(b)
	menu_btns.add_child(chs)
	for i in chapters.size():
		var b := _flat_btn(chapters[i], caps, 15, App.BONE); b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = i > max_ch; b.pressed.connect(func(): Snd.sfx("pick"); on_chapter.call(i)); chs.add_child(b)
	menu_foot.text = "Una aventura narrativa. Se recomienda sonido.\n" + ("Arrastra para moverte · toca para continuar · mejor en horizontal" if touch else "WASD / flechas · E interactuar · Espacio continuar · V cambiar de vista · J inventario")

func hide_menu() -> void:
	menu.visible = false; menu_open = false; hud.visible = true


# ---------- piezas ----------
class ChoiceRow extends PanelContainer:
	signal chosen
	var _lock := false
	var _hover := false
	func setup(ui: UIRoot, bb: String, lock: bool, first: bool) -> void:
		_lock = lock
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_ARROW if lock else Control.CURSOR_POINTING_HAND
		var e := StyleBoxEmpty.new(); e.content_margin_left = 12; e.content_margin_right = 8; e.content_margin_top = 9; e.content_margin_bottom = 9
		add_theme_stylebox_override("panel", e)
		var r := ui._rich(21, App.FAINT if lock else App.GAS)
		r.add_theme_font_size_override("bold_font_size", 12)
		r.text = bb; add_child(r)
		custom_minimum_size.y = 44
		set_meta("first", first)
		mouse_entered.connect(func(): _hover = true; queue_redraw())
		mouse_exited.connect(func(): _hover = false; queue_redraw())
	func _draw() -> void:
		draw_line(Vector2(0, 0), Vector2(size.x, 0), App.LINE, 1.0)
		if _hover and not _lock:
			draw_rect(Rect2(Vector2.ZERO, size), Color(App.GAS, 0.09))
			draw_rect(Rect2(0, 0, 2, size.y), App.GAS)
	func _gui_input(ev: InputEvent) -> void:
		if _lock: return
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed and Rect2(Vector2.ZERO, size).has_point(ev.position):
			accept_event(); chosen.emit()

class OptCard extends PanelContainer:
	signal chosen
	var o := {}
	var _hover := false
	func setup(ui: UIRoot, opt: Dictionary, i: int) -> void:
		o = opt
		mouse_filter = Control.MOUSE_FILTER_STOP; mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if o.has("swatch"):
			custom_minimum_size = Vector2(48, 48); add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		else:
			add_theme_stylebox_override("panel", ui._box(Color(0, 0, 0, 0), App.LINE, 14, 7))
			custom_minimum_size = Vector2(98, 48)
			var v := VBoxContainer.new(); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_theme_constant_override("separation", 0); add_child(v)
			if o.has("icon"):
				var ic := PolyIcon.new(); ic.kind = o.icon; ic.custom_minimum_size = Vector2(26, 28); ic.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_child(ic)
			var l := ui._lbl(o.label, ui.serif, 18, App.BONE); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l)
			var s := ui._lbl(o.get("sub", str(i + 1)), ui.caps, 11, App.FAINT); s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(s)
		mouse_entered.connect(func(): _hover = true; queue_redraw())
		mouse_exited.connect(func(): _hover = false; queue_redraw())
	func _draw() -> void:
		if o.has("swatch"):
			draw_circle(size / 2.0, 21, Color(o.swatch))
			if _hover: draw_arc(size / 2.0, 23, 0, TAU, 40, App.BONE, 2.0, true)
		elif _hover: draw_rect(Rect2(Vector2.ZERO, size), App.GAS, false, 1.0)
	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed and Rect2(Vector2.ZERO, size).has_point(ev.position):
			accept_event(); chosen.emit()

# icono de clase: 2 = línea, 1 = isósceles, n = polígono
class PolyIcon extends Control:
	var kind := 4
	func _draw() -> void:
		var c := Vector2(size.x / 2.0, 14); var col := App.BONE
		if kind == 2: draw_line(c + Vector2(-10, 0), c + Vector2(10, 0), col, 1.4, true); return
		var pts := PackedVector2Array()
		if kind == 1: pts = PackedVector2Array([c + Vector2(-1.5, 9), c + Vector2(1.5, 9), c + Vector2(0, -11)])
		else:
			for i in kind: pts.append(c + Vector2(cos(TAU * i / kind - PI / 2), sin(TAU * i / kind - PI / 2)) * 10.0)
		pts.append(pts[0])
		draw_polyline(pts, col, 1.3, true)

class Bar extends Control:
	var v := 0.0
	func _draw() -> void:
		var y := size.y / 2.0
		draw_rect(Rect2(0, y - 1.5, size.x, 3), App.FAINT)
		draw_line(Vector2(size.x / 2.0, y - 5), Vector2(size.x / 2.0, y + 5), App.DIM, 1.0)
		var x := size.x * (0.5 + v * 0.1)
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - 7), Vector2(x + 7, y), Vector2(x, y + 7), Vector2(x - 7, y)]), App.BONE)

class Compass extends Control:
	var ui: UIRoot
	func _draw() -> void:
		var c := size / 2.0
		draw_arc(c, 22, 0, TAU, 48, App.LINE, 1.0, true)
		draw_line(c + Vector2(0, -4), c + Vector2(0, 16), Color(App.BONE, 0.5), 1.0)
		draw_string(ui.caps, c + Vector2(-5, -8), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, App.DIM)
