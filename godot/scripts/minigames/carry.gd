# S-13 · Tomar desde Arriba (C8-03). En vuelo, a menos de 3 u en horizontal de una figura `carryable` y
# por debajo de 6 u de altura, {act} la levanta fuera del Plano: deja de proyectar sombra y desaparece de la
# línea de los planilandeses. Sigue al Cuadrado 1,2 u por debajo, con una plomada hasta el Plano que marca
# dónde caerá. Al soltar {act}, cae en 0,5 s; si cae dentro de un muro, se empuja al hueco libre más cercano.
# Si cae dentro de un recinto cerrado, allí se queda: es justo la gracia.
class_name Carry extends RefCounted

const REACH := 3.0
const ALT := 6.0

# activa el transporte mientras dure el capítulo; devuelve la función que lo detiene.
# on_drop(e) se llama cada vez que algo se suelta.
static func enable(c: Ch, on_drop := Callable()) -> Callable:
	var g := c.g; var W := g.world
	var plumb := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.05, 1.0, 0.05); plumb.mesh = bm
	var pm := StandardMaterial3D.new(); pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; pm.albedo_color = W.pal.acc
	plumb.material_override = pm; plumb.visible = false; W.add_child(plumb)
	var st := {held = null, was = false, fall = []}
	var stop := g.tick(func(dt):
		var p := g.player
		if p == null: return
		var act := g.act_held() and not g.busy
		var e = st.held
		# tomar: la figura más cercana que se pueda llevar
		if act and not st.was and e == null and p.alt < ALT:
			var best = null; var bd := REACH
			for o in W.ents.values():
				if not o.carryable or o.hid or o.lifted: continue
				var d := Vector2(o.x - p.x, o.y - p.y).length()
				if d < bd: bd = d; best = o
			if best != null:
				st.held = best; best.lifted = true; best.no_collide = true
				Snd.sfx('rise'); App.rumble(0.1, 0.3, 0.1)
		# soltar
		elif not act and st.was and e != null:
			st.held = null; st.fall.append([e, e.alt]); Snd.sfx('fall')
		st.was = act
		e = st.held
		if e != null:
			e.x = lerpf(e.x, p.x, minf(1.0, dt * 6.0)); e.y = lerpf(e.y, p.y, minf(1.0, dt * 6.0))
			e.alt = lerpf(e.alt, maxf(0.3, p.alt - 1.2), minf(1.0, dt * 5.0))
			# la plomada: un trazo vertical de la figura al Plano
			plumb.visible = true; plumb.scale = Vector3(1, maxf(e.alt, 0.05), 1); plumb.position = Vector3(e.x, e.alt / 2.0, -e.y)
		else: plumb.visible = false
		for f in st.fall.duplicate():
			var o: Ent = f[0]
			o.alt = move_toward(o.alt, 0.0, maxf(f[1], 0.5) / 0.5 * dt)
			if o.alt <= 0.0:
				st.fall.erase(f); o.lifted = false
				var x0 := o.x; var y0 := o.y
				W._walls_push(o)
				if Vector2(o.x - x0, o.y - y0).length() > 0.01: Snd.sfx('bad')
				W.fx_add('puff', o.x, o.y, 0.5, 0.5); Snd.sfx('pick')
				if on_drop.is_valid(): on_drop.call(o))
	return func():
		stop.call(); plumb.queue_free()
		if st.held != null: st.held.lifted = false; st.held.alt = 0.0

# espera a que la figura `id` quede soltada donde pide `goal(e) -> bool`
static func run(c: Ch, id: String, goal: Callable, hint: String, auto_at := Vector2.ZERO) -> bool:
	var g := c.g; var e := g.npc(id)
	if e == null: return false
	if g.auto or g.bot:
		g.objective(hint, id)
		e.x = auto_at.x; e.y = auto_at.y; e.alt = 0.0
		await g.wait(0.2)
		g.objective('', null)
		return goal.call(e)
	g.objective(hint, id); g.world.mark(id)
	await g.until(func(): return not e.lifted and e.alt <= 0.0 and goal.call(e))
	g.world.unmark(id); g.objective('', null)
	return true
