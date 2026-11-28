# Acceso global a los nodos vivos de la partida, colores de la interfaz (tinta sobre papel) y ajustes.
class_name App

static var g: Game
static var ui: UIRoot
static var pending_start := -1   # capítulo a lanzar tras recargar la escena (-1: menú)
static var args := {}            # --ch=N --auto --bot --touch --shots=dir --dpr=2.6
# ajustes del jugador: tamaño de interfaz, velocidad de texto (0 lenta, 1 normal, 2 rápida, 3 instantánea),
# avance automático, reducir movimiento, subtítulos de sonido, sensibilidad de la mirada y teclas reasignadas
static var cfg := {scale = 1.0, text_speed = 1, auto_adv = false, reduce_motion = false, sound_captions = true, look_sens = 1.0, bindings = {}, difficulty = "normal", patterns = true,
	hold_toggle = false, invert_y = false, plain_font = false, vol_music = 1.0, vol_sfx = 1.0, vol_voice = 1.0}
static var _dpr := 0.0

const CFG := "user://planilandia_cfg.json"
const SCALES := [1.0, 1.15, 1.3, 0.88]
const SCALE_NAMES := {1.0: "normal", 1.15: "grande", 1.3: "muy grande", 0.88: "pequeño"}

# interfaz: tinta sobre papel de dibujo
const INK := Color("17212b")      # texto principal
const SOFT := Color("4a5761")     # texto secundario
const FAINT := Color("8d959a")    # desactivado
const ACC := Color("a8392a")      # lápiz rojo: acento, acción, objetivo
const LINE := Color(0.09, 0.13, 0.17, 0.30)
const CARD := Color("f7f1e0")     # cartela de papel
const PAPER := Color("ece4cf")
const HERESY := Color("5b3fa8")
const BAD := Color("9c2f20")
const GOOD := Color("2c6a45")
const HEX_ACC := "#a8392a"
const HEX_FAINT := "#8d959a"

static func col(c) -> Color:
	if c is Color: return c
	if c is String: return Color(c)
	if c is int: return Color.hex((c << 8) | 0xff)
	return INK

# un color pensado para brillar sobre negro, llevado a tinta legible sobre papel
static func inked(c: Color, vmax := 0.5) -> Color:
	var s := minf(1.0, c.s * 1.3 + (0.12 if c.s > 0.08 else 0.0))
	return Color.from_hsv(c.h, s, minf(c.v, vmax), c.a)

static func lin(c: Color) -> Color:
	return Color(pow(c.r, 2.2), pow(c.g, 2.2), pow(c.b, 2.2), c.a)

static func ang_diff(a: float, b: float) -> float:
	var d := fmod(b - a, TAU)
	if d > PI: d -= TAU
	if d < -PI: d += TAU
	return d

static func ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

# vibración: mando (motor débil y fuerte, 0..1) y, en el móvil, el vibrador del teléfono
static func rumble(weak: float, strong: float, sec: float) -> void:
	for j in Input.get_connected_joypads(): Input.start_joy_vibration(j, clampf(weak, 0, 1), clampf(strong, 0, 1), sec)
	if OS.has_feature("mobile") or OS.has_feature("web"): Input.vibrate_handheld(int(sec * 1000.0))

# ---------- ajustes ----------
static func load_cfg() -> void:
	if not FileAccess.file_exists(CFG): return
	var f := FileAccess.open(CFG, FileAccess.READ)
	if f == null: return
	var s = JSON.parse_string(f.get_as_text())
	if s is Dictionary:
		for k in s: cfg[k] = s[k]

static func save_cfg() -> void:
	var f := FileAccess.open(CFG, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(cfg))

static func scale_name() -> String:
	for k in SCALE_NAMES:
		if absf(k - float(cfg.scale)) < 0.01: return SCALE_NAMES[k]
	return "normal"

static func next_scale() -> void:
	var i := 0
	for k in SCALES.size():
		if absf(SCALES[k] - float(cfg.scale)) < 0.01: i = k
	cfg.scale = SCALES[(i + 1) % SCALES.size()]; save_cfg()

# píxeles físicos por píxel de diseño del dispositivo (2–3 en un móvil)
static func dpr() -> float:
	if _dpr > 0.0: return _dpr
	_dpr = 1.0
	if args.has("dpr"): _dpr = float(args.dpr)
	elif OS.has_feature("web"):
		var v = JavaScriptBridge.eval("window.devicePixelRatio || 1", true)
		if v is float or v is int: _dpr = float(v)
	else: _dpr = maxf(1.0, DisplayServer.screen_get_scale())
	_dpr = clampf(_dpr, 1.0, 5.0)
	return _dpr

# La interfaz se mide en «puntos» del dispositivo, no en píxeles: en un móvil de alta densidad
# un botón de 48 puntos mide lo mismo que en cualquier otra aplicación. En pantallas grandes crece.
static func fit(w: Window) -> void:
	var px := Vector2(DisplayServer.window_get_size())
	if px.x < 8.0 or px.y < 8.0: return
	var s := maxf(dpr(), minf(px.x / 1280.0, px.y / 720.0)) * float(cfg.scale)
	s = minf(s, minf(px.x / 330.0, px.y / 300.0))   # nunca menos sitio que un móvil pequeño
	s = maxf(s, 0.5)
	if absf(w.content_scale_factor - s) > 0.002: w.content_scale_factor = s
