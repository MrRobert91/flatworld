# Panel de ajustes (S-17), por grupos: pantalla y texto, juego, accesibilidad, controles, sonido e idioma.
class_name SettingsPanel extends Control

var ui: UIRoot
var list: VBoxContainer
var title_l: Label
var _wait_key := ""      # acción que espera una tecla nueva
var _wait_btn: Button

const SPEEDS := ["lenta", "normal", "rápida", "instantánea"]
const SENS := [0.5, 1.0, 1.5, 2.0]
const DIFF := ["relaxed", "normal", "expert"]
const DIFF_NAME := ["relajadas (segunda oportunidad)", "normales", "de perito (sin traza)"]

func _ready() -> void:
	var veil := ColorRect.new(); veil.color = Color(App.PAPER, 0.92); veil.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(veil)
	var sc := ScrollContainer.new(); sc.set_anchors_preset(Control.PRESET_FULL_RECT); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; add_child(sc)
	var c := CenterContainer.new(); c.size_flags_horizontal = Control.SIZE_EXPAND_FILL; c.size_flags_vertical = Control.SIZE_EXPAND_FILL; sc.add_child(c)
	var card := PanelContainer.new(); card.add_theme_stylebox_override("panel", ui._card(App.CARD, 22, 16)); c.add_child(card)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 8); card.add_child(v)
	title_l = ui._lbl("", ui.caps, 15, App.ACC); title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(title_l)
	list = VBoxContainer.new(); list.add_theme_constant_override("separation", 6); v.add_child(list)

func open() -> void:
	visible = true; _main()

func _clear() -> void:
	for k in list.get_children(): list.remove_child(k); k.queue_free()
	_wait_key = ""

func _add(text: String, cb: Callable, kind := "ghost") -> Button:
	var b := ui._btn(text, kind, 14, 42.0 if ui.compact else 46.0)
	b.custom_minimum_size.x = clampf(ui.size.x - 80, 260, 420)
	b.pressed.connect(func(): Snd.sfx("ui"); cb.call(b))
	list.add_child(b)
	return b

# palabras sueltas de estas listas, para el extractor de textos (S-10)
func _tr_words() -> Array:
	return [tr("lenta"), tr("normal"), tr("normales"), tr("grande"), tr("muy grande"), tr("pequeño"), tr("bronce"), tr("plata"), tr("oro")]

func _yn(v) -> String:
	return ui.T("sí") if bool(v) else ui.T("no")

func _main() -> void:
	_clear(); title_l.text = ui.T("AJUSTES")
	_add(ui.T("Pantalla y texto"), func(_b): _text())
	_add(ui.T("Juego"), func(_b): _game())
	_add(ui.T("Accesibilidad"), func(_b): _access())
	_add(ui.T("Controles"), func(_b): _controls())
	_add(ui.T("Sonido"), func(_b): _sound())
	_add(ui.T("Idioma: ") + LANG_NAME.get(I18n.lang, I18n.lang), func(_b): _lang())
	_add(ui.T("Volver"), func(_b): ui.close_settings(), "primary")
	ui.focus_first()

func _back() -> void:
	_add(ui.T("Volver"), func(_b): _main(), "primary")
	ui.focus_first()

func _text() -> void:
	_clear(); title_l.text = ui.T("PANTALLA Y TEXTO")
	var C := App.cfg
	_add(ui.T("Tamaño de interfaz: ") + ui.T(App.scale_name()), func(_b): App.next_scale(); App.fit(get_window()); ui._layout(); _text())
	_add(ui.T("Pantalla completa"), func(_b):
		var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN))
	_add(ui.T("Velocidad del texto: ") + ui.T(SPEEDS[clampi(int(C.text_speed), 0, 3)]), func(_b): C.text_speed = (int(C.text_speed) + 1) % 4; App.save_cfg(); _text())
	_add(ui.T("Avance automático: ") + _yn(C.auto_adv), func(_b): C.auto_adv = not bool(C.auto_adv); App.save_cfg(); _text())
	_add(ui.T("Letra clara: ") + _yn(C.get("plain_font", false)), func(_b): C.plain_font = not bool(C.get("plain_font", false)); App.save_cfg(); ui.apply_fonts(); _text())
	_back()

func _game() -> void:
	_clear(); title_l.text = ui.T("JUEGO")
	var C := App.cfg
	var di := DIFF.find(String(C.get("difficulty", "normal")))
	_add(ui.T("Deducciones: ") + ui.T(DIFF_NAME[maxi(di, 1)]), func(_b): C.difficulty = DIFF[(maxi(di, 1) + 1) % 3]; App.save_cfg(); _game())
	_add(ui.T("Acciones largas: ") + (ui.T("pulsar una vez") if bool(C.get("hold_toggle", false)) else ui.T("mantener pulsado")), func(_b): C.hold_toggle = not bool(C.get("hold_toggle", false)); App.save_cfg(); _game())
	_back()

func _access() -> void:
	_clear(); title_l.text = ui.T("ACCESIBILIDAD")
	var C := App.cfg
	_add(ui.T("Colores con patrón: ") + _yn(C.get("patterns", true)), func(_b):
		C.patterns = not bool(C.get("patterns", true)); App.save_cfg()
		if App.g != null:
			for e in App.g.world.ents.values(): e.build()
		_access())
	_add(ui.T("Subtítulos de sonido: ") + _yn(C.get("sound_captions", true)), func(_b): C.sound_captions = not bool(C.get("sound_captions", true)); App.save_cfg(); _access())
	_add(ui.T("Reducir movimiento: ") + _yn(C.reduce_motion), func(_b): C.reduce_motion = not bool(C.reduce_motion); App.save_cfg(); _access())
	_back()

func _controls() -> void:
	_clear(); title_l.text = ui.T("CONTROLES")
	var C := App.cfg
	var si := SENS.find(float(C.get("look_sens", 1.0)))
	_add(ui.T("Mirada con el stick: ") + "×" + str(SENS[maxi(si, 1)]), func(_b): C.look_sens = SENS[(maxi(si, 1) + 1) % SENS.size()]; App.save_cfg(); _controls())
	_add(ui.T("Invertir el eje vertical: ") + _yn(C.get("invert_y", false)), func(_b): C.invert_y = not bool(C.get("invert_y", false)); App.save_cfg(); _controls())
	if not ui.touch: _add(ui.T("Teclas"), func(_b): _keys())
	_back()

const VOLS := [1.0, 0.75, 0.5, 0.25, 0.0]
func _vol(key: String, label: String) -> void:
	var v := float(App.cfg.get(key, 1.0))
	_add(ui.T(label) + "  " + str(int(round(v * 100.0))) + " %", func(_b):
		var i := VOLS.find(v)
		App.cfg[key] = VOLS[(maxi(i, 0) + 1) % VOLS.size()]; App.save_cfg(); Snd.sfx("ui"); _sound())

func _sound() -> void:
	_clear(); title_l.text = ui.T("SONIDO")
	_vol("vol_music", "Música:"); _vol("vol_sfx", "Efectos:"); _vol("vol_voice", "Voces:")
	_back()

const LANG_NAME := {es = "Español", en = "English"}
func _lang() -> void:
	_clear(); title_l.text = ui.T("IDIOMA")
	for l in I18n.LANGS:
		_add(LANG_NAME.get(l, l) + ("  ·" if l == I18n.lang else ""), func(_b):
			Profile.data.lang = l; Profile.save()
			if l == I18n.lang: _main(); return
			# el idioma cambia el libro entero: se aplica volviendo al menú (la partida se guarda por capítulos)
			ui.close_settings(); App.pending_start = -1; get_tree().reload_current_scene())
	var r := ui._lbl(ui.T("El cambio de idioma vuelve al menú principal."), ui.serif_it, 15, App.SOFT); r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size.x = 300; list.add_child(r)
	_back()

func _keys() -> void:
	_clear(); title_l.text = ui.T("TECLAS")
	for a in Keys.REBIND:
		var b := _add("", func(btn): _listen(a, btn))
		b.text = "%s:  %s" % [ui.T(Keys.LABEL[a]), Keys.key_name(a)]
	_add(ui.T("Restablecer las teclas"), func(_b): Keys.reset_bindings(); _keys())
	_add(ui.T("Volver"), func(_b): _controls(), "primary")
	ui.focus_first()

func _listen(action: String, b: Button) -> void:
	_wait_key = action; _wait_btn = b
	b.text = "%s:  %s" % [ui.T(Keys.LABEL[action]), ui.T("pulsa una tecla…  (Esc cancela)")]

func _unhandled_input(ev: InputEvent) -> void:
	if visible and _wait_key == "" and (ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause")):
		get_viewport().set_input_as_handled(); ui.close_settings()

func _input(ev: InputEvent) -> void:
	if not visible or _wait_key == "": return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		get_viewport().set_input_as_handled()
		if ev.physical_keycode != KEY_ESCAPE: Keys.rebind(_wait_key, ev.physical_keycode)
		_wait_key = ""
		_keys.call_deferred()
