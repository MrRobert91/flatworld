# M-04 · Tres voces en la niebla (C2-05). Se acercan por turnos; sólo una es de un Hexágono de verdad.
# Las otras dos son Isósceles que imitan la voz: «el Isósceles empuja la garganta» y las sílabas largas
# le tiemblan (vibrato). Hay que apartarse ante la verdadera y no ante las falsas.
# Devuelve [bool, bool, bool]: si cada respuesta fue la correcta.
class_name Voices extends RefCounted

const LINES := ['¡Paso, paso a un Hexágono!', '¡Aparte, buen hombre, que llevo prisa!', '¡Abran paso a un caballero de seis lados!']

static func run(c: Ch, at: Vector2) -> Array:
	var g := c.g; var ui := c.ui; var W := g.world
	if g.auto: return [true, true, true]
	var real := randi() % 3
	var out := []
	var fog_was := W.fog; W.fog = 2.4
	g.set_view('eye')
	var p := g.player
	for i in 3:
		var is_real := i == real
		var side := p.rot + (0.9 if i % 2 == 0 else -0.9)
		var x0 := p.x + cos(side) * 13.0; var y0 := p.y + sin(side) * 13.0
		var d: Dictionary = c.F_hexa("vz", x0, y0, {name = 'una voz'}) if is_real else c.F_iso("vz", x0, y0, 9, {name = 'una voz'})
		d.noCollide = true
		var e := g.add(d)
		var st := {t = 0.0, k = 0}
		var stop := g.tick(func(dt):
			st.t -= dt
			if st.t <= 0.0:
				st.t = 1.6
				Snd.voice_at('hexa', e.x, e.y, 0.0 if is_real else 38.0)
				ui.note('«%s»' % ui.T(LINES[st.k % LINES.size()]), 1.4); st.k += 1)
		await e.move_to(p.x + cos(side) * 2.8, p.y + sin(side) * 2.8, 2.6)
		var ch = await c.choose([{t = '(Apartarte con una reverencia.)', id = 'a'}, {t = '(Seguir tu camino.)', id = 'n'}])
		stop.call()
		var ok: bool = (ch == 'a') == is_real
		out.append(ok)
		if is_real:
			if ch == 'a': await c.say('noble', 'Gracias, caballero. Da gusto encontrar educación con esta niebla.')
			else:
				await c.say('noble', '¿No se aparta usted ante un Hexágono? ¡Qué tiempos! Ya no se respeta ni un ángulo.')
				g.her(1)
		else:
			if ch == 'a': await c.say('soldado', 'Je. Perdone el señor. A uno le sale la voz que quiere, y con ésa me ahorro los empujones.')
			else: await c.say('soldado', '(Un Isósceles, que se aparta él, gruñendo.) Pues no ha colado.')
		var leave := func():
			await e.move_to(e.x - cos(side) * 12.0, e.y - sin(side) * 12.0, 4.0)
			W.remove('vz')
		leave.call()
		await g.wait(1.0)
	W.fog = fog_was
	g.set_view('top')
	return out
