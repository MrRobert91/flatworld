# Acceso global a los nodos vivos de la partida y a los colores de la interfaz.
class_name App

static var g: Game
static var ui: UIRoot
static var pending_start := -1   # capítulo a lanzar tras recargar la escena (-1: menú)
static var args := {}            # --ch=N --auto --bot --touch --shots=dir

const BONE := Color("ece5d0")
const DIM := Color("8fa3a0")
const FAINT := Color("4b605f")
const GAS := Color("e6bd6e")
const LINE := Color(0.925, 0.898, 0.816, 0.22)
const HERESY := Color("b79cf0")
const BAD := Color("e08a7a")
const GOOD := Color("9fd6b0")
const PANEL := Color(0.031, 0.063, 0.075, 0.92)
const INK := Color("05090b")

static func col(c) -> Color:
	if c is Color: return c
	if c is String: return Color(c)
	if c is int: return Color.hex((c << 8) | 0xff)
	return BONE

static func lin(c: Color) -> Color:
	return Color(pow(c.r, 2.2), pow(c.g, 2.2), pow(c.b, 2.2), c.a)

static func ang_diff(a: float, b: float) -> float:
	var d := fmod(b - a, TAU)
	if d > PI: d -= TAU
	if d < -PI: d += TAU
	return d

static func ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)
