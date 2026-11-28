# Glifos de los controles según el último dispositivo usado (S-01): teclado, mando (Xbox, PlayStation,
# Nintendo, Steam Deck) o pantalla táctil. Toda cadena de interfaz que nombra una tecla pasa por aquí.
class_name Glyphs extends RefCounted

static var last := "kb"            # kb | xbox | ps | nintendo | deck | touch
static var changed := Callable()   # la interfaz se redibuja al cambiar de dispositivo

const PAD := {
	xbox = {act = "A", advance = "A", view = "Y", journal = "Menú", pause = "Vista", rise = "RB", sink = "LB", history = "R3", skip_hold = "B", run = "L3", tab_prev = "LB", tab_next = "RB", back = "B"},
	ps = {act = "Cruz", advance = "Cruz", view = "Triángulo", journal = "Options", pause = "Share", rise = "R1", sink = "L1", history = "R3", skip_hold = "Círculo", run = "L3", tab_prev = "L1", tab_next = "R1", back = "Círculo"},
	nintendo = {act = "B", advance = "B", view = "X", journal = "+", pause = "−", rise = "R", sink = "L", history = "R3", skip_hold = "A", run = "L3", tab_prev = "L", tab_next = "R", back = "A"},
	deck = {act = "A", advance = "A", view = "Y", journal = "≡", pause = "⧉", rise = "R1", sink = "L1", history = "R3", skip_hold = "B", run = "L3", tab_prev = "L1", tab_next = "R1", back = "B"},
}

static func pad() -> bool:
	return PAD.has(last)

static func touch() -> bool:
	return last == "touch"

static func set_device(d: String) -> void:
	if d == last: return
	last = d
	if changed.is_valid(): changed.call()

# familia del mando a partir de su nombre
static func family(joy_name: String) -> String:
	var n := joy_name.to_lower()
	if "steam deck" in n or "valve" in n or "steam" in n: return "deck"
	if "ps" in n or "dualshock" in n or "dualsense" in n or "playstation" in n or "sony" in n: return "ps"
	if "nintendo" in n or "switch" in n or "pro controller" in n or "joy-con" in n: return "nintendo"
	return "xbox"

# se llama desde la interfaz con cada evento de entrada
static func observe(ev: InputEvent) -> void:
	if ev is InputEventJoypadButton and ev.pressed:
		set_device(family(Input.get_joy_name(ev.device)))
	elif ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.5:
		set_device(family(Input.get_joy_name(ev.device)))
	elif ev is InputEventKey and ev.pressed:
		set_device("kb")
	elif ev is InputEventMouseButton and ev.pressed and ev.device != InputEvent.DEVICE_ID_EMULATION:
		set_device("kb")
	elif ev is InputEventScreenTouch:
		set_device("touch")

# nombre corto del control de una acción en el dispositivo actual
static func name_of(action: String) -> String:
	if pad(): return PAD[last].get(action, "?")
	return Keys.key_name(action)

# texto con formato para la interfaz: el control entre filetes, en rojo
static func of(action: String) -> String:
	return "[color=%s][b]%s[/b][/color]" % [App.HEX_ACC, name_of(action)]

# sustituye {act}, {view}, {journal}… en un texto (versión sin formato si plain)
static func fill(t: String, plain := true) -> String:
	if not "{" in t: return t
	var out := t
	for a in Keys.MAP:
		var k := "{%s}" % a
		if k in out: out = out.replace(k, name_of(a) if plain else of(a))
	if "{move}" in out: out = out.replace("{move}", "stick izquierdo" if pad() else "%s%s%s%s" % [name_of("move_up"), name_of("move_left"), name_of("move_down"), name_of("move_right")])
	if "{look}" in out: out = out.replace("{look}", "stick derecho" if pad() else "ratón")
	return out
