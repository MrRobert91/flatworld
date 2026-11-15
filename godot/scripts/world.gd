# El mundo plano: mapa, muros, figuras, colisiones, cámara y aspecto («sombras duras de bordes luminosos»).
class_name World extends Node3D

# Cada mundo es una lámina distinta: papel crema, papel de calco, papel de acuarela, cianotipo, papel gris.
# bg: papel · a/b: nubes del papel · line: cuadrícula · fog: margen · edge: tinta · fill: interior · acc: lápiz de color
const PAL := {
	flat = {bg = Color("ece4cf"), a = Color("efe8d4"), b = Color("e5dbc1"), line = Color("6d93b0"), fog = Color("ddd2b6"), edge = Color("17212b"), fill = Color("f6f0df"), wall = Color("17212b"), acc = Color("a8392a")},
	dream = {bg = Color("e3dfee"), a = Color("e8e4f2"), b = Color("d9d3ea"), line = Color("8a7fc0"), fog = Color("cfc8e2"), edge = Color("27204c"), fill = Color("f0edf8"), wall = Color("27204c"), acc = Color("7a3fa8")},
	color = {bg = Color("f2e7d0"), a = Color("f5ebd5"), b = Color("ecdcbb"), line = Color("c79f70"), fog = Color("e2d2b0"), edge = Color("35261a"), fill = Color("fcf5e4"), wall = Color("35261a"), acc = Color("a8392a")},
	space = {bg = Color("12315a"), a = Color("163966"), b = Color("1c4577"), line = Color("8db6e4"), fog = Color("0f2a4e"), edge = Color("f2f6ff"), fill = Color("0f2b50"), wall = Color("e2ecfb"), acc = Color("ffd27a"), dark = true},
	cell = {bg = Color("d8d4c8"), a = Color("dcd8cc"), b = Color("cdc8b9"), line = Color("868f96"), fog = Color("c6c1b2"), edge = Color("1e2429"), fill = Color("e7e3d7"), wall = Color("1e2429"), acc = Color("a8392a")},
}
const FLAT_SH := preload("res://shaders/flat.gdshader")
const GROUND_SH := preload("res://shaders/ground.gdshader")
const F_CAPS := preload("res://assets/fonts/IMFeENsc28P.ttf")
const F_FELL_IT := preload("res://assets/fonts/IMFeENit28P.ttf")

var cam: Camera3D
var figs: Node3D
var static_g: Node3D
var fx: Node3D
var ground: MeshInstance3D
var arrow: MeshInstance3D
var trail: MeshInstance3D
var ents := {}
var spots := {}
var walls := []          # [ax, ay, bx, by, lum]
var marks := {}
var pal: Dictionary = PAL.flat
var pal_name := "flat"
var show_guts := false
var zoom := 58.0
var zoom_cur := 58.0
var base_zoom := 58.0
var focus = null         # Vector2 o null (sigue al jugador)
var cam_x := 0.0
var cam_y := 0.0
var eye_t := 0.0
var cam_mode := "follow"
var free := {yaw = 0.6, pitch = 0.9, dist = 30.0}
var fog := 13.0
var rain := 0.0
var rain_cur := 0.0
var time := 0.0
var target = null        # id, Vector2 o null
var map := {}
var known := {}
var door_state := {}
var shift := 0.0
var shift_y := 0.0
var shift_cur := 0.0
var shift_y_cur := 0.0
var lead := Vector2.ZERO  # la cámara se adelanta un poco al movimiento
var speed_zoom := 0.0
var _mats := {}
var _caps: FontVariation
var _trail_pts := []
# vida de la escena
var talker = null         # Ent o Node3D que habla ahora
var talk_w := 0.0         # 0..1: cuánto se va la cámara hacia quien habla
var talk_cur := Vector2.ZERO
var shake := 0.0          # sacudida de cámara
var fx_im: MeshInstance3D
var fxs := []             # efectos sueltos: {k, x, y, t, dur, s, c}
var rain_im: MeshInstance3D
var drops := []           # gotas: [x, y, vel, largo]
var roofs := {}           # columna → [[y_bajo, y_alto], ...] : donde la lluvia no cae (tejados, muros)
var _greet_t := 0.0
var _free_tgt := Vector3.ZERO
var _free_ok := false
const COL := 0.5          # anchura de columna de lluvia

func _init() -> void:
	_caps = FontVariation.new(); _caps.base_font = F_CAPS; _caps.spacing_glyph = 3
	cam = Camera3D.new(); cam.fov = 30; cam.near = 0.05; cam.far = 900; add_child(cam); cam.current = true
	ground = MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(1, 1); ground.mesh = pm
	var gm := ShaderMaterial.new(); gm.shader = GROUND_SH; gm.render_priority = -8; ground.material_override = gm
	ground.position.y = -0.03; add_child(ground)
	static_g = Node3D.new(); figs = Node3D.new(); fx = Node3D.new()
	add_child(static_g); add_child(figs); add_child(fx)
	var mb := Geo.MB.new()
	mb.tri(Vector3(0.45, 0, 0), Vector3(-0.2, 0, -0.26), Vector3(-0.2, 0, 0.26), Color.WHITE)
	arrow = MeshInstance3D.new(); arrow.mesh = mb.commit()
	var am := ShaderMaterial.new(); am.shader = FLAT_SH; am.render_priority = 4; arrow.material_override = am
	arrow.position.y = 0.05; add_child(arrow)
	trail = MeshInstance3D.new(); trail.mesh = ImmediateMesh.new(); trail.material_override = mat(0); add_child(trail)
	rain_im = MeshInstance3D.new(); rain_im.mesh = ImmediateMesh.new(); rain_im.material_override = mat(2); add_child(rain_im)
	fx_im = MeshInstance3D.new(); fx_im.mesh = ImmediateMesh.new(); fx_im.material_override = mat(3); add_child(fx_im)

# material plano compartido por capa (prioridad de dibujo)
func mat(prio: int) -> ShaderMaterial:
	if not _mats.has(prio):
		var m := ShaderMaterial.new(); m.shader = FLAT_SH; m.render_priority = prio
		m.set_shader_parameter("fill_col", _v3(pal.fill))
		_mats[prio] = m
	return _mats[prio]

static func _v3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)

# tinta de un color «de luz»: sobre papel claro se oscurece; en el cianotipo se deja como está
func ink(c: Color, vmax := 0.5) -> Color:
	return c if pal.get("dark", false) else App.inked(c, vmax)

func set_palette(pname: String) -> void:
	pal_name = pname; pal = PAL[pname]
	var gm: ShaderMaterial = ground.material_override
	for k in [["u_a", "a"], ["u_b", "b"], ["u_line", "line"], ["u_fog", "fog"], ["u_bg", "bg"], ["u_ink", "edge"]]:
		gm.set_shader_parameter(k[0], _v3(pal[k[1]]))
	for m in _mats.values(): m.set_shader_parameter("fill_col", _v3(pal.fill))
	arrow.material_override.set_shader_parameter("tint", _v3(pal.acc))
	for e in ents.values(): e.build()
	if not map.is_empty(): rebuild()

func load_map(m: Dictionary) -> void:
	for e in ents.values(): e.queue_free()
	ents.clear()
	for s in spots.values(): s.queue_free()
	spots.clear()
	for k in marks.values(): k.queue_free()
	marks.clear()
	for c in fx.get_children(): c.queue_free()
	target = null; focus = null; _trail_pts.clear(); lead = Vector2.ZERO
	talker = null; talk_w = 0.0; shake = 0.0; fxs.clear(); drops.clear(); _free_ok = false
	map = m; fog = m.get("fog", 13.0); known = {}; ground.visible = true; rain = 0.0
	door_state = {}
	for b in m.get("buildings", []):
		for d in b.get("doors", []): door_state[d.id] = d.get("open", false)
	var bd: Dictionary = m.bounds
	ground.scale = Vector3(bd.x1 - bd.x0 + 120.0, 1, bd.y1 - bd.y0 + 120.0)
	ground.position = Vector3((bd.x0 + bd.x1) / 2.0, -0.03, -(bd.y0 + bd.y1) / 2.0)
	ground.material_override.set_shader_parameter("u_bounds", Vector4(bd.x0, bd.y0, bd.x1, bd.y1))
	show_guts = false; cam_mode = "follow"; base_zoom = m.get("zoom", 58.0); zoom = base_zoom
	set_palette(m.get("palette", "flat"))

func set_door(id: String, open: bool) -> void:
	if door_state.get(id) != open: door_state[id] = open; rebuild()

func reveal(id: String, v := true) -> void:
	if known.get(id, false) != v: known[id] = v; rebuild()

func rebuild() -> void:
	for c in static_g.get_children(): c.queue_free()
	walls = []
	var P := pal
	var segs := []   # [a, b, door]
	var fills := Geo.MB.new(); var cons := Geo.MB.new()
	for w in map.get("walls", []): segs.append([Vector2(w[0], w[1]), Vector2(w[2], w[3]), false])
	for B in map.get("buildings", []):
		var a0 := deg_to_rad(B.get("rot", 0.0)); var c := cos(a0); var s := sin(a0)
		var pts := []
		for p in Geo.make_points({n = B.n, r = B.R}): pts.append(Vector2(B.x + p.x * c - p.y * s, B.y + p.x * s + p.y * c))
		B.poly = pts
		for i in pts.size():
			var a: Vector2 = pts[i]; var b: Vector2 = pts[(i + 1) % pts.size()]
			var ds := []
			for d in B.get("doors", []):
				if d.side == i: ds.append(d)
			ds.sort_custom(func(p, q): return p.t < q.t)
			var L := a.distance_to(b); var t0 := 0.0
			for d in ds:
				var h: float = d.get("w", 2.3) / 2.0 / L
				var p0 := a.lerp(b, d.t - h); var p1 := a.lerp(b, d.t + h)
				segs.append([a.lerp(b, t0), p0, false])
				if not door_state.get(d.id, false): segs.append([p0, p1, true])
				d.pos = a.lerp(b, d.t); t0 = d.t + h
			segs.append([a.lerp(b, t0), b, false])
		for w in B.get("inner", []): segs.append([Vector2(B.x + w[0], B.y + w[1]), Vector2(B.x + w[2], B.y + w[3]), false])
		var sealed: bool = B.get("sealed", true) != false and not known.get(B.id, false)
		var ink: Color = P.wall; ink.a = 1.0 if sealed else 0.6
		fills.fan(pts, 0.004, ink, Vector2(1.6 if sealed else 0.6, 0.30 if sealed else 0.0))
		# trazos de construcción: circunferencia circunscrita, centro y prolongación de los lados
		var circ := []
		for q in Geo.make_points({n = 64, r = B.R}): circ.append(q + Vector2(B.x, B.y))
		cons.ring(circ, 0.035, 0.006, null, P.line, 0.55)
		cons.quad(Vector2(B.x - 0.45, B.y), Vector2(B.x + 0.45, B.y), 0.035, 0.006, Color(P.wall, 0.45))
		cons.quad(Vector2(B.x, B.y - 0.45), Vector2(B.x, B.y + 0.45), 0.035, 0.006, Color(P.wall, 0.45))
		for i in pts.size():
			var a: Vector2 = pts[i]; var b: Vector2 = pts[(i + 1) % pts.size()]
			var dn := (b - a).normalized() * minf(1.1, B.R * 0.16)
			cons.quad(a - dn, a, 0.04, 0.006, Color(P.wall, 0.4)); cons.quad(b, b + dn, 0.04, 0.006, Color(P.wall, 0.4))
		if B.has("label") and (sealed or B.get("sealed", true) == false):
			static_g.add_child(text_plane(B.label, B.x, B.y + B.get("labelDy", 0.0 if sealed else -B.R * 0.55), B.get("labelSize", 1.05), 0.0, 0.75 if sealed else 0.4, false))
	for l in map.get("labels", []):
		static_g.add_child(text_plane(l.t, l.x, l.y, l.get("s", 1.2), l.get("rot", 0.0), l.get("a", 0.38), l.get("it", false)))
	var fm := MeshInstance3D.new(); fm.mesh = fills.commit(); fm.material_override = mat(-4); static_g.add_child(fm)
	var cm := MeshInstance3D.new(); cm.mesh = cons.commit(); cm.material_override = mat(-3); static_g.add_child(cm)
	var mb := Geo.MB.new()
	var wc: Color = P.wall
	for sgm in segs:
		walls.append([sgm[0].x, sgm[0].y, sgm[1].x, sgm[1].y, 0.38 if sgm[2] else 0.62])
		if not sgm[2]: mb.quad(sgm[0], sgm[1], 0.5, 0.012, Color(wc, 0.06))
	for sgm in segs:
		if sgm[2]: mb.quad(sgm[0], sgm[1], 0.06, 0.015, Color(wc, 0.6))
		else: mb.quad(sgm[0], sgm[1], 0.16, 0.015, wc)
	var wm := MeshInstance3D.new(); wm.mesh = mb.commit(); wm.material_override = mat(-2); static_g.add_child(wm)
	_build_roofs()

# Dónde no llueve: la lluvia viene del Norte y rompe contra el tejado (el lado norte) de cada casa
# y contra los muros sueltos. Se guarda, por columnas, el tramo [sur, norte] que queda a cubierto.
func _build_roofs() -> void:
	roofs = {}
	for B in map.get("buildings", []):
		var pts: Array = B.poly; var n := pts.size()
		var x0 := 1e9; var x1 := -1e9
		for q in pts: x0 = minf(x0, q.x); x1 = maxf(x1, q.x)
		for c in range(int(floor(x0 / COL)), int(floor(x1 / COL)) + 1):
			var cx := (c + 0.5) * COL; var lo := 1e9; var hi := -1e9
			for i in n:
				var a: Vector2 = pts[i]; var b: Vector2 = pts[(i + 1) % n]
				if (a.x - cx) * (b.x - cx) > 0.0 or absf(b.x - a.x) < 1e-6: continue
				var yy := a.y + (b.y - a.y) * (cx - a.x) / (b.x - a.x)
				lo = minf(lo, yy); hi = maxf(hi, yy)
			if hi > lo: _roof(c, lo, hi)
	for w in map.get("walls", []):
		var a := Vector2(w[0], w[1]); var b := Vector2(w[2], w[3])
		for c in range(int(floor(minf(a.x, b.x) / COL)), int(floor(maxf(a.x, b.x) / COL)) + 1):
			if absf(b.x - a.x) < COL:
				_roof(c, minf(a.y, b.y), maxf(a.y, b.y))
			else:
				var yy := a.y + (b.y - a.y) * clampf(((c + 0.5) * COL - a.x) / (b.x - a.x), 0.0, 1.0)
				_roof(c, yy - 0.15, yy + 0.15)

func _roof(c: int, lo: float, hi: float) -> void:
	if not roofs.has(c): roofs[c] = []
	roofs[c].append([lo, hi])

func text_plane(text: String, x: float, y: float, size: float, rot: float, alpha: float, italic: bool) -> Label3D:
	var l := Label3D.new()
	l.text = text; l.font = F_FELL_IT if italic else _caps; l.font_size = 40
	l.pixel_size = size * (64.0 / 96.0) / 40.0
	l.modulate = Color(pal.edge, clampf(alpha * 1.5, 0.0, 0.95)); l.shaded = false; l.double_sided = true
	l.outline_size = 14; l.outline_modulate = Color(pal.fill, 0.9); l.outline_render_priority = -4
	l.render_priority = -3; l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	l.basis = Basis(Vector3.UP, rot) * Basis(Vector3.RIGHT, -PI / 2)
	l.position = Vector3(x, 0.008, -y)
	return l

func add(d: Dictionary) -> Ent:
	if ents.has(d.id): remove(d.id)
	var e := Ent.new().setup(self, d)
	figs.add_child(e); ents[d.id] = e; e.update(0.0)
	return e

func remove(id: String) -> void:
	if ents.has(id): ents[id].queue_free(); ents.erase(id)
	unmark(id)

func obj(id):
	if ents.has(id): return ents[id]
	return spots.get(id)

func add_spot(d: Dictionary) -> Ent:
	if spots.has(d.id): remove_spot(d.id)
	var dd := d.duplicate(); dd.spot = true
	var s := Ent.new().setup(self, dd)
	fx.add_child(s); spots[d.id] = s; s.update(0.0)
	return s

func remove_spot(id: String) -> void:
	if spots.has(id): spots[id].queue_free(); spots.erase(id)
	unmark(id)

func mark(id: String) -> void:
	if marks.has(id): return
	var mb := Geo.MB.new()
	mb.ring(Geo.make_points({n = 40, r = 1.0}), 0.06, 0.04, null, pal.acc, 0.9)
	var m := MeshInstance3D.new(); m.mesh = mb.commit(); m.material_override = mat(3)
	fx.add_child(m); marks[id] = m

func unmark(id: String) -> void:
	if marks.has(id): marks[id].queue_free(); marks.erase(id)

# un cuadrilátero suelto sobre el plano (para efectos de capítulo)
func fx_quad(color: Color, opacity := 1.0) -> MeshInstance3D:
	var mb := Geo.MB.new()
	var c := Color(color, opacity)
	mb.tri(Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5), Vector3(0.5, 0, 0.5), c)
	mb.tri(Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, 0.5), Vector3(-0.5, 0, 0.5), c)
	var m := MeshInstance3D.new(); m.mesh = mb.commit(); m.material_override = mat(0)
	fx.add_child(m)
	return m

func collide(e: Ent) -> Array:
	var hits := []
	if e.no_collide: return hits
	var r := e.rad * e.sc
	for w in walls:
		var dx: float = w[2] - w[0]; var dy: float = w[3] - w[1]
		var l2 := dx * dx + dy * dy
		if l2 == 0.0: l2 = 1.0
		var tt := clampf(((e.x - w[0]) * dx + (e.y - w[1]) * dy) / l2, 0.0, 1.0)
		var px: float = w[0] + dx * tt; var py: float = w[1] + dy * tt
		var ox := e.x - px; var oy := e.y - py; var d := sqrt(ox * ox + oy * oy)
		if d < r and d > 1e-6: e.x = px + ox / d * r; e.y = py + oy / d * r
	for o in ents.values():
		if o == e or o.hid or o.no_collide or absf(o.alt - e.alt) > 0.5: continue
		var ox2: float = e.x - o.x; var oy2: float = e.y - o.y
		var d2 := sqrt(ox2 * ox2 + oy2 * oy2); var rr: float = r + o.rad * o.sc
		if d2 < rr + 0.45: hits.append(o)
		if d2 < rr and d2 > 1e-6: e.x = o.x + ox2 / d2 * rr; e.y = o.y + oy2 / d2 * rr
	var b: Dictionary = map.bounds
	e.x = clampf(e.x, b.x0 + 1.0, b.x1 - 1.0); e.y = clampf(e.y, b.y0 + 1.0, b.y1 - 1.0)
	return hits

# ---------- efectos ----------
# k: "spark" (pinchazo), "splash" (gota), "cross" (caído), "puff" (onda)
func fx_add(k: String, x: float, y: float, dur := 0.4, sz := 1.0, c = null) -> void:
	fxs.append({k = k, x = x, y = y, t = 0.0, dur = dur, s = sz, c = c if c != null else pal.acc, a = randf() * TAU})
	if fxs.size() > 220: fxs.pop_front()

# una figura cae: gira, se encoge y deja su marca en el papel
func slay(e: Ent) -> void:
	if e == null or not is_instance_valid(e) or e.hid or e.dying >= 0.0: return
	e.dying = 0.0; e.ai = null; e.mv = null; e.no_collide = true
	fx_add("spark", e.x, e.y, 0.5, 1.3); fx_add("cross", e.x, e.y, 600.0, 0.5)
	shake = maxf(shake, 0.35)

func _line(im: ImmediateMesh, a: Vector2, b: Vector2, w: float, col: Color, h := 0.03) -> void:
	var d := b - a; var l := maxf(d.length(), 1e-6)
	var nn := Vector2(-d.y, d.x) / l * w * 0.5
	for q in [a + nn, b + nn, b - nn, a + nn, b - nn, a - nn]:
		im.surface_set_color(col); im.surface_set_uv(Vector2.ZERO); im.surface_add_vertex(Vector3(q.x, h, -q.y))

func _ring(im: ImmediateMesh, c: Vector2, r: float, w: float, col: Color, seg := 28, h := 0.03) -> void:
	for i in seg:
		var a0 := TAU * i / seg; var a1 := TAU * (i + 1) / seg
		_line(im, c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r, w, col, h)

func talker_pos():
	if talker == null or not is_instance_valid(talker): return null
	if talker is Ent: return null if talker.hid else Vector2(talker.x, talker.y)
	return Vector2(talker.position.x, -talker.position.z)

func _update_fx(dt: float) -> void:
	var im: ImmediateMesh = fx_im.mesh
	im.clear_surfaces()
	var tp = talker_pos()
	if fxs.is_empty() and tp == null: return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	# ondas de voz: dos anillos que se abren desde quien habla
	if tp != null and eye_t < 0.5:
		var base: float = (talker.rad * talker.sc if talker is Ent else 1.9) + 0.25
		var hh: float = (talker.alt + 0.045) if talker is Ent else talker.position.y
		for i in 2:
			var ph := fmod(time * 0.9 + i * 0.5, 1.0)
			_ring(im, tp, base + ph * 1.1, 0.07 * (1.0 - ph * 0.5), Color(pal.acc, 0.85 * (1.0 - ph)), 32, hh); any = true
	var keep := []
	for f in fxs:
		f.t += dt
		if f.t >= f.dur: continue
		keep.append(f)
		var u: float = f.t / f.dur; var c := Vector2(f.x, f.y); var col: Color = f.c
		match f.k:
			"spark":
				for i in 7:
					var a: float = f.a + TAU * i / 7.0; var d := Vector2(cos(a), sin(a))
					var r0: float = (0.25 + 0.9 * u) * f.s; var r1: float = r0 + (0.32 * (1.0 - u) + 0.05) * f.s
					_line(im, c + d * r0, c + d * r1, 0.075 * f.s, Color(col, 1.0 - u * u), 0.06)
			"splash":
				for sgn in [-1.0, 1.0]:
					var d := Vector2(sgn * 0.75, 0.65)
					_line(im, c + d * (0.05 + 0.22 * u), c + d * (0.16 + 0.32 * u), 0.035, Color(pal.edge, 0.5 * (1.0 - u)), 0.035)
			"cross":
				var al := minf(1.0, f.t * 3.0) * 0.8
				_line(im, c + Vector2(-f.s, -f.s), c + Vector2(f.s, f.s), 0.09, Color(col, al), 0.02)
				_line(im, c + Vector2(-f.s, f.s), c + Vector2(f.s, -f.s), 0.09, Color(col, al), 0.02)
			"puff":
				_ring(im, c, (0.4 + 2.4 * u) * f.s, 0.06, Color(col, 0.7 * (1.0 - u)), 28, 0.05)
		any = true
	fxs = keep
	if not any: _line(im, Vector2.ZERO, Vector2.ZERO, 0.0, Color(0, 0, 0, 0))
	im.surface_end()

# ---------- lluvia ----------
# Gotas de tinta que caen del Norte. Rompen contra tejados, muros y figuras, y no cruzan las casas.
func _covered(x: float, y: float) -> bool:
	for iv in roofs.get(int(floor(x / COL)), []):
		if y >= iv[0] - 0.05 and y <= iv[1]: return true
	return false

func _update_rain(dt: float, p) -> void:
	var im: ImmediateMesh = rain_im.mesh
	im.clear_surfaces()
	var want := int(rain_cur * 230.0)
	if want <= 0 or eye_t > 0.6:
		drops.clear(); return
	# rectángulo visible (con margen)
	var vs := get_viewport().get_visible_rect().size
	var cx := cam_x; var cy := cam_y; var hh := zoom_cur * 0.45 + 3.0
	if cam_mode == "free" and p != null: cx = p.x; cy = p.y; hh = 30.0
	var hw := hh * clampf(vs.x / maxf(vs.y, 1.0), 0.6, 2.4)
	if cam_mode == "free": hw = 34.0
	while drops.size() > want: drops.pop_back()
	while drops.size() < want:
		drops.append([cx + (randf() * 2.0 - 1.0) * hw, cy + (randf() * 2.0 - 1.0) * hh, 6.0 + randf() * 4.5, 0.7 + randf() * 0.9])
	# figuras: por columnas, para que cada gota sólo mire las que tiene debajo
	var bodies := {}
	for e in ents.values():
		if e.hid or absf(e.alt) > 0.3: continue
		var r: float = maxf(e.rad * e.sc, 0.3)
		for c in range(int(floor((e.x - r) / COL)), int(floor((e.x + r) / COL)) + 1):
			if not bodies.has(c): bodies[c] = []
			bodies[c].append(e)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var ink := Color(pal.edge, 0.38)
	for d in drops:
		var y0: float = d[1]
		d[1] -= d[2] * dt
		var x: float = d[0]; var y: float = d[1]
		var c := int(floor(x / COL)); var hit := false; var hy := 0.0
		for iv in roofs.get(c, []):
			if y <= iv[1] and y0 >= iv[0] - 0.05: hit = true; hy = iv[1]; break
		if not hit:
			for e in bodies.get(c, []):
				var r: float = maxf(e.rad * e.sc, 0.3)
				var dx: float = x - e.x
				if absf(dx) < r:
					var top: float = e.y + sqrt(r * r - dx * dx) * 0.9
					if y <= top and y0 >= e.y - r: hit = true; hy = top; break
		if hit:
			if hy <= y0 + 0.3: fx_add("splash", x, hy, 0.28)
		if hit or y < cy - hh or absf(x - cx) > hw:
			# nueva gota: arriba de la vista o, si cae a cubierto, en otro sitio
			d[0] = cx + (randf() * 2.0 - 1.0) * hw
			d[1] = cy + hh * (0.2 + 0.8 * randf()) if hit else cy + hh + randf() * 2.0
			var tries := 0
			while _covered(d[0], d[1]) and tries < 4:
				d[0] = cx + (randf() * 2.0 - 1.0) * hw; tries += 1
			if _covered(d[0], d[1]): d[1] = cy + hh + 40.0
			continue
		_line(im, Vector2(x, y), Vector2(x, y + d[3]), 0.045, ink, 0.03)
	_line(im, Vector2.ZERO, Vector2.ZERO, 0.0, Color(0, 0, 0, 0))
	im.surface_end()

# los paseantes que se cruzan se detienen un instante y se saludan
func _greetings(dt: float) -> void:
	_greet_t -= dt
	if _greet_t > 0.0: return
	_greet_t = 0.4
	var free := []
	for e in ents.values():
		if e.hid or e.id == "yo" or e.ai == null or e.mv != null or e.frozen or e.greet_cd > 0.0 or e.pause > 0.0 or e.dying >= 0.0: continue
		if e.ai.type in ["wander", "stroll"]: free.append(e)
	for i in free.size():
		var a: Ent = free[i]
		if a.greet_cd > 0.0: continue
		for j in range(i + 1, free.size()):
			var b: Ent = free[j]
			if b.greet_cd > 0.0: continue
			if Vector2(a.x - b.x, a.y - b.y).length() < 2.3:
				var tt := 1.3 + randf() * 1.4
				for q in [[a, b], [b, a]]:
					var m: Ent = q[0]; var o: Ent = q[1]
					m.pause = tt; m.greet_cd = 9.0 + randf() * 8.0; m.talk = 0.8
					if not m.fixed_rot: m.rot = atan2(o.y - m.y, o.x - m.x) + (0.0 if not m.woman else PI * 0.5)
				break

func nearest(x: float, y: float, maxd: float, ok: Callable):
	var best = null; var bd := maxd
	for group in [ents, spots]:
		for o in group.values():
			if o.hid or not ok.call(o): continue
			var d: float = Vector2(o.x - x, o.y - y).length() - o.rad * o.sc
			if d < bd: bd = d; best = o
	return best

func target_obj():
	if target is String or target is StringName: return obj(String(target))
	return target

static func pos_of(o) -> Vector2:
	if o is Vector2: return o
	return Vector2(o.x, o.y)

func update(dt: float, player) -> void:
	time += dt
	rain_cur = lerpf(rain_cur, rain, minf(1.0, dt * 0.8))
	var gm: ShaderMaterial = ground.material_override
	gm.set_shader_parameter("u_rain", rain_cur)
	# quien habla late; los que están cerca y quietos se vuelven hacia él
	var tp = talker_pos()
	if talker is Ent and tp != null: talker.talk = 1.0
	for e in ents.values():
		e.look = tp if tp != null and e != talker and Vector2(e.x, e.y).distance_to(tp) < 15.0 else null
		e.update(dt)
	_greetings(dt)
	for s in spots.values(): s.update(dt)
	for id in marks:
		var m: MeshInstance3D = marks[id]; var o = obj(id)
		if o == null or o.hid: m.visible = false; continue
		m.visible = true
		var r: float = (o.rad * o.sc + 0.5) * (1.0 + 0.1 * sin(time * 4.0))
		m.scale = Vector3.ONE * r; m.position = Vector3(o.x, o.alt, -o.y)
	var T = target_obj()
	arrow.visible = false
	if T != null and player != null and not (T is Ent and T.hid) and eye_t < 0.3 and cam_mode == "follow":
		var gp := pos_of(T)
		if gp.distance_to(Vector2(player.x, player.y)) > 5.0:
			var a := atan2(gp.y - player.y, gp.x - player.x)
			arrow.visible = true
			arrow.position = Vector3(player.x + cos(a) * 2.0, 0.05, -(player.y + sin(a) * 2.0)); arrow.rotation.y = a
			arrow.material_override.set_shader_parameter("alpha_mul", 0.55 + 0.35 * sin(time * 5.0))
	_update_trail(dt, player)
	_update_rain(dt, player)
	_update_fx(dt)
	update_cam(dt, player)

# estela: rombos que se apagan tras el jugador cuando corre
func _update_trail(dt: float, p) -> void:
	var im: ImmediateMesh = trail.mesh
	im.clear_surfaces()
	for q in _trail_pts: q[2] += dt
	while not _trail_pts.is_empty() and _trail_pts[0][2] > 0.7: _trail_pts.pop_front()
	if p != null and cam_mode == "follow" and eye_t < 0.5 and App.g.vel.length() > 3.0:
		if _trail_pts.is_empty() or Vector2(_trail_pts[-1][0] - p.x, _trail_pts[-1][1] - p.y).length() > 0.55:
			_trail_pts.append([p.x, p.y, 0.0])
	if _trail_pts.is_empty() or eye_t > 0.5: return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for q in _trail_pts:
		var k: float = 1.0 - q[2] / 0.7
		var s := 0.06 + 0.1 * k
		var col := Color(pal.edge, 0.4 * k)
		var c := Vector3(q[0], 0.006, -q[1])
		for v in [Vector3(s, 0, 0), Vector3(0, 0, s), Vector3(-s, 0, 0), Vector3(s, 0, 0), Vector3(-s, 0, 0), Vector3(0, 0, -s)]:
			im.surface_set_color(col); im.surface_set_uv(Vector2.ZERO); im.surface_add_vertex(c + v)
	im.surface_end()

func update_cam(dt: float, p) -> void:
	var f: Vector2 = focus if focus != null else (Vector2(p.x, p.y) if p != null else Vector2.ZERO)
	var k := minf(1.0, dt * 4.0)
	var want_lead := Vector2.ZERO
	if focus == null and p != null and cam_mode == "follow": want_lead = App.g.vel * 0.28
	lead = lead.lerp(want_lead, minf(1.0, dt * 2.5))
	speed_zoom = lerpf(speed_zoom, want_lead.length() * 1.6, minf(1.0, dt * 2.0))
	shift_cur = lerpf(shift_cur, shift, k); shift_y_cur = lerpf(shift_y_cur, shift_y, k)
	# la cámara se va hacia quien habla (a medio camino del jugador) y se acerca un poco
	var tp = talker_pos()
	var near_talk: bool = tp != null and p != null and (tp as Vector2).distance_to(Vector2(p.x, p.y)) < 34.0
	talk_w = lerpf(talk_w, 1.0 if near_talk else 0.0, minf(1.0, dt * 2.2))
	if near_talk: talk_cur = talk_cur.lerp(tp, minf(1.0, dt * 3.0)) if talk_w > 0.05 else tp
	var zmul := 1.0
	if focus == null and talk_w > 0.01:
		f = f.lerp(talk_cur, 0.5 * talk_w); zmul = 1.0 - 0.13 * talk_w
	shake = maxf(0.0, shake - dt * 2.2)
	var sx := sin(time * 61.0) * shake * 0.5; var sy := cos(time * 47.0) * shake * 0.5
	cam_x = lerpf(cam_x, f.x + shift_cur + lead.x, k); cam_y = lerpf(cam_y, f.y + shift_y_cur + lead.y, k)
	zoom_cur = lerpf(zoom_cur, zoom * zmul + speed_zoom, minf(1.0, dt * 2.0))
	var gm: ShaderMaterial = ground.material_override
	if cam_mode == "free" and p != null:
		var cp := cos(free.pitch as float)
		var tgt := Vector3(p.x, p.alt, -p.y)
		# en el Espacio la mirada se desliza hacia quien habla allá abajo
		if talk_w > 0.01: tgt = tgt.lerp(Vector3(talk_cur.x, 0.0, -talk_cur.y), 0.55 * talk_w)
		if not _free_ok: _free_tgt = tgt; _free_ok = true
		_free_tgt = _free_tgt.lerp(tgt, minf(1.0, dt * 5.0)); tgt = _free_tgt + Vector3(sx, 0, sy)
		var pos := tgt + Vector3(sin(free.yaw) * cp * free.dist, sin(free.pitch) * free.dist, cos(free.yaw) * cp * free.dist)
		cam.fov = 42; cam.near = 0.2
		cam.look_at_from_position(pos, tgt, Vector3.UP)
		gm.set_shader_parameter("u_fade", 0.0)
		return
	var e := App.ease(eye_t)
	var px: float = p.x if p != null else f.x; var py: float = p.y if p != null else f.y
	var r: float = p.rot if p != null else PI / 2
	var dx := cos(r); var dy := sin(r)
	cam.fov = lerpf(30, 62, e); cam.near = lerpf(0.5, 0.008, minf(1.0, e * 3.0))
	# en vertical la cámara se aleja para que quepa más mundo a lo ancho
	var vs := get_viewport().get_visible_rect().size
	var zf := clampf(vs.y / maxf(vs.x, 1.0), 1.0, 1.6)
	# en un móvil apaisado la pantalla es pequeña: la cámara se acerca para que las figuras se lean
	if App.ui != null and App.ui.compact: zf *= 0.74
	var pos2 := Vector3(lerpf(cam_x + sx, px - dx * 0.2, e), lerpf(zoom_cur * zf, 0.012, e), -lerpf(cam_y + sy, py - dy * 0.2, e))
	var look := Vector3(lerpf(cam_x + sx, px + dx * 12.0, e), lerpf(0.0, 0.012, e), -lerpf(cam_y + sy, py + dy * 12.0, e))
	var up := Vector3(dx * e * (1.0 - e) * 2.0, e, -(1.0 - e) - dy * e * (1.0 - e) * 2.0)
	if e >= 0.999: up = Vector3.UP
	cam.look_at_from_position(pos2, look, up.normalized())
	gm.set_shader_parameter("u_fade", e * e)
