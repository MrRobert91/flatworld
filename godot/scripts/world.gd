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

func collide(e: Ent) -> void:
	if e.no_collide: return
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
		if d2 < rr and d2 > 1e-6: e.x = o.x + ox2 / d2 * rr; e.y = o.y + oy2 / d2 * rr
	var b: Dictionary = map.bounds
	e.x = clampf(e.x, b.x0 + 1.0, b.x1 - 1.0); e.y = clampf(e.y, b.y0 + 1.0, b.y1 - 1.0)

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
	for e in ents.values(): e.update(dt)
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
		var tp := pos_of(T)
		if tp.distance_to(Vector2(player.x, player.y)) > 5.0:
			var a := atan2(tp.y - player.y, tp.x - player.x)
			arrow.visible = true
			arrow.position = Vector3(player.x + cos(a) * 2.0, 0.05, -(player.y + sin(a) * 2.0)); arrow.rotation.y = a
			arrow.material_override.set_shader_parameter("alpha_mul", 0.55 + 0.35 * sin(time * 5.0))
	_update_trail(dt, player)
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
	cam_x = lerpf(cam_x, f.x + shift_cur + lead.x, k); cam_y = lerpf(cam_y, f.y + shift_y_cur + lead.y, k)
	zoom_cur = lerpf(zoom_cur, zoom + speed_zoom, minf(1.0, dt * 2.0))
	var gm: ShaderMaterial = ground.material_override
	if cam_mode == "free" and p != null:
		var cp := cos(free.pitch as float)
		var tgt := Vector3(p.x, p.alt, -p.y)
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
	var pos2 := Vector3(lerpf(cam_x, px - dx * 0.2, e), lerpf(zoom_cur * zf, 0.012, e), -lerpf(cam_y, py - dy * 0.2, e))
	var look := Vector3(lerpf(cam_x, px + dx * 12.0, e), lerpf(0.0, 0.012, e), -lerpf(cam_y, py + dy * 12.0, e))
	var up := Vector3(dx * e * (1.0 - e) * 2.0, e, -(1.0 - e) - dy * e * (1.0 - e) * 2.0)
	if e >= 0.999: up = Vector3.UP
	cam.look_at_from_position(pos2, look, up.normalized())
	gm.set_shader_parameter("u_fade", e * e)
