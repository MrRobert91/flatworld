# Panel de ajustes (S-09, S-01, T-11): tamaño de interfaz, pantalla completa, lectura (velocidad, avance
# automático), accesibilidad (subtítulos de sonido, reducir movimiento), mando y reasignación de teclas.
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

func _yn(v) -> String:
	return ui.T("sí") if bool(v) else ui.T("no")

func _toggle(key: String) -> Callable:
	return func(_b): App.cfg[key] = not bool(App.cfg.get(key, false)); App.save_cfg(); _main()

func _main() -> void:
	_clear(); title_l.text = ui.T("AJUSTES")
	var C := App.cfg
	_add(ui.T("Tamaño de interfaz: ") + ui.T(App.scale_name()), func(_b): App.next_scale(); App.fit(get_window()); ui._layout(); _main())
	_add(ui.T("Pantalla completa"), func(_b):
		var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN))
	_add(ui.T("Velocidad del texto: ") + ui.T(SPEEDS[clampi(int(C.text_speed), 0, 3)]), func(_b): C.text_speed = (int(C.text_speed) + 1) % 4; App.save_cfg(); _main())
	_add(ui.T("Avance automático: ") + _yn(C.auto_adv), _toggle("auto_adv"))
	_add(ui.T("Subtítulos de sonido: ") + _yn(C.get("sound_captions", true)), func(_b): C.sound_captions = not bool(C.get("sound_captions", true)); App.save_cfg(); _main())
	_add(ui.T("Reducir movimiento: ") + _yn(C.reduce_motion), _toggle("reduce_motion"))
	var di := DIFF.find(String(C.get("difficulty", "normal")))
	_add(ui.T("Deducciones: ") + ui.T(DIFF_NAME[maxi(di, 1)]), func(_b): C.difficulty = DIFF[(maxi(di, 1) + 1) % 3]; App.save_cfg(); _main())
	var si := SENS.find(float(C.get("look_sens", 1.0)))
	_add(ui.T("Mirada con el stick: ") + "×" + str(SENS[maxi(si, 1)]), func(_b): C.look_sens = SENS[(maxi(si, 1) + 1) % SENS.size()]; App.save_cfg(); _main())
	if not ui.touch: _add(ui.T("Teclas"), func(_b): _keys())
	_add(ui.T("Volver"), func(_b): ui.close_settings(), "primary")
	ui.focus_first()

func _keys() -> void:
	_clear(); title_l.text = ui.T("TECLAS")
	for a in Keys.REBIND:
		var b := _add("", func(btn): _listen(a, btn))
		b.text = "%s:  %s" % [ui.T(Keys.LABEL[a]), Keys.key_name(a)]
	_add(ui.T("Restablecer las teclas"), func(_b): Keys.reset_bindings(); _keys())
	_add(ui.T("Volver"), func(_b): _main(), "primary")
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
