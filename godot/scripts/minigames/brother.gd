# M-15 · Las visitas del hermano (C10-06). Cada visita, un argumento del tratado (state.argumentos) con un
# juego breve tomado de lo que el jugador ya hizo. Ninguno convence: la respuesta del hermano sale de
# book.argumentos[id].reply_y1 / y4 / y7.
class_name Brother extends RefCounted

# ocho vértices de la sombra del Cubo (la orientación elegida en el VIII, C8-06) en la pizarra, y 16 puntos más
static func shadow_anchors(xf) -> PackedVector2Array:
	var b := Basis(Vector3.UP, 0.35) * Basis(Vector3.RIGHT, 0.5)
	if xf is Array and xf.size() == 9:
		b = Basis(Vector3(xf[0], xf[1], xf[2]), Vector3(xf[3], xf[4], xf[5]), Vector3(xf[6], xf[7], xf[8]))
	var C := Geom3.cube(4.0)
	var light := Vector3(0, 16, 0)
	var P := []
	for v in C.verts:
		var w: Vector3 = b * v + Vector3(0, 5, 0)
		var d := w - light; var t := -w.y / d.y
		P.append(Vector2(w.x + d.x * t, w.z + d.z * t))
	var lo := Vector2(INF, INF); var hi := Vector2(-INF, -INF)
	for q in P: lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y)); hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	var s := 230.0 / maxf(maxf(hi.x - lo.x, hi.y - lo.y), 0.01)
	var cen := (lo + hi) / 2.0
	var out := PackedVector2Array()
	for q in P: out.append(Vector2(320, 190) + (q - cen) * s)
	for j in 4:
		for i in 4:
			var e := Vector2(110 + i * 140, 60 + j * 100)
			var ok := true
			for q in out:
				if q.distance_to(e) < 30.0: ok = false
			if ok: out.append(e)
	return out

# dibuja la sombra con la guía tenue; devuelve lo que reconoce la pizarra (Sketch.classify)
static func draw_shadow(c: Ch, cap: String, help: String, max_s := 60.0) -> String:
	var g := c.g; var ui := c.ui
	if g.auto or g.bot: return 'cube_shadow'
	var anc := shadow_anchors(g.flag('shadow_xf'))
	var b := ui.draw_board(true, cap)
	b.reset(anc)
	var E: Array = Geom3.cube(4.0).edges
	var st := {t = 0.0, done = false, was = false}
	b.hint = func(bd: SlateBoard):
		for e in E: bd.line(anc[e.x].x, anc[e.x].y, anc[e.y].x, anc[e.y].y, 0.12)
		bd.text(ui.T(help), 30, 30, 15)
		bd.text(ui.T('Cuando acabes, mantén {skip_hold}.'), 30, 405, 13)
	await g.tick_until(func(dt) -> bool:
		st.t += dt
		var cls := Sketch.classify(b.segs)
		return cls == 'cube_shadow' or st.t > max_s or (b.segs.size() >= 4 and Input.is_action_pressed('skip_hold')))
	var r := Sketch.classify(b.segs)
	await g.wait(0.8)
	ui.slate(false)
	return r

static func run(c: Ch, arg: String, year: int) -> void:
	var g := c.g; var ui := c.ui
	var A: Dictionary = g.book.get('argumentos', {}).get(arg, {})
	if not A.is_empty(): await c.say('yo', A.get('pitch', ''))
	ui.close_dlg()
	match arg:
		'analogia':
			if not g.auto:
				var chips := [4, 6, 8, 12, 16].map(func(n): return {id = n, label = str(n), sub = ''})
				for q in [['Puntos terminales del Cubo', 8], ['Lados del Cubo', 6]]:
					var ans = await ui.panel('La Analogía', q[0], chips)
					if g.bot: ans = q[1]
					Snd.sfx('chalk' if ans == q[1] else 'chalk_break')
		'secciones':
			var e := g.add(c.F_circ('esferita', 1.6, 0.6, {name = 'un círculo de tiza', r = 0.9, noGuts = true, noCollide = true}))
			await SpherePredict.run(c, e, [0.5])
			g.world.remove('esferita')
		'sombras':
			await draw_shadow(c, 'la pared de la celda', 'Dibuja la sombra del Cubo')
		'lineal':
			for k in 3:
				g.add({id = 'lv%d' % k, woman = true, sway = 0.0, r = [0.3, 0.7, 0.5][k], x = -2.0 + k * 1.6, y = -2.4, rot = 0.0, fixedRot = true, noCollide = true})
			await VoiceLength.run(c, ['lv0', 'lv1', 'lv2'])
			for k in 3: g.world.remove('lv%d' % k)
		_:
			Snd.tone(880, 0.6, 'sine', 0.05)
	var key := 'reply_y%d' % year
	if A.has(key): await c.say('hermano', A[key])
