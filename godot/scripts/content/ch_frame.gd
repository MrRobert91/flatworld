# El marco: la mesa del lector (P-01, S-15). El jugador es el habitante del Espacio: antes del Prólogo,
# la cámara baja desde sus ojos hasta una hoja de papel milimetrado que hay sobre una mesa, junto a un
# ejemplar abierto de Flatland (1884), y se endereza en vertical. La hoja ES la lámina de la celda: la
# mesa se construye en el mismo espacio 3D que el Plano, así que el último encuadre del descenso es
# exactamente el de la cámara de lámina y no hay corte.
class_name ChFrame extends Ch

const PAPER := Vector2(30.0, 40.0)    # la hoja (unidades del Plano)
var desk: Node3D

func _mat(c: Color, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough
	return m

func _box(size: Vector3, pos: Vector3, m: Material, rot := 0.0) -> MeshInstance3D:
	var b := BoxMesh.new(); b.size = size
	var mi := MeshInstance3D.new(); mi.mesh = b; mi.material_override = m; mi.position = pos; mi.rotation.y = rot
	desk.add_child(mi)
	return mi

func _text(t: String, pos: Vector3, px: float, col: Color, italic := false, rot := 0.0, w := 0.0) -> Label3D:
	var l := Label3D.new(); l.text = t; l.font = UIRoot.F_FELL_IT if italic else UIRoot.F_FELL; l.font_size = 64
	l.pixel_size = px; l.modulate = col; l.shaded = false; l.double_sided = true; l.outline_size = 0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if w > 0.0: l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.width = w
	l.basis = Basis(Vector3.UP, rot) * Basis(Vector3.RIGHT, -PI / 2)
	l.position = pos
	desk.add_child(l)
	return l

# la mesa, el libro abierto por la portada, el lápiz rojo y la lámpara
func build(W: World) -> void:
	desk = Node3D.new(); desk.name = "Desk"; W.add_child(desk)
	W.cam.far = 3000.0
	var wood := _mat(Color("8a6244"), 0.65)
	_box(Vector3(1400, 2.0, 1400), Vector3(-20, -1.1, 0), wood)
	# vetas de la madera
	var vet := _mat(Color("6e4b33"), 0.7)
	for i in 60: _box(Vector3(1400, 0.02, 0.35 + 0.5 * randf()), Vector3(-20, -0.09, -300 + i * 10.0 + randf() * 6.0), vet)
	# el libro, abierto: dos páginas sobre las tapas
	var cover := _mat(Color("3d2a22"), 0.5)
	var page := _mat(Color("efe6cf"), 0.95)
	_box(Vector3(62, 1.2, 42), Vector3(-58, -0.5, 2), cover, 0.06)
	_box(Vector3(29, 0.8, 39), Vector3(-73.5, 0.2, 2.9), page, 0.06)
	_box(Vector3(29, 0.8, 39), Vector3(-43.5, 0.2, 1.1), page, 0.06)
	var ink := Color("2a211b")
	# portada de 1884 (dominio público) y su epígrafe
	_text("FLATLAND", Vector3(-43.5, 0.65, -12.0), 0.055, ink, false, 0.06)
	_text("A ROMANCE OF\nMANY DIMENSIONS", Vector3(-43.6, 0.65, -6.0), 0.028, ink, false, 0.06)
	_text("By A SQUARE", Vector3(-43.5, 0.65, -0.5), 0.03, ink, true, 0.06)
	_text("«Fie, fie, how franticly I square my talk!»", Vector3(-43.4, 0.65, 4.0), 0.02, ink, true, 0.06, 1100)
	_text("LONDON\nSEELEY & Co.\n1884", Vector3(-43.3, 0.65, 13.0), 0.024, ink, false, 0.06)
	_text("To\nThe Inhabitants of SPACE IN GENERAL\nAnd H. C. IN PARTICULAR\nThis Work is Dedicated\nBy a Humble Native of Flatland\nIn the Hope that\nEven as he was Initiated into the Mysteries\nOf THREE Dimensions\nHaving been previously conversant\nWith ONLY TWO\nSo the Citizens of that Celestial Region\nMay aspire yet higher and higher\nTo the Secrets of FOUR FIVE OR EVEN SIX Dimensions",
		Vector3(-73.5, 0.65, 2.9), 0.017, ink, true, 0.06)
	# el lápiz rojo del delineante y una regla
	_box(Vector3(22, 0.9, 0.9), Vector3(24, 0.0, 14), _mat(Color("a8392a"), 0.5), 0.35)
	_box(Vector3(2.2, 0.9, 0.9), Vector3(13.6, 0.0, 17.9), _mat(Color("d9c08a"), 0.5), 0.35)
	_box(Vector3(4.5, 0.25, 46), Vector3(22, -0.1, -3), _mat(Color("c9b48a"), 0.6), -0.08)
	# la lámpara
	var brass := _mat(Color("8a6a35"), 0.35); brass.metallic = 0.7
	var base := CylinderMesh.new(); base.top_radius = 6; base.bottom_radius = 7; base.height = 1.5
	var mb := MeshInstance3D.new(); mb.mesh = base; mb.material_override = brass; mb.position = Vector3(55, 0.6, -45); desk.add_child(mb)
	_box(Vector3(1.2, 40, 1.2), Vector3(55, 20, -45), brass)
	var shade := CylinderMesh.new(); shade.top_radius = 4; shade.bottom_radius = 13; shade.height = 9
	var sm := MeshInstance3D.new(); sm.mesh = shade; sm.material_override = _mat(Color("2f4a3a"), 0.6); sm.position = Vector3(50, 40, -38); desk.add_child(sm)
	var light := OmniLight3D.new(); light.light_color = Color("ffd9a0"); light.light_energy = 4.0; light.omni_range = 260; light.omni_attenuation = 0.7
	light.position = Vector3(48, 32, -34); desk.add_child(light)
	var fill := DirectionalLight3D.new(); fill.light_energy = 0.45; fill.light_color = Color("e8dcc8")
	fill.rotation = Vector3(-1.1, 0.6, 0); desk.add_child(fill)
	# la hoja: el propio suelo del Plano, recortado al tamaño de un folio
	W.ground.scale = Vector3(PAPER.x, 1, PAPER.y)
	W.ground.position = Vector3(0, -0.03, 0)

func clear(W: World) -> void:
	if desk != null and is_instance_valid(desk): desk.queue_free()
	W.cam.far = 900.0
	desk = null

# encuadre exacto de la cámara de lámina (World.update_cam con eye_t = 0)
static func lamina_cam(W: World, c: Vector2) -> Dictionary:
	var vs := W.get_viewport().get_visible_rect().size
	var zf := clampf(vs.y / maxf(vs.x, 1.0), 1.0, 1.6)
	if App.ui != null and App.ui.compact: zf *= 0.74
	return {pos = Vector3(c.x, W.zoom * zf, -c.y), look = Vector3(c.x, 0, -c.y), fov = 30.0, up = Vector3(0, 0, -1)}

func opening() -> void:
	var W := g.world
	if g.auto: return
	g.set_map(a.cell()); g.spawn_player(0, -1, PI / 2)
	g.show_strip = false; g.view_lock = true; g.set_view('top'); W.eye_t = 0.0
	W.zoom = W.base_zoom; W.zoom_cur = W.zoom
	build(W)
	ui.hud.visible = false
	Snd.drone('none'); Snd.hum(true)
	var end := lamina_cam(W, Vector2(0, -1))
	var keys := [
		{t = 0.0, pos = Vector3(70, 75, 120), look = Vector3(-20, 0, 0), fov = 42.0, up = Vector3(0, 0, -1), ease = 'linear'},
		{t = 8.0, pos = Vector3(30, 52, 62), look = Vector3(-8, 0, 0), fov = 38.0, up = Vector3(0, 0, -1)},
		{t = 15.0, pos = Vector3(6, 40, 22), look = Vector3(0, 0, -1), fov = 34.0, up = Vector3(0, 0, -1)},
		{t = 21.0, pos = end.pos, look = end.look, fov = end.fov, up = end.up, hold = true},
	]
	# el reloj de la habitación
	var st := {t = 0.0}
	var stop := g.tick(func(dt):
		st.t += dt
		if fmod(st.t, 1.0) < dt: Snd.perc('tick', -4.0))
	ui.fade(false, 1.6)
	var fade_text := func():
		await g.wait(2.0)
		ui.note('*A los habitantes del ESPACIO EN GENERAL… para que aspiren más y más alto a los secretos de CUATRO, CINCO o incluso SEIS Dimensiones.*', 10.0)
	fade_text.call()
	await Cine.play(W, keys, true)
	stop.call(); Snd.hum(false); ui.note('', 0.01)
	Profile.data.seen_opening = true; Profile.touch(0.0)
	# al tocar el papel, el sonido «pierde una dimensión»: seco y cercano
	Snd.sfx('page')
	await ui.fade(true, 0.8)
	W.rail = {}
	clear(W)
	ui.hud.visible = true

# C10-08 · el cierre: la cámara sale del papel y se eleva sobre la mesa; la dedicatoria aparece línea a
# línea y, durante dos segundos, sobre la mesa cae una sombra que no corresponde a nada de la habitación:
# la de un teseracto.
const DEDICATION := ['A los habitantes del ESPACIO EN GENERAL', 'y a H. C. EN PARTICULAR', 'dedica esta obra', 'un humilde nativo de Planilandia,',
	'con la esperanza de que,', 'así como él fue iniciado en los misterios', 'de TRES Dimensiones,', 'habiendo conocido antes SÓLO DOS,',
	'también los ciudadanos de esa región celestial', 'aspiren más y más alto', 'a los secretos de CUATRO, CINCO o incluso SEIS Dimensiones.']

func closing() -> void:
	if g.auto: return
	var W := g.world
	g.set_map(a.cell()); g.spawn_player(0, -1, PI / 2)
	g.show_strip = false; g.view_lock = true; g.set_view('top'); W.eye_t = 0.0
	W.zoom = W.base_zoom; W.zoom_cur = W.zoom
	build(W)
	ui.hud.visible = false
	Snd.drone('none'); Snd.hum(true)
	var s := lamina_cam(W, Vector2(0, -1))
	var keys := [
		{t = 0.0, pos = s.pos, look = s.look, fov = s.fov, up = s.up, ease = 'linear'},
		{t = 6.0, pos = Vector3(6, 40, 22), look = Vector3(0, 0, -1), fov = 34.0, up = Vector3(0, 0, -1)},
		{t = 13.0, pos = Vector3(30, 52, 62), look = Vector3(-8, 0, 0), fov = 38.0, up = Vector3(0, 0, -1)},
		{t = 20.0, pos = Vector3(70, 75, 120), look = Vector3(-20, 0, 0), fov = 42.0, up = Vector3(0, 0, -1), hold = true},
	]
	ui.fade(false, 1.2)
	# la dedicatoria, sobre la madera, línea a línea
	var lines := []
	for i in DEDICATION.size():
		var l := _text(tr(DEDICATION[i]), Vector3(-38, 0.2, 26 + i * 3.4), 0.034, Color('f3ead2'), i % 2 == 1, 0.0)
		l.modulate.a = 0.0; lines.append(l)
	g.tween(18.0, func(t):
		for i in lines.size(): lines[i].modulate.a = clampf(t * lines.size() * 1.1 - i, 0.0, 1.0))
	await Cine.play(W, keys, true)
	# la sombra del teseracto: dos cubos cosidos por sus vértices, sobre la mesa, del 0 al 35 % y al 0 %
	var V := []; var E := []
	for i in 16: V.append([1.0 if i & 1 else -1.0, 1.0 if i & 2 else -1.0, 1.0 if i & 4 else -1.0, 1.0 if i & 8 else -1.0])
	for i in 16:
		for bit in 4:
			if not (i & (1 << bit)): E.append(Vector2i(i, i | (1 << bit)))
	var P3 := PackedVector3Array()
	var ca := cos(0.6); var sa := sin(0.6)
	for v in V:
		var x: float = v[0] * ca - v[3] * sa; var w: float = v[0] * sa + v[3] * ca
		var k := 2.6 / (3.2 - w)
		P3.append(Vector3(x, v[1], v[2]) * k * 9.0)
	var poly := {verts = P3, edges = E}
	var xf := Transform3D(Basis(Vector3.UP, 0.4) * Basis(Vector3.RIGHT, 0.5), Vector3(-10, 60, 10))
	var segs := Geom3.shadow(poly, xf, Vector4(-30, 140, 40, 1.0))
	var im := ImmediateMesh.new(); var mi := MeshInstance3D.new(); mi.mesh = im; mi.material_override = W.mat(3); desk.add_child(mi)
	Snd.tone(110, 3.0, 'sine', 0.05)
	await g.tween(2.0, func(t):
		var al := 0.35 * sin(PI * t)
		im.clear_surfaces(); im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for sg in segs: W._line(im, sg[0], sg[1], 0.6, Color(0, 0, 0, al), 0.05)
		im.surface_end())
	Snd.hum(false)
	await ui.fade(true, 1.4)
	W.rail = {}
	clear(W)
