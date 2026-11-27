# Acciones de entrada (S-01): cada acción tiene su tecla y su botón de mando. Se registran en el InputMap
# al arrancar (en lugar de en project.godot) para poder reasignarlas desde los ajustes.
class_name Keys extends RefCounted

const DEAD := 0.2

# acción → [teclas físicas], [botones de mando], [[eje, signo]]
const MAP := {
	move_left = [[KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1]]],
	move_right = [[KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1]]],
	move_up = [[KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1]]],
	move_down = [[KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1]]],
	run = [[KEY_SHIFT], [JOY_BUTTON_LEFT_STICK], []],
	act = [[KEY_E], [JOY_BUTTON_A], []],
	advance = [[KEY_SPACE, KEY_ENTER, KEY_KP_ENTER], [JOY_BUTTON_A], []],
	view = [[KEY_V, KEY_TAB], [JOY_BUTTON_Y], []],
	journal = [[KEY_J], [JOY_BUTTON_START], []],
	pause = [[KEY_ESCAPE], [JOY_BUTTON_BACK], []],
	rise = [[KEY_R, KEY_SPACE], [JOY_BUTTON_RIGHT_SHOULDER], [[JOY_AXIS_TRIGGER_RIGHT, 1]]],
	sink = [[KEY_F], [JOY_BUTTON_LEFT_SHOULDER], [[JOY_AXIS_TRIGGER_LEFT, 1]]],
	look_left = [[], [], [[JOY_AXIS_RIGHT_X, -1]]],
	look_right = [[], [], [[JOY_AXIS_RIGHT_X, 1]]],
	look_up = [[], [], [[JOY_AXIS_RIGHT_Y, -1]]],
	look_down = [[], [], [[JOY_AXIS_RIGHT_Y, 1]]],
	history = [[KEY_H], [JOY_BUTTON_RIGHT_STICK], []],
	skip_hold = [[KEY_CTRL], [JOY_BUTTON_B], []],
	mute = [[KEY_M], [], []],
	tab_prev = [[KEY_Q], [JOY_BUTTON_LEFT_SHOULDER], []],
	tab_next = [[KEY_TAB], [JOY_BUTTON_RIGHT_SHOULDER], []],
}

# las que el jugador puede reasignar (sólo teclado: el mando lo reasigna Steam Input)
const REBIND := ["move_up", "move_down", "move_left", "move_right", "run", "act", "advance", "view", "journal", "rise", "sink", "history", "skip_hold"]
const LABEL := {
	move_up = "Avanzar / Norte", move_down = "Retroceder / Sur", move_left = "Izquierda", move_right = "Derecha", run = "Correr",
	act = "Interactuar · palpar", advance = "Continuar el texto", view = "Cambiar de vista", journal = "Inventario",
	rise = "Subir (Espacio)", sink = "Bajar (Espacio)", history = "Historial", skip_hold = "Saltar lo leído (mantener)",
}

static func setup() -> void:
	for a in MAP:
		if InputMap.has_action(a): InputMap.erase_action(a)
		InputMap.add_action(a, DEAD)
		var m: Array = MAP[a]
		for k in m[0]: InputMap.action_add_event(a, key_ev(k))
		for b in m[1]:
			var e := InputEventJoypadButton.new(); e.button_index = b; e.device = -1
			InputMap.action_add_event(a, e)
		for ax in m[2]:
			var e := InputEventJoypadMotion.new(); e.axis = ax[0]; e.axis_value = float(ax[1]); e.device = -1
			InputMap.action_add_event(a, e)
	# en los menús (foco de Godot) se navega con la cruceta: el stick mandaría un evento por fotograma
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var e := InputEventJoypadButton.new(); e.button_index = pair[1]; e.device = -1
		if not InputMap.action_has_event(pair[0], e): InputMap.action_add_event(pair[0], e)
	apply_bindings()

static func key_ev(k: int) -> InputEventKey:
	var e := InputEventKey.new(); e.physical_keycode = k as Key
	return e

# ajustes del jugador: cfg.bindings = {acción: [código físico, ...]}
static func apply_bindings() -> void:
	var b = App.cfg.get("bindings", {})
	if not b is Dictionary: return
	for a in b:
		if not InputMap.has_action(a) or not b[a] is Array: continue
		for e in InputMap.action_get_events(a):
			if e is InputEventKey: InputMap.action_erase_event(a, e)
		for k in b[a]: InputMap.action_add_event(a, key_ev(int(k)))

static func rebind(action: String, physical: int) -> void:
	if not App.cfg.has("bindings") or not App.cfg.bindings is Dictionary: App.cfg.bindings = {}
	App.cfg.bindings[action] = [physical]
	App.save_cfg(); apply_bindings()

static func reset_bindings() -> void:
	App.cfg.bindings = {}; App.save_cfg(); setup()

# nombre de la tecla de una acción (la primera)
static func key_name(action: String) -> String:
	if not InputMap.has_action(action): return "?"
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			var pk: Key = e.physical_keycode
			var kc := DisplayServer.keyboard_get_keycode_from_physical(pk) if DisplayServer.get_name() != "headless" else pk
			var s := OS.get_keycode_string(kc if kc != KEY_NONE else pk)
			return {"Space": "Espacio", "Escape": "Esc", "Shift": "Mayús", "Ctrl": "Ctrl", "Enter": "Intro", "Left": "←", "Right": "→", "Up": "↑", "Down": "↓"}.get(s, s)
	return "—"
