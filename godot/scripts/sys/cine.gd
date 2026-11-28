# Raíles de cámara (S-08, T-07). Un plano es una lista de llaves con tiempo; la cámara interpola entre
# ellas y, si el plano se puede saltar, mantener «avanzar» 1 s lleva a la última llave.
#   Plano (lámina):   [{t = 0.0, focus = Vector2(..), zoom = 40.0}, {t = 2.5, focus = .., zoom = .., ease = "inout"}]
#   Espacio (libre):  [{t, pos = Vector3, look = Vector3, fov = 42.0}]   (cámara libre: W.cam_mode == "free")
# Con «reducir movimiento», las llaves con fast = true duran el doble.
class_name Cine extends RefCounted

const HOLD := 1.0

static func _ease(k: Dictionary, u: float) -> float:
	match k.get("ease", "inout"):
		"linear": return u
		"in": return u * u
		"out": return 1.0 - (1.0 - u) * (1.0 - u)
		_: return App.ease(u)

static func _times(keys: Array) -> Array:
	var slow := bool(App.cfg.get("reduce_motion", false))
	var out := []; var acc := 0.0; var prev := 0.0
	for k in keys:
		var dt: float = float(k.get("t", 0.0)) - prev; prev = float(k.get("t", 0.0))
		if slow and k.get("fast", false): dt *= 2.0
		acc += dt; out.append(acc)
	return out

# reproduce el plano; espera a que termine (o a que se salte)
static func play(W: World, keys: Array, skippable := true) -> void:
	var g := App.g; var ui := App.ui
	if keys.is_empty(): return
	if g.auto:
		_apply(W, keys[-1], keys[-1], 1.0); return
	var ts := _times(keys)
	var total: float = ts[-1]
	var rail: bool = keys[0].has("pos") or keys[-1].has("pos")
	var bands: bool = keys[0].get("bands", true)
	if bands: ui.letterbox.show_bands(true, skippable)
	# sólo bloquea al jugador si nadie lo había bloqueado ya (un raíl puede correr bajo un diálogo)
	var took := not g.busy and bands
	if took: g.busy = true
	var t := 0.0; var held := 0.0; var ep := g.epoch
	while t < total:
		var dt: float = await g.frame
		if ep != g.epoch: break
		if keys[0].has("stop") and keys[0].stop.call(): return
		t += dt
		if skippable and (Input.is_action_pressed("advance") or ui.pad.held("act") or Input.is_action_pressed("skip_hold")):
			held += dt
			if held >= HOLD: t = total
		else: held = maxf(0.0, held - dt * 2.0)
		ui.letterbox.hold = clampf(held / HOLD, 0.0, 1.0)
		var i := 1
		while i < ts.size() - 1 and t > ts[i]: i += 1
		var a: Dictionary = keys[i - 1]; var b: Dictionary = keys[min(i, keys.size() - 1)]
		var span: float = maxf(ts[min(i, ts.size() - 1)] - ts[i - 1], 0.0001)
		var u := clampf((t - ts[i - 1]) / span, 0.0, 1.0)
		_apply(W, a, b, _ease(b, u))
	_apply(W, keys[-1], keys[-1], 1.0)
	if rail and not keys[-1].get("hold", false): W.rail = {}
	if bands: ui.letterbox.show_bands(false)
	if took: g.busy = false

static func _apply(W: World, a: Dictionary, b: Dictionary, u: float) -> void:
	if a.has("focus") or b.has("focus"):
		var fa: Vector2 = a.get("focus", b.get("focus")); var fb: Vector2 = b.get("focus", fa)
		W.focus = fa.lerp(fb, u)
	if a.has("zoom") or b.has("zoom"):
		var za: float = a.get("zoom", b.get("zoom")); var zb: float = b.get("zoom", za)
		W.zoom = lerpf(za, zb, u); W.zoom_cur = W.zoom
	if a.has("pos") or b.has("pos"):
		var pa: Vector3 = a.get("pos", b.get("pos")); var pb: Vector3 = b.get("pos", pa)
		var la: Vector3 = a.get("look", b.get("look", Vector3.ZERO)); var lb: Vector3 = b.get("look", la)
		W.rail = {pos = pa.lerp(pb, u), look = la.lerp(lb, u), fov = lerpf(float(a.get("fov", 42.0)), float(b.get("fov", a.get("fov", 42.0))), u), up = b.get("up", a.get("up", Vector3.UP))}

# órbita lenta (P-03): la cámara mira a `center` desde una distancia fija y su inclinación pasa de
# from_pitch a to_pitch (radianes sobre el plano: PI/2 es la vertical, 0 el ras del suelo) en `sec`.
static func orbit(W: World, center: Vector2, from_pitch: float, to_pitch: float, sec: float, dist := 14.0, yaw := 0.0) -> void:
	var g := App.g
	if g.auto: return
	if bool(App.cfg.get("reduce_motion", false)): sec *= 1.5
	W.orbit = {center = center, pitch = from_pitch, dist = dist, yaw = yaw}
	App.ui.letterbox.show_bands(true, false)
	await g.tween(sec, func(t): W.orbit.pitch = lerpf(from_pitch, to_pitch, App.ease(t)))
	App.ui.letterbox.show_bands(false)

static func orbit_end(W: World) -> void:
	W.orbit = {}
