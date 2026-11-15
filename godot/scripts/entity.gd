# Una figura de Planilandia (o un «punto de interés»): polígono con borde luminoso, IA mínima y movimiento guionizado.
class_name Ent extends Node3D

signal arrived(tok)

var id := ""
var nm := ""
var n := 4
var voice := "yo"
var woman := false
var label := ""
var x := 0.0
var y := 0.0
var rot := 0.0
var alt := 0.0
var sc := 1.0
var speed := 2.6
var ai = null            # {type='wander'|'path'|'follow', ...}
var lum := 1.0
var solidity := 0
var sway := 0.0
var hid := false
var no_collide := false
var side_colors = null
var t := 0.0
var def := {}
var local := []          # Array[Vector2]
var rad := 0.5
var frozen := false
var fixed_rot := false   # habitantes de la Línea: no pueden girar fuera de ella
var is_spot := false
var mv = null            # movimiento guionizado {x, y, speed, tok}
var x0 := 0.0
var world
var body: MeshInstance3D
var guts: MeshInstance3D
var _tok := 0

func setup(w, d: Dictionary) -> Ent:
	world = w; def = d
	id = d.get("id", ""); nm = d.get("name", ""); n = d.get("n", 4); voice = d.get("voice", "yo")
	woman = d.get("woman", false); label = d.get("label", "")
	x = d.get("x", 0.0); y = d.get("y", 0.0); rot = d.get("rot", 0.0); speed = d.get("speed", 2.6)
	ai = d.get("ai", null); lum = d.get("lum", 1.0); solidity = 1 if d.get("solid", false) else 0
	sway = d.get("sway", 1.0) if woman else 0.0
	no_collide = d.get("noCollide", false); fixed_rot = d.get("fixedRot", false)
	t = randf() * 10.0
	body = MeshInstance3D.new(); add_child(body)
	if d.get("spot", false):
		is_spot = true; rad = 0.2; no_collide = true
		var mb := Geo.MB.new()
		mb.ring(Geo.make_points({n = 4, r = 0.36}), 0.08, 0.02, null, world.pal.acc, 0.95)
		body.mesh = mb.commit(); body.material_override = world.mat(3)
		return self
	local = Geo.make_points(d)
	if woman: rad = 0.35
	else:
		var m := 0.0
		for p in local: m = maxf(m, p.length())
		rad = m * 0.86
	guts = MeshInstance3D.new(); add_child(guts)
	build()
	return self

func build() -> void:
	if is_spot: return
	var P: Dictionary = world.pal
	var pts := local
	if woman:
		var L: float = local[0].x
		pts = [Vector2(L, 0), Vector2(0, 0.055), Vector2(-L, 0), Vector2(0, -0.055)]
	var edge_col: Color = world.ink(App.col(def.tint)) if def.has("tint") else P.edge
	var sides = null
	if side_colors:
		sides = []
		for c in side_colors: sides.append(world.ink(App.col(c), 0.74))
	var mb := Geo.MB.new()
	# interior de papel con rayado de sección (más denso si la figura es «sólida»)
	mb.fan(pts, 0.01, Color(edge_col, 1.0), Vector2(4.0, 0.62 if solidity else 0.24))
	if not woman:
		var hp := []
		for p in pts: hp.append(p * 1.0)
		mb.ring(hp, 0.2, 0.012, null, edge_col, 0.07)
		# trazos de construcción: prolongación de los lados y, en los regulares, su circunferencia
		var np := pts.size()
		if np <= 8:
			for i in np:
				var a: Vector2 = pts[i]; var b: Vector2 = pts[(i + 1) % np]
				var dn := (b - a).normalized() * 0.16
				mb.quad(a - dn, a, 0.022, 0.016, Color(edge_col, 0.5)); mb.quad(b, b + dn, 0.022, 0.016, Color(edge_col, 0.5))
			if not def.has("iso") and not def.has("pts"):
				mb.ring(Geo.make_points({n = 40, r = local[0].length() + 0.012}), 0.02, 0.014, null, P.line, 0.7)
		mb.quad(Vector2(-0.07, 0), Vector2(0.07, 0), 0.02, 0.016, Color(edge_col, 0.55))
		mb.quad(Vector2(0, -0.07), Vector2(0, 0.07), 0.02, 0.016, Color(edge_col, 0.55))
	mb.ring(pts, 0.06 if woman else 0.07, 0.02, sides, edge_col, 1.0)
	if woman:
		mb.disc(Vector2(pts[0].x, 0), 0.085, 0.03, edge_col)
		mb.disc(Vector2(-pts[0].x, 0), 0.05, 0.03, edge_col)
	elif not def.get("noEye", false):
		var f: Vector2 = local[0]
		mb.disc(f * (1.0 - 0.2 / f.length()), 0.055, 0.03, edge_col)
	body.mesh = mb.commit(); body.material_override = world.mat(1)
	# entrañas: sólo visibles desde el Espacio
	if not woman and not def.get("noGuts", false):
		var s := rad * 0.42; var gp := []
		for i in 9:
			var a := TAU * i / 9.0
			gp.append(Vector2(s * (0.75 + 0.3 * sin(i * 2.3)) * cos(a) - s * 0.3, s * (0.7 + 0.3 * cos(i * 1.7)) * sin(a)))
		var gb := Geo.MB.new()
		gb.ring(gp, 0.045, 0.025, null, world.ink(Color("e2857a"), 0.7))
		gb.disc(Vector2(s * 0.1, 0), s * 0.2, 0.028, world.ink(Color("f0b25c"), 0.8), 10)
		guts.mesh = gb.commit(); guts.material_override = world.mat(2)
	guts.visible = world.show_guts

func set_colors(arr) -> void:
	side_colors = arr; build()

func eff_rot() -> float:
	return rot + (sin(t * 4.2) * 0.3 * sway if sway != 0.0 else 0.0)

func world_pts() -> Array:
	var r := eff_rot(); var c := cos(r); var s := sin(r)
	var out := []
	for p in local: out.append(Vector2(x + (p.x * c - p.y * s) * sc, y + (p.x * s + p.y * c) * sc))
	return out

# movimiento guionizado; se puede esperar con await
func move_to(tx: float, ty: float, sp := 0.0) -> void:
	_tok += 1
	var tok := _tok
	if App.g.auto:
		x = tx; y = ty; mv = null
		await App.g.frame
		return
	mv = {x = tx, y = ty, speed = sp if sp > 0.0 else speed, tok = tok}
	while true:
		var got = await arrived
		if got == tok: return

func face(px: float, py: float) -> void:
	rot = atan2(py - y, px - x)

func update(dt: float) -> void:
	t += dt
	if is_spot:
		visible = not hid
		position = Vector3(x, 0, -y); rotation.y = world.time * 1.3
		scale = Vector3.ONE * (1.0 + 0.15 * sin(world.time * 3.0))
		return
	var has_t := false; var tx := 0.0; var ty := 0.0; var sp := speed
	if mv != null:
		tx = mv.x; ty = mv.y; sp = mv.speed; has_t = true
	elif ai != null and not frozen:
		var a: Dictionary = ai
		if a.type == "wander":
			if not a.has("wait"): a.wait = randf() * 3.0
			a.wait -= dt
			if a.wait <= 0.0 and a.get("tgt") == null:
				var an := randf() * TAU; var r: float = randf() * a.r
				a.tgt = Vector2(a.home.x + cos(an) * r * a.get("sx", 1.0), a.home.y + sin(an) * r); a.life = 7.0
			if a.get("tgt") != null:
				tx = a.tgt.x; ty = a.tgt.y; has_t = true; a.life -= dt
				if a.life < 0.0: a.tgt = null; a.wait = 1.0; has_t = false
		elif a.type == "path":
			var p: Vector2 = a.pts[a.get("i", 0)]
			tx = p.x; ty = p.y; has_t = true
		elif a.type == "follow":
			var o = world.obj(a.target)
			if o and Vector2(o.x - x, o.y - y).length() > a.get("dist", 2.0):
				tx = o.x; ty = o.y; sp = a.get("speed", 5.5); has_t = true
	if has_t:
		var dx := tx - x; var dy := ty - y; var d := sqrt(dx * dx + dy * dy); var step := sp * dt
		if d <= maxf(step, 0.05):
			if mv != null:
				x = tx; y = ty
				var tok = mv.tok; mv = null
				arrived.emit(tok)
			elif ai.type == "wander": ai.tgt = null; ai.wait = 1.5 + randf() * 4.0
			elif ai.type == "path": ai.i = (ai.get("i", 0) + 1) % ai.pts.size()
		else:
			x += dx / d * step; y += dy / d * step
			if not fixed_rot: rot += App.ang_diff(rot, atan2(dy, dx)) * minf(1.0, dt * 7.0)
			if mv == null and ai != null and ai.type == "wander": world.collide(self)
	visible = not hid
	position = Vector3(x, alt, -y); rotation.y = eff_rot(); scale = Vector3.ONE * maxf(sc, 0.0001)
