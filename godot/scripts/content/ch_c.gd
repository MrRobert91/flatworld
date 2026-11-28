# Capítulos VI–VII: la visión de Linealandia y el Forastero de Espaciolandia.
class_name ChC extends Ch

# ============ CAP. VI — LINEALANDIA ============
const SIDE := 1.103   # el lado del Cuadrado (2r·sin 45°, r = 0,78)
const DIAG := 1.56    # su diagonal (2r)

func ch6() -> void:
	g.set_map({bounds = {x0 = -52, y0 = -18, x1 = 52, y1 = 18}, fog = 22.0, palette = 'dream', zoom = 44.0,
		labels = [{t = 'Linealandia', x = 0, y = -12.5, s = 1.5, a = 0.3}, {t = 'un sueño · penúltima noche del año 1999', x = 0, y = -14.6, s = 0.65, a = 0.4, it = true}]})
	var W := g.world; g.spawn_player(3, -7, PI / 2)
	Snd.mono(true)   # C6-05: en la Línea, todo suena por un solo canal
	var line := W.fx_quad(W.pal.edge, 0.55); line.scale = Vector3(110, 1, 0.035); line.position.y = 0.006
	var sec := W.fx_quad(W.pal.acc, 1.0); sec.position.y = 0.05; sec.visible = false
	var folk := []
	# Los habitantes de la Línea no pueden salir de ella: ni siquiera girar (fixedRot).
	var man := func(id: String, x: float, r: float, name := 'un súbdito'):
		folk.append(g.add({id = id, woman = true, sway = 0.0, r = r, voice = 'rey', x = x, y = 0, name = name, rot = 0.0, fixedRot = true}))
	var wom := func(id: String, x: float):
		var e := g.add({id = id, woman = true, sway = 0.0, r = 0.07, voice = 'mujer', x = x, y = 0, name = 'una súbdita (un Punto)', rot = 0.0, fixedRot = true})
		e.x0 = x; folk.append(e)
		return e
	man.call('rey', 0, 1.6, 'la Línea más larga')
	wom.call('w1', 3); man.call('m1', 8.6, 0.9); wom.call('w2', 11); man.call('m2', 13.6, 0.7); wom.call('w3', 16); man.call('m3', 19, 0.78); wom.call('w4', 22); man.call('m4', 26, 0.55)
	wom.call('w5', -3); man.call('m5', -6.2, 0.8); wom.call('w6', -8.6); man.call('m6', -11.4, 0.9); wom.call('w7', -14); man.call('m7', -17, 0.7); wom.call('w8', -20); man.call('m8', -24, 0.85)
	for e in folk: e.x0 = e.x
	var king: Ent = g.npc('rey')
	margins([['m_c6_corto', 27.4, 1.7], ['m_c6_leguas', -1.2, 3.2], ['m_c6_sombra', 6.6, -1.9]])
	# st.war: los súbditos dejan el vaivén y se lanzan contra la sección del intruso (C6-06)
	var st := {t = 0.0, osc = 1.0, war = false, lo = 0.0, hi = 0.0, was_on = false, pan = 0.0, touched = false}
	var stop_line := g.tick(func(dt):
		st.t += dt
		# sección del Cuadrado sobre la Línea: lo único que de él existe para Linealandia
		var s := Geom3.line_section(g.player.world_pts())
		var on := s.y > s.x + 0.005
		st.lo = s.x; st.hi = s.y
		for e in folk:
			if st.war and on:
				# cada uno corre hacia su lado de la sección, en su única dirección
				var side := 1.0 if e.x0 > g.player.x else -1.0
				var want: float = (st.hi if side > 0.0 else st.lo) + side * (float(e.def.r) + 0.05 + absf(e.x0 - g.player.x) * 0.06)
				e.x = move_toward(e.x, want, 4.0 * dt)
				var edge: float = e.x - side * float(e.def.r)
				if (side > 0.0 and edge <= st.hi + 0.02) or (side < 0.0 and edge >= st.lo - 0.02):
					if not st.touched: st.touched = true; g.hurt(0.25, Vector2(edge, 0.0))
			elif not st.war:
				e.x = e.x0 + sin(st.t * 0.9 + e.phase * 0.4) * 0.45 * st.osc
			e.y = 0.0; e.rot = 0.0   # pase lo que pase, siguen dentro de la Línea
		sec.visible = on
		if on: sec.scale = Vector3(s.y - s.x, 1, 0.14); sec.position = Vector3((s.x + s.y) / 2.0, 0.05, 0)
		g.on_line = on
		# al salir de la Línea, la voz recupera el panorama un instante (C6-05)
		if st.was_on and not on: st.pan = 2.2
		st.was_on = on
		st.pan = maxf(0.0, st.pan - dt)
		Snd.mono_mix(1.0 - 0.5 * clampf(st.pan, 0.0, 1.0)))
	await a.intro('Capítulo VI', 'El Rey de la Línea', 'Donde un Cuadrado se siente, por una noche, infinitamente superior.', 'dream')
	await narr('Soñé. Vi una multitud de pequeñas Líneas —mujeres, pensé— y entre ellas puntos brillantes, todos moviéndose adelante y atrás sobre una misma Recta, al mismo compás. Un gorjeo confuso salía de ellos.')
	var o := await g.talk_begin('rey', 'Dirígete a la Línea más larga')
	await say('yo', 'Mujer, ¿qué significa este concurso, este extraño gorjeo, este ir y venir sobre una sola recta?')
	await say('rey', 'No soy mujer. Soy el Monarca del mundo. ¿Y tú desde dónde te entrometes en mi reino de Linealandia? No te veo. Sólo oigo una voz que no viene ni de delante ni de detrás.')
	g.ledger('1d.habitante'); g.ledger('2d.habitante')
	await say('logica', 'Estás a su costado. Para él no existe el costado: su mundo es esa Recta, y nada más. Lo que no está en ella, no está. Ni siquiera puede volverse hacia ti.')
	g.ledger('1d.no_concibe')
	var done := {}
	for n in 3:
		var opts := []
		if not done.has('a'): opts.append({t = '¿Qué es tu reino?', id = 'a'})
		if not done.has('b'): opts.append({t = '¿Cómo veis? ¿Cómo os reconocéis?', id = 'b'})
		if not done.has('c'): opts.append({t = '¿Y cómo os casáis, si no podéis cruzaros?', id = 'c'})
		var c = await choose(opts)
		done[c] = 1
		if c == 'a':
			await say('rey', 'El universo: la Línea. Se extiende sin fin hacia delante y hacia atrás. Cada súbdito tiene dos vecinos y los tendrá hasta la muerte, pues nadie puede adelantar a nadie. Los varones somos Líneas; las mujeres, Puntos.')
			await say('rey', 'Yo mido seis pulgadas y cuatrocientas cincuenta y siete milésimas. Soy el más largo. Por eso reino.')
		if c == 'b':
			await say('rey', '¿Ver? Vemos lo que hay que ver: un Punto. Delante de mí, el extremo de mi vecina; detrás, el de la otra. Nada más hay. Mira como yo, si puedes.')
			await _king_view(king)
			await say('rey', 'Nos conocemos por la voz. Cada varón tiene dos bocas, una en cada extremo: grave en una, tenor en la otra. Escucha.')
			Snd.tone(110, 1.2, 'square', 0.07); Snd.tone(165, 1.0, 'square', 0.06, 0, 0.42)
			await say('logica', 'Dos notas, y una llega algo después que la otra. Del retraso deducen la longitud del que canta. Miden con el oído lo que no pueden ver.')
			# C6-02 · medir con el oído
			await say('rey', 'Yo te reconozco a ti por la voz, aunque no te vea. Escucha a tres de mis súbditos, y dime quién es el más corto y quién el más largo.')
			ui.close_dlg()
			var ok: bool = await VoiceLength.run(self, ['m1', 'm3', 'm4'])
			g.flag('oido_rey', 1 if ok else 0)
			if ok: await say('rey', 'Justo. Tienes oído. Quizá no seas sólo una voz.')
			else: await say('rey', 'No. El más corto es el del extremo de Oriente; el más largo, el de las nueve décimas. Hasta mis niñas lo saben.')
		if c == 'c':
			await say('rey', '¿Cruzarnos? ¿Tocarnos? Qué idea tan baja. La vecindad es eterna; el matrimonio se celebra a distancia, cantando. Cada varón, dos esposas: soprano y contralto.')
			var fs := [110, 165, 330, 440]
			for i in 4: Snd.tone(fs[i], 1.8, 'square' if i < 2 else 'sine', 0.05, 0, i * 0.3)
			await say('rey', 'Cuando las tres voces casan en armonía, la unión está hecha, aunque los esposos disten mil leguas. Así nacen tres: dos niñas y un varón.')
			# C6-04 · el matrimonio por armonía (opcional)
			var w = await choose([{t = '¿Me dejáis cantar la tercera voz?', id = 'y'}, {t = '(Seguir escuchando.)', id = 'n'}])
			if w == 'y':
				await say('rey', 'Atrevido. Canto yo, canta mi soprano; tú busca dónde casan las tres. Si no casan, no hay boda.')
				ui.close_dlg()
				if await Harmony.run(self):
					g.achieve('ACH_WED'); g.flag('boda', 1)
					for xx in [2.0, 2.4, -2.0]:
						var kid: Ent = wom.call('nac%d' % int(xx * 10), xx); kid.pop = 0.0; Snd.sfx('pick')
						W.fx_add('puff', xx, 0.0, 0.6, 0.4)
						await g.wait(0.35)
					await say('rey', '¡Casan! Y ahí están: dos niñas y un varón. ¿Quién ha cantado? Esa voz no era de este mundo.')
				else:
					await say('rey', 'No casan. Ásperas como dos varones que se rozan. Otra noche será.')
			await say('asombro', 'Un mundo entero construido con sonido, porque no hay sitio para nada más. Y está *satisfecho*.')
	g.frag(13); g.learn('lineal')
	await say('yo', 'Majestad: vuestro reino no es el universo. Es una Línea dentro de un Plano. Yo estoy fuera de ella, y desde aquí os veo a todos a la vez.')
	await say('rey', 'Demuéstralo. Muévete de «izquierda a derecha», como tú dices, y que yo lo vea.')
	g.talk_end(o)
	await narr('Atravesé su mundo. Fíjate en la franja dorada: es lo único de mí que existía para ellos.')
	g.objective('Entra en la Línea: cruza la Recta al este del Rey', Vector2(5.6, 0))
	await g.until(func(): return g.on_line and absf(g.player.x - 5.6) < 2.4, func(): g.player.x = 5.6; g.player.y = 0.0)
	g.begin_scene()
	Snd.sfx('her')
	await say('rey', '¡Una Línea! ¡Ha surgido una Línea de la nada, entre mi esposa y mi vecino! ¿Eres tú, voz?')
	await say('logica', 'Ve tu sección: el tramo de ti que corta su Recta. No a ti. Si giras, tu «longitud» cambia, y para él es brujería.')
	await say('rey', 'Si de verdad eres una Línea de Líneas, obedece a tu Rey. Crece. Mengua. Hazte lo que yo te pida.')
	g.end_scene(); ui.close_dlg()
	# C6-03 · hazte tan largo como pida el Rey
	var nsec := await LineSection.run(self, [0.25, SIDE, DIAG],
		['Hazte tan corto como una de mis mujeres: casi un Punto.', 'Ahora, tan largo como el más corto de mis súbditos, el del extremo de Oriente.', 'Y ahora, lo más largo que puedas ser. Más que ninguno de ellos.'],
		['Entra apenas por un vértice: la punta dentro de la Recta y nada más.', 'Avanza en diagonal hasta el centro: así uno de tus lados queda paralelo a la Recta.', 'Avanza derecho hacia el Norte o el Sur hasta el centro: dos de tus vértices quedarán sobre la Recta.'])
	g.flag('king_sections', nsec)
	if nsec >= 3: g.achieve('ACH_KING')
	g.ledger('1d.desde_arriba')
	g.begin_scene()
	if nsec >= 2: await say('rey', '¡Brujería! Has crecido y menguado sin moverte de tu sitio, como una voz que se acerca y se aleja. Ningún súbdito mío puede hacer eso.')
	else: await say('rey', '¡Brujería, o torpeza! Creces y menguas a tontas, sin moverte de tu sitio. Ningún súbdito mío haría eso.')
	await say('logica', 'Para él has crecido y menguado sin moverte. Tú sólo has girado y te has desplazado hacia un lado que no existe. Recuérdalo.')
	g.end_scene()
	g.objective('Ahora sal de la Línea, hacia el Norte', Vector2(5.6, 6))
	await g.until(func(): return not g.on_line and g.player.y > 3, func(): g.player.y = 6.0)
	g.objective('', null)
	g.begin_scene()
	await say('rey', '¡Ha desaparecido! No se ha movido adelante ni atrás: se ha *desvanecido*. Eso no es moverse. Eso es un truco de mago.')
	g.ledger('1d.rechazo')
	await say('yo', 'No he desaparecido. Estoy al Norte de vos. Y veo a vuestros vecinos: decidme si miento.')
	var c2 = await choose([{t = 'Al Este tenéis una mujer; tras ella, un varón.', id = 'ok'}, {t = 'Al Este tenéis un varón; tras él, una mujer.', id = 'no'}, {t = 'Al Este, dos mujeres seguidas.', id = 'no2'}])
	if c2 == 'ok': await say('rey', 'Cierto. Pero eso lo sabe cualquiera con oídos. Los habrás oído cantar.')
	else: await say('rey', 'Falso. Ni siquiera eso sabes. *(Mira la lámina: al Este del Rey hay un Punto, y luego una Línea.)*')
	await say('rey', 'Si fueras un hombre de juicio escucharías a la razón. Me pides creer que hay otra Línea además de la que mis sentidos me muestran, y otro movimiento además del que hago cada día. ¿Hay algo más ridículo?')
	var d = await choose([
		{t = '¡Ser obcecado! Te crees la perfección y no ves más que un Punto. Yo soy una Línea de Líneas: un Cuadrado.', id = 'r', tag = 'Soberbia'},
		{t = 'Yo tampoco lo habría creído, Majestad. No sé cómo decíroslo mejor.', id = 'h', tag = 'Humildad'}])
	if d == 'r':
		await say('yo', 'Y aun yo, infinitamente superior a ti, soy poca cosa entre los grandes nobles de Planilandia.')
		await say('narr', 'Lo dije así, palabra por palabra. Infinitamente superior. Guarda esa frase: volverá.'); g.flag('soberbia', 1)
	else:
		await say('narr', 'Me habría gustado decir eso. Dije otra cosa: que yo era infinitamente superior a él. Guarda esa frase: volverá.'); g.her(1)
	await say('narr', 'Y, para que me oyera bien, volví a entrar en su Línea.')
	g.end_scene(); ui.close_dlg()
	g.objective('Vuelve a entrar en la Línea', Vector2(5.6, 0))
	await g.until(func(): return g.on_line, func(): g.player.x = 5.6; g.player.y = 0.0)
	g.objective('', null)
	# C6-06 · la guerra, con huida: escapar es salir hacia una dirección que para ellos no existe
	Snd.tension(1.0); Snd.sfx('herald')
	ui.note('*El Rey:* «¡A mí, mis Líneas! ¡A mí, mis Puntos! ¡Guerra al intruso!»', 4.0)
	var i := 0
	for e in folk:
		Snd.tone(110 + i * 23, 2.5, 'square', 0.02, 1.5, i * 0.05); i += 1
	st.war = true
	g.objective('¡Huye! Por donde ellos no pueden seguirte')
	var esc := {t = 0.0}
	await g.until(func():
		esc.t += g.get_process_delta_time()
		if esc.t > 6.0 and not esc.has('hint'):
			esc.hint = 1; ui.note('*Lógica:* ' + ui.T('Adelante y atrás, ellos. Tú tienes otra dirección.'), 5.0)
		return absf(g.player.y) > 2.0, func(): g.player.y = 3.0)
	g.objective('', null)
	g.flag('huida', 0 if st.touched else 1)
	g.begin_scene()
	await g.tween(1.6, func(k): W.zoom = 44 - k * 14)
	await say('rey', '¡Se ha vuelto a esfumar! ¿Dónde estás, cobarde? ¡Da la cara, adelante o atrás, como un varón!')
	await say('asombro', 'Adelante o atrás. No conciben otra salida. Y la salida estaba a medio palmo, a su costado.')
	g.frag(14)
	g.end_scene()
	Snd.sfx('bell'); Snd.tension(0.0)
	await ui.fade(true, 0.5)
	stop_line.call(); line.queue_free(); sec.queue_free()
	Snd.mono(false)
	await narr('…y me despertó la campana del desayuno.', true)
	await narr('Me reí del Rey toda la mañana. Qué criatura tan limitada, tan segura de que su Recta era todo cuanto había.', true)

# C6-01 · la vista del Rey: la línea se encoge hasta ser un punto, con el brillo de lo que tiene delante
func _king_view(king: Ent) -> void:
	g.lenses = ['top', 'eye', 'king']; g.eye_src = king
	if g.auto: g.ledger('1d.ve'); g.ledger('2d.ve'); return
	ui.close_dlg()
	g.view_lock = true; g.set_view('king'); g.hide_eye_hint = true
	ui.note('*Lo que ve el Rey: un solo punto, que brilla cuando su vecina se acerca y se apaga cuando se aleja.*', 7.0)
	await g.wait(7.2)
	g.ledger('1d.ve')
	g.eye_src = null; g.set_view('eye')
	await g.wait(2.6)
	g.ledger('2d.ve')
	await say('asombro', 'Una línea. En la celda era una cárcel. Después de ese punto es una riqueza: cerca y lejos, largo y corto, los ángulos.')
	g.set_view('top'); g.view_lock = false; g.hide_eye_hint = false
	g.eye_src = king
	ui.note(tx('Con {view} puedes volver a mirar como el Rey.', 'Con el botón del ojo puedes volver a mirar como el Rey.'), 5.0)

# ============ CAP. VII — EL FORASTERO ============
func emerge(e: Ent, to: float, sec := 2.4) -> void:
	var s0 := e.sc; e.hid = false
	await g.tween(sec, func(t): e.sc = maxf(0.001, lerpf(s0, to, App.ease(t))))
	e.hid = to < 0.02

func ch7() -> void:
	g.set_map(town()); var W := g.world; W.rain = 1.0; g.spawn_player(-30, 11, PI)
	var wife := g.add(F_mujer('esposa', -25.5, 12.5, {name = 'tu esposa', rot = 2.6}))
	var kid := g.add(F_hexa('nieto', -34.5, 10.5, {name = 'tu nieto menor', r = 0.6, rot = 0.0}))
	margins([['m_c7_reloj', -30.8, 16.6], ['m_c7_puerta', -26.4, 19.4]])
	await a.intro('Capítulo VII', 'El Forastero', 'Última noche del año 1999. Donde alguien entra sin usar ninguna puerta.', 'home')
	await narr('El último día del milenio. El repiqueteo de la lluvia anunciaba la noche. Mis hijos se habían retirado; quedaba el pequeño, esperando su lección.')
	var o := await g.talk_begin('nieto', 'Dale a tu nieto su lección de Geometría')
	Snd.motif('nieto')
	await say('nieto', '¡Abuelo! Hoy tocan los cuadrados de los números.')
	await say('yo', 'Un Punto que se mueve tres pulgadas traza una Línea de tres. La Línea, moviéndose paralela a sí misma, traza un Cuadrado de tres por tres. Dibújalo conmigo.')
	ui.close_dlg()
	await _draw_square()   # C7-01
	await say('yo', 'Nueve pulgadas cuadradas: tres al cuadrado.')
	await say('nieto', 'También me has enseñado a elevar números a la *tercera* potencia. Entonces 3³ tiene que significar algo en Geometría. ¿Qué significa?')
	ui.close_dlg()
	await _draw_cube_attempt()   # C7-01: el primer «no puedes»
	var c = await choose([{t = 'Nada en absoluto. La Geometría sólo tiene Dos Dimensiones.', id = 'o'}, {t = 'No lo sé. Nunca me lo había preguntado.', id = 'h', tag = 'Herejía'}])
	if c == 'h': await say('narr', 'Eso habría sido lo honrado. Dije: «Nada en absoluto; la Geometría sólo tiene Dos Dimensiones».'); g.her(1)
	await say('nieto', 'Pero mira: si el Punto hace la Línea, y la Línea hace el Cuadrado… entonces el Cuadrado, moviéndose *de algún modo* paralelo a sí mismo, que no veo cómo, hará *algo*, que no veo qué, de tres pulgadas en todos los sentidos. Y eso será 3³.')
	await say('asombro', 'Lo ha dicho. Con seis lados y diez años. Algo en ti ha oído un crujido.')
	await say('yo', 'Vete a la cama.')
	slate_off()
	g.talk_end(o)
	kid.move_to(-33.6, 8.6, 2.2)
	margins([['m_c7_pisos', -35.2, 9.4]])
	await g.go_to(-27.6, 12, 1.2, 'Siéntate en el salón, junto a tu esposa')
	g.begin_scene()
	g.player.rot = -PI / 2
	await say('narr', 'El reloj de arena dejaba caer los últimos granos del año, del siglo, del milenio. Yo rumiaba la impertinencia del crío.')
	await say('yo', 'El chico es tonto.')
	Snd.sfx('sphere'); Snd.motif('esfera')
	await say('esfera', 'El chico no es tonto. Y 3³ tiene un significado geométrico evidente.')
	var sph := g.add(F_circ('esfera', -28, 9.3, {name = 'el Forastero', r = 1.7, tint = Color('9fe8e0'), noGuts = true})); sph.sc = 0.001
	W.focus = Vector2(-28, 12); W.zoom = 36
	await emerge(sph, 0.55, 2.6)
	await say('narr', 'Había una Figura en el salón. No había entrado por ninguna puerta. Primero fue un punto; luego una raya que crecía.')
	await say('esposa', '¡Esposo! ¿Cómo ha entrado esta persona? Me prometiste que no habría ventiladores en la casa nueva.')
	await say('yo', 'Parece una Mujer vista de lado… pero su brillo cambia. Pálpala tú, querida; a mí no me corresponde.')
	await wife.move_to(-26.6, 9, 1.5)
	await say('esposa', '¡Oh! No hay ángulo. No hay ni rastro de ángulo. ¡Es un Círculo perfecto! Perdone Vuestra Reverencia la torpeza de una pobre mujer.')
	wife.move_to(-21.5, 10, 2.4)
	await emerge(sph, 1, 2)
	g.frag(15)
	# --- las palabras ---
	await say('esfera', 'No soy un Círculo. Vengo del Espacio: de la tierra de las Tres Dimensiones. Tú conoces el Largo y el Ancho. Yo te traigo la Altura.')
	g.ledger('3d.habitante')
	c = await choose([{t = '¿Altura? Señaladme hacia dónde cae.', id = 'a'}, {t = 'El Espacio es esto, señor: Norte, Sur, Este y Oeste.', id = 'b'}])
	await say('esfera', 'No puedo señalarla dentro de tu Plano. Es una dirección que corta en ángulo recto al Norte-Sur *y* al Este-Oeste a la vez. Hacia Arriba, no hacia el Norte.' if c == 'a' else 'Eso que llamas Espacio es un Plano. Hay otra dirección, perpendicular a todas las tuyas a la vez. Hacia Arriba, no hacia el Norte.')
	await say('logica', 'Perpendicular a Norte y a Este a la vez. Tal dirección no existe. La frase es gramatical y no significa nada.')
	g.ledger('2d.no_concibe')
	await say('esfera', 'Me llamas Círculo. Soy muchos Círculos en uno: infinitos, de todos los tamaños, apilados. Lo que ves es sólo la rebanada de mí que corta tu mundo.')
	# C7-02 · predice la sección de la Esfera
	await say('esfera', 'Ya que eres matemático: si me elevo un poco, ¿qué tamaño tendré para ti? Piénsalo antes de verlo.')
	ui.close_dlg()
	var hits := await SpherePredict.run(self, sph, [0.5, 0.9])
	g.flag('sphere_pred', hits)
	if hits >= 2: g.achieve('ACH_SPHERE')
	g.ledger('2d.desde_arriba')
	if int(g.flag('king_sections') if g.flag('king_sections') != null else 0) >= 2:
		await say('asombro', 'Esto ya lo has hecho tú. Del otro lado: crecer y menguar ante el Rey sin moverte de tu sitio.')
	await say('esfera', 'Y ahora, mira lo que ocurre si me elevo del todo.')
	Snd.tone(330, 2.5, 'sine', 0.08, 2)
	await emerge(sph, 0.001, 2.0); await g.wait(0.8)
	await say('yo', '¡Ha menguado hasta un punto y… se ha ido!')
	sph.x = -26.6; sph.y = 9.6; Snd.sfx('sphere'); Snd.motif('esfera', '', true); await emerge(sph, 1, 2.4)
	await _turn_to(sph)   # C7-06
	c = await choose([{t = 'Un truco de prestidigitador. Como desvanecerse en una Línea.', id = 'a', lock = null if g.knows('lineal') else 'requiere haber soñado con la Línea'}, {t = 'No habéis ido a ninguna parte. Os habéis encogido.', id = 'b'}])
	if c == 'a': await say('asombro', '«Eso no es moverse, es un truco de mago.» ¿Dónde has oído tú esa frase, hace nada? ¿Quién la decía?'); g.her(1)
	await say('esfera', 'Probemos con la Analogía, ya que eres matemático. Rellena tú la tabla.')
	ui.close_dlg()
	await _analogy_table()   # C7-03
	slate_off(); g.learn('analogia'); g.frag(16)
	g.ledger('1d.limites'); g.ledger('2d.limites'); g.ledger('3d.limites')
	await say('logica', 'La aritmética es impecable. Y no describe nada que pueda existir. ¿Qué haces con un razonamiento correcto sobre una cosa imposible?')
	c = await choose([{t = '¡Monstruo! Brujo, sueño o demonio: no soportaré más tus burlas.', id = 'a', tag = 'Embestir'}, {t = 'Seguid. Os lo ruego: seguid hablando.', id = 'h', tag = 'Escuchar'}])
	if c == 'h': await say('narr', 'Ojalá hubiera dicho eso. Me acuerdo de mis ángulos temblando, de la certeza de que se reían de mí en mi propia casa. Embestí.'); g.her(1)
	W.focus = null; W.zoom = W.base_zoom
	g.end_scene()
	Snd.tension(0.75)
	g.objective('Embiste al Forastero con tu ángulo más duro', 'esfera'); W.mark('esfera'); sph.no_collide = true
	await g.until(func(): return Vector2(g.player.x - sph.x, g.player.y - sph.y).length() < 2.1, func(): pass)
	W.unmark('esfera'); g.objective('', null); Snd.sfx('bad'); Snd.tension(0.45)
	g.begin_scene()
	await emerge(sph, 0.001, 0.5); sph.x = -28.4; sph.y = 16.6; await g.wait(0.6); await emerge(sph, 1, 1.2)
	await _turn_to(sph)   # C7-06
	await say('esfera', '¿Por qué te niegas a oír razones? Esperaba hallar en ti, hombre de juicio y matemático, un apóstol del Evangelio de las Tres Dimensiones. Sólo se me permite predicarlo una vez cada mil años.')
	await say('esfera', 'Si las palabras no bastan, hechos. Desde donde estoy veo tu alacena, ahí arriba, en el estudio. Cerrada con llave. Dentro: dos cofres de dinero y dos tablillas de cuentas. Voy a bajar a ella y traerte una.')
	await say('logica', 'Entre él y la alacena hay una pared. Y la alacena está cerrada por sus cuatro lados. Por *todos* sus lados.')
	await emerge(sph, 0.001, 1.6); await g.wait(1.2); Snd.sfx('pick')
	W.add_spot({id = 'tab', x = -30.2, y = 8.6, label = 'una tablilla'})
	sph.x = -26.8; sph.y = 10; await emerge(sph, 0.8, 1.4)
	await say('esfera', 'Ahí la tienes, en el suelo. Ve luego a tu alacena, si quieres: falta una.')
	await say('yo', '…Es mi tablilla. La de las cuentas del mes.')
	g.end_scene(); ui.close_dlg()
	await _cupboard()   # C7-04
	g.begin_scene()
	await say('esfera', 'Y ahora, desde aquí arriba, veo algo más: tu interior. Tus entrañas, abiertas como una casa sin tejado. Voy a tocarte el estómago. No te alarmes.')
	await _touch()   # C7-05
	await say('yo', '¡Ah! Un dolor… *dentro*. Nada me ha tocado el perímetro. Me ha tocado por dentro.')
	await say('asombro', 'Por un instante tú también lo has visto: lo que hay dentro de ti, desde un sitio que no es ningún sitio.')
	Snd.tension(0.8)
	c = await choose([{t = '(Lanzarte otra vez sobre él, gritando.)', id = 'a'}, {t = '(Quedarte inmóvil.) ¿Qué sois?', id = 'h'}])
	if c == 'h': await say('narr', 'No me quedé inmóvil. Grité como un Isósceles y cargué.')
	Snd.sfx('peace')
	await say('esposa', '(Desde sus aposentos.) ¿Esposo? ¿Qué son esas voces? ¡Paz, paz! Voy para allá.')
	await say('esfera', 'O esto termina aquí, o vienes conmigo adonde no hacen falta palabras. ¡Fuera de tu Plano! Una… dos… tres. ¡Hecho!')
	g.frag(17)
	ui.close_dlg(); Snd.sfx('rise'); Snd.drone('none'); Snd.tension(0.0)
	g.tween(1.8, func(t): W.zoom = W.base_zoom - t * 40; g.player.rot += 0.2)
	await ui.fade(true, 1.7)
	g.end_scene()

# C7-06 · la cámara no sigue sola a la Esfera: el jugador se vuelve hacia la voz
func _turn_to(sph: Ent) -> void:
	if g.auto: return
	g.end_scene(); ui.close_dlg()
	g.objective('Gírate hacia la voz', 'esfera')
	await g.until(func(): return g.eye.sees('esfera'), func(): g.player.face(sph.x, sph.y))
	g.objective('', null)
	g.begin_scene()

# C7-01 · la lección de 3²: el jugador traza el Cuadrado de 3×3 sobre una rejilla de 4×4 puntos
const SQ_U := 70.0
const SQ_X0 := 215.0
const SQ_Y0 := 320.0

func _grid_anchors() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for j in 4:
		for i in 4: pts.append(Vector2(SQ_X0 + i * SQ_U, SQ_Y0 - j * SQ_U))
	return pts

# las 24 aristas unidad de la rejilla que cubren los trazos (uno largo cubre varias)
static func _covered(segs: Array) -> Dictionary:
	var cov := {}
	for s in segs:
		var ai: int = s.x % 4; var aj: int = floori(s.x / 4.0); var bi: int = s.y % 4; var bj: int = floori(s.y / 4.0)
		if aj == bj:
			for i in range(mini(ai, bi), maxi(ai, bi)): cov['h%d_%d' % [i, aj]] = 1
		elif ai == bi:
			for j in range(mini(aj, bj), maxi(aj, bj)): cov['v%d_%d' % [ai, j]] = 1
	return cov

func _draw_square() -> void:
	var anim := func(c: SlateBoard, t: float):
		var u := SQ_U; var x0 := SQ_X0; var y0 := SQ_Y0; var pa := minf(1.0, t / 0.3); var pb := clampf((t - 0.35) / 0.45, 0.0, 1.0)
		c.dot(x0, y0)
		c.line(x0, y0, x0 + 3 * u * pa, y0)
		if pb > 0:
			for i in 4: c.line(x0 + i * u, y0, x0 + i * u, y0 - 3 * u * pb, 0.5)
			for j in range(1, 4):
				if pb >= j / 3.0 - 0.01: c.line(x0, y0 - j * u, x0 + 3 * u, y0 - j * u, 0.5)
			c.line(x0, y0 - 3 * u * pb, x0 + 3 * u, y0 - 3 * u * pb)
		c.text('Un Punto que se mueve 3 pulgadas traza una Línea: 3' if t < 0.33 else ('La Línea, moviéndose paralela a sí misma…' if t < 0.82 else '…traza un Cuadrado de 3 por 3:  3² = 9'), 110, 380)
	if g.auto or g.bot:
		await slate_anim('tablilla de lecciones', 5, anim); return
	var b := ui.draw_board(true, 'tablilla de lecciones')
	b.reset(_grid_anchors())
	var st := {t = 0.0, n = 0}
	var help := ui.T(tx('Traza líneas de tiza: mantén {act} (o el ratón) sobre un punto y suéltalo sobre otro. {view} deshace.', 'Arrastra el dedo de un punto a otro para trazar una línea.', 'Mueve el cursor con el stick; mantén {act} sobre un punto y suéltalo sobre otro. {view} deshace.'))
	b.hint = func(bd: SlateBoard):
		bd.text(help, 30, 34, 15)
		bd.text(ui.T('Traza el Cuadrado de 3 por 3, con sus nueve casillas') if st.n < 24 else '3² = 9', 110, 380)
	await g.tick_until(func(dt) -> bool:
		st.t += dt; st.n = _covered(b.segs).size()
		return st.n >= 24 or st.t > 90.0)
	if st.n >= 24:
		Snd.sfx('good'); await g.wait(1.4)
		ui.slate(true, 'tablilla de lecciones'); ui.slate_board.paint(anim, 1.0)
	else:
		await slate_anim('tablilla de lecciones', 3, anim)

# C7-01 · 3³: todo trazo cae en el mismo plano y la pizarra lo rechaza
func _draw_cube_attempt() -> void:
	if g.auto or g.bot: return
	var b := ui.draw_board(true, 'tablilla de lecciones')
	b.reset(_grid_anchors(), 'reject')
	for i in 4:
		for j in 4:
			if i < 3: b.segs.append(Vector2i(j * 4 + i, j * 4 + i + 1))
			if j < 3: b.segs.append(Vector2i(j * 4 + i, (j + 1) * 4 + i))
	b.hint = func(bd: SlateBoard):
		bd.text(ui.T('Intenta dibujar lo que haría el Cuadrado al moverse «de algún modo» paralelo a sí mismo.'), 30, 34, 15)
		bd.text(ui.T('3³ = ?   Mueve el Cuadrado paralelo a sí mismo… ¿hacia dónde?'), 110, 380)
	var st := {t = 0.0, n = 0}
	var on_rej := func(): st.n += 1
	b.rejected.connect(on_rej)
	await g.tick_until(func(dt) -> bool:
		st.t += dt
		return st.n >= 2 or st.t > 25.0 or (st.n >= 1 and st.t > 12.0))
	b.rejected.disconnect(on_rej)
	await g.wait(0.8)
	await say('asombro', 'Cada trazo cae en la misma tablilla. No hay otro sitio donde ponerlo.' if st.n > 0 else 'No sabes ni por dónde empezar. Ningún trazo serviría: caería en la misma tablilla.')
	ui.slate(true, 'tablilla de lecciones')

# C7-03 · la Analogía, construida: el jugador escribe los números de la tabla
func _analogy_table() -> void:
	# [columna, fila] → valor; las dos primeras columnas se dan hechas
	var val := {'2,0': 4, '3,0': 8, '2,1': 4, '3,1': 6}
	var st := {got = {}, cur = '', lit = false}
	var draw := func(cx: SlateBoard, _t: float):
		var y := 140.0
		cx.dot(240, y); cx.text(ui.T('Punto'), 212, y + 70)
		cx.line(300, y, 380, y); cx.dot(300, y); cx.dot(380, y); cx.text(ui.T('Línea'), 312, y + 70)
		cx.box(430, y - 40, 80, 80)
		for q in [[430, y - 40], [510, y - 40], [430, y + 40], [510, y + 40]]: cx.dot(q[0], q[1])
		cx.text(ui.T('Cuadrado'), 425, y + 85)
		if st.lit: cx.text(ui.T('Cubo'), 560, y + 85)
		else: cx.text('?', 575, y + 24, 70)
		cx.text(ui.T('puntos terminales:'), 20, 300, 19); cx.text(ui.T('lados:'), 20, 350, 19)
		var xs := [240, 340, 470, 590]
		var given := {'0,0': '1', '1,0': '2', '0,1': '0', '1,1': '2'}
		for col in 4:
			for row in 2:
				var k := '%d,%d' % [col, row]
				var yy := 300 + row * 50
				if given.has(k): cx.text(given[k], xs[col] - 6, yy)
				elif st.got.has(k):
					if col == 3: cx.draw_string(cx.font, Vector2(xs[col] - 6, yy) * cx.k, str(st.got[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * cx.k), App.ACC)
					else: cx.text(str(st.got[k]), xs[col] - 6, yy)
				if k == st.cur: cx.draw_rect(Rect2(Vector2(xs[col] - 22, yy - 30) * cx.k, Vector2(48, 40) * cx.k), App.ACC, false, maxf(1.0, 2.0 * cx.k))
	var b := ui.slate(true, 'el argumento de la Analogía')
	var redraw := func(): b.paint(draw, 1.0)
	var chips := [2, 3, 4, 5, 6, 8, 12, 16].map(func(n): return {id = n, label = str(n), sub = ''})
	for i in chips.size(): chips[i].sub = str(i + 1)
	var lines := {
		'2,0': ['Un Punto que se mueve engendra una Línea, con dos puntos terminales. ¿Y una Línea que se mueve, paralela a sí misma? ¿Cuántos tiene lo que engendra?', 'Cuatro: el Cuadrado. Tú mismo.'],
		'3,0': ['Uno, dos, cuatro. ¿Qué número sigue? Lo que engendra el Cuadrado al moverse en la dirección nueva.', 'Ocho. Exacto: progresión geométrica. El Cuadrado, movido en la dirección nueva, engendra Algo con ocho puntos terminales. Lo llamamos Cubo.'],
		'2,1': ['Y los lados. El Punto tiene cero. La Línea, dos: sus dos extremos. ¿Y el Cuadrado?', 'Cuatro lados. Cero, dos, cuatro.'],
		'3,1': ['Cero, dos, cuatro. ¿Qué sigue?', 'Seis. Progresión aritmética. El Cubo está limitado por seis lados, y cada uno es un Cuadrado como tú.'],
	}
	for k in ['2,0', '3,0', '2,1', '3,1']:
		st.cur = k; redraw.call()
		await say('esfera', lines[k][0])
		if g.auto:
			st.got[k] = val[k]
		else:
			var tries := 0
			while true:
				var ans = await ui.panel('La Analogía', 'Elige el número de la casilla marcada.', chips)
				if g.bot: ans = val[k]
				if ans == val[k]: break
				tries += 1; Snd.sfx('chalk_break')
				if tries >= 2: ui.note(ui.T('*La Esfera:* «%s»') % ui.T('No. Mira cómo crece la fila.'), 3.0); ans = val[k]; break
				ui.note(ui.T('*Lógica:* %s') % ui.T('Mira la fila: ¿cuánto cambia de una casilla a la siguiente?'), 4.0)
			st.got[k] = val[k]; Snd.sfx('chalk')
		if k == '3,1': st.lit = true; Snd.sfx('good')
		st.cur = ''; redraw.call()
		await say('esfera', lines[k][1])

# C7-04 · la alacena: compruébalo tú
func _cupboard() -> void:
	var W := g.world
	await g.go_to(-23.3, 20.4, 1.2, 'Comprueba tu alacena')
	g.begin_scene()
	await _hold('La llave', tx('Mantén pulsado {act} para girar la llave.', 'Mantén pulsado el botón de acción para girar la llave.'), 'Girar', 0.8)
	Snd.sfx('lock')
	var c := Vector2(-22.3, 21.8)
	g.add({id = 'cofre1', n = 4, r = 0.3, rot = 0.785, x = c.x - 0.5, y = c.y - 0.35, name = 'un cofre', noCollide = true, noGuts = true})
	g.add({id = 'cofre2', n = 4, r = 0.3, rot = 0.785, x = c.x + 0.5, y = c.y - 0.35, name = 'un cofre', noCollide = true, noGuts = true})
	g.add({id = 'tab1', pts = [[0.32, 0.12], [-0.32, 0.12], [-0.32, -0.12], [0.32, -0.12]], x = c.x - 0.45, y = c.y + 0.4, name = 'una tablilla', noCollide = true, noGuts = true, noEye = true})
	W.focus = c; W.zoom = 14
	await say('narr', 'Dos cofres. Y una sola tablilla.')
	if g.flag('alacena_vista') != null: await say('asombro', 'La otra noche contaste dos. Desde ahí arriba, como él.')
	Snd.sfx('chalk_break')
	await say('logica', '…')
	W.focus = null; W.zoom = W.base_zoom
	g.end_scene(); ui.close_dlg()
	await g.go_to(-27.4, 11.2, 1.6, 'Vuelve al salón, con el Forastero')

# C7-05 · el toque, con vista de entrañas: un punto de luz dentro del cuerpo, sin cruzar el perímetro
func _touch() -> void:
	var W := g.world; var p := g.player
	ui.close_dlg()
	Snd.sfx('stab'); App.rumble(0.3, 0.6, 0.4)
	p.guts.visible = true; W.focus = Vector2(p.x, p.y); W.zoom = 14
	for i in 6:
		W.fx_add('spark', p.x + 0.12 * cos(i * 1.7), p.y + 0.12 * sin(i * 1.7), 0.5, 0.3, Color('9fe8e0'))
		await g.wait(0.5)
	p.guts.visible = false; W.focus = null; W.zoom = W.base_zoom

# --try=kingview|section|ear|harmony|square|cube|sphere|table|cupboard: piezas sueltas del VI y el VII
func try_mini(name: String) -> void:
	ui.hud.visible = true; ui.chapter_tag('Prueba · ' + name)
	if name in ['kingview', 'section', 'ear', 'harmony']:
		g.set_map({bounds = {x0 = -52, y0 = -18, x1 = 52, y1 = 18}, fog = 22.0, palette = 'dream', zoom = 44.0})
		var W := g.world; g.spawn_player(5.6, -3, PI / 2); Snd.mono(true)
		var line := W.fx_quad(W.pal.edge, 0.55); line.scale = Vector3(110, 1, 0.035); line.position.y = 0.006
		var sec := W.fx_quad(W.pal.acc, 1.0); sec.position.y = 0.05
		var folk := []
		for f in [['rey', 0, 1.6], ['w1', 3, 0.07], ['m1', 8.6, 0.9], ['w2', 11, 0.07], ['m3', 19, 0.78], ['m4', 26, 0.55]]:
			var e := g.add({id = f[0], woman = true, sway = 0.0, r = f[2], voice = 'rey', x = f[1], y = 0, rot = 0.0, fixedRot = true}); e.x0 = e.x; folk.append(e)
		var st := {t = 0.0}
		g.tick(func(dt):
			st.t += dt
			for e in folk: e.x = e.x0 + sin(st.t * 0.9 + e.phase * 0.4) * 0.45; e.y = 0.0; e.rot = 0.0
			var s := Geom3.line_section(g.player.world_pts())
			sec.visible = s.y > s.x
			if sec.visible: sec.scale = Vector3(s.y - s.x, 1, 0.14); sec.position = Vector3((s.x + s.y) / 2.0, 0.05, 0)
			g.on_line = sec.visible)
		g.begin_scene()
		match name:
			'kingview': await _king_view(g.npc('rey')); await g.wait(1.0)
			'ear': print('oído ', await VoiceLength.run(self, ['m1', 'm3', 'm4']))
			'harmony': print('armonía ', await Harmony.run(self))
			'section':
				g.end_scene(); g.teleport(5.6, -1.2, PI / 2)
				print('secciones ', await LineSection.run(self, [0.25, SIDE, DIAG], ['Casi un Punto.', 'Un lado.', 'Lo más largo.'], ['vértice', 'diagonal', 'recto']))
		Snd.mono(false)
		return
	g.set_map(town()); var W := g.world; g.spawn_player(-30, 11, PI)
	match name:
		'square': g.begin_scene(); await _draw_square(); await g.wait(1.0)
		'cube': g.begin_scene(); await _draw_cube_attempt()
		'table': g.begin_scene(); await _analogy_table(); await g.wait(1.0)
		'sphere':
			g.teleport(-27.6, 12, -PI / 2); g.begin_scene()
			var sph := g.add(F_circ('esfera', -28, 9.3, {name = 'el Forastero', r = 1.7, tint = Color('9fe8e0'), noGuts = true}))
			W.focus = Vector2(-28, 11); W.zoom = 30
			print('esfera ', await SpherePredict.run(self, sph, [0.5, 0.9]))
		'cupboard': await _cupboard()
