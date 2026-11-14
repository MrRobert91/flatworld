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
var _cpu := []           # segmentos relativos al ojo, para consultas puntuales: [ax, ay, bx, by, id]
var _facing := 0.0

func _init() -> void:
	data.resize(N * 2 * 4)
	img = Image.create_from_data(N, 2, false, Image.FORMAT_RGBAF, data.to_byte_array())
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
	view_mat.set_shader_parameter("t_data", vp.get_texture())
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
	var wc := App.lin(W.pal.wall)
	for w in W.walls:
		if k >= N: break
		var ax: float = w[0] - ox; var ay: float = w[1] - oy; var bx: float = w[2] - ox; var by: float = w[3] - oy
		var mx := (ax + bx) * 0.5; var my := (ay + by) * 0.5
		var hl := sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay)) * 0.5
		if sqrt(mx * mx + my * my) - hl > max_d or mx * cf + my * sf < -hl: continue
		var o := k * 4
		data[o] = ax; data[o + 1] = ay; data[o + 2] = bx; data[o + 3] = by
		data[row + o] = wc.r; data[row + o + 1] = wc.g; data[row + o + 2] = wc.b; data[row + o + 3] = w[4]
		_cpu.append([ax, ay, bx, by, ""])
		k += 1
	var edge: Color = W.pal.edge
	for e in W.ents.values():
		if e == exclude or e.hid or absf(e.alt) > 0.01: continue
		var dx: float = e.x - ox; var dy: float = e.y - oy
		var reach: float = e.rad * e.sc * 1.3 + 1.0
		if sqrt(dx * dx + dy * dy) - reach > max_d or dx * cf + dy * sf < -reach: continue
		var p: Array = e.world_pts(); var n := p.size(); var m := 1 if e.woman else n
		var base: Color = App.lin(App.col(e.def.tint) if e.def.has("tint") else edge)
		for i in m:
			if k >= N: break
			var a: Vector2 = p[i]; var b: Vector2 = p[(i + 1) % n]
			var c: Color = App.lin(App.col(e.side_colors[i % e.side_colors.size()])) if e.side_colors else base
			var o := k * 4
			data[o] = a.x - ox; data[o + 1] = a.y - oy; data[o + 2] = b.x - ox; data[o + 3] = b.y - oy
			data[row + o] = c.r; data[row + o + 1] = c.g; data[row + o + 2] = c.b; data[row + o + 3] = e.lum
			_cpu.append([a.x - ox, a.y - oy, b.x - ox, b.y - oy, e.id])
			k += 1
	img.set_data(N, 2, false, Image.FORMAT_RGBAF, data.to_byte_array())
	tex.update(img)
	cast_mat.set_shader_parameter("count", k)
	cast_mat.set_shader_parameter("fog", fog)
	cast_mat.set_shader_parameter("facing", Vector2(cf, sf))

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

# t: 0 = tira en el HUD, 1 = pantalla completa
func layout(t: float, size: Vector2, time: float, strip_visible: bool) -> void:
	var e := t * t * (3.0 - 2.0 * t)
	var sw := 0.7 if size.x < size.y and size.x < 820.0 else 0.44
	var w := sw + (1.0 - sw) * e
	var h := (44.0 / size.y) + (1.0 - 44.0 / size.y) * e
	var cy := (1.0 - 36.0 / size.y) + (0.5 - (1.0 - 36.0 / size.y)) * e
	view.size = Vector2(w * size.x, h * size.y)
	view.position = Vector2(0.5 * size.x - view.size.x / 2.0, (1.0 - cy) * size.y - view.size.y / 2.0)
	view_mat.set_shader_parameter("u_strip", 1.0 - e)
	view_mat.set_shader_parameter("u_half", 0.26 + (0.022 - 0.26) * e)
	view_mat.set_shader_parameter("u_bg", 0.85 + 0.15 * e)
	view_mat.set_shader_parameter("u_alpha", 1.0 if strip_visible else e)
	view_mat.set_shader_parameter("u_time", time)
	view_mat.set_shader_parameter("u_trace", trace)

# rumbo en pantalla (0..1) de un punto del mundo; <0 o >1 si queda fuera del campo
func bearing(ox: float, oy: float, facing: float, x: float, y: float) -> float:
	var a := atan2(y - oy, x - ox) - facing; var c := cos(a); var s := sin(a)
	if c <= 0.05: return -1.0 if s > 0.0 else 2.0
	return 0.5 - (s / c) / tan(fov / 2.0) / 2.0
