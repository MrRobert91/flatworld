# Interfaz en tinta sobre papel: HUD, bloques de diálogo, narrador, avisos, inventario (manuscrito, saberes, posición), paneles y menú.
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
	logica = {name = "Lógica", cls = "inner", color = "#1f6f8a", voice = "inner"},
	decoro = {name = "Decoro", cls = "inner", color = "#8a5a1c", voice = "inner"},
	asombro = {name = "Asombro", cls = "inner", color = "#5b3fa8", voice = "inner"},
	recelo = {name = "Recelo", cls = "inner", color = "#9c2f20", voice = "inner"},
}

const ICON := {mujer = 2, iso = 1, tri = 3, cuad = 4, yo = 4, penta = 5, hexa = 6, nino = 6, circ = 24, esfera = 24, rey = 2, punto = 0}

var auto := false
var serif: FontVariation
var serif_it: FontVariation
var caps: FontVariation
var size := Vector2(1280, 720)
var touch := false
var compact := false     # pantalla baja (móvil apaisado)
var port := false
var strip_rect := Rect2(0, 0, 100, 40)

# nodos
var paper: ColorRect
var hud: Control
var hud_card: PanelContainer
var chapter_tag_l: Label
var objective_l: Label
var eye_frame: Panel
var compass: Control
var prompt_l: RichTextLabel
var prompt_box: PanelContainer
var bearing_l: Bearing
var eye_hint: Label
var keys_l: Label
var keys_box: PanelContainer
var pad: Pad
var note_l: RichTextLabel
var note_box: PanelContainer
var toasts: VBoxContainer
var fade_r: ColorRect
var hurt_r: ColorRect
var dock: VBoxContainer
var dock_margin: MarginContainer
var dlg: PanelContainer
var dlg_head: HBoxContainer
var dlg_icon: PolyIcon
var dlg_who: Label
var dlg_text: RichTextLabel
var dlg_choices: VBoxContainer
var dlg_scroll: ScrollContainer
var dlg_scroll_hint: Label
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
var title_rule: Rule
var journal: Control
var j_tabs := {}
var j_list: VBoxContainer
var j_body: VBoxContainer
var j_split: BoxContainer
var j_ls: ScrollContainer
var menu: Control
var menu_split: BoxContainer
var menu_title: Label
var menu_btns: VBoxContainer
var menu_foot: Label
var pause: Control
var pause_btns: VBoxContainer

# estado
var dlg_open := false
var choosing := false
var picking := false
var journal_open := false
var menu_open := false
var pause_open := false
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
var _menu_args := []
var _typing := false      # el bloque se va escribiendo
var _type_n := 0.0
var _type_total := 0
var _type_voice := "yo"
var _type_blip := 0
var _type_pause := 0.0
var _fit_n := 0
var _page_info := ""      # «2 / 3» cuando un parlamento ocupa varias páginas
# historial, lectura y elección (S-09)
var history := []         # [{who, text}] (tope de 200)
const HISTORY_MAX := 200
const CPS := [30.0, 62.0, 110.0, 100000.0]   # letras por segundo: lenta, normal, rápida, instantánea
var _auto_t := -1.0       # cuenta atrás del avance automático
var _skip_t := 0.0
var _cur_seen := false    # el parlamento en pantalla ya se leyó en alguna partida
var _sel := -1            # respuesta resaltada con el mando o las flechas
var settings_open := false
var settings: SettingsPanel
var letterbox: Letterbox
var caption_l: Label
var _cap_t := 0.0
var blind: ColorRect      # venda (palpar sin ver)
var black: ColorRect      # negro (el gancho del juicio)
var tally_l: Label        # las muescas del sargento (C3-02)
var split: SubViewportContainer   # plano partido: la lámina bajo la línea (C3-03)
var split_cam: Camera3D

# ---------- construcción ----------
func _init() -> void:
	layer = 5
	_re.compile("\\*(.+?)\\*")
	var ts := TextServerManager.get_primary_interface()
	serif = FontVariation.new(); serif.base_font = F_SERIF; serif.variation_opentype = {ts.name_to_tag("wght"): 620}
	serif_it = FontVariation.new(); serif_it.base_font = F_SERIF_IT; serif_it.variation_opentype = {ts.name_to_tag("wght"): 620}
	caps = FontVariation.new(); caps.base_font = F_CAPS; caps.spacing_glyph = 2

func _ready() -> void:
	paper = ColorRect.new(); paper.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(paper)
	var pm := ShaderMaterial.new(); pm.shader = preload("res://shaders/paper.gdshader"); paper.material = pm; add_child(paper)
	_build_hud()
	pad = Pad.new(); pad.ui = self; _full(pad); add_child(pad)
	note_box = PanelContainer.new(); note_box.mouse_filter = Control.MOUSE_FILTER_IGNORE; note_box.visible = false
	note_box.add_theme_stylebox_override("panel", _card(Color(App.CARD, 0.93), 18, 8, 1, 0)); add_child(note_box)
	note_l = _rich(20, App.INK, F_FELL_IT, F_FELL); note_box.add_child(note_l)
	toasts = VBoxContainer.new(); toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_theme_constant_override("separation", 6); add_child(toasts)
	fade_r = ColorRect.new(); fade_r.color = Color("e6dec8"); fade_r.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(fade_r); add_child(fade_r)
	var fm := ShaderMaterial.new(); fm.shader = preload("res://shaders/fade.gdshader"); fade_r.material = fm
	hurt_r = ColorRect.new(); hurt_r.color = Color(App.ACC, 0.0); hurt_r.mouse_filter = Control.MOUSE_FILTER_IGNORE; hurt_r.visible = false; _full(hurt_r); add_child(hurt_r)
	_build_dock()
	_build_info()
	_build_slate()
	_build_title()
	_build_journal()
	_build_menu()
	_build_pause()
	letterbox = Letterbox.new(); letterbox.ui = self; _full(letterbox); add_child(letterbox); move_child(letterbox, hud.get_index() + 1)
	caption_l = _lbl("", caps, 13, App.ACC); caption_l.visible = false; hud.add_child(caption_l)
	settings = SettingsPanel.new(); settings.ui = self; _full(settings); settings.visible = false; add_child(settings)
	blind = ColorRect.new(); blind.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(blind); blind.visible = false
	var bm := ShaderMaterial.new(); bm.shader = preload("res://shaders/blindfold.gdshader"); blind.material = bm
	add_child(blind); move_child(blind, dock_margin.get_index())
	black = ColorRect.new(); black.color = Color("0b0d10"); black.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(black); black.visible = false
	add_child(black); move_child(black, dock_margin.get_index())
	tally_l = _lbl("", caps, 15, App.INK); tally_l.visible = false; hud.add_child(tally_l)
	split = SubViewportContainer.new(); split.stretch = true; split.visible = false; split.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sv := SubViewport.new(); sv.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE; split.add_child(sv)
	split_cam = Camera3D.new(); split_cam.fov = 30; split_cam.far = 400; sv.add_child(split_cam)
	add_child(split); move_child(split, 1)
	Glyphs.changed = _on_device
	get_viewport().size_changed.connect(_layout)
	_layout()

func _input(ev: InputEvent) -> void:
	Glyphs.observe(ev)

# cambia el dispositivo: los textos con glifos se rehacen y el foco sólo se ve con mando
func _on_device() -> void:
	if not Glyphs.pad():
		var f := get_viewport().gui_get_focus_owner()
		if f != null: f.release_focus()
	else: focus_first()
	if dlg_more.visible: _more(true)
	if menu_open and not _menu_args.is_empty(): show_menu.callv(_menu_args)
	for c in dlg_choices.get_children(): c.queue_redraw()
	for c in pick_opts.get_children(): c.queue_redraw()

# con mando, el primer botón del panel abierto toma el foco
func focus_first() -> void:
	if not Glyphs.pad(): return
	var box: Node = null
	if settings_open: box = settings.list
	elif pause_open: box = pause_btns
	elif journal_open: box = j_list
	elif menu_open: box = menu_btns
	if box == null: return
	for c in _all_children(box):
		if c is Button and c.is_visible_in_tree() and not c.disabled and c.focus_mode != Control.FOCUS_NONE:
			c.call_deferred("grab_focus"); return

func _all_children(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		out.append(c); out.append_array(_all_children(c))
	return out

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
	r.add_theme_constant_override("line_separation", 3)
	return r

# cartela de papel: filete de tinta y sombra suave
func _card(bg := App.CARD, mx := 22, my := 14, border := 2, shadow := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = App.INK if border >= 2 else App.LINE; s.set_border_width_all(border)
	s.set_corner_radius_all(3); s.anti_aliasing = true
	s.content_margin_left = mx; s.content_margin_right = mx; s.content_margin_top = my; s.content_margin_bottom = my
	if shadow > 0: s.shadow_color = Color(0.05, 0.07, 0.09, 0.22); s.shadow_size = shadow; s.shadow_offset = Vector2(0, 3)
	return s

# botón de interfaz. kind: primary (tinta), ghost (papel con filete), flat (sólo texto)
func _btn(text: String, kind := "ghost", fsize := 17, min_h := 48.0) -> Button:
	var b := Button.new(); b.text = text; b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size.y = min_h
	b.add_theme_font_override("font", caps); b.add_theme_font_size_override("font_size", fsize)
	var fg := App.CARD if kind == "primary" else App.INK
	for k in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]: b.add_theme_color_override(k, fg)
	b.add_theme_color_override("font_disabled_color", App.FAINT)
	var mk := func(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
		var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = border; s.set_border_width_all(bw); s.set_corner_radius_all(3)
		s.content_margin_left = 18; s.content_margin_right = 18; s.content_margin_top = 6; s.content_margin_bottom = 6
		return s
	var n: StyleBoxFlat; var h: StyleBoxFlat; var p: StyleBoxFlat; var d: StyleBoxFlat
	if kind == "primary":
		n = mk.call(App.INK, App.INK, 2); h = mk.call(Color("2a3948"), App.INK, 2); p = mk.call(App.ACC, App.ACC, 2); d = mk.call(App.FAINT, App.FAINT, 2)
	elif kind == "ghost":
		n = mk.call(Color(App.CARD, 0.94), App.INK, 2); h = mk.call(Color("fffaf0"), App.ACC, 2); p = mk.call(Color("ead9c8"), App.ACC, 2); d = mk.call(Color(App.CARD, 0.5), App.FAINT, 1)
	else:
		n = mk.call(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0); h = mk.call(Color(App.ACC, 0.10), Color(0, 0, 0, 0), 0); p = mk.call(Color(App.ACC, 0.2), Color(0, 0, 0, 0), 0); d = n
		n.content_margin_left = 10; h.content_margin_left = 10; p.content_margin_left = 10
	b.add_theme_stylebox_override("normal", n); b.add_theme_stylebox_override("hover", h); b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("disabled", d)
	# el foco (mando) se dibuja como el paso del ratón, con un filete rojo
	var fo: StyleBoxFlat = h.duplicate(); fo.draw_center = false; fo.border_color = App.ACC; fo.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", fo)
	b.focus_entered.connect(func(): if Glyphs.pad(): Snd.sfx("ui"))
	return b

# barra de desplazamiento fina, a tinta
func _ink_scrollbar(sb: ScrollBar) -> void:
	var tr := StyleBoxFlat.new(); tr.bg_color = Color(App.INK, 0.08); tr.set_corner_radius_all(3); tr.content_margin_left = 3; tr.content_margin_right = 3
	var gr := StyleBoxFlat.new(); gr.bg_color = Color(App.INK, 0.55); gr.set_corner_radius_all(3)
	var gh := StyleBoxFlat.new(); gh.bg_color = App.ACC; gh.set_corner_radius_all(3)
	sb.add_theme_stylebox_override("scroll", tr); sb.add_theme_stylebox_override("grabber", gr)
	sb.add_theme_stylebox_override("grabber_highlight", gh); sb.add_theme_stylebox_override("grabber_pressed", gh)

func fmt(t: String, em := "i") -> String:
	return _re.sub(t, "[%s]$1[/%s]" % [em, em.split("=")[0]], true)

# texto de interfaz: traducido (S-10) y con los glifos del dispositivo actual
func T(t: String) -> String:
	return Glyphs.fill(I18n.t(t))

func modal() -> bool:
	return journal_open or menu_open or pause_open or settings_open

func _build_hud() -> void:
	hud = Control.new(); hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(hud); hud.visible = false; add_child(hud)
	hud_card = PanelContainer.new(); hud_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_card.add_theme_stylebox_override("panel", _card(Color(App.CARD, 0.90), 12, 7, 1, 0)); hud.add_child(hud_card)
	var hv := VBoxContainer.new(); hv.mouse_filter = Control.MOUSE_FILTER_IGNORE; hv.add_theme_constant_override("separation", 0); hud_card.add_child(hv)
	chapter_tag_l = _lbl("", caps, 12, App.SOFT); chapter_tag_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; hv.add_child(chapter_tag_l)
	objective_l = _lbl("", serif_it, 18, App.ACC); objective_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; objective_l.visible = false
	objective_l.add_theme_constant_override("line_spacing", -2); hv.add_child(objective_l)
	eye_frame = Panel.new(); eye_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := StyleBoxFlat.new(); fs.bg_color = Color(0, 0, 0, 0); fs.border_color = App.INK; fs.set_border_width_all(2); fs.set_corner_radius_all(2)
	fs.shadow_color = Color(0.05, 0.07, 0.09, 0.18); fs.shadow_size = 6; fs.shadow_offset = Vector2(0, 2); fs.draw_center = false
	eye_frame.add_theme_stylebox_override("panel", fs); hud.add_child(eye_frame)
	compass = Compass.new(); compass.ui = self; compass.size = Vector2(46, 46); compass.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(compass)
	prompt_box = PanelContainer.new(); prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_box.add_theme_stylebox_override("panel", _card(App.CARD, 18, 7, 2, 8)); prompt_box.visible = false
	prompt_l = _rich(20, App.INK); prompt_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	prompt_box.add_child(prompt_l); hud.add_child(prompt_box)
	bearing_l = Bearing.new(); bearing_l.visible = false; bearing_l.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(bearing_l)
	eye_hint = _lbl("VISTA DEL PLANO", caps, 13, App.SOFT); eye_hint.visible = false
	eye_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; eye_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; hud.add_child(eye_hint)
	keys_box = PanelContainer.new(); keys_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keys_box.add_theme_stylebox_override("panel", _card(Color(App.CARD, 0.85), 12, 4, 1, 0)); hud.add_child(keys_box)
	keys_l = _lbl("", caps, 12, App.SOFT); keys_box.add_child(keys_l)

func _build_dock() -> void:
	dock_margin = MarginContainer.new(); dock_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(dock_margin); add_child(dock_margin)
	dock = VBoxContainer.new(); dock.mouse_filter = Control.MOUSE_FILTER_IGNORE; dock.alignment = BoxContainer.ALIGNMENT_END
	dock.add_theme_constant_override("separation", 10); dock_margin.add_child(dock)
	# panel de minijuego (elección con iconos)
	pick = PanelContainer.new(); pick.add_theme_stylebox_override("panel", _card(App.CARD, 18, 12)); pick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pick.visible = false; dock.add_child(pick)
	var pv := VBoxContainer.new(); pv.add_theme_constant_override("separation", 6); pick.add_child(pv)
	pick_title = _lbl("", caps, 14, App.ACC); pick_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; pv.add_child(pick_title)
	pick_text = _rich(20, App.INK, serif_it, serif); pick_text.text = ""; pv.add_child(pick_text)
	pick_opts = HFlowContainer.new(); pick_opts.alignment = FlowContainer.ALIGNMENT_CENTER
	pick_opts.add_theme_constant_override("h_separation", 8); pick_opts.add_theme_constant_override("v_separation", 8); pv.add_child(pick_opts)
	# bloque de diálogo
	dlg = PanelContainer.new(); dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg.add_theme_stylebox_override("panel", _card(Color(App.CARD, 0.98), 24, 14)); dlg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dlg.visible = false; dock.add_child(dlg)
	var dv := VBoxContainer.new(); dv.mouse_filter = Control.MOUSE_FILTER_IGNORE; dv.add_theme_constant_override("separation", 4); dlg.add_child(dv)
	dlg_head = HBoxContainer.new(); dlg_head.mouse_filter = Control.MOUSE_FILTER_IGNORE; dlg_head.add_theme_constant_override("separation", 8); dv.add_child(dlg_head)
	dlg_icon = PolyIcon.new(); dlg_icon.custom_minimum_size = Vector2(20, 20); dlg_icon.mid = true; dlg_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; dlg_head.add_child(dlg_icon)
	dlg_who = _lbl("", caps, 14, App.SOFT); dlg_head.add_child(dlg_who)
	dlg_text = _rich(23, App.INK); dv.add_child(dlg_text)
	dlg_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING   # el texto ya está compuesto: nada salta al escribirse
	# las respuestas van en un contenedor con desplazamiento: si no caben, se desliza, nunca se cortan
	dlg_scroll = ScrollContainer.new(); dlg_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dlg_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; dlg_scroll.visible = false; dlg_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	dv.add_child(dlg_scroll); _ink_scrollbar(dlg_scroll.get_v_scroll_bar())
	dlg_choices = VBoxContainer.new(); dlg_choices.add_theme_constant_override("separation", 0); dlg_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dlg_choices.mouse_filter = Control.MOUSE_FILTER_PASS; dlg_scroll.add_child(dlg_choices)
	dlg_scroll_hint = _lbl("desliza para ver más respuestas", caps, 12, App.ACC); dlg_scroll_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dlg_scroll_hint.visible = false; dv.add_child(dlg_scroll_hint)
	dlg_more = _lbl("continuar", caps, 13, App.ACC); dlg_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; dlg_more.visible = false; dv.add_child(dlg_more)

func _build_info() -> void:
	info = PanelContainer.new(); info.mouse_filter = Control.MOUSE_FILTER_IGNORE; info.add_theme_stylebox_override("panel", _card(App.CARD, 20, 10, 2, 8))
	info.visible = false; add_child(info)
	var v := VBoxContainer.new(); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_theme_constant_override("separation", 2); info.add_child(v)
	info_title = _lbl("", caps, 13, App.ACC); info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(info_title)
	info_text = _rich(19, App.INK, serif_it, serif); v.add_child(info_text)

func _build_slate() -> void:
	slate_box = PanelContainer.new(); slate_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slate_box.add_theme_stylebox_override("panel", _card(Color("fbf7ea"), 12, 10)); slate_box.visible = false; add_child(slate_box)
	var v := VBoxContainer.new(); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; slate_box.add_child(v)
	slate_board = SlateBoard.new(); slate_board.font = serif_it; slate_board.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_child(slate_board)
	slate_cap = _lbl("", caps, 12, App.SOFT); slate_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(slate_cap)

func _build_title() -> void:
	title_box = Control.new(); title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(title_box); title_box.visible = false; add_child(title_box)
	title_veil = ColorRect.new(); title_veil.color = Color(App.PAPER, 0.93); title_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(title_veil); title_box.add_child(title_veil)
	var c := CenterContainer.new(); c.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(c); title_box.add_child(c)
	var v := VBoxContainer.new(); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_theme_constant_override("separation", 8); c.add_child(v)
	t_num = _lbl("", caps, 16, App.ACC); t_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t_num)
	t_title = _lbl("", F_FELL, 64, App.INK); t_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(t_title)
	var rule := Rule.new(); rule.custom_minimum_size = Vector2(220, 12); rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; v.add_child(rule)
	title_rule = rule
	t_sub = _lbl("", serif_it, 22, App.SOFT); t_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(t_sub)

const JTABS := [["ms", "Manuscrito"], ["know", "Saberes"], ["pos", "Personas"], ["log", "Historial"]]

func _build_journal() -> void:
	journal = Control.new(); _full(journal); journal.visible = false; add_child(journal)
	var bg := ColorRect.new(); bg.color = Color("f3ecd9"); _full(bg); journal.add_child(bg)
	var m := MarginContainer.new(); _full(m); journal.add_child(m)
	for k in ["margin_left", "margin_right"]: m.add_theme_constant_override(k, 20)
	m.add_theme_constant_override("margin_top", 10); m.add_theme_constant_override("margin_bottom", 10)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 6); m.add_child(v)
	var head := HBoxContainer.new(); head.add_theme_constant_override("separation", 4); v.add_child(head)
	for t in JTABS:
		var b := _btn(T(t[1]), "flat", 16, 46); b.pressed.connect(j_tab.bind(t[0])); head.add_child(b); j_tabs[t[0]] = b
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(sp)
	var cl := _btn(T("Cerrar"), "ghost", 15, 44); cl.pressed.connect(func(): toggle_journal()); head.add_child(cl)
	var rule := ColorRect.new(); rule.color = App.INK; rule.custom_minimum_size.y = 2; v.add_child(rule)
	j_split = BoxContainer.new(); j_split.size_flags_vertical = Control.SIZE_EXPAND_FILL; j_split.add_theme_constant_override("separation", 24); v.add_child(j_split)
	j_ls = ScrollContainer.new(); j_ls.custom_minimum_size = Vector2(290, 150); j_ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; j_split.add_child(j_ls)
	j_list = VBoxContainer.new(); j_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; j_list.add_theme_constant_override("separation", 0); j_ls.add_child(j_list)
	var ts := ScrollContainer.new(); ts.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ts.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ts.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; j_split.add_child(ts)
	var tm := MarginContainer.new(); tm.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tm.add_theme_constant_override("margin_right", 16); ts.add_child(tm)
	j_body = VBoxContainer.new(); j_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; j_body.add_theme_constant_override("separation", 10); tm.add_child(j_body)

func _build_menu() -> void:
	menu = Control.new(); _full(menu); menu.visible = false; add_child(menu)
	var veil := ColorRect.new(); veil.color = Color(App.PAPER, 0.80); veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; _full(veil); menu.add_child(veil)
	var sc := ScrollContainer.new(); _full(sc); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; menu.add_child(sc)
	var c := CenterContainer.new(); c.size_flags_horizontal = Control.SIZE_EXPAND_FILL; c.size_flags_vertical = Control.SIZE_EXPAND_FILL; sc.add_child(c)
	var mm := MarginContainer.new(); c.add_child(mm)
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: mm.add_theme_constant_override(k, 14)
	menu_split = BoxContainer.new(); menu_split.add_theme_constant_override("separation", 26); menu_split.alignment = BoxContainer.ALIGNMENT_CENTER; mm.add_child(menu_split)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 0); v.alignment = BoxContainer.ALIGNMENT_CENTER; menu_split.add_child(v)
	var over := _lbl("EDWIN A. ABBOTT  ·  1884", caps, 13, App.SOFT); over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(over)
	var ft := FontVariation.new(); ft.base_font = F_FELL; ft.spacing_glyph = 6
	menu_title = _lbl("PLANILANDIA", ft, 96, App.INK); menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(menu_title)
	var rule := Rule.new(); rule.custom_minimum_size = Vector2(240, 14); rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; v.add_child(rule)
	var sub := _lbl("Un romance de muchas dimensiones", serif_it, 24, App.ACC); sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(sub)
	var v2 := VBoxContainer.new(); v2.add_theme_constant_override("separation", 10); v2.alignment = BoxContainer.ALIGNMENT_CENTER; menu_split.add_child(v2)
	menu_btns = VBoxContainer.new(); menu_btns.add_theme_constant_override("separation", 8); menu_btns.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; v2.add_child(menu_btns)
	menu_foot = _lbl("", serif_it, 15, App.SOFT); menu_foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v2.add_child(menu_foot)

func _build_pause() -> void:
	pause = Control.new(); _full(pause); pause.visible = false; add_child(pause)
	var veil := ColorRect.new(); veil.color = Color(App.PAPER, 0.86); _full(veil); pause.add_child(veil)
	var sc := ScrollContainer.new(); _full(sc); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; pause.add_child(sc)
	var c := CenterContainer.new(); c.size_flags_horizontal = Control.SIZE_EXPAND_FILL; c.size_flags_vertical = Control.SIZE_EXPAND_FILL; sc.add_child(c)
	var card := PanelContainer.new(); card.add_theme_stylebox_override("panel", _card(App.CARD, 22, 16)); c.add_child(card)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 8); card.add_child(v)
	var t := _lbl("PAUSA", caps, 15, App.ACC); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t)
	pause_btns = VBoxContainer.new(); pause_btns.add_theme_constant_override("separation", 8); v.add_child(pause_btns)

# botones de ajustes compartidos por el menú y la pausa: sonido a mano y el resto en el panel de ajustes
func _settings_btns(into: Container, min_h: float) -> void:
	var bm := _btn("", "ghost", 14, min_h)
	var upd_m := func(): bm.text = T("Sonido: ") + (T("no") if Snd.muted else T("sí"))
	upd_m.call()
	bm.pressed.connect(func(): Snd.toggle_mute(); upd_m.call())
	into.add_child(bm)
	var bs := _btn(T("Ajustes"), "ghost", 14, min_h)
	bs.pressed.connect(func(): Snd.sfx("ui"); open_settings())
	into.add_child(bs)

func open_settings() -> void:
	settings_open = true; settings.open()
	if App.g != null: App.g.paused = true
	focus_first()

func close_settings() -> void:
	settings_open = false; settings.visible = false
	if App.g != null: App.g.paused = journal_open or pause_open
	Snd.sfx("ui"); focus_first()

# ---------- disposición ----------
func _layout() -> void:
	size = get_viewport().get_visible_rect().size
	port = size.x < size.y
	compact = size.y < 440
	var narrow := size.x < 640
	# la tira del ojo: centrada arriba; en pantallas estrechas baja a una segunda fila
	if narrow:
		strip_rect = Rect2(14, 66, size.x - 28, 40)
		hud_card.position = Vector2(12, 10); hud_card.custom_minimum_size.x = 0
		objective_l.custom_minimum_size.x = minf(size.x - 150, 300)
	else:
		var sw := clampf(size.x * 0.42, 240, 620)
		strip_rect = Rect2((size.x - sw) / 2.0, 12, sw, 40)
		hud_card.position = Vector2(12, 10)
		objective_l.custom_minimum_size.x = clampf((size.x - sw) / 2.0 - 52, 130, 300)
	chapter_tag_l.custom_minimum_size.x = objective_l.custom_minimum_size.x
	objective_l.add_theme_font_size_override("font_size", 15 if compact else 18)
	chapter_tag_l.add_theme_font_size_override("font_size", 11 if compact else 12)
	hud_card.reset_size()
	eye_frame.position = strip_rect.position - Vector2(2, 2); eye_frame.size = strip_rect.size + Vector2(4, 4)
	compass.position = Vector2(strip_rect.end.x + 14, 9)
	eye_hint.size.x = size.x - 150; eye_hint.position = Vector2(75, 16)
	var side := 14.0
	# la palanca sólo ocupa los lados cuando se puede andar; en una conversación el bloque usa el ancho
	if touch and not port and not dlg_open and not picking: side = 168.0
	var w := clampf(size.x - side * 2.0, 280.0, 780.0)
	dlg.custom_minimum_size.x = w; pick.custom_minimum_size.x = minf(size.x - 24.0, 860.0)
	var fs := 21 if compact or narrow else 23
	for k in ["normal_font_size", "italics_font_size"]: dlg_text.add_theme_font_size_override(k, fs)
	dock_margin.add_theme_constant_override("margin_left", 12); dock_margin.add_theme_constant_override("margin_right", 12)
	_dock_bottom()
	info.custom_minimum_size.x = minf(size.x - 40.0, 600.0)
	note_l.custom_minimum_size.x = minf(size.x - 60.0, 720.0)
	t_title.custom_minimum_size.x = minf(size.x - 40.0, 1000.0); t_sub.custom_minimum_size.x = minf(size.x - 60.0, 680.0)
	t_title.add_theme_font_size_override("font_size", int(clampf(minf(size.x * 0.07, size.y * 0.16), 34, 76)))
	var sbw := minf(minf(640.0, size.x - 60.0), (size.y - 90.0) * 640.0 / 420.0)
	slate_board.custom_minimum_size = Vector2(sbw, sbw * 420.0 / 640.0)
	j_split.vertical = port or size.x < 700
	j_ls.custom_minimum_size = Vector2(size.x - 40, minf(190, size.y * 0.3)) if j_split.vertical else Vector2(clampf(size.x * 0.32, 230, 320), 120)
	# menú: en un móvil apaisado, título a la izquierda y botones a la derecha
	var wide_menu := compact and not port and size.x > 620
	menu_split.vertical = not wide_menu
	var tfs := clampf(size.x * (0.058 if wide_menu else 0.085), 38, 112)
	menu_title.add_theme_font_size_override("font_size", int(minf(tfs, size.y * 0.2)))
	menu_foot.custom_minimum_size.x = minf(size.x - 40, 420)
	if menu_open and not _menu_args.is_empty(): show_menu.callv(_menu_args)
	pad.queue_redraw()

func _dock_bottom() -> void:
	var b := 12.0
	if touch and port and not dlg_open and not picking: b = 190.0
	dock_margin.add_theme_constant_override("margin_bottom", int(b))

func _top_y() -> float:
	if size.x < 640: return hud_card.position.y + hud_card.size.y + strip_rect.size.y + 22
	var y := strip_rect.end.y + 12
	if hud.visible: y = maxf(y, hud_card.position.y + hud_card.size.y + 8)
	return y

func _process(dt: float) -> void:
	tick.emit(dt)
	if fade_r.color.a != _fade_to:
		fade_r.color.a = move_toward(fade_r.color.a, _fade_to, dt * _fade_sp)
	fade_r.visible = fade_r.color.a > 0.001
	# un fundido de otro color (el papel de calco del sueño, C5-06) vuelve al papel de siempre al desaparecer
	if not fade_r.visible and fade_r.color.r8 != 230: fade_r.color = Color(Color("e6dec8"), 0.0)
	if size.x < 640:
		# fila 1: capítulo y objetivo; fila 2: la tira del ojo
		hud_card.reset_size()
		strip_rect.position.y = hud_card.position.y + maxf(hud_card.size.y, 52) + 8
		eye_frame.position = strip_rect.position - Vector2(2, 2)
	toasts.position = Vector2(12, (strip_rect.end.y if size.x < 640 else hud_card.position.y + hud_card.size.y) + 8)
	if note_box.visible and _note_t > 0.0:
		_note_t -= dt
		if _note_t <= 0.0: note_box.visible = false
	# durante un diálogo el objetivo se pliega: la cartela del HUD ocupa sólo el rótulo del capítulo
	var obj_on := objective_l.text != "" and not ((dlg_open or picking) and compact)
	if objective_l.visible != obj_on: objective_l.visible = obj_on; hud_card.reset_size()
	var ty := maxf(strip_rect.end.y, hud_card.position.y + hud_card.size.y if hud.visible else 0.0) + 10
	if info.visible:
		info.reset_size(); info.position = Vector2((size.x - info.size.x) / 2.0, ty); ty += info.size.y + 8
	if note_box.visible:
		note_box.reset_size(); note_box.position = Vector2((size.x - note_box.size.x) / 2.0, ty)
	if slate_box.visible:
		slate_box.reset_size(); slate_box.position = Vector2((size.x - slate_box.size.x) / 2.0, maxf(6.0, (size.y - slate_box.size.y) * 0.3))
	if prompt_box.visible:
		prompt_box.reset_size(); prompt_box.position = Vector2((size.x - prompt_box.size.x) / 2.0, size.y * 0.80 - prompt_box.size.y)
	keys_box.reset_size(); keys_box.position = Vector2(size.x - keys_box.size.x - 14, size.y - keys_box.size.y - 12)
	if dlg_more.visible: dlg_more.modulate.a = 0.82 + 0.18 * sin(Time.get_ticks_msec() * 0.004)
	_dock_bottom()
	_type_step(dt)
	_read_step(dt)
	if dlg_scroll.visible: _fit_choices()
	if caption_l.visible:
		_cap_t -= dt; caption_l.modulate.a = clampf(_cap_t / 0.4, 0.0, 1.0)
		if _cap_t <= 0.0: caption_l.visible = false

# avance automático y «saltar lo leído» (mantener pulsado)
func _read_step(dt: float) -> void:
	if modal() or choosing or picking or auto: _auto_t = -1.0; return
	var skipping := Input.is_action_pressed("skip_hold") and (_typing or _adv_wait)
	if skipping and _cur_seen:
		_skip_t -= dt
		if _skip_t <= 0.0:
			_skip_t = 0.08
			if _typing: _finish_type()
			if _adv_wait: _adv_ok = 0; advance()
		return
	if _auto_t >= 0.0 and _adv_wait and not _typing:
		_auto_t -= dt
		if _auto_t < 0.0: _adv_ok = 0; advance()

# venda: todo a oscuras salvo el centro, donde se dibuja el arco que palpas
func blindfold(on: bool) -> void:
	if auto: return
	blind.visible = true
	(blind.material as ShaderMaterial).set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
	var tw := create_tween(); var m := blind.material as ShaderMaterial
	tw.tween_method(func(v): m.set_shader_parameter("alpha", v), 0.0 if on else 1.0, 1.0 if on else 0.0, 0.6)
	if not on: tw.tween_callback(func(): blind.visible = false)

func blackout(on: bool, sec := 0.6) -> void:
	if auto: return
	black.visible = true; black.modulate.a = 0.0 if on else 1.0
	var tw := create_tween(); tw.tween_property(black, "modulate:a", 1.0 if on else 0.0, sec)
	if not on: tw.tween_callback(func(): black.visible = false)
	await sleep(sec)

# las muescas del sargento: una raya por acierto, un aspa por fallo
func eye_tally(marks: Array) -> void:
	if marks.is_empty(): tally_l.visible = false; return
	var t := ""
	for m in marks: t += ("|" if m else "×") + " "
	tally_l.text = T("PERITO") + "   " + t.strip_edges()
	tally_l.reset_size()
	tally_l.position = Vector2(size.x - tally_l.size.x - 18, strip_rect.end.y + 30)
	tally_l.visible = true

# plano partido: abajo, la lámina (lo que ve el jugador); arriba, la línea (lo que ve el Cuadrado)
func split_view(on: bool, center := Vector2.ZERO, zoom := 16.0) -> void:
	if auto: return
	var g := App.g
	g.force_world = on
	if on:
		(split.get_child(0) as SubViewport).world_3d = get_viewport().world_3d
		split.position = Vector2(0, size.y * 0.56); split.size = Vector2(size.x, size.y * 0.44)
		var pos := Vector3(center.x, zoom, -center.y)
		split_cam.look_at_from_position(pos, Vector3(center.x, 0.0, -center.y), Vector3(0, 0, -1))
		split_cam.fov = 30
		split.visible = true; split.modulate.a = 0.0
		create_tween().tween_property(split, "modulate:a", 1.0, 0.35)
	else:
		var tw := create_tween(); tw.tween_property(split, "modulate:a", 0.0, 0.35)
		tw.tween_callback(func(): split.visible = false)

# rótulo de sonido junto a la línea del ojo (T-11): dir < 0 izquierda, > 0 derecha, 0 al frente
func caption(text: String, dir: float) -> void:
	if auto or not bool(App.cfg.get("sound_captions", true)) or (caption_l.visible and _cap_t > 1.1): return
	var t := T(text)
	caption_l.text = ("⟨  " + t) if dir < -0.15 else ((t + "  ⟩") if dir > 0.15 else ("·  " + t + "  ·"))
	caption_l.reset_size()
	var y := strip_rect.end.y + 6.0
	var x := strip_rect.position.x if dir < -0.15 else (strip_rect.end.x - caption_l.size.x if dir > 0.15 else strip_rect.get_center().x - caption_l.size.x / 2.0)
	caption_l.position = Vector2(x, y); caption_l.visible = true; _cap_t = 1.5

# Las respuestas siempre caben: si con el último parlamento no hay sitio, el parlamento (ya leído) se
# pliega; y si ni así, la lista se desliza con un aviso. Nunca queda una opción fuera de la pantalla.
func _fit_choices() -> void:
	var avail := size.y - _top_y() - 12.0 - 30.0
	var head := dlg_head.size.y + 4.0 if dlg_head.visible else 0.0
	var ch := dlg_choices.get_combined_minimum_size().y
	_fit_n += 1
	# las filas tardan un par de fotogramas en conocer su anchura (y su altura real)
	if _fit_n < 4 or dlg_choices.size.x < 100.0: return
	if dlg_text.visible:
		var th := dlg_text.get_content_height() + 4.0
		if head + th + ch > avail: dlg_text.visible = false
		else: head += th
	var room := maxf(avail - head - 20.0, 90.0)
	var want := minf(ch, room)
	if absf(dlg_scroll.custom_minimum_size.y - want) > 0.5: dlg_scroll.custom_minimum_size.y = want
	var more := ch > room + 1.0
	dlg_scroll_hint.visible = more and dlg_scroll.scroll_vertical < int(ch - room) - 4
	if dlg_scroll_hint.visible: dlg_scroll_hint.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.006)

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
	var s := _card(App.CARD, 14, 6, 1, 6); s.border_width_left = 5
	s.border_color = {frag = App.INK, her = App.HERESY, bad = App.BAD, good = App.GOOD}.get(kind, App.ACC)
	p.add_theme_stylebox_override("panel", s)
	var v := VBoxContainer.new(); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_theme_constant_override("separation", -2); p.add_child(v)
	v.add_child(_lbl(T(small).to_upper(), caps, 11, App.SOFT))
	var tl := _lbl(T(text), serif, 18, App.INK); tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; tl.custom_minimum_size.x = minf(300, size.x * 0.5); v.add_child(tl)
	toasts.add_child(p)
	while toasts.get_child_count() > (2 if compact else 4): toasts.get_child(0).free()
	p.modulate.a = 0.0; p.modulate = Color(1.25, 1.25, 1.25, 0.0)
	var tw := p.create_tween()
	tw.tween_property(p, "modulate", Color.WHITE, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT); tw.tween_interval(3.6); tw.tween_property(p, "modulate:a", 0.0, 0.6); tw.tween_callback(p.queue_free)

func objective(t: String) -> void:
	t = T(t)
	if t != "" and t != objective_l.text and not auto:
		# el objetivo nuevo se subraya con un destello
		objective_l.pivot_offset = Vector2(0, 10); objective_l.modulate = Color(1.6, 1.3, 1.3, 0.0)
		var tw := objective_l.create_tween(); tw.tween_property(objective_l, "modulate", Color.WHITE, 0.5)
	objective_l.text = t; objective_l.visible = t != ""; hud_card.reset_size()

func chapter_tag(t: String) -> void:
	chapter_tag_l.text = T(t).to_upper(); hud_card.reset_size()

func prompt(text) -> void:
	if text == null or touch: prompt_box.visible = false; return
	if prompt_l.text != text: prompt_l.text = text
	prompt_box.visible = true

func fade(on: bool, sec := 0.3) -> void:
	_fade_to = 1.0 if on else 0.0
	if auto: fade_r.color.a = _fade_to; return
	_fade_sp = 1.0 / maxf(sec, 0.01)
	await sleep(sec + 0.03)

# destello de dolor: un velo rojo que se apaga
func flash(a: float, c := App.ACC) -> void:
	if auto: return
	hurt_r.color = Color(c, a); hurt_r.visible = true
	var tw := create_tween(); tw.tween_property(hurt_r, "color:a", 0.0, 0.45); tw.tween_callback(func(): hurt_r.visible = false)

# rótulo de capítulo: breve, sobre un velo, y se puede saltar con un toque
func title(num: String, title_text: String, sub := "", dur := 2.6) -> void:
	if auto: return
	t_num.text = T(num).to_upper(); t_title.text = T(title_text); t_sub.text = T(sub)
	title_box.visible = true; title_box.modulate.a = 0.0; _title_on = true; _title_skip = false
	Snd.sfx("title"); Snd.duck(0.8)
	var t := 0.0
	var parts: Array = [t_num, t_title, title_rule, t_sub]
	for k in parts.size(): parts[k].modulate.a = 0.0
	title_rule.grow = 0.0
	while t < dur and not (_title_skip and t > 0.45):
		t += await tick
		title_box.modulate.a = minf(1.0, t / 0.3)
		# entrada escalonada: número, título (sube), filete (se traza), subtítulo
		for k in parts.size():
			var u := clampf((t - 0.12 - k * 0.22) / 0.5, 0.0, 1.0)
			if _title_skip: u = 1.0
			parts[k].modulate.a = App.ease(u)
		title_rule.grow = App.ease(clampf((t - 0.5) / 0.6, 0.0, 1.0)) if not _title_skip else 1.0
		title_rule.queue_redraw()
		t_title.pivot_offset = t_title.size / 2.0
		t_title.scale = Vector2.ONE * (1.0 + 0.06 * (1.0 - App.ease(clampf((t - 0.34) / 0.7, 0.0, 1.0)))) if not _title_skip else Vector2.ONE
	var a := 1.0
	_title_on = false
	while a > 0.0:
		a -= (await tick) / 0.3
		title_box.modulate.a = maxf(a, 0.0)
	title_box.visible = false

# ---------- avance ----------
func advance() -> bool:
	if _title_on: _title_skip = true; return true
	if _typing: _finish_type(); return true
	if _adv_wait:
		if Time.get_ticks_msec() >= _adv_ok:
			_adv_wait = false; advanced.emit()
		return true
	return false

func wait_advance() -> void:
	_adv_wait = true; _adv_ok = Time.get_ticks_msec() + 160
	if not _typing: _arm_auto()
	await advanced
	_auto_t = -1.0

func _arm_auto() -> void:
	_auto_t = (1.2 + 0.045 * _type_total) if bool(App.cfg.get("auto_adv", false)) else -1.0

func waiting() -> bool:
	return _adv_wait

# ---------- bloques de texto ----------
func cast(map: Dictionary) -> void:
	SPEAKERS.merge(map, true)

func _speaker(who: String) -> Dictionary:
	return SPEAKERS.get(who, {name = who, voice = "yo"})

func _show_block(who: String, text: String, cont := false) -> void:
	var sp := _speaker(who)
	var cls: String = sp.get("cls", "")
	var col: Color = App.inked(Color(sp.color), 0.46) if sp.has("color") else App.SOFT
	dlg_who.text = T(sp.name as String).to_upper(); dlg_head.visible = sp.name != ""
	dlg_who.add_theme_color_override("font_color", App.SOFT if cls == "you" else col)
	dlg_icon.visible = cls != "inner" and ICON.has(sp.get("voice", ""))
	if dlg_icon.visible: dlg_icon.kind = ICON[sp.voice]; dlg_icon.col = App.SOFT if cls == "you" else col; dlg_icon.queue_redraw()
	var body := fmt(text)
	var tc := App.INK
	if cls == "narr":
		body = "[center]" + fmt(text, "color=" + App.HEX_ACC) + "[/center]"; tc = Color("2a3540")
		dlg_text.add_theme_font_override("normal_font", F_FELL_IT)
	elif cls == "inner":
		body = fmt(text, "color=#17212b"); tc = col
		dlg_text.add_theme_font_override("normal_font", serif_it)
	else:
		if cls == "you": tc = Color("36434e")
		dlg_text.add_theme_font_override("normal_font", serif)
	dlg_text.add_theme_color_override("default_color", tc)
	dlg_text.text = body; dlg_text.visible = true
	dlg_scroll.visible = false; dlg_scroll_hint.visible = false
	if App.g != null: App.g.speaking(who)
	if _block_tw: _block_tw.kill()
	_block_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if cont or dlg.visible:
		# página siguiente o nuevo parlamento: sólo el texto se renueva, con un leve desliz
		dlg.modulate.a = 1.0; dlg_text.modulate.a = 0.0
		_block_tw.tween_property(dlg_text, "modulate:a", 1.0, 0.14)
	else:
		# el bloque entra: sube desde abajo y aparece
		dlg.modulate.a = 0.0; dlg_text.modulate.a = 1.0; dlg.pivot_offset = Vector2(dlg.size.x / 2.0, dlg.size.y)
		dlg.scale = Vector2(0.97, 0.97)
		_block_tw.set_parallel(true)
		_block_tw.tween_property(dlg, "modulate:a", 1.0, 0.18)
		_block_tw.tween_property(dlg, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK)
	dlg.visible = true
	# se escribe letra a letra (un toque lo completa)
	_type_voice = sp.get("voice", "yo") if cls != "narr" else "narr"
	_type_total = _plain(text).length(); _type_n = 0.0; _type_blip = 0
	dlg_text.visible_characters = 0; _typing = true
	if not cont: Snd.blip(sp.get("voice", "yo"))

func _plain(t: String) -> String:
	return t.replace("*", "")

func _finish_type() -> void:
	_typing = false; dlg_text.visible_characters = -1
	_adv_ok = Time.get_ticks_msec() + 140
	if _adv_wait: _arm_auto()

func _type_step(dt: float) -> void:
	if not _typing: return
	if _type_pause > 0.0: _type_pause -= dt; return
	var plain := dlg_text.get_parsed_text()
	var before := int(_type_n)
	_type_n += dt * CPS[clampi(int(App.cfg.get("text_speed", 1)), 0, 3)]
	var n := mini(int(_type_n), plain.length())
	# las pausas de la puntuación: el texto respira
	for i in range(before, n):
		var c := plain[i]
		if c in ".!?…:;" or c in ",—":
			n = i + 1; _type_n = float(n); _type_pause = 0.17 if c in ".!?…:;" else 0.06
			break
	if n / 3 != before / 3 and _type_voice != "narr": Snd.talk(_type_voice)
	if n >= plain.length(): _finish_type()
	else: dlg_text.visible_characters = n

func open_dlg() -> void:
	if not dlg_open: dlg_open = true; _layout()

func close_dlg() -> void:
	if App.g != null: App.g.speaking("")
	_typing = false
	dlg_open = false; dlg.visible = false; dlg_more.visible = false; _layout()

func _more(on: bool) -> void:
	var how := T("toca para continuar  ›") if touch else ("%s  ›  %s" % [Glyphs.name_of("advance").to_lower(), T("continuar")])
	if _cur_seen and not touch: how = "%s %s · %s   %s" % [T("mantén"), Glyphs.name_of("skip_hold").to_lower(), T("saltar"), how]
	dlg_more.text = how + _page_info
	dlg_more.visible = on

# ---------- páginas ----------
# Un parlamento largo se parte en páginas breves (por frases, y si hace falta por incisos o palabras)
# que siempre caben en pantalla, sea cual sea el tamaño de letra.
func _dlg_font(cls: String) -> Font:
	if cls == "narr": return F_FELL_IT
	if cls == "inner": return serif_it
	return serif

func _text_h(t: String, cls: String) -> float:
	var fs := dlg_text.get_theme_font_size("normal_font_size")
	var w := maxf(dlg.custom_minimum_size.x - 52.0, 120.0)
	return _dlg_font(cls).get_multiline_string_size(_plain(t), HORIZONTAL_ALIGNMENT_LEFT, w, fs).y

func _max_lines() -> int:
	var fs := dlg_text.get_theme_font_size("normal_font_size")
	var lh := _dlg_font("").get_height(fs) + 3.0
	# lo que queda bajo el HUD, descontando cabecera, márgenes y «continuar»
	var avail := size.y - _top_y() - 12.0 - 28.0 - 24.0 - 26.0
	return clampi(int(avail * 0.62 / lh), 2, 3)

func _paginate(text: String, cls: String) -> Array:
	var fs := dlg_text.get_theme_font_size("normal_font_size")
	var lh := _dlg_font(cls).get_height(fs)
	var max_h := lh * _max_lines() + 2.0
	var max_c := 190
	var fits := func(t: String) -> bool: return t.length() <= max_c and _text_h(t, cls) <= max_h
	var pages := []
	var cur := ""
	for snt in _sentences(text):
		var pieces: Array = [snt] if fits.call(snt) else _split_long(snt, fits)
		for pc in pieces:
			var cand: String = pc if cur == "" else cur + " " + pc
			if cur == "" or fits.call(cand): cur = cand
			else: pages.append(cur); cur = pc
	if cur != "": pages.append(cur)
	# el énfasis (*…*) que cruza una frontera de página se cierra y se vuelve a abrir
	var open := false
	for i in pages.size():
		var p: String = pages[i]
		if open: p = "*" + p
		open = p.count("*") % 2 == 1
		if open: p += "*"
		pages[i] = p
	return pages if not pages.is_empty() else [text]

func _sentences(t: String) -> Array:
	var out := []
	var cur := ""
	var i := 0
	var n := t.length()
	while i < n:
		var c := t[i]
		cur += c
		if c in ".!?…":
			# absorbe cierres: comillas, paréntesis, asteriscos
			while i + 1 < n and t[i + 1] in "»”\")*":
				i += 1; cur += t[i]
			if i + 2 < n and t[i + 1] == " ":
				var nx := t[i + 2]
				if nx == nx.to_upper() and nx != nx.to_lower() or nx in "¿¡«(—*\"":
					out.append(cur.strip_edges()); cur = ""; i += 1
		i += 1
	if cur.strip_edges() != "": out.append(cur.strip_edges())
	return out

func _split_long(snt: String, fits: Callable) -> Array:
	# por incisos
	var parts := []
	var cur := ""
	for i in snt.length():
		cur += snt[i]
		if snt[i] in ",;:" and i + 1 < snt.length() and snt[i + 1] == " ":
			parts.append(cur.strip_edges()); cur = ""
	if cur.strip_edges() != "": parts.append(cur.strip_edges())
	var out := []
	var acc := ""
	for pc in parts:
		var cand: String = pc if acc == "" else acc + " " + pc
		if acc == "" or fits.call(cand): acc = cand
		else: out.append(acc); acc = pc
	if acc != "": out.append(acc)
	# y si un inciso sigue sin caber, por palabras
	var res := []
	for o in out:
		if fits.call(o): res.append(o); continue
		var line := ""
		for wd in (o as String).split(" "):
			var cand: String = wd if line == "" else line + " " + wd
			if line == "" or fits.call(cand + " …"): line = cand
			else: res.append(line + " …"); line = wd
		if line != "": res.append(line)
	return res

func say(who: String, text: String) -> void:
	if auto: I18n.t(text); return
	open_dlg()
	await _speak(who, text, _speaker(who).get("cls", ""))

# un parlamento: se traduce, se parte en páginas, se apunta en el historial y se marca como leído.
# msgid es el texto original (español): así «saltar lo leído» funciona en cualquier idioma.
func _speak(who: String, msgid: String, cls: String) -> void:
	var text := T(msgid)
	_cur_seen = Profile.seen(msgid)
	_log(who, text)
	var pages := _paginate(text, cls)
	for i in pages.size():
		_page_info = "" if pages.size() == 1 else "   ·   %d / %d" % [i + 1, pages.size()]
		_show_block(who, pages[i], i > 0)
		_more(true)
		await wait_advance()
		dlg_more.visible = false; Snd.sfx("page" if i < pages.size() - 1 else "ui")
	_page_info = ""
	Profile.mark_seen(msgid); _cur_seen = false

func _log(who: String, text: String) -> void:
	history.append({who = who, text = text})
	if history.size() > HISTORY_MAX: history.pop_front()

# Narración del preso (bloqueante: espera a que el jugador continúe)
func narrate(text: String, _wide := false) -> void:
	if auto: I18n.t(text); return
	await _speak("narr", text, "narr")
	if not dlg_open:
		dlg.visible = false
		if App.g != null: App.g.speaking("")


# Apunte no bloqueante
func note(text: String, sec := 6.0) -> void:
	if auto: I18n.t(text); return
	note_l.text = "[center]" + fmt(T(text), "color=" + App.HEX_ACC) + "[/center]"; note_box.visible = true; _note_t = sec
	_log("note", T(text))

# opts: [{t, id, tag, lock}] → devuelve id (o índice)
func choose(opts: Array, _echo := true):
	var key := _choice_key(opts)
	if auto:
		var i := 0
		if auto_pick.is_valid(): i = auto_pick.call(opts)
		else:
			for k in opts.size():
				if not _locked(opts[k]): i = k; break
		for o in opts: I18n.t(o.t)
		return opts[i].get("id", i)
	open_dlg()
	for c in dlg_choices.get_children(): c.free()
	_opt_lock = []
	for i in opts.size():
		var o: Dictionary = opts[i]
		var lock := _locked(o)
		_opt_lock.append(lock)
		var bb := ""
		if o.get("tag", "") != "": bb += "[color=%s][b]%s[/b][/color]  " % [App.HEX_FAINT if lock else "#5b3fa8", (o.tag as String).to_upper()]
		bb += fmt(T(o.t))
		if lock and o.lock is String: bb += "  [color=%s][i]— %s[/i][/color]" % [App.HEX_FAINT, T(o.lock)]
		var row := ChoiceRow.new(); row.setup(self, bb, lock, i)
		row.was_picked = Profile.picked(key + "." + str(o.get("id", i)))
		if not lock: row.chosen.connect(_pick.bind(i))
		dlg_choices.add_child(row)
		# las respuestas entran una tras otra
		row.modulate.a = 0.0
		var tw := row.create_tween(); tw.tween_interval(0.05 * i); tw.tween_property(row, "modulate:a", 1.0, 0.18)
	_n_opts = opts.size()
	if not dlg.visible:
		dlg_head.visible = false; dlg_text.visible = false; dlg.visible = true; dlg.modulate.a = 1.0
	dlg_scroll.visible = true; dlg_scroll.scroll_vertical = 0; _fit_n = 0; dlg_scroll.custom_minimum_size.y = 0; dlg_more.visible = false; choosing = true
	_adv_ok = Time.get_ticks_msec() + 260
	_sel = _first_free() if Glyphs.pad() else -1
	var p: int = await picked
	choosing = false; _n_opts = 0; _sel = -1
	Profile.mark_picked(key + "." + str(opts[p].get("id", p)))
	_log("yo", "› " + _plain(T(opts[p].t)))
	dlg_scroll.visible = false; dlg_scroll_hint.visible = false
	Snd.sfx("pick")
	return opts[p].get("id", p)

# clave estable de una elección: capítulo y texto de las opciones (no depende del idioma)
func _choice_key(opts: Array) -> String:
	var ch := int(App.g.state.chapter) if App.g != null else 0
	var t := ""
	for o in opts: t += str(o.get("t", "")) + "|"
	return "c%d.%s" % [ch, Profile.key_of(t)]

func _first_free() -> int:
	for k in _n_opts:
		if picking or not _opt_lock[k]: return k
	return 0

# mando o flechas: mueve el resaltado entre las respuestas libres
func sel_move(step: int) -> void:
	if _n_opts == 0: return
	if _sel < 0: _sel = _first_free()
	else:
		var k := _sel
		for _i in _n_opts:
			k = (k + step + _n_opts) % _n_opts
			if picking or not _opt_lock[k]: break
		_sel = k
	Snd.sfx("ui")
	var box: Container = pick_opts if picking else dlg_choices
	for c in box.get_children(): c.queue_redraw()
	if choosing and _sel < dlg_choices.get_child_count(): dlg_scroll.ensure_control_visible(dlg_choices.get_child(_sel))

func sel_accept() -> bool:
	if _sel < 0 or _sel >= _n_opts: return false
	_pick(_sel); return true

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
	pick_title.text = T(title_text).to_upper(); pick_text.text = "[center]" + fmt(T(text), "color=" + App.HEX_ACC) + "[/center]"
	for i in options.size():
		var o: Dictionary = options[i]
		var card := OptCard.new(); card.setup(self, o, i)
		card.chosen.connect(_pick.bind(i)); pick_opts.add_child(card)
	_n_opts = options.size(); picking = true; pick.visible = true
	_adv_ok = Time.get_ticks_msec() + 260
	_sel = 0 if Glyphs.pad() else -1
	_layout()
	var p: int = await picked
	picking = false; pick.visible = false; _n_opts = 0; _sel = -1
	Snd.sfx("pick"); _layout()
	return options[p].get("id", p)

func panel_info(title_text, text := "") -> void:
	if title_text == null: info.visible = false; return
	if auto: return
	info_title.text = T(title_text as String).to_upper(); info_text.text = "[center]" + fmt(T(text), "color=" + App.HEX_ACC) + "[/center]"; info.visible = true

func slate(show: bool, cap := "") -> SlateBoard:
	slate_box.visible = show and not auto; slate_cap.text = T(cap).to_upper()
	return slate_board

# ---------- inventario: manuscrito, saberes, posición ----------
func toggle_journal(tab := "") -> void:
	journal_open = not journal_open; journal.visible = journal_open
	App.g.paused = journal_open or pause_open
	if journal_open:
		new_pages = false
		j_tab(tab if tab != "" else _tab); Snd.sfx("ui")

func j_cycle(d: int) -> void:
	var ids := JTABS.map(func(t): return t[0])
	j_tab(ids[(ids.find(_tab) + d + ids.size()) % ids.size()]); Snd.sfx("page")

func _j_head(t: String) -> void:
	var l := _lbl(t.to_upper(), caps, 12, App.ACC); j_list.add_child(l)

func _j_item(text: String, have: bool, cb: Callable) -> Button:
	var b := _btn(text, "flat", 18, 42)
	b.add_theme_font_override("font", serif if have else serif_it)
	if not have:
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: b.add_theme_color_override(k, App.FAINT)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; b.clip_text = true
	b.pressed.connect(cb); j_list.add_child(b)
	return b

func _j_clear(c: Node) -> void:
	for k in c.get_children(): k.free()

func _j_text(sec: String, head: String, paras: Array, missing := "") -> void:
	_j_clear(j_body)
	j_body.add_child(_lbl(sec.to_upper(), caps, 12, App.ACC))
	if head != "":
		var h := _lbl(head, F_FELL, 30, App.INK); h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; j_body.add_child(h)
	for p in paras:
		var r := _rich(21, App.INK); r.text = fmt(Glyphs.fill(p)); r.add_theme_constant_override("line_separation", 6); j_body.add_child(r)
	if missing != "":
		var r := _rich(20, App.SOFT, serif_it); r.text = missing; j_body.add_child(r)

func j_tab(tab: String) -> void:
	_tab = tab
	var S: Dictionary = App.g.state
	for k in j_tabs:
		var on: bool = k == tab
		for c in ["font_color", "font_hover_color", "font_focus_color"]: j_tabs[k].add_theme_color_override(c, App.INK if on else App.SOFT)
		var sb := StyleBoxFlat.new(); sb.bg_color = Color(App.ACC, 0.10 if on else 0.0); sb.border_color = App.ACC; sb.border_width_bottom = 3 if on else 0
		sb.content_margin_left = 14; sb.content_margin_right = 14
		j_tabs[k].add_theme_stylebox_override("normal", sb)
	_j_clear(j_list); _j_clear(j_body)
	if tab == "ms":
		var F: Array = App.g.book.fragments
		var show := func(n: int):
			var f: Dictionary = F[n - 1]
			var sec := ("Parte I · Este mundo" if n <= 12 else "Parte II · Otros mundos") + " — § %d" % n
			if S.frags.has(str(n)): _j_text(sec, f.title, f.text)
			else: _j_text(sec, f.title, [], "Esta sección aún no ha sido escrita. " + f.hint)
		var info_l := _lbl(T("%d de 22 secciones recuperadas") % S.frags.size(), serif_it, 16, App.SOFT); j_list.add_child(info_l)
		for i in F.size():
			if i == 0: _j_head("Parte I — Este mundo")
			if i == 12: _j_head("Parte II — Otros mundos")
			var have: bool = S.frags.has(str(i + 1))
			_j_item("§%d   %s" % [i + 1, F[i].title if have else "· · ·"], have, show.bind(i + 1))
		# notas al margen recogidas (S-04)
		var got := (App.g.book.get("margins", []) as Array).filter(func(m): return S.get("margins", {}).has(m.id))
		if not got.is_empty():
			_j_head(T("Notas al margen") + "  ·  %d" % got.size())
			for m in got: _j_item(m.title, true, func(): _j_text(T("Nota al margen"), m.title, [m.text]))
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
	elif tab == "pos": _j_people(S)
	else: _j_history()
	focus_first()

# personas que recuerdan (T-02): una frase por relación, sin números
func _j_people(S: Dictionary) -> void:
	var P: Dictionary = App.g.book.get("people", {})
	_j_head(T("Tu figura"))
	var r := _rich(18, App.INK)
	r.text = T("Un [b]Cuadrado[/b]: cuatro lados iguales, cuatro ángulos rectos. Clase profesional. Tus hijos son Pentágonos; tus nietos, Hexágonos.") + "\n\n[color=#4a5761][i]" + T("Mujeres (líneas) · Isósceles · Equiláteros · ") + "[/i][/color][b]" + T("Cuadrados") + "[/b][color=#4a5761][i] · " + T("Pentágonos · Hexágonos… · Círculos") + "[/i][/color]"
	j_list.add_child(r)
	var inv: Dictionary = S.get("inv", {})
	if not inv.is_empty():
		_j_head(T("Lo que llevas"))
		var names := {estilete = "El estilete del calderero"}
		for k in inv:
			var l := _lbl(T(names.get(k, k)), serif_it, 17, App.INK); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; j_list.add_child(l)
	j_body.add_child(_lbl(T("PERSONAS").to_upper(), caps, 12, App.ACC))
	j_body.add_child(_lbl(T("Quién te recuerda, y cómo"), F_FELL, 30, App.INK))
	for id in P:
		var lv := clampi(int(S.get("rel", {}).get(id, 0)), -2, 2)
		var row := VBoxContainer.new(); row.add_theme_constant_override("separation", 0); j_body.add_child(row)
		row.add_child(_lbl(String(P[id].name).to_upper(), caps, 13, App.INK))
		var ds := _lbl(P[id].lv.get(str(lv), ""), serif_it, 19, App.SOFT); ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; row.add_child(ds)

# historial (T-09): las últimas intervenciones, con el nombre y el color de quien habló
func _j_history() -> void:
	_j_head(T("Lo último que se dijo"))
	var info_l := _lbl(T("%d intervenciones") % history.size(), serif_it, 16, App.SOFT); j_list.add_child(info_l)
	j_body.add_child(_lbl(T("HISTORIAL"), caps, 12, App.ACC))
	if history.is_empty():
		var r := _rich(20, App.SOFT, serif_it); r.text = T("Aún no ha hablado nadie."); j_body.add_child(r); return
	for h in history.slice(maxi(0, history.size() - HISTORY_MAX)):
		var sp := _speaker(h.who)
		var r := _rich(19, App.INK)
		var nm: String = sp.get("name", "")
		var col := App.inked(Color(sp.color), 0.46).to_html(false) if sp.has("color") else "4a5761"
		var body := fmt(h.text)
		if h.who == "narr" or h.who == "note": r.text = "[color=#2a3540][i]%s[/i][/color]" % body
		elif nm == "": r.text = body
		else: r.text = "[color=#%s][b]%s[/b][/color]   %s" % [col, T(nm).to_upper(), body]
		j_body.add_child(r)
	# al abrirlo, se ve lo más reciente
	var sc := j_body.get_parent().get_parent() as ScrollContainer
	if sc != null:
		await get_tree().process_frame
		sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value)

# ---------- menú ----------
func show_menu(items: Array, chapters: Array, max_ch: int, on_chapter: Callable) -> void:
	_menu_args = [items, chapters, max_ch, on_chapter]
	menu.visible = true; menu_open = true; hud.visible = false
	var chs_open := false
	for c in menu_btns.get_children():
		if c is GridContainer: chs_open = c.visible
		menu_btns.remove_child(c); c.queue_free()
	var bw := clampf(size.x - 40, 240, 340)
	var bh := 44.0 if compact else 50.0
	var chs := GridContainer.new(); chs.columns = 1 if size.x < 560 else 2; chs.visible = chs_open
	chs.add_theme_constant_override("h_separation", 6); chs.add_theme_constant_override("v_separation", 4)
	for k in items.size():
		var it = items[k]
		var b := _btn(T(it[0] as String).to_upper(), "primary" if k == 0 else "ghost", 16, bh)
		b.custom_minimum_size.x = bw; b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; b.clip_text = true
		if it[1] is String and it[1] == "chapters": b.pressed.connect(func(): Snd.sfx("pick"); chs.visible = not chs.visible)
		else: b.pressed.connect(func(): Snd.sfx("pick"); it[1].call(b))
		menu_btns.add_child(b)
		b.modulate.a = 0.0
		var tw := b.create_tween(); tw.tween_interval(0.25 + 0.08 * k); tw.tween_property(b, "modulate:a", 1.0, 0.35)
	menu_btns.add_child(chs)
	for i in chapters.size():
		var b := _btn(T(chapters[i]), "flat", 14, 40); b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = i > max_ch; b.pressed.connect(func(): Snd.sfx("pick"); on_chapter.call(i)); chs.add_child(b)
	var opts := HFlowContainer.new(); opts.alignment = FlowContainer.ALIGNMENT_CENTER; opts.custom_minimum_size.x = bw
	opts.add_theme_constant_override("h_separation", 6); opts.add_theme_constant_override("v_separation", 6)
	if items.size() > 0 and not (items[0].size() > 2 and items[0][2] == "sub"): _settings_btns(opts, 40)
	menu_btns.add_child(opts)
	var foot := T("Arrastra a la izquierda para moverte · toca para continuar") if touch else (
		T("stick izquierdo · {act} interactuar y continuar · {view} vista · {journal} inventario") if Glyphs.pad() else
		T("{move} / flechas · {act} interactuar · {advance} continuar · {view} vista · {journal} inventario"))
	menu_foot.text = T("Una aventura narrativa. Se recomienda sonido.") + "\n" + foot
	focus_first()

func hide_menu() -> void:
	menu.visible = false; menu_open = false; hud.visible = true; _menu_args = []

# ---------- pausa ----------
func toggle_pause(on_quit := Callable()) -> void:
	pause_open = not pause_open; pause.visible = pause_open
	App.g.paused = pause_open or journal_open
	Snd.sfx("ui")
	if not pause_open: return
	for c in pause_btns.get_children(): pause_btns.remove_child(c); c.queue_free()
	var bw := clampf(size.x - 80, 220, 320); var bh := 42.0 if compact else 48.0
	var add := func(text: String, kind: String, cb: Callable) -> Button:
		var b := _btn(T(text).to_upper(), kind, 15, bh); b.custom_minimum_size.x = bw; b.pressed.connect(cb); pause_btns.add_child(b)
		return b
	add.call("Continuar", "primary", func(): toggle_pause())
	add.call("Manuscrito y saberes", "ghost", func(): toggle_pause(); toggle_journal())
	add.call("Historial", "ghost", func(): toggle_pause(); toggle_journal("log"))
	_settings_btns(pause_btns, bh)
	var sure := {on = false}
	var q: Button = add.call("Salir al menú", "ghost", func(): pass)
	q.pressed.connect(func():
		if not sure.on: sure.on = true; q.text = T("¿SEGURO? SE GUARDA POR CAPÍTULOS"); return
		if on_quit.is_valid(): on_quit.call())
	focus_first()


# ---------- piezas ----------
class ChoiceRow extends PanelContainer:
	signal chosen
	var was_picked := false   # ya se eligió en alguna partida: punto de tinta (T-09)
	var _lock := false
	var _hover := false
	var _down := false
	var _at := Vector2.ZERO
	var _n := 0
	var _ui: UIRoot
	func setup(ui: UIRoot, bb: String, lock: bool, i: int) -> void:
		_lock = lock; _n = i + 1; _ui = ui
		mouse_filter = Control.MOUSE_FILTER_PASS
		mouse_default_cursor_shape = Control.CURSOR_ARROW if lock else Control.CURSOR_POINTING_HAND
		var e := StyleBoxEmpty.new(); e.content_margin_left = 40; e.content_margin_right = 10; e.content_margin_top = 9; e.content_margin_bottom = 9
		add_theme_stylebox_override("panel", e)
		var r := ui._rich(20 if ui.compact else 21, App.FAINT if lock else App.INK)
		r.add_theme_font_size_override("bold_font_size", 12)
		r.text = bb; add_child(r)
		custom_minimum_size.y = 46 if ui.compact else 50
		mouse_entered.connect(func(): _hover = true; queue_redraw())
		mouse_exited.connect(func(): _hover = false; _down = false; queue_redraw())
	func _draw() -> void:
		draw_line(Vector2(0, 0), Vector2(size.x, 0), App.LINE, 1.0)
		var on := (_hover or _down or _ui._sel == _n - 1) and not _lock
		if on:
			draw_rect(Rect2(Vector2.ZERO, size), Color(App.ACC, 0.16 if _down else 0.08))
			draw_rect(Rect2(0, 0, 4, size.y), App.ACC)
		# marcador: número en un círculo de compás
		var c := Vector2(20, size.y / 2.0); var col := App.FAINT if _lock else (App.ACC if on else App.SOFT)
		draw_arc(c, 11, 0, TAU, 32, col, 1.4, true)
		var t := str(_n); var w := _ui.caps.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(_ui.caps, c + Vector2(-w / 2.0 + 0.5, 4.5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
		if was_picked: draw_circle(Vector2(size.x - 8, size.y / 2.0), 2.6, Color(App.INK, 0.55))
	func _gui_input(ev: InputEvent) -> void:
		if _lock: return
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed: _down = true; _at = ev.global_position; queue_redraw()
			elif _down and Rect2(Vector2.ZERO, size).has_point(ev.position) and ev.global_position.distance_to(_at) < 14.0:
				_down = false; accept_event(); chosen.emit()
			else: _down = false; queue_redraw()
		elif ev is InputEventMouseMotion and _down and ev.global_position.distance_to(_at) > 14.0:
			_down = false; queue_redraw()

class OptCard extends PanelContainer:
	signal chosen
	var o := {}
	var _hover := false
	var _ui: UIRoot
	var _i := 0
	func setup(ui: UIRoot, opt: Dictionary, i: int) -> void:
		o = opt; _ui = ui; _i = i
		mouse_filter = Control.MOUSE_FILTER_STOP; mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if o.has("swatch"):
			custom_minimum_size = Vector2(54, 54); add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		else:
			var sb := ui._card(Color("fffaf0"), 14, 6, 2, 0)
			add_theme_stylebox_override("panel", sb)
			custom_minimum_size = Vector2(104, 54)
			var v := VBoxContainer.new(); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_theme_constant_override("separation", -1); v.alignment = BoxContainer.ALIGNMENT_CENTER; add_child(v)
			if o.has("icon"):
				var ic := PolyIcon.new(); ic.kind = o.icon; ic.custom_minimum_size = Vector2(28, 28); ic.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_child(ic)
			var l := ui._lbl(ui.T(str(o.label)), ui.serif, 18, App.INK); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l)
			var s := ui._lbl(ui.T(str(o.get("sub", str(i + 1)))), ui.caps, 11, App.SOFT); s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(s)
		mouse_entered.connect(func(): _hover = true; queue_redraw())
		mouse_exited.connect(func(): _hover = false; queue_redraw())
	func _draw() -> void:
		var on := _hover or (_ui != null and _ui._sel == _i)
		if o.has("swatch"):
			draw_circle(size / 2.0, 22, Color(o.swatch))
			draw_arc(size / 2.0, 22, 0, TAU, 40, App.INK, 2.0, true)
			if on: draw_arc(size / 2.0, 26, 0, TAU, 40, App.ACC, 2.0, true)
		elif on: draw_rect(Rect2(Vector2.ZERO, size), App.ACC, false, 3.0)
	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed and Rect2(Vector2.ZERO, size).has_point(ev.position):
			accept_event(); chosen.emit()

# icono de clase: 0 = punto, 2 = línea, 1 = isósceles, n = polígono
class PolyIcon extends Control:
	var kind := 4
	var col := App.INK
	var mid := false     # centrado vertical (cabecera de diálogo)
	func _draw() -> void:
		var r := minf(size.x, 22.0) / 2.0 - 1.0
		var c := Vector2(size.x / 2.0, size.y / 2.0 if mid else 14.0)
		if kind == 0: draw_circle(c, 3.0, col); return
		if kind == 2: draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), col, 2.0, true); return
		var pts := PackedVector2Array()
		if kind == 1: pts = PackedVector2Array([c + Vector2(-2.0, r * 0.9), c + Vector2(2.0, r * 0.9), c + Vector2(0, -r * 1.1)])
		else:
			for i in kind: pts.append(c + Vector2(cos(TAU * i / kind - PI / 2), sin(TAU * i / kind - PI / 2)) * r)
		pts.append(pts[0])
		draw_polyline(pts, col, 1.6, true)

class Bar extends Control:
	var v := 0.0
	func _draw() -> void:
		var y := size.y / 2.0
		draw_line(Vector2(0, y), Vector2(size.x, y), App.INK, 1.5)
		for i in 11:
			var x := size.x * i / 10.0; var h := 6.0 if i % 5 == 0 else 3.0
			draw_line(Vector2(x, y - h), Vector2(x, y + h), App.INK, 1.2)
		var x := size.x * (0.5 + v * 0.1)
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - 9), Vector2(x + 8, y), Vector2(x, y + 9), Vector2(x - 8, y)]), App.ACC)

# filete doble con rombo: adorno de rótulo
class Rule extends Control:
	var grow := 1.0
	func _draw() -> void:
		var y := size.y / 2.0; var c := Vector2(size.x / 2.0, y)
		var L := (c.x - 10.0) * grow
		draw_line(Vector2(c.x - 10 - L, y), Vector2(c.x - 10, y), App.INK, 1.5); draw_line(Vector2(c.x + 10, y), Vector2(c.x + 10 + L, y), App.INK, 1.5)
		draw_polyline(PackedVector2Array([c + Vector2(-6, 0), c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0)]), App.ACC, 1.5, true)

class Compass extends Control:
	var ui: UIRoot
	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, 22, Color(App.CARD, 0.9))
		draw_arc(c, 22, 0, TAU, 48, App.INK, 1.5, true)
		draw_line(c + Vector2(0, -3), c + Vector2(0, 16), App.INK, 1.2)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -19), c + Vector2(4, -11), c + Vector2(-4, -11)]), App.ACC)
		draw_string(ui.caps, c + Vector2(-4.5, 3), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, App.INK)

# señal del objetivo en la vista del plano: «v» encima, «<» «>» fuera del campo
class Bearing extends Control:
	var text := "v":
		set(t): text = t; queue_redraw()
	func _draw() -> void:
		var p: PackedVector2Array
		match text:
			"<": p = PackedVector2Array([Vector2(-9, 0), Vector2(5, -9), Vector2(5, 9)])
			">": p = PackedVector2Array([Vector2(9, 0), Vector2(-5, -9), Vector2(-5, 9)])
			_: p = PackedVector2Array([Vector2(0, 9), Vector2(-9, -5), Vector2(9, -5)])
		draw_colored_polygon(p, App.ACC)
