# M-03 · Cruzar la Calle Mayor por el oído (C2-02, el §4 hecho juego). La lámina se bloquea y la niebla
# se cierra: sólo el ojo. Tres mujeres cruzan la calle; de canto son una línea, de punta casi nada. Para
# saber dónde están: su Grito de Paz (posicional, con subtítulo de dirección) y el vaivén.
# Si te pinchan, retrocedes a la acera y se repite. No hay derrota.
#   opts: from (Vector2, salida en la acera sur), to (Rect2, la acera de enfrente), women (n), lanes ([y])
# Devuelve {pricks, time}.
class_name CrossStreet extends RefCounted

static func run(c: Ch, opts := {}) -> Dictionary:
	var g := c.g; var ui := c.ui; var W := g.world
	var from: Vector2 = opts.get("from", Vector2(6, -9.5))
	var to: Rect2 = opts.get("to", Rect2(1, 6.6, 10, 3))
	if g.auto:
		g.teleport(to.get_center().x, to.get_center().y, PI / 2)
		return {pricks = 0, time = 0.0}
	# la calle se despeja de paseantes con punta (sólo quedan ellas, que es la lección)
	var hidden := []
	for e in W.ents.values():
		if e.id in ["yo", "mercader", "noble", "irregular"] or e.is_spot: continue
		if absf(e.x - from.x) < 30.0 and not e.hid: e.hid = true; e.no_collide = true; hidden.append(e)
	await ui.fade(true, 0.35)
	g.teleport(from.x, from.y, PI / 2)
	g.set_view('eye'); W.eye_t = 1.0; g.view_lock = true
	var fog_was := W.fog; W.fog = 5.0
	var lanes: Array = opts.get("lanes", [-5.5, -1.0, 3.5])
	var speeds := [1.6, 2.1, 1.8]
	var ids := []
	for i in opts.get("women", 3):
		var y: float = lanes[i % lanes.size()]
		var dir := 1.0 if i % 2 == 0 else -1.0
		var x0 := from.x - 12.0 * dir; var x1 := from.x + 12.0 * dir
		# cruzan con quiebros: a ratos de canto (una línea) y a ratos de punta (casi nada)
		var pts := [Vector2(x0, y), Vector2(from.x - 4.0 * dir, y + 1.6), Vector2(from.x + 2.0 * dir, y - 1.2), Vector2(x1, y + 0.6), Vector2(from.x + 3.0 * dir, y - 1.4), Vector2(from.x - 5.0 * dir, y + 1.2)]
		var id := "cw%d" % i
		g.add(c.F_mujer(id, from.x + (randf() * 10.0 - 5.0), y, {name = 'una mujer', ai = {type = 'path', pts = pts, i = randi() % pts.size()}, speed = speeds[i % 3], cry = true, cryRange = 16.0}))
		ids.append(id)
	await ui.fade(false, 0.35)
	g.objective('Cruza la calle hasta el puesto del comerciante, en la otra acera', null)
	var st := {pricks = 0, t = 0.0, back = -1.0, said = false}
	var on_hurt := func(_sev):
		st.pricks += 1; st.back = 1.2
	g.hurt_taken.connect(on_hurt)
	await g.tick_until(func(dt) -> bool:
		st.t += dt
		var p := g.player
		if g.bot and st.t > 1.0: g.teleport(to.get_center().x, to.get_center().y, PI / 2)
		if st.back > 0.0:
			st.back -= dt
			if st.back <= 0.0:
				g.teleport(from.x, from.y, PI / 2); g.vel = Vector2.ZERO
				if not st.said:
					st.said = true; ui.note('*Decoro* — Por esto existe la ley.', 4)
		return to.has_point(Vector2(p.x, p.y)))
	g.hurt_taken.disconnect(on_hurt)
	g.objective('', null)
	for id in ids: W.remove(id)
	for e in hidden:
		if is_instance_valid(e): e.hid = false; e.no_collide = e.def.get("noCollide", false)
	W.fog = fog_was; g.view_lock = false
	g.state.stats.street_pricks = st.pricks
	Snd.sfx('pick')
	return {pricks = st.pricks, time = st.t}
