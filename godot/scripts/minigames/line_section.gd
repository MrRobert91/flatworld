# M-07 · Tu sección ante el Rey (C6-03). El Cuadrado atraviesa la Recta y gira para que su sección
# —lo único de él que existe en Linealandia— mida lo que pide el Rey: casi un punto (un vértice), un
# lado (de frente) y la diagonal (lo más largo que puede ser). Una regla con marcas cada 0,25 u acompaña
# a la sección, y dos muescas rojas señalan el largo pedido. Hay que mantenerlo 0,6 s (±0,06 u; ±0,1 en
# relajado). El Rey reacciona a cada cambio de largo de más de 0,2 u. Devuelve los retos logrados.
class_name LineSection extends RefCounted

const BANK := ['¡Crece!', '¡Mengua!', '¡Brujería! Se estira sin moverse.', '¡Ahora es más corto! ¿Cómo lo hace?',
	'¡Más largo que mi vecino!', '¡Se encoge hasta ser casi una mujer!']
const LIMIT := 45.0

static func run(c: Ch, targets: Array, asks: Array, hints: Array) -> int:
	var g := c.g; var ui := c.ui; var W := g.world
	if g.auto: return targets.size()
	# la regla: marcas cada 0,25 u (más largas cada unidad) alrededor del Cuadrado
	var ticks := []
	for i in 49:
		var q := W.fx_quad(W.pal.edge, 0.55 if i % 4 == 0 else 0.3); q.position.y = 0.04; ticks.append(q)
	var notch := [W.fx_quad(W.pal.acc, 0.95), W.fx_quad(W.pal.acc, 0.95)]
	for q in notch: q.scale = Vector3(0.05, 1, 0.5); q.position.y = 0.06
	var z0 := W.zoom; W.zoom = 18.0   # de cerca: la sección y la regla se leen
	var bank := BANK.duplicate(); bank.shuffle()
	var tol := 0.1 if g.difficulty() == 'relaxed' else 0.06
	var done := 0
	var king := func(t: String, sec: float): ui.note(ui.T('*El Rey:* «%s»') % ui.T(t), sec)
	for k in targets.size():
		var L: float = targets[k]
		var st := {t = 0.0, hold = 0.0, last = 0.0, cd = 0.0, hinted = false, bot = 0.0}
		king.call(asks[k], 7.0)
		g.objective('Haz tu sección tan larga como pide el Rey')
		await g.tick_until(func(dt) -> bool:
			st.t += dt; st.cd = maxf(0.0, st.cd - dt)
			var p := g.player
			if g.bot:
				# el autómata se coloca: vértice al Norte, de canto (45°) o con la diagonal sobre la Recta
				st.bot += dt
				match k:
					0: p.rot = PI / 2; p.y = -(0.78 - L / 2.0); p.x = 5.6
					1: p.rot = PI / 4; p.y = 0.0; p.x = 5.6
					_: p.rot = PI / 2; p.y = 0.0; p.x = 5.6
			var s := Geom3.line_section(p.world_pts())
			var len := maxf(0.0, s.y - s.x)
			var cx := (s.x + s.y) / 2.0 if len > 0.0 else p.x
			var base := floorf(cx * 4.0) / 4.0 - 6.0
			for i in ticks.size():
				var q: MeshInstance3D = ticks[i]; var xx := base + i * 0.25
				var big := int(roundf(xx * 4.0)) % 4 == 0
				q.scale = Vector3(0.03, 1, 0.32 if big else 0.18); q.position = Vector3(xx, 0.04, 0.0)
			notch[0].position = Vector3(cx - L / 2.0, 0.06, 0.0); notch[1].position = Vector3(cx + L / 2.0, 0.06, 0.0)
			ui.panel_info('El Rey te mide', ui.T('Tu sección: %.2f   ·   lo pedido: %.2f') % [len, L])
			# el Rey lo nota todo
			if absf(len - st.last) > 0.2 and st.cd <= 0.0 and len > 0.0:
				if bank.is_empty(): bank = BANK.duplicate(); bank.shuffle()
				king.call(bank.pop_back(), 2.2); st.cd = 1.8
				Snd.voice_at('rey', 0.0, 0.0, 0.0, -4.0)
				st.last = len
			if len > 0.0 and absf(len - L) <= tol: st.hold += dt
			else: st.hold = 0.0
			if st.t > 15.0 and not st.hinted:
				st.hinted = true; ui.note(ui.T('*Lógica:* %s') % ui.T(hints[k]), 7.0)
			return st.hold >= 0.6 or st.t > LIMIT)
		if st.hold >= 0.6:
			done += 1; Snd.sfx('good'); W.fx_add('puff', g.player.x, 0.0, 0.6, 0.6)
			king.call(['¡Casi nada! Como un Punto.', '¡Como mi súbdito del Este, exactamente!', '¡Más largo que todos ellos! ¿Qué eres?'][mini(k, 2)], 3.0)
		else:
			Snd.sfx('bad'); king.call('¡Bah! Ni siquiera eso.', 3.0)
		await g.wait(1.4)
	g.objective('', null); ui.panel_info(null)
	for q in ticks + notch: q.queue_free()
	W.zoom = z0
	return done
