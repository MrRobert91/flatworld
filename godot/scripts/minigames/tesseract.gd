# M-13 · El teseracto, manejable (C8-07). Dos ángulos: XW (stick izquierdo, o izquierda/derecha) e YZ
# (stick derecho, o arriba/abajo). Se conserva la proyección de siempre: k = 2,6 / (3,2 − w). Gira solo,
# despacio, si nadie lo toca. ACH_TESS al acumular una vuelta entera en cada ángulo.
# start() devuelve la función que lo detiene; mientras tanto, la conversación sigue.
class_name Tesseract extends RefCounted

static func start(c: Ch, tess: MeshInstance3D, center: Vector3, ts: Dictionary) -> Callable:
	var g := c.g
	var V := []; var E := []
	for i in 16: V.append([1.0 if i & 1 else -1.0, 1.0 if i & 2 else -1.0, 1.0 if i & 4 else -1.0, 1.0 if i & 8 else -1.0])
	for i in 16:
		for bit in 4:
			if not (i & (1 << bit)): E.append([i, i | (1 << bit)])
	var st := {a = 0.0, b = 0.0, acc_a = 0.0, acc_b = 0.0, got = false}
	g.need_stick = true
	if not g.auto: c.ui.note(c.tx('Gira el teseracto: {move_left} / {move_right} y {move_up} / {move_down}.', 'Gira el teseracto con la palanca.', 'Gira el teseracto: stick izquierdo y stick derecho.'), 8.0)
	var stop := g.tick(func(dt):
		var ax := g.axis(); var lk := g.look_axis()
		var da: float = ax.x * 1.8 * dt
		var db: float = (lk.y if absf(lk.y) > 0.05 else ax.y) * 1.8 * dt
		if absf(da) + absf(db) < 1e-4: da = 0.25 * dt; db = 0.15 * dt   # solo, despacio
		else: st.acc_a += absf(da); st.acc_b += absf(db)
		st.a += da; st.b += db
		if not st.got and st.acc_a >= TAU and st.acc_b >= TAU: st.got = true; g.achieve('ACH_TESS')
		var ca := cos(st.a); var sa := sin(st.a); var cb := cos(st.b); var sb := sin(st.b)
		var im: ImmediateMesh = tess.mesh
		im.clear_surfaces(); im.surface_begin(Mesh.PRIMITIVE_LINES)
		for e in E:
			for vi in e:
				var v: Array = V[vi]
				var x: float = v[0] * ca - v[3] * sa; var w: float = v[0] * sa + v[3] * ca
				var y: float = v[1] * cb - v[2] * sb; var z: float = v[1] * sb + v[2] * cb
				var k: float = 2.6 / (3.2 - w) * float(ts.sc) * 2.6
				im.surface_add_vertex(center + Vector3(x, y, z) * k)
		im.surface_end())
	return func(): stop.call(); g.need_stick = false
