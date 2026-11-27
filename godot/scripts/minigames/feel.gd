# M-01 · Palpar un ángulo (v2). Mantener la acción recorre el ángulo con tu lado; la velocidad sube de
# 0,3/s a 1,2/s en 1,5 s de pulsación continua y soltar la reinicia. Con risky, pasar de 0,95/s (1,1 en
# relajado) es un sobresalto: el arco se tiñe de rojo, la figura te pincha y pierdes la mitad.
#   opts: text, risky, toy (juguetes del nieto: el sobresalto es una risa), blind (venda), on_fast(Callable)
# Devuelve {ok, pricks, fast}.
class_name Feel extends RefCounted

static func run(c: Ch, e: Ent, opts := {}) -> Dictionary:
	var g := c.g; var ui := c.ui
	if g.auto: return {ok = true, pricks = 0, fast = 0}
	var W := g.world; var p := g.player
	ui.close_dlg()
	var pts := e.world_pts(); var bi := 0; var bd := 1e9
	for i in pts.size():
		var dd: float = (pts[i] as Vector2).distance_to(Vector2(p.x, p.y))
		if dd < bd: bd = dd; bi = i
	var n := pts.size(); var v: Vector2 = pts[bi]; var pa: Vector2 = pts[(bi + n - 1) % n]; var pb: Vector2 = pts[(bi + 1) % n]
	var a0 := atan2(pa.y - v.y, pa.x - v.x); var a1 := atan2(pb.y - v.y, pb.x - v.x)
	var da := App.ang_diff(a0, a1)
	var arc := MeshInstance3D.new(); arc.mesh = ImmediateMesh.new(); arc.material_override = W.mat(3); W.fx.add_child(arc)
	W.focus = v; W.zoom = 13 if not opts.get("blind", false) else 9
	if opts.get("blind", false): ui.blindfold(true)
	var risky: bool = opts.get("risky", false)
	var limit := 1.1 if g.difficulty() == "relaxed" else 0.95
	var default_text := c.tx('Mantén pulsado {act} para recorrer el ángulo con tu lado. *Despacio: un ángulo agudo hiere.*', 'Mantén pulsado el botón «Palpar» para recorrer el ángulo con tu lado. *Despacio: un ángulo agudo hiere.*')
	ui.panel_info('Reconocimiento por el tacto', opts.get("text", default_text))
	g.need_act = 'Palpar'
	var st := {prog = 0.0, held = 0.0, red = 0.0, pricks = 0, fast = 0}
	await g.tick_until(func(dt) -> bool:
		if g.bot: st.prog = 1.0
		var sp := 0.0
		if g.act_held():
			st.held += dt
			sp = lerpf(0.3, 1.2, clampf(st.held / 1.5, 0.0, 1.0))
			st.prog = minf(1.0, st.prog + dt * sp)
			if randf() < 0.3: Snd.sfx('chalk')
			if sp > limit and (risky or opts.get("toy", false)):
				st.held = 0.0; st.red = 1.0; st.prog *= 0.5; st.fast += 1
				if risky:
					st.pricks += 1; g.hurt_cd = 0.0; g.hurt(0.4, v)
				if opts.has("on_fast"): opts.on_fast.call(st.fast)
		else: st.held = 0.0
		st.red = maxf(0.0, st.red - dt * 1.5)
		var col: Color = W.pal.acc.lerp(Color("d0261a"), st.red) if st.red > 0.0 else W.pal.acc
		var im: ImmediateMesh = arc.mesh
		im.clear_surfaces()
		var steps := 24; var cnt := int(steps * st.prog)
		if cnt > 0:
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in cnt:
				var t0 := a0 + da * i / steps; var t1 := a0 + da * (i + 1) / steps
				var q := [Vector2(cos(t0), sin(t0)) * 0.34, Vector2(cos(t1), sin(t1)) * 0.34, Vector2(cos(t1), sin(t1)) * 0.42, Vector2(cos(t0), sin(t0)) * 0.34, Vector2(cos(t1), sin(t1)) * 0.42, Vector2(cos(t0), sin(t0)) * 0.42]
				for k in q:
					im.surface_set_color(col); im.surface_set_uv(Vector2.ZERO); im.surface_add_vertex(Geo.v3(v + k, 0.05))
			im.surface_end()
		return st.prog >= 1.0)
	g.need_act = ''
	ui.panel_info(null)
	var deg := roundi(absf(da) * 180.0 / PI)
	var answer := func() -> bool:
		var ops := [{id = 'iso', label = 'Agudo, menor de 60°', sub = 'Isósceles'}, {id = 60, label = '60°', sub = 'Equilátero'}, {id = 90, label = '90°', sub = 'Cuadrado'}, {id = 108, label = '108°', sub = 'Pentágono'}, {id = 120, label = '120°', sub = 'Hexágono'}]
		var ans = await ui.panel('Has palpado el ángulo', '¿Cuánto mide la abertura que has recorrido?', ops)
		if deg < 58: return ans is String
		return ans is int and absi(ans - deg) < 4
	var ok: bool = await answer.call()
	if not ok and g.difficulty() == "relaxed":
		Snd.sfx('bad'); await c.say('logica', 'Piensa en cuántos lados caben en una vuelta: cuantos más lados, más abierto el ángulo. Otra vez.')
		ok = await answer.call()
	arc.queue_free(); W.focus = null; W.zoom = W.base_zoom
	if opts.get("blind", false): ui.blindfold(false)
	Snd.sfx('good' if ok else 'bad')
	return {ok = ok, pricks = st.pricks, fast = st.fast}
