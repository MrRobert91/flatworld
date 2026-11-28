# M-12 · La sombra del Cubo (C8-06). Una luz sobre el Cubo proyecta su sombra en el Plano (Geom3.shadow):
# dos cuadrados desplazados y cuatro rayas que los cosen. El jugador gira el Cubo con el stick o las
# flechas y la sombra cambia. {act} lo da por hecho (pasados 3 s). Guarda la orientación elegida en
# flags.shadow_xf (nueve números: la base del Cubo) para el dibujo del X (C10-04). Devuelve la base.
class_name ShadowTurn extends RefCounted

static func run(c: Ch, mesh: MeshInstance3D, at: Vector2, L := 4.0, height := 5.0) -> Basis:
	var g := c.g; var ui := c.ui; var W := g.world
	var C := Geom3.cube(L)
	var light := Vector4(at.x, 16.0, -at.y, 1.0)
	var im := ImmediateMesh.new(); var mi := MeshInstance3D.new(); mi.mesh = im; mi.material_override = W.mat(3); W.fx.add_child(mi)
	var st := {yaw = 0.35, pitch = 0.5, t = 0.0, done = false, was = true}
	var col := Color(W.pal.edge, 0.8)
	var draw := func():
		var b := Basis(Vector3.UP, st.yaw) * Basis(Vector3.RIGHT, st.pitch)
		mesh.transform = Transform3D(b.scaled(Vector3.ONE * L), Vector3(at.x, height, -at.y))
		im.clear_surfaces(); im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for s in Geom3.shadow(C, Transform3D(b, Vector3(at.x, height, -at.y)), light):
			W._line(im, s[0], s[1], 0.13, col, 0.05)
		im.surface_end()
		return b
	mesh.visible = true
	var b: Basis = draw.call()
	if not g.auto:
		ui.panel_info('La sombra del Cubo', c.tx('Gira el Cubo con {move}. Cuando te guste su sombra, pulsa {act}.', 'Gira el Cubo con la palanca. Cuando te guste su sombra, toca el botón de acción.', 'Gira el Cubo con el stick. Cuando te guste su sombra, pulsa {act}.'))
		g.need_stick = true; g.need_act = 'Hecho'
		await g.tick_until(func(dt) -> bool:
			st.t += dt
			var ax := g.axis() + g.look_axis() * Vector2(1, -1)
			if g.bot: ax = Vector2(0.6, 0.2)
			st.yaw += ax.x * 1.6 * dt; st.pitch = clampf(st.pitch + ax.y * 1.2 * dt, -1.5, 1.5)
			b = draw.call()
			var act := g.act_held()
			var fin: bool = (act and not st.was and st.t > 3.0) or st.t > 60.0 or (g.bot and st.t > 2.0)
			st.was = act
			return fin)
		g.need_stick = false; g.need_act = ''; ui.panel_info(null)
	g.flag('shadow_xf', [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z])
	mi.queue_free()
	return b
