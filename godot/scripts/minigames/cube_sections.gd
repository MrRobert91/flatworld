# M-11 · Las secciones del Cubo (C8-05). Antes de cada pasada, el jugador ve el Cubo en 3D y predice qué
# verán los planilandeses al atravesar el Plano: de cara, un cuadrado que no cambia; de arista, un
# rectángulo que se ensancha y se estrecha; de vértice, un triángulo que se vuelve hexágono y vuelve a
# triángulo. La sección (Geom3.section) es una figura más del Plano: se ve en la lámina y en la línea del
# ojo de un planilandés. Después, la ronda inversa: un sólido oculto (pirámide, cono o cilindro tumbado)
# del que sólo se ve la sección. Devuelve {pred: aciertos de 0 a 3, hidden: bool}.
class_name CubeSections extends RefCounted

const SPEED := 1.2
const SIL := [{id = 'square', label = 'un cuadrado que no cambia', sil = 'square'}, {id = 'rect', label = 'un rectángulo que se ensancha', sil = 'rect'},
	{id = 'tri_hex', label = 'un triángulo que se vuelve hexágono', sil = 'tri_hex'}, {id = 'circle', label = 'un círculo que crece y mengua', sil = 'circle'}]
const SOLIDS := [{id = 'pyramid', label = 'una pirámide', sil = 'pyramid'}, {id = 'cone', label = 'un cono', sil = 'cone'},
	{id = 'cylinder', label = 'un cilindro tumbado', sil = 'cylinder'}, {id = 'cube', label = 'un cubo', sil = 'cube'}]

static func vertex_basis() -> Basis:
	var up := Vector3(1, 1, 1).normalized()
	return Basis(up.cross(Vector3.UP).normalized(), up.angle_to(Vector3.UP))

# media altura de un poliedro transformado (hasta dónde asoma por encima y por debajo de su centro)
static func half_h(poly: Dictionary, b: Basis) -> float:
	var m := 0.0
	for v in poly.verts: m = maxf(m, absf((b * v).y))
	return m

# hace pasar `poly` por el Plano en `at`; `mesh` (opcional) sigue la misma transformación
static func pass_through(c: Ch, poly: Dictionary, b: Basis, at: Vector2, sec: Ent, mesh: MeshInstance3D, L: float) -> void:
	var g := c.g
	var H := half_h(poly, b) + 0.15
	var st := {h = H}
	if g.auto: return
	await g.tick_until(func(dt) -> bool:
		st.h -= SPEED * dt
		var xf := Transform3D(b, Vector3(0, st.h, 0))
		if mesh != null: mesh.transform = Transform3D(b.scaled(Vector3.ONE * L), Vector3(at.x, st.h, -at.y))
		var s := Geom3.section(poly, xf)
		if s.size() >= 3: sec.set_shape(s)
		else: sec.hid = true
		return st.h < -H)
	sec.hid = true

static func run(c: Ch, mesh: MeshInstance3D, at: Vector2, L := 4.0) -> Dictionary:
	var g := c.g; var ui := c.ui
	var sec: Ent = g.add({id = 'secc', pts = [[0.1, 0], [0, 0.1], [-0.1, 0]], x = at.x, y = at.y, name = 'la sección', tint = Color('e6bd6e'), noGuts = true, noCollide = true})
	sec.hid = true
	var C := Geom3.cube(L)
	var passes := [['square', Basis(), 'De cara.'], ['rect', Basis(Vector3.RIGHT, PI / 4), 'De arista.'], ['tri_hex', vertex_basis(), 'Y ahora, de vértice.']]
	var hits := 0
	for P in passes:
		var b: Basis = P[1]
		mesh.visible = true
		mesh.transform = Transform3D(b.scaled(Vector3.ONE * L), Vector3(at.x, half_h(C, b) + 0.8, -at.y))
		ui.note(ui.T('*La Esfera:* «%s»') % ui.T(P[2]), 4.0)
		var tries := 2 if g.difficulty() == 'relaxed' else 1
		var ans = ''
		for k in tries:
			ans = await ui.panel('Las secciones del Cubo', '¿Qué verán tus compatriotas cuando el Cubo atraviese su Plano así?', SIL)
			if g.bot: ans = P[0]
			if ans == P[0] or k == tries - 1: break
			ui.note(ui.T('*Lógica:* %s') % ui.T('Fíjate en lo que toca primero el Plano: ¿una cara, una arista o un vértice?'), 5.0)
		if ans == P[0]: hits += 1
		ui.panel_info('Lo que ven allá abajo', 'la sección, en la lámina y en la línea')
		await pass_through(c, C, b, at, sec, mesh, L)
		ui.panel_info(null)
		if ans == P[0]: Snd.sfx('good')
		else: Snd.sfx('bad')
		await g.wait(0.6)
	mesh.visible = false
	# la ronda inversa: un sólido que no se ve; sólo su sección
	var pick: Dictionary = [{id = 'pyramid', p = Geom3.pyramid(L * 0.9, L), b = Basis()}, {id = 'cone', p = Geom3.cone_n(24, L * 0.45, L), b = Basis()},
		{id = 'cylinder', p = Geom3.prism_n(24, L * 0.35, L * 1.3), b = Basis(Vector3.RIGHT, PI / 2)}].pick_random()
	if g.auto or g.bot: pick.id = 'cone'
	ui.note(ui.T('*La Esfera:* «%s»') % ui.T('Ahora, al revés. Esto no lo verás: sólo lo que ven ellos. Dime qué era.'), 5.0)
	await g.wait(1.0)
	await pass_through(c, pick.p, pick.b, at, sec, null, L)
	var guess = await ui.panel('El sólido escondido', '¿Qué ha atravesado el Plano?', SOLIDS)
	if g.auto or g.bot: guess = pick.id
	var hidden_ok: bool = guess == pick.id
	if hidden_ok: Snd.sfx('good')
	else: Snd.sfx('bad'); ui.note(ui.T('*La Esfera:* «%s»') % ui.T('Era %s. Mira otra vez cómo crecía.') % ui.T({pyramid = 'una pirámide', cone = 'un cono', cylinder = 'un cilindro tumbado'}[pick.id]), 5.0)
	g.world.remove('secc')
	return {pred = hits, hidden = hidden_ok}
