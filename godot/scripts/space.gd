# Objetos de Espaciolandia. Las mallas vienen de Blender (assets/models/espacio.glb).
class_name Space

const MODELS := preload("res://assets/models/espacio.glb")
static var _meshes := {}

static func mesh(name: String) -> Mesh:
	if _meshes.is_empty():
		var root := MODELS.instantiate()
		for n in root.find_children("*", "MeshInstance3D", true, false): _meshes[String(n.name)] = n.mesh
		root.free()
	return _meshes[name]

static func make_sphere() -> MeshInstance3D:
	var m := MeshInstance3D.new(); m.mesh = mesh("Esfera"); m.scale = Vector3.ONE * 1.7
	var sm := ShaderMaterial.new(); sm.shader = preload("res://shaders/sphere.gdshader"); m.material_override = sm
	return m

static func make_cube() -> MeshInstance3D:
	var m := MeshInstance3D.new(); m.mesh = mesh("Cubo")
	var sm := ShaderMaterial.new(); sm.shader = preload("res://shaders/cube.gdshader"); m.material_override = sm
	return m

# firmamento: estrellas y Sólidos a lo lejos, girando despacio
static func backdrop() -> Node3D:
	var G := Node3D.new()
	var pts := PackedVector3Array()
	for i in 1400:
		var v := Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized() * (380.0 + randf() * 60.0)
		if v.y < -60.0: v.y = -v.y
		pts.append(v)
	var arr := []; arr.resize(Mesh.ARRAY_MAX); arr[Mesh.ARRAY_VERTEX] = pts
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arr)
	var stars := MeshInstance3D.new(); stars.mesh = am
	var sm := ShaderMaterial.new(); sm.shader = preload("res://shaders/stars.gdshader"); stars.material_override = sm
	G.add_child(stars)
	var names := ["Icosaedro", "Hexaedro", "Tetraedro", "Octaedro", "Dodecaedro", "Cono", "Cilindro"]
	var cols := [Color("9fe8e0"), Color("e6bd6e"), Color("b79cf0"), Color("f0a090")]
	var spin := []
	for i in names.size():
		var a := float(i) / names.size() * TAU + 0.4
		var s := MeshInstance3D.new(); s.mesh = mesh(names[i])
		var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(cols[i % 4], 0.6); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s.material_override = m
		s.position = Vector3(cos(a) * 170.0, 50.0 + (i % 3) * 30.0, sin(a) * 170.0)
		G.add_child(s); spin.append(s)
	G.set_meta("spin", spin)
	return G

# líneas sueltas (teseracto imaginado)
static func make_lines(color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new(); m.mesh = ImmediateMesh.new()
	var sm := StandardMaterial3D.new(); sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; sm.albedo_color = color
	m.material_override = sm
	return m

# el Punto: un resplandor que siempre mira a la cámara
static func make_point() -> MeshInstance3D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.12, 0.4, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color("ffe9a8"), Color(1, 0.86, 0.51, 0.18), Color(1, 0.86, 0.51, 0)])
	var t := GradientTexture2D.new(); t.gradient = g; t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5); t.fill_to = Vector2(1.0, 0.5); t.width = 128; t.height = 128
	var m := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(1, 1); m.mesh = q
	var sm := StandardMaterial3D.new(); sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_texture = t; sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; sm.no_depth_test = true
	m.material_override = sm
	return m
