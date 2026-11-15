# Capítulos VI–VII: la visión de Linealandia y el Forastero de Espaciolandia.
class_name ChC extends Ch

# ============ CAP. VI — LINEALANDIA ============
func ch6() -> void:
	g.set_map({bounds = {x0 = -52, y0 = -18, x1 = 52, y1 = 18}, fog = 22.0, palette = 'dream', zoom = 44.0,
		labels = [{t = 'Linealandia', x = 0, y = -12.5, s = 1.5, a = 0.3}, {t = 'un sueño · penúltima noche del año 1999', x = 0, y = -14.6, s = 0.65, a = 0.4, it = true}]})
	var W := g.world; g.spawn_player(3, -7, PI / 2)
	var line := W.fx_quad(W.pal.edge, 0.55); line.scale = Vector3(110, 1, 0.035); line.position.y = 0.006
	var sec := W.fx_quad(W.pal.acc, 1.0); sec.position.y = 0.05; sec.visible = false
	var folk := []
	# Los habitantes de la Línea no pueden salir de ella: ni siquiera girar (fixedRot).
	var man := func(id: String, x: float, r: float, name := 'un súbdito'):
		folk.append(g.add({id = id, woman = true, sway = 0.0, r = r, voice = 'rey', x = x, y = 0, name = name, rot = 0.0, fixedRot = true}))
	var wom := func(id: String, x: float):
		folk.append(g.add({id = id, woman = true, sway = 0.0, r = 0.07, voice = 'mujer', x = x, y = 0, name = 'una súbdita (un Punto)', rot = 0.0, fixedRot = true}))
	man.call('rey', 0, 1.6, 'la Línea más larga')
	wom.call('w1', 3); man.call('m1', 8.6, 0.9); wom.call('w2', 11); man.call('m2', 13.6, 0.7); wom.call('w3', 16); man.call('m3', 19, 0.8); wom.call('w4', 22); man.call('m4', 26, 0.6)
	wom.call('w5', -3); man.call('m5', -6.2, 0.8); wom.call('w6', -8.6); man.call('m6', -11.4, 0.9); wom.call('w7', -14); man.call('m7', -17, 0.7); wom.call('w8', -20); man.call('m8', -24, 0.85)
	for e in folk: e.x0 = e.x
	var st := {t = 0.0, osc = 1.0}
	var stop_line := g.tick(func(dt):
		st.t += dt
		for e in folk:
			e.x = e.x0 + sin(st.t * 0.9) * 0.45 * st.osc
			e.y = 0.0; e.rot = 0.0   # pase lo que pase, siguen dentro de la Línea
		# sección del Cuadrado sobre la Línea: lo único que de él existe para Linealandia
		var p := g.player.world_pts(); var lo := 1e9; var hi := -1e9
		for i in 4:
			var pa: Vector2 = p[i]; var pb: Vector2 = p[(i + 1) % 4]
			if (pa.y > 0) != (pb.y > 0):
				var x := pa.x + (pb.x - pa.x) * (-pa.y / (pb.y - pa.y))
				lo = minf(lo, x); hi = maxf(hi, x)
		sec.visible = hi > lo
		if sec.visible: sec.scale = Vector3(hi - lo, 1, 0.14); sec.position = Vector3((lo + hi) / 2.0, 0.05, 0)
		g.on_line = hi > lo)
	await a.intro('Capítulo VI', 'El Rey de la Línea', 'Donde un Cuadrado se siente, por una noche, infinitamente superior.', 'dream')
	await narr('Soñé. Vi una multitud de pequeñas Líneas —mujeres, pensé— y entre ellas puntos brillantes, todos moviéndose adelante y atrás sobre una misma Recta, al mismo compás. Un gorjeo confuso salía de ellos.')
	var o := await g.talk_begin('rey', 'Dirígete a la Línea más larga')
	await say('yo', 'Mujer, ¿qué significa este concurso, este extraño gorjeo, este ir y venir sobre una sola recta?')
	await say('rey', 'No soy mujer. Soy el Monarca del mundo. ¿Y tú desde dónde te entrometes en mi reino de Linealandia? No te veo. Sólo oigo una voz que no viene ni de delante ni de detrás.')
	await say('logica', 'Estás a su costado. Para él no existe el costado: su mundo es esa Recta, y nada más. Lo que no está en ella, no está. Ni siquiera puede volverse hacia ti.')
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
			await say('rey', '¿Ver? Vemos lo que hay que ver: un Punto. Delante de mí, el extremo de mi vecina; detrás, el de la otra. Nada más hay.')
			await say('rey', 'Nos conocemos por la voz. Cada varón tiene dos bocas, una en cada extremo: grave en una, tenor en la otra. Escucha.')
			Snd.tone(110, 1.2, 'square', 0.07); Snd.tone(165, 1.0, 'square', 0.06, 0, 0.42)
			await say('logica', 'Dos notas, y una llega algo después que la otra. Del retraso deducen la longitud del que canta. Miden con el oído lo que no pueden ver.')
		if c == 'c':
			await say('rey', '¿Cruzarnos? ¿Tocarnos? Qué idea tan baja. La vecindad es eterna; el matrimonio se celebra a distancia, cantando. Cada varón, dos esposas: soprano y contralto.')
			var fs := [110, 165, 330, 440]
			for i in 4: Snd.tone(fs[i], 1.8, 'square' if i < 2 else 'sine', 0.05, 0, i * 0.3)
			await say('rey', 'Cuando las tres voces casan en armonía, la unión está hecha, aunque los esposos disten mil leguas. Así nacen tres: dos niñas y un varón.')
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
	g.end_scene()
	g.objective('Ahora sal de la Línea, hacia el Norte', Vector2(5.6, 6))
	await g.until(func(): return not g.on_line and g.player.y > 3, func(): g.player.y = 6.0)
	g.objective('', null)
	g.begin_scene()
	await say('rey', '¡Ha desaparecido! No se ha movido adelante ni atrás: se ha *desvanecido*. Eso no es moverse. Eso es un truco de mago.')
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
	await say('rey', '¡A mí, mis Líneas! ¡A mí, mis Puntos! ¡Guerra al intruso!')
	ui.close_dlg(); st.osc = 0.0; Snd.sfx('herald')
	var i := 0
	for e in folk:
		e.x0 = e.x0 + (g.player.x - e.x0) * 0.6; Snd.tone(110 + i * 23, 2.5, 'square', 0.02, 1.5, i * 0.05); i += 1
	await g.tween(2.2, func(k): st.osc = k * 3.0; W.zoom = 44 - k * 14)
	g.frag(14)
	g.end_scene()
	Snd.sfx('bell')
	await ui.fade(true, 0.5)
	stop_line.call(); line.queue_free(); sec.queue_free()
	await narr('…y me despertó la campana del desayuno.', true)
	await narr('Me reí del Rey toda la mañana. Qué criatura tan limitada, tan segura de que su Recta era todo cuanto había.', true)

# ============ CAP. VII — EL FORASTERO ============
func emerge(e: Ent, to: float, sec := 2.4) -> void:
	var s0 := e.sc; e.hid = false
	await g.tween(sec, func(t): e.sc = maxf(0.001, lerpf(s0, to, App.ease(t))))
	e.hid = to < 0.02

func ch7() -> void:
	g.set_map(town()); var W := g.world; W.rain = 1.0; g.spawn_player(-30, 11, PI)
	var wife := g.add(F_mujer('esposa', -25.5, 12.5, {name = 'tu esposa', rot = 2.6}))
	var kid := g.add(F_hexa('nieto', -34.5, 10.5, {name = 'tu nieto menor', r = 0.6, rot = 0.0}))
	await a.intro('Capítulo VII', 'El Forastero', 'Última noche del año 1999. Donde alguien entra sin usar ninguna puerta.', 'home')
	await narr('El último día del milenio. El repiqueteo de la lluvia anunciaba la noche. Mis hijos se habían retirado; quedaba el pequeño, esperando su lección.')
	var o := await g.talk_begin('nieto', 'Dale a tu nieto su lección de Geometría')
	await say('nieto', '¡Abuelo! Hoy tocan los cuadrados de los números.')
	await slate_anim('tablilla de lecciones', 5, func(c: SlateBoard, t: float):
		var u := 70.0; var x0 := 215.0; var y0 := 320.0; var pa := minf(1.0, t / 0.3); var pb := clampf((t - 0.35) / 0.45, 0.0, 1.0)
		c.dot(x0, y0)
		c.line(x0, y0, x0 + 3 * u * pa, y0)
		if pb > 0:
			for i in 4: c.line(x0 + i * u, y0, x0 + i * u, y0 - 3 * u * pb, 0.5)
			for j in range(1, 4):
				if pb >= j / 3.0 - 0.01: c.line(x0, y0 - j * u, x0 + 3 * u, y0 - j * u, 0.5)
			c.line(x0, y0 - 3 * u * pb, x0 + 3 * u, y0 - 3 * u * pb)
		c.text('Un Punto que se mueve 3 pulgadas traza una Línea: 3' if t < 0.33 else ('La Línea, moviéndose paralela a sí misma…' if t < 0.82 else '…traza un Cuadrado de 3 por 3:  3² = 9'), 110, 380))
	await say('yo', 'Un Punto que se mueve tres pulgadas traza una Línea de tres. La Línea, moviéndose paralela a sí misma, traza un Cuadrado de tres por tres. Nueve pulgadas cuadradas: tres al cuadrado.')
	await say('nieto', 'También me has enseñado a elevar números a la *tercera* potencia. Entonces 3³ tiene que significar algo en Geometría. ¿Qué significa?')
	var c = await choose([{t = 'Nada en absoluto. La Geometría sólo tiene Dos Dimensiones.', id = 'o'}, {t = 'No lo sé. Nunca me lo había preguntado.', id = 'h', tag = 'Herejía'}])
	if c == 'h': await say('narr', 'Eso habría sido lo honrado. Dije: «Nada en absoluto; la Geometría sólo tiene Dos Dimensiones».'); g.her(1)
	await say('nieto', 'Pero mira: si el Punto hace la Línea, y la Línea hace el Cuadrado… entonces el Cuadrado, moviéndose *de algún modo* paralelo a sí mismo, que no veo cómo, hará *algo*, que no veo qué, de tres pulgadas en todos los sentidos. Y eso será 3³.')
	await say('asombro', 'Lo ha dicho. Con seis lados y diez años. Algo en ti ha oído un crujido.')
	await say('yo', 'Vete a la cama.')
	slate_off()
	g.talk_end(o)
	kid.move_to(-33.6, 8.6, 2.2)
	await g.go_to(-27.6, 12, 1.2, 'Siéntate en el salón, junto a tu esposa')
	g.begin_scene()
	g.player.rot = -PI / 2
	await say('narr', 'El reloj de arena dejaba caer los últimos granos del año, del siglo, del milenio. Yo rumiaba la impertinencia del crío.')
	await say('yo', 'El chico es tonto.')
	Snd.sfx('sphere')
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
	c = await choose([{t = '¿Altura? Señaladme hacia dónde cae.', id = 'a'}, {t = 'El Espacio es esto, señor: Norte, Sur, Este y Oeste.', id = 'b'}])
	await say('esfera', 'No puedo señalarla dentro de tu Plano. Es una dirección que corta en ángulo recto al Norte-Sur *y* al Este-Oeste a la vez. Hacia Arriba, no hacia el Norte.' if c == 'a' else 'Eso que llamas Espacio es un Plano. Hay otra dirección, perpendicular a todas las tuyas a la vez. Hacia Arriba, no hacia el Norte.')
	await say('logica', 'Perpendicular a Norte y a Este a la vez. Tal dirección no existe. La frase es gramatical y no significa nada.')
	await say('esfera', 'Me llamas Círculo. Soy muchos Círculos en uno: infinitos, de todos los tamaños, apilados. Lo que ves es sólo la rebanada de mí que corta tu mundo. Mira lo que ocurre si me elevo.')
	Snd.tone(330, 2.5, 'sine', 0.08, 2)
	await emerge(sph, 0.001, 2.8); await g.wait(0.8)
	await say('yo', '¡Ha menguado hasta un punto y… se ha ido!')
	sph.x = -26.6; sph.y = 9.6; Snd.sfx('sphere'); await emerge(sph, 1, 2.4)
	c = await choose([{t = 'Un truco de prestidigitador. Como desvanecerse en una Línea.', id = 'a', lock = null if g.knows('lineal') else 'requiere haber soñado con la Línea'}, {t = 'No habéis ido a ninguna parte. Os habéis encogido.', id = 'b'}])
	if c == 'a': await say('asombro', '«Eso no es moverse, es un truco de mago.» ¿Dónde has oído tú esa frase, hace nada? ¿Quién la decía?'); g.her(1)
	await say('esfera', 'Probemos con la Analogía, ya que eres matemático.')
	await slate_anim('el argumento de la Analogía', 3.5, func(cx: SlateBoard, t: float):
		var y := 150.0
		cx.dot(90, y); cx.text('Punto', 62, y + 70)
		if t > 0.25:
			cx.line(190, y, 280, y); cx.dot(190, y); cx.dot(280, y); cx.text('Línea', 208, y + 70)
		if t > 0.5:
			cx.box(370, y - 45, 90, 90)
			for q in [[370, y - 45], [460, y - 45], [370, y + 45], [460, y + 45]]: cx.dot(q[0], q[1])
			cx.text('Cuadrado', 372, y + 90)
		if t > 0.75: cx.text('?', 545, y + 24, 70)
		cx.text('puntos terminales:', 40, 300); cx.text('lados:', 40, 345)
		var xs := [90, 235, 415, 560]; var pt := ['1', '2', '4', '?']; var ld := ['0', '2', '4', '?']
		for i in 4:
			if i >= 1 and t <= 0.25 * i: continue
			cx.text(pt[i], xs[i] - 5, 300); cx.text(ld[i], xs[i] - 5, 345))
	await say('esfera', 'Un Punto que se mueve engendra una Línea, con dos puntos terminales. Una Línea que se mueve, un Cuadrado, con cuatro. Uno, dos, cuatro. ¿Qué número sigue?')
	c = await choose([{t = 'Seis.', id = 6}, {t = 'Ocho.', id = 8}, {t = 'Dieciséis.', id = 16}])
	await say('esfera', 'Ocho. Exacto: progresión geométrica. El Cuadrado, movido en la dirección nueva, engendra Algo con ocho puntos terminales. Lo llamamos Cubo.' if c == 8 else 'No. Uno, dos, cuatro: cada vez el doble. *Ocho.* El Cuadrado, movido en la dirección nueva, engendra Algo con ocho puntos terminales. Lo llamamos Cubo.')
	await say('esfera', 'Y los lados. El Punto tiene cero. La Línea, dos. El Cuadrado, cuatro. Cero, dos, cuatro. ¿Qué sigue?')
	c = await choose([{t = 'Seis.', id = 6}, {t = 'Ocho.', id = 8}, {t = 'Cinco.', id = 5}])
	await say('esfera', 'Seis. Progresión aritmética. El Cubo está limitado por seis lados, y cada uno es un Cuadrado como tú.' if c == 6 else 'No: cada vez dos más. *Seis.* El Cubo está limitado por seis lados, y cada uno es un Cuadrado como tú.')
	slate_off(); g.learn('analogia'); g.frag(16)
	await say('logica', 'La aritmética es impecable. Y no describe nada que pueda existir. ¿Qué haces con un razonamiento correcto sobre una cosa imposible?')
	c = await choose([{t = '¡Monstruo! Brujo, sueño o demonio: no soportaré más tus burlas.', id = 'a', tag = 'Embestir'}, {t = 'Seguid. Os lo ruego: seguid hablando.', id = 'h', tag = 'Escuchar'}])
	if c == 'h': await say('narr', 'Ojalá hubiera dicho eso. Me acuerdo de mis ángulos temblando, de la certeza de que se reían de mí en mi propia casa. Embestí.'); g.her(1)
	W.focus = null; W.zoom = W.base_zoom
	g.end_scene()
	g.objective('Embiste al Forastero con tu ángulo más duro', 'esfera'); W.mark('esfera'); sph.no_collide = true
	await g.until(func(): return Vector2(g.player.x - sph.x, g.player.y - sph.y).length() < 2.1, func(): pass)
	W.unmark('esfera'); g.objective('', null); Snd.sfx('bad')
	g.begin_scene()
	await emerge(sph, 0.001, 0.5); sph.x = -28.4; sph.y = 16.6; await g.wait(0.6); await emerge(sph, 1, 1.2)
	await say('esfera', '¿Por qué te niegas a oír razones? Esperaba hallar en ti, hombre de juicio y matemático, un apóstol del Evangelio de las Tres Dimensiones. Sólo se me permite predicarlo una vez cada mil años.')
	await say('esfera', 'Si las palabras no bastan, hechos. Desde donde estoy veo tu alacena, ahí arriba, en el estudio. Cerrada con llave. Dentro: dos cofres de dinero y dos tablillas de cuentas. Voy a bajar a ella y traerte una.')
	await say('logica', 'Entre él y la alacena hay una pared. Y la alacena está cerrada por sus cuatro lados. Por *todos* sus lados.')
	await emerge(sph, 0.001, 1.6); await g.wait(1.2); Snd.sfx('pick')
	W.add_spot({id = 'tab', x = -30.2, y = 8.6, label = 'una tablilla'})
	sph.x = -26.8; sph.y = 10; await emerge(sph, 0.8, 1.4)
	await say('esfera', 'Ahí la tienes, en el suelo. Ve luego a tu alacena, si quieres: falta una.')
	await say('yo', '…Es mi tablilla. La de las cuentas del mes.')
	await say('esfera', 'Y ahora, desde aquí arriba, veo algo más: tu interior. Tus entrañas, abiertas como una casa sin tejado. Voy a tocarte el estómago. No te alarmes.')
	Snd.sfx('stab'); Input.vibrate_handheld(120); g.player.guts.visible = true; W.zoom = 20; await g.wait(1.6); g.player.guts.visible = false; W.zoom = W.base_zoom
	await say('yo', '¡Ah! Un dolor… *dentro*. Nada me ha tocado el perímetro. Me ha tocado por dentro.')
	await say('asombro', 'Por un instante tú también lo has visto: lo que hay dentro de ti, desde un sitio que no es ningún sitio.')
	c = await choose([{t = '(Lanzarte otra vez sobre él, gritando.)', id = 'a'}, {t = '(Quedarte inmóvil.) ¿Qué sois?', id = 'h'}])
	if c == 'h': await say('narr', 'No me quedé inmóvil. Grité como un Isósceles y cargué.')
	Snd.sfx('peace')
	await say('esposa', '(Desde sus aposentos.) ¿Esposo? ¿Qué son esas voces? ¡Paz, paz! Voy para allá.')
	await say('esfera', 'O esto termina aquí, o vienes conmigo adonde no hacen falta palabras. ¡Fuera de tu Plano! Una… dos… tres. ¡Hecho!')
	g.frag(17)
	ui.close_dlg(); Snd.sfx('rise'); Snd.drone('none')
	g.tween(1.8, func(t): W.zoom = W.base_zoom - t * 40; g.player.rot += 0.2)
	await ui.fade(true, 1.7)
	g.end_scene()
