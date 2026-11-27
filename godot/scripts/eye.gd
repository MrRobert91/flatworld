# EL OJO: la vista desde dentro del plano. Un planilandés sólo ve una línea; la niebla atenúa lo lejano
# y así se deducen los ángulos (Reconocimiento por la Vista). El trazado se hace en la GPU (eye_cast).
class_name Eye extends Node

const N := 1024          # resolución de la línea y máximo de segmentos
var vp: SubViewport
var view: ColorRect      # lo que se muestra (tira del HUD o pantalla completa)
var cast_mat: ShaderMaterial
var view_mat: ShaderMaterial
var data := PackedFloat32Array()
var img: Image
var tex: ImageTexture
var fov := 1.75
var trace := 0.0
var desat := 0.0         # la línea en gris (C4-03)
var _cpu := []           # segmentos relativos al ojo, para consultas puntuales: [ax, ay, bx, by, id]
var _facing := 0.0

func _init() -> void:
	data.resize(N * 3 * 4)
	img = Image.create_from_data(N, 3, false, Image.FORMAT_RGBAF, data.to_byte_array())
	tex = ImageTexture.create_from_image(img)
	vp = SubViewport.new(); vp.size = Vector2i(N, 2); vp.disable_3d = true; vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var r := ColorRect.new(); r.size = Vector2(N, 2)
	cast_mat = ShaderMaterial.new(); cast_mat.shader = preload("res://shaders/eye_cast.gdshader")
	cast_mat.set_shader_parameter("segs", tex); cast_mat.set_shader_parameter("fov_tan", tan(fov / 2.0))
	r.material = cast_mat; vp.add_child(r)
	view = ColorRect.new(); view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view_mat = ShaderMaterial.new(); view_mat.shader = preload("res://shaders/eye_view.gdshader")
	view_mat.set_shader_parameter("t_data", vp.get_texture()); view_mat.set_shader_parameter("fov_tan", tan(fov / 2.0))
	view.material = view_mat; view.visible = false

func set_active(on: bool) -> void:
	view.visible = on
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED

# vuelca a la textura los segmentos visibles (muros y lados de figuras), relativos al ojo
func cast(W: World, exclude, ox: float, oy: float, facing: float, fog: float) -> void:
	_facing = facing
	var cf := cos(facing); var sf := sin(facing); var max_d := fog * 5.5
	var k := 0; var row := N * 4
	_cpu.clear()
	var row2 := N * 8
	var dark: bool = W.pal.get("dark", false)
	var wc: Color = W.pal.wall
	for w in W.walls:
		if k >= N: break
		var ax: float = w[0] - ox; var ay: float = w[1] - oy; var bx: float = w[2] - ox; var by: float = w[3] - oy
		var mx := (ax + bx) * 0.5; var my := (ay + by) * 0.5
		var hl := sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay)) * 0.5
		if sqrt(mx * mx + my * my) - hl > max_d or mx * cf + my * sf < -hl: continue
		var o := k * 4
		data[o] = ax; data[o + 1] = ay; data[o + 2] = bx; data[o + 3] = by
		data[row + o] = wc.r; data[row + o + 1] = wc.g; data[row + o + 2] = wc.b; data[row + o + 3] = w[4]
		# distancia del ojo al punto más cercano del muro
		var ex := bx - ax; var ey := by - ay
		var tt := clampf(-(ax * ex + ay * ey) / maxf(ex * ex + ey * ey, 1e-9), 0.0, 1.0)
		data[row2 + o] = Vector2(ax + ex * tt, ay + ey * tt).length(); data[row2 + o + 1] = 0.0
		_cpu.append([ax, ay, bx, by, ""])
		k += 1
	var edge: Color = W.pal.edge
	for e in W.ents.values():
		if e == exclude or e.hid or absf(e.alt) > 0.01: continue
		var dx: float = e.x - ox; var dy: float = e.y - oy
		var reach: float = e.rad * e.sc * 1.3 + 1.0
		if sqrt(dx * dx + dy * dy) - reach > max_d or dx * cf + dy * sf < -reach: continue
		var p: Array = e.world_pts(); var n := p.size(); var m := 1 if e.woman else n
		var base: Color = W.ink(App.col(e.def.tint)) if e.def.has("tint") else edge
		var near := 1e9
		for q in p: near = minf(near, Vector2(q.x - ox, q.y - oy).length())
		for i in m:
			if k >= N: break
			var a: Vector2 = p[i]; var b: Vector2 = p[(i + 1) % n]
			var c: Color = W.ink(App.col(e.side_colors[i % e.side_colors.size()]), 0.74) if e.side_colors else base
			var o := k * 4
			data[o] = a.x - ox; data[o + 1] = a.y - oy; data[o + 2] = b.x - ox; data[o + 3] = b.y - oy
			data[row + o] = c.r; data[row + o + 1] = c.g; data[row + o + 2] = c.b; data[row + o + 3] = e.lum
			data[row2 + o] = near; data[row2 + o + 1] = 1.0
			_cpu.append([a.x - ox, a.y - oy, b.x - ox, b.y - oy, e.id])
			k += 1
	# notas al margen (S-04): una chispa de lápiz rojo, perpendicular a la mirada
	var acc: Color = W.pal.acc
	for s in W.spots.values():
		if k >= N: break
		if not s.margin or s.hid: continue
		var dx: float = s.x - ox; var dy: float = s.y - oy
		var dd := sqrt(dx * dx + dy * dy)
		if dd > 6.0 or dd < 0.05 or dx * cf + dy * sf < 0.0: continue
		var px := -dy / dd * 0.04; var py := dx / dd * 0.04
		_put(k, dx - px, dy - py, dx + px, dy + py, acc, 0.7, dd, 0.0); k += 1
	# lluvia (S-06): cada gota es un trazo corto en la dirección de su caída (hacia el Sur) y otro aún
	# más corto de través. Como todas caen al Sur, su centelleo se desliza por la línea; mirando al
	# Norte se queda quieto y se aviva (las gotas vienen hacia ti).
	var drops: Array = W.drops if W.eye_t > 0.6 else []
	var rr := fog * 3.0; var nd := 0
	for d in drops:
		if k >= N - 1 or nd >= 40: break
		var dx: float = d[0] - ox; var dy: float = d[1] - oy
		if dx * cf + dy * sf < 0.1 or dx * dx + dy * dy > rr * rr: continue
		var dl := sqrt(dx * dx + dy * dy)
		_put(k, dx, dy, dx, dy + 0.12, edge, 0.35, dl, 0.0); k += 1
		_put(k, dx - 0.03, dy + 0.04, dx + 0.03, dy + 0.04, edge, 0.35, dl, 0.0); k += 1
		nd += 1
	img.set_data(N, 3, false, Image.FORMAT_RGBAF, data.to_byte_array())
	tex.update(img)
	cast_mat.set_shader_parameter("count", k)
	cast_mat.set_shader_parameter("fog", fog)
	cast_mat.set_shader_parameter("facing", Vector2(cf, sf))
	cast_mat.set_shader_parameter("reach", max_d)
	view_mat.set_shader_parameter("bg_col", World._v3(W.pal.bg))
	view_mat.set_shader_parameter("ink_col", World._v3(W.pal.edge))
	view_mat.set_shader_parameter("acc_col", World._v3(W.pal.acc))
	view_mat.set_shader_parameter("u_dark", 1.0 if dark else 0.0)
	view_mat.set_shader_parameter("u_desat", desat)
	view_mat.set_shader_parameter("u_patterns", 1.0 if bool(App.cfg.get("patterns", true)) else 0.0)

func _put(k: int, ax: float, ay: float, bx: float, by: float, c: Color, lum: float, near: float, fig: float) -> void:
	var o := k * 4; var row := N * 4; var row2 := N * 8
	data[o] = ax; data[o + 1] = ay; data[o + 2] = bx; data[o + 3] = by
	data[row + o] = c.r; data[row + o + 1] = c.g; data[row + o + 2] = c.b; data[row + o + 3] = lum
	data[row2 + o] = near; data[row2 + o + 1] = fig

# ¿qué figura toca un rayo lanzado con desvío u (-1..1 del campo visual)?
func _ray(u: float) -> String:
	var th := tan(fov / 2.0); var cf := cos(_facing); var sf := sin(_facing)
	var l := Vector2(1.0, -u * th).normalized()
	var dx := l.x * cf + l.y * sf; var dy := l.x * sf - l.y * cf
	var bt := 1e9; var hit := ""
	for s in _cpu:
		var ex: float = s[2] - s[0]; var ey: float = s[3] - s[1]
		var den := dx * ey - dy * ex
		if absf(den) < 1e-9: continue
		var t: float = (s[0] * ey - s[1] * ex) / den
		if t < 0.02 or t >= bt: continue
		var v: float = (s[0] * dy - s[1] * dx) / den
		if v < 0.0 or v > 1.0: continue
		bt = t; hit = s[4]
	return hit

func sees(id: String) -> bool:
	for i in 41:
		if _ray(1.0 - 2.0 * i / 40.0) == id: return true
	return false

# t: 0 = tira en el HUD (rect), 1 = pantalla completa
func layout(t: float, size: Vector2, time: float, strip_visible: bool, rect: Rect2) -> void:
	var e := t * t * (3.0 - 2.0 * t)
	view.size = rect.size.lerp(size, e)
	view.position = rect.position.lerp(Vector2.ZERO, e)
	# grosor de la línea: fino pero legible (unos 26 puntos en pantalla completa)
	var full_half := clampf(13.0 / size.y, 0.022, 0.05)
	view_mat.set_shader_parameter("u_strip", 1.0 - e)
	view_mat.set_shader_parameter("u_half", lerpf(0.30, full_half, e))
	view_mat.set_shader_parameter("u_bg", 1.0)
	view_mat.set_shader_parameter("u_alpha", 1.0 if strip_visible else e)
	view_mat.set_shader_parameter("u_time", time)
	view_mat.set_shader_parameter("u_trace", trace)
	view_mat.set_shader_parameter("u_px", view.get_viewport().get_window().content_scale_factor if view.is_inside_tree() else 1.0)

# rumbo en pantalla (0..1) de un punto del mundo; <0 o >1 si queda fuera del campo
func bearing(ox: float, oy: float, facing: float, x: float, y: float) -> float:
	var a := atan2(y - oy, x - ox) - facing; var c := cos(a); var s := sin(a)
	if c <= 0.05: return -1.0 if s > 0.0 else 2.0
	return 0.5 - (s / c) / tan(fov / 2.0) / 2.0
