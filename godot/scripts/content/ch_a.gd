# Prólogo y capítulos I–III: la celda, la casa, la calle, la Puerta Oeste.
class_name ChA extends Ch

func intro(num: String, title: String, sub: String, drone: String) -> void:
	ui.chapter_tag('%s · %s' % [num, title]); Snd.drone(drone); g.set_view('top'); g.world.eye_t = 0.0
	ui.fade(false, 0.5)
	await ui.title(num, title, sub)

func outro() -> void:
	g.objective('', null)
	await ui.fade(true)
	ui.close_dlg()

func cell() -> Dictionary:
	# siete grupos de muescas en la pared Norte (P-02): siete años
	var labels := []
	for k in 7: labels.append({t = 'IIII', x = -3.05 + k * 0.82, y = 3.25, s = 0.42, a = 0.55})
	return {bounds = {x0 = -14, y0 = -14, x1 = 14, y1 = 14}, fog = 9.0, palette = 'cell', zoom = 30.0,
		buildings = [{id = 'cell', x = 0, y = 0, R = 5.2, n = 4, rot = 45, sealed = false}], labels = labels}

# ============ PRÓLOGO ============
func prologue() -> void:
	g.set_map(cell()); g.spawn_player(0, -1, PI / 2)
	g.show_strip = false; g.view_lock = true; g.set_view('eye'); g.world.eye_t = 1.0; g.hide_eye_hint = true
	ui.chapter_tag('Prólogo · La celda'); Snd.drone('cell')
	var W := g.world
	# el cántaro: el primer interior que el jugador ve y el Cuadrado no (marginalia)
	g.add({id = 'cantaro', n = 24, r = 0.55, x = -2.6, y = -2.5, name = 'el cántaro', voice = 'yo', noEye = true})
	W.static_g.add_child(W.text_plane('agua', -2.6, -2.55, 0.32, 0.0, 0.5, true))
	margins([['m_p_muescas', -1.4, 2.85], ['m_p_puerta', 0.0, -3.25], ['m_p_cantaro', -2.0, -1.8]])
	await ui.fade(false, 1.2)
	await narr('Siete años llevo en esta celda.')
	await narr('Esa raya pálida que tienes delante no es un defecto de tu vista. Es *todo* lo que ve un habitante de mi mundo: una línea, más clara donde la pared está cerca, más oscura donde se aleja.')
	# tutorial escalonado (P-05): una instrucción cada vez, que se va al cumplirla
	ui.note(tx('Gira con {move_left} / {move_right}.', 'Arrastra el pulgar a los lados, por la izquierda de la pantalla, para girar.', 'Gira con el stick izquierdo, a los lados.'), 60)
	var st := {turned = 0.0, last = g.player.rot, moved = 0.0, at = Vector2(g.player.x, g.player.y)}
	await g.until(func():
		st.turned += absf(g.player.rot - st.last); st.last = g.player.rot
		return st.turned > 0.9, func(): pass)
	ui.note(tx('Avanza con {move_up} / {move_down}.', 'Arrastra el pulgar hacia delante para avanzar.', 'Avanza con el stick izquierdo, hacia delante.'), 60)
	await g.until(func():
		st.moved = Vector2(g.player.x, g.player.y).distance_to(st.at)
		return st.moved > 1.0, func(): pass)
	ui.note('', 0.01)
	g.objective('Mira a tu alrededor')
	st.turned = 0.0
	await g.until(func():
		st.turned += absf(g.player.rot - st.last); st.last = g.player.rot
		return st.turned > 2.2, func(): pass)
	g.objective('')
	await narr('Cuatro paredes. Las reconozco por cómo se apagan en la niebla: así se deduce aquí un ángulo. Me costó años de colegio aprenderlo.')
	await narr('Pero tú no eres de aquí. Tú vienes de un mundo con una dirección de sobra. Voy a concederte, lector, lo que a mí me costó la libertad: *mirar desde arriba*.')
	g.view_lock = false; g.hide_eye_hint = false
	g.objective(tx('Pulsa {view} para elevarte sobre el plano', 'Toca el botón del ojo para elevarte sobre el plano'))
	await g.until(func(): return g.view == 'top' and g.world.eye_t < 0.05, func(): g.set_view('top'))
	g.objective(''); g.show_strip = true
	await narr('Ese soy yo. Un Cuadrado. Cuatro lados iguales, cuatro ángulos rectos: un caballero de la clase profesional, o eso era.')
	await narr('Arriba, en ese marco, sigue mi ojo: lo que yo veo mientras tú me ves a mí. Ningún compatriota mío ha contemplado jamás esta lámina. Disfrútala con un poco de culpa.')
	var coin := Vector2(0, 2.2)
	g.add(F_circ('moneda', coin.x, coin.y, {name = 'una moneda', noGuts = true, r = 0.7}))
	await narr('Los de tu mundo lo entendéis con una moneda sobre la mesa. Desde arriba: un círculo. Baja ahora el ojo hasta el borde de la mesa y dime qué queda de ella.')
	g.objective(tx('Colócate frente a la moneda y pulsa {view}', 'Colócate frente a la moneda y toca el botón del ojo'))
	await g.until(func(): return g.view == 'eye' and g.eye.sees('moneda'), func(): pass)
	g.objective('')
	# la moneda que se inclina (P-03): la primera vez, la cámara del lector baja despacio alrededor de la
	# moneda, de la vertical al ras, y el círculo se vuelve elipse y luego raya
	if not g.auto and W.eye_t < 0.5:
		g.view = 'top'; g.view_lock = true
		var p := g.player
		var yaw := atan2(p.x - coin.x, -(p.y - coin.y))
		var marks := [['círculo', 0.2], ['elipse', 0.55], ['línea', 0.85]]
		var labels := []
		for k in marks.size():
			var l := W.text_plane(marks[k][0], coin.x + 1.3, coin.y + 0.9 - k * 0.9, 0.55, 0.0, 0.0, true)
			W.static_g.add_child(l); labels.append(l)
		var show_marks := func():
			var prev := 0.0
			for k in marks.size():
				await g.wait(3.5 * (marks[k][1] - prev)); prev = marks[k][1]
				if not is_instance_valid(labels[k]): return
				var l: Label3D = labels[k]
				g.tween(0.4, func(t): if is_instance_valid(l): l.modulate.a = t * 0.9)
				Snd.sfx('chalk')
		show_marks.call()
		await Cine.orbit(W, coin, PI / 2 - 0.02, 0.035, 3.5, 9.0, yaw)
		await ui.fade(true, 0.25)
		g.set_view('eye'); W.eye_t = 1.0
		Cine.orbit_end(W)
		for l in labels: l.queue_free()
		await ui.fade(false, 0.4)
		g.view_lock = false
	await narr('Una línea. Triángulo, cuadrado, círculo, esposa, sacerdote: aquí todos somos, unos para otros, una línea que brilla y se apaga.')
	g.frag(1); g.learn('linea')
	g.achieve('ACH_COIN')
	await narr('Llamo a mi mundo Planilandia. No porque nosotros lo llamemos así, sino para que tú lo entiendas.')
	g.set_view('top'); g.world.remove('moneda')
	g.world.add_spot({id = 'tablilla', x = 2.2, y = -2.2, label = 'la tablilla'})
	ui.note(tx('Acércate y pulsa {act} para interactuar.', 'Acércate y toca el botón de acción para interactuar.'), 60)
	var o := await g.talk_begin('tablilla', 'Acércate a la tablilla y empieza a escribir', 'Escribir')
	ui.note('', 0.01)
	await say('narr', 'Me permiten tablillas. Supongo que piensan que un loco que escribe es un loco ocupado.')
	await say('narr', 'Lo contaré todo, en orden. Cada página que recuperes conmigo irá al manuscrito —*lo encontrarás en el inventario, arriba*—. Cuando esté completo, quizá alguien, en Alguna Dimensión, lo lea. Quizá ya me estás leyendo.')
	await say('narr', 'Empezaré por la última semana del año 1999 de nuestra era. Por mi casa. Por la lluvia.')
	g.talk_end(o)
	# el gancho del juicio (P-04): una frase en negro, que no se entiende hasta el capítulo X
	if not g.auto and not Profile.data.get("seen_hook", false):
		await ui.blackout(true, 0.8)
		await g.wait(0.6)
		await say('presidente', '*Sea tan amable de indicarnos esa dirección.*')
		ui.close_dlg()
		await g.wait(1.2)
		Profile.data.seen_hook = true; Profile.touch(0.0)
		ui.fade_r.color.a = 1.0; ui._fade_to = 1.0
		ui.blackout(false, 0.01)
	await outro()

# ============ CAP. I — LA CASA ============
func ch1() -> void:
	g.set_map(town()); g.spawn_player(-28, 22.5, -PI / 2); g.world.rain = 1.0; g.show_strip = true; g.view_lock = false
	var W := g.world
	# la esposa va y viene por sus aposentos de punta, gritando su «¡Paz!» (C1-05)
	g.add(F_mujer('esposa', -18.5, 13.7, {name = 'tu esposa', ai = {type = 'path', pts = [Vector2(-18.5, 13.7), Vector2(-23.4, 13.7), Vector2(-21.0, 17.5), Vector2(-21.0, 10.0)]}, speed = 1.1, cry = true, cryRange = 8.0}))
	g.add(F_mujer('hija', -21.8, 9, {name = 'tu hija', r = 0.8, sway = 1.4}))
	# la casa respira (C1-06): los nietos se persiguen, los hijos salen a sus consultas, el criado barre
	g.add(F_hexa('nieto', -34.5, 9, {name = 'tu nieto menor', r = 0.6, ai = {type = 'wander', home = Vector2(-34.5, 9.5), r = 2.0}, speed = 2.0}))
	g.add(F_hexa('nieto2', -33.2, 8.6, {name = 'tu otro nieto', r = 0.66, ai = {type = 'follow', target = 'nieto', dist = 1.4, speed = 2.4}}))
	g.add(F_penta('hijo', -28, 9, {name = 'tu hijo mayor', rot = 1.2}))
	var rooms := [Vector2(-28, 10.5), Vector2(-26.5, 14.5), Vector2(-30, 16), Vector2(-35, 15), Vector2(-38, 11.5)]
	g.add(F_penta('hijo2', -29, 12, {name = 'tu segundo hijo', ai = {type = 'stroll', pts = rooms, jit = 1.0}, speed = 1.4}))
	g.add(F_penta('hijo3', -36, 12.5, {name = 'tu tercer hijo', ai = {type = 'path', pts = [Vector2(-36, 12.5), Vector2(-39.5, 13.3), Vector2(-46, 12), Vector2(-46, 0), Vector2(-20, -2)]}, speed = 1.6}))
	g.add(F_iso('criado', -36.2, 15.6, 10, {name = 'el criado', ai = {type = 'wander', home = Vector2(-37.0, 14.2), r = 1.3}, speed = 0.8}))
	# el tercer hijo sale a su consulta y se pierde calle abajo
	g.tick(func(_dt):
		var h := g.npc('hijo3')
		if h != null and not h.hid and Vector2(h.x + 20.0, h.y + 2.0).length() < 1.5: h.hid = true; return true)
	W.add_spot({id = 'tejado', x = -28, y = 27, label = 'el vértice del tejado'})
	W.add_spot({id = 'alacena', x = -23.3, y = 20.4, label = 'la alacena'})
	margins([['m_c1_puerta_este', -20.6, 13.0], ['m_c1_reloj', -29.6, 17.2], ['m_c1_cuentas', -37.6, 17.4]])
	var pr := {said = false}
	var on_hurt := func(_sev):
		var e := g.npc('esposa'); var p := g.player
		if not pr.said and e != null and Vector2(e.x - p.x, e.y - p.y).length() < 2.6:
			pr.said = true; ui.note('*Tu esposa:* «¡Esposo! ¿No me oías?»', 4)
	g.hurt_taken.connect(on_hurt)
	await intro('Capítulo I', 'La casa de cinco lados', 'Donde se aprende de dónde viene la lluvia y por qué puerta entra cada cual.', 'home')
	await narr(tx('Mi estudio, bajo el vértice del tejado. Muévete con {move} o las flechas.', 'Mi estudio, bajo el vértice del tejado. Arrastra el pulgar por la izquierda de la pantalla para moverte: cuanto más lejos, más deprisa.', 'Mi estudio, bajo el vértice del tejado. Muévete con el stick izquierdo: cuanto más lo inclines, más deprisa.'))
	await narr('Aquel día llovía. Siempre que empiezo a recordar, llueve.')

	var f_alacena := func():
		await say('narr', 'Mi alacena, cerrada con llave por sus cuatro lados. Yo guardo la llave.')
		await _hold('La llave', tx('Mantén pulsado {act} para girar la llave.', 'Mantén pulsado el botón de acción para girar la llave.'), 'Girar', 0.8)
		Snd.sfx('lock')
		# desde la lámina se ve dentro: el lector es tridimensional; el Cuadrado no (C1-01)
		var c := Vector2(-22.3, 21.8)
		g.add({id = 'cofre1', n = 4, r = 0.3, rot = 0.785, x = c.x - 0.5, y = c.y - 0.35, name = 'un cofre', noCollide = true, noGuts = true})
		g.add({id = 'cofre2', n = 4, r = 0.3, rot = 0.785, x = c.x + 0.5, y = c.y - 0.35, name = 'un cofre', noCollide = true, noGuts = true})
		g.add({id = 'tab1', pts = [[0.32, 0.12], [-0.32, 0.12], [-0.32, -0.12], [0.32, -0.12]], x = c.x - 0.45, y = c.y + 0.4, name = 'una tablilla', noCollide = true, noGuts = true, noEye = true})
		g.add({id = 'tab2', pts = [[0.32, 0.12], [-0.32, 0.12], [-0.32, -0.12], [0.32, -0.12]], x = c.x + 0.45, y = c.y + 0.4, name = 'una tablilla', noCollide = true, noGuts = true, noEye = true})
		W.focus = c; W.zoom = 14
		await say('narr', 'Dentro: dos cofres de dinero y dos tablillas de cuentas. Las cuento cada noche, de memoria, porque no las veo.')
		await say('logica', 'Cerrada por sus cuatro lados está cerrada del todo. No existe otro lado por el que entrar.')
		await say('asombro', 'Tú sí las ves, ¿verdad? Desde ahí arriba. Dos cofres, dos tablillas. Él no podría ni imaginarlo.' if g.state.max < 8 else 'Y sin embargo.')
		W.focus = null; W.zoom = W.base_zoom
		g.flag('alacena_vista', 1)
	var f_hija := func():
		await say('hija', '¡Padre! Mira: ya meneo la espalda sin pensar. La institutriz dice que tengo un vaivén muy distinguido.')
		await say('narr', 'En las familias de rango, el vaivén del extremo posterior se enseña como un arte. Avisa de tu presencia a quien viene detrás. Las hijas de los Círculos lo ejecutan con un ritmo que da envidia.')
		await say('hija', '¿Me enseñarás a contar, como al nieto? Sólo hasta diez.')
		var c = await choose([{t = 'Las niñas no necesitan contar, hija.', id = 'o'}, {t = 'Cuando tu madre no mire. Hasta diez.', id = 'h', tag = 'Herejía'}, {t = '(Cambiar de tema.) Qué bien meneas la espalda.', id = 's'}])
		if c == 'o': await say('hija', 'Ya. Eso dice la institutriz.'); g.her(-1)
		if c == 'h':
			await say('decoro', 'Hace trescientos años que la ley prohíbe exactamente esto.')
			g.her(1); g.flag('hijaCuenta', 1); g.rel('hija', 1)
			await _count_game()
		if c == 's': await say('hija', '¿Verdad que sí?')
	g.on('hija', 'Hablar', f_hija)
	var f_hijo := func():
		await say('hijo', 'Padre. Salgo a visitar enfermos. Un Hexágono con un lado inflamado; nada grave, pero paga bien.')
		await say('narr', 'Mis cuatro hijos son Pentágonos: un lado más que yo, como manda la Naturaleza. Médicos todos. Hombres rectos. Jamás les he oído una pregunta que no supieran ya contestar.')
	g.on('hijo', 'Hablar', f_hijo)
	g.on('nieto2', 'Hablar', func(): await say('nieto', '(Tu otro nieto dormita, con la quietud perfecta de seis lados bien educados.)'))

	var f_tejado := func():
		await say('narr', 'El vértice de mi casa apunta al Norte, como el de todas. La lluvia viene siempre de allí, a intervalos fijos, y el tejado la parte en dos.')
		await say('logica', 'No hay sol ni estrellas en este mundo. Para orientarte tienes dos cosas: la lluvia, y un tirón leve y constante hacia el Sur. Las mujeres y los ancianos lo notan más.')
		await say('narr', 'Tampoco hay ventanas. ¿Para qué? La luz está en todas partes, dentro y fuera, de día y de noche. Nadie sabe de dónde viene.')
		var c = await choose([{t = '¿Y nadie lo ha investigado?', id = 'q'}, {t = 'Así ha sido siempre.', id = 'o'}])
		if c == 'q':
			await say('narr', 'Antaño era la pregunta favorita de los sabios. Hoy esa investigación paga un impuesto ruinoso, y los manicomios están llenos de quienes creyeron tener la respuesta.')
			await say('recelo', 'Toma nota: en este país las preguntas tienen precio.')
		else: await say('narr', 'Eso respondía yo también. Es una frase muy cómoda, con cinco lados y ninguna ventana.')
		g.frag(2); g.learn('norte')
	var f_nieto := func():
		await say('nieto', '¡Abuelo! ¿Jugamos a los ángulos? Yo te pongo una figura delante, tú cierras los ojos y la palpas. ¡Y adivinas cuál es!')
		await say('narr', 'Figuras de juguete, de madera, con las puntas limadas. Se las había hecho yo. El juego era mío también: así aprendí a palpar.')
		var hits := await _angle_game()
		if hits >= 2:
			g.rel('nieto', 1)
			await say('nieto', '¡Dos de tres! Abuelo, tú ves con los lados.' if hits < 3 else '¡Las tres! Abuelo, tú ves con los lados.')
		else: await say('nieto', 'Je. A ver si se te va a escapar un Isósceles por un Hexágono, abuelo.')
		await say('nieto', 'Oye, ¿y por qué nuestra casa tiene cinco lados y no cuatro, como tú?')
		var c = await choose([{t = 'Porque lo manda la ley, y con eso basta.', id = 'o'}, {t = 'Piénsalo: ¿qué pasa si tropiezas con una esquina?', id = 'm'}])
		if c == 'o':
			await say('nieto', 'Pero la ley tendrá un porqué…')
			await say('narr', 'Tenía la mala costumbre de los niños listos: no aceptar la primera respuesta.')
		await say('nieto', '¡Ya sé! Las esquinas de una casa cuadrada pinchan más que las de una de cinco lados. Y como las paredes brillan menos que las personas, uno no las ve venir en la niebla.')
		await say('narr', 'Exacto. Por eso las casas triangulares se prohibieron hace siglos, salvo cuarteles y polvorines, y las cuadradas pagan impuesto. En las ciudades, cinco lados como mínimo.')
		g.learn('casas')
		await say('nieto', 'Abuelo, ¿y si hubiera una casa que no pinchara por *ningún* lado?')
		await say('asombro', 'Seis lados y ya hace preguntas que tú, con cuatro, no te has hecho nunca.')
		if c == 'm': g.flag('nietoCurioso', 1)
	var f_esposa := func():
		await say('decoro', 'Has entrado en los aposentos del Este. Aquí se anuncia uno, y se mira dónde se pisa.')
		await say('esposa', 'Esposo. No te había oído. Deberías hablar al acercarte; ya sabes lo que le pasó a mi primo.')
		await say('narr', 'Mi esposa es una Línea recta, como todas las mujeres: una aguja. Vista de costado, un trazo. Vista de punta, casi nada: un brillo, y luego el pinchazo.')
		g.set_view('eye'); await ui.sleep(1.6)
		await say('logica', 'Mírala con tu ojo. Cuando gira hacia ti, desaparece. Por eso la ley la obliga a menearse.')
		g.set_view('top')
		await say('esposa', 'He oído que en casa del boticario la mujer estornudó al volverse. Él ya no está. Ella no recordaba nada a la media hora; cenó tan tranquila.')
		var c = await choose([{t = 'Por eso existen las leyes, querida: la puerta del Este, el Grito de Paz.', id = 'o'}, {t = '¿Y a ti no te pesa gritar por la calle toda tu vida?', id = 'h', tag = 'Herejía'}, {t = 'Mi amor, mi deber es protegerte. (Lengua de mujeres.)', id = 'm'}])
		if c == 'o':
			await say('esposa', 'Sí, esposo. Las leyes son sabias.')
			await say('narr', 'Toda casa, una puerta al Este sólo para ellas. En la calle, el Grito de Paz sin interrupción, bajo pena de muerte. Así vivíamos tranquilos. Nosotros.'); g.her(-1)
		if c == 'h':
			await say('esposa', '¿Pesarme? Qué preguntas haces. No sé… nunca lo he pensado. No me han enseñado a pensarlo.')
			await say('recelo', 'Lo ha dicho sin rencor. Eso es lo que debería inquietarte.'); g.her(1)
		if c == 'm':
			await say('esposa', 'Lo sé. Y el mío, quererte.')
			await say('logica', '«Amor». «Deber». Con ellas usas palabras que entre varones no significan nada. Ya ni notas el cambio de idioma.')
		g.frag(4); g.learn('mujeres')
	var f_criado := func():
		await say('criado', '¿El señor va a salir? Le abro. Cuidado en la calle, que hoy no se ve un ángulo a dos pasos.')
		await say('narr', 'Un Isósceles de diez grados. Soldados y obreros lo son todos: dos lados largos, una base mínima, una punta que da miedo. Apenas se les considera figuras.')
		await say('criado', 'Mi chico ha salido de diez grados y medio, señor. Medio grado más que yo. A este paso, en cien generaciones, un biznieto mío será Equilátero.')
		var c = await choose([{t = 'Es un buen muchacho. Me alegro por ti.', id = 'a'}, {t = 'No te hagas ilusiones por encima de tu ángulo.', id = 'b'}, {t = '(Asentir sin decir nada.)', id = 'c'}])
		if c == 'a': await say('criado', 'Dios… quiero decir, los Círculos se lo paguen, señor.'); g.rep('ciu', 1); g.rel('criado', 1)
		if c == 'b': await say('criado', 'No, señor. Claro que no, señor.'); g.rep('ciu', -1); g.rel('criado', -1)
		await say('logica', 'Entre los tuyos, cada hijo gana un lado entero. Entre los suyos, medio grado, y sólo si trabajan sin tacha. Alguien diseñó esa diferencia.')
		g.learn('herencia')
	await g.all({
		tejado = {label = 'Examinar', fn = f_tejado},
		alacena = {label = 'Abrir', fn = f_alacena, again = func(): await say('narr', 'Dos cofres, dos tablillas. Cerrada por sus cuatro lados.')},
		nieto = {fn = f_nieto, again = func(): await say('nieto', '¿Jugamos luego a los ángulos, abuelo?')},
		esposa = {fn = f_esposa, again = func(): await say('esposa', 'Abrígate el perímetro si sales. Hay niebla.')},
		criado = {fn = f_criado},
	}, 'Recorre tu casa: el tejado, la alacena, tu nieto, tu esposa, el criado')
	g.hurt_taken.disconnect(on_hurt)

	await narr('Tenía que salir. Por la puerta del Oeste, la ancha: la de los varones.')
	var st := {warned = false}
	var stop := g.tick(func(_dt):
		var p := g.player
		if not st.warned and Vector2(p.x + 19.4, p.y - 13.3).length() < 2.2:
			st.warned = true; ui.note('*Decoro* — Esa es la puerta del Este. Es de ellas. Un caballero no la cruza.', 5); Snd.sfx('bad'))
	await g.go_to(-41, 13.3, 1.8, 'Sal a la calle por la puerta del Oeste')
	stop.call()
	await _rain_north()
	await outro()

# C1-03 · el juego de los ángulos: tres juguetes, a ciegas y sin riesgo. Devuelve los aciertos.
func _angle_game() -> int:
	if g.auto: return 2
	var kinds := ['tri', 'cuad', 'penta', 'hexa']; kinds.shuffle()
	var hits := 0
	var p := g.player
	for k in 3:
		var dir := p.rot
		var x := p.x + cos(dir) * 1.25; var y := p.y + sin(dir) * 1.25
		var d: Dictionary
		match kinds[k]:
			'tri': d = F_tri('juguete', x, y, {r = 0.5})
			'cuad': d = F_cuad('juguete', x, y, {r = 0.5})
			'penta': d = F_penta('juguete', x, y, {r = 0.5})
			_: d = F_hexa('juguete', x, y, {r = 0.5})
		d.noCollide = true; d.noGuts = true; d.name = 'un juguete'
		d.rot = dir + PI   # un vértice hacia ti
		g.add(d)
		var r: Dictionary = await Feel.run(self, g.npc('juguete'), {toy = true, blind = true,
			text = tx('Con los ojos cerrados: mantén {act} y recorre el ángulo con tu lado.', 'Con los ojos cerrados: mantén pulsado «Palpar» y recorre el ángulo con tu lado.'),
			on_fast = func(_n): ui.note('*Tu nieto se ríe:* «¡Así, en la calle, te pinchas!»', 3)})
		g.world.remove('juguete')
		if r.ok: hits += 1
		await say('nieto', ['¡Bien!', '¡Otra vez bien!', '¡Y la última!'][k] if r.ok else '¡No! Mira…')
	return hits

# C1-04 · la hija aprende a contar: diez guijarros, con ritmo, sin que la madre lo vea
func _count_game() -> void:
	if g.auto: return
	var W := g.world; var p := g.player
	var wife := g.npc('esposa')
	var was_ai = wife.ai; var was_sp := wife.speed
	wife.ai = {type = 'path', pts = [Vector2(-20.2, 19.0), Vector2(-20.2, 8.6)]}; wife.speed = 1.0
	ui.panel_info('Hasta diez', tx('Pulsa {act} para dejar cada guijarro, con ritmo. Si tu esposa se acerca por el pasillo, para.', 'Toca «Contar» para dejar cada guijarro, con ritmo. Si tu esposa se acerca por el pasillo, para.'))
	g.need_act = 'Contar'
	var words := ['¡Uno!', '¡Dos!', '¡Tres!', '¡Cuatro!', '¡Cinco!', '¡Seis!', '¡Siete!', '¡Ocho!', '¡Nueve!', '¡Diez!']
	var st := {n = 0, down = false, last = -1.0, t = 0.0, caught = false}
	var hija := g.npc('hija')
	await g.tick_until(func(dt) -> bool:
		st.t += dt
		var held := g.act_held()
		if g.bot: held = not st.down and st.t - st.last > 0.4
		if held and not st.down:
			if Vector2(wife.x - p.x, wife.y - p.y).length() < 6.0 and not g.bot:
				st.caught = true; return true
			if st.t - st.last >= 0.3:
				st.last = st.t
				var a := hija.rot + PI / 2
				W.fx_add('puff', hija.x + cos(a) * (0.5 + st.n * 0.28), hija.y + sin(a) * (0.5 + st.n * 0.28), 0.6, 0.3)
				g.add({id = 'guij%d' % st.n, n = 8, r = 0.1, x = hija.x + cos(a) * (0.6 + st.n * 0.28), y = hija.y + sin(a) * (0.6 + st.n * 0.28), noCollide = true, noGuts = true, noEye = true, name = 'un guijarro'})
				ui.note(tr('*Tu hija:* «%s»') % ui.T(words[st.n]), 1.2); Snd.blip('mujer')
				st.n += 1
		st.down = held
		return st.n >= 10)
	g.need_act = ''; ui.panel_info(null)
	if st.caught:
		ui.note('', 0.01)
		await wife.move_to(p.x + 1.8, p.y + 0.6, 2.0)
		await say('esposa', '¿Qué le estás enseñando a la niña?')
		var c = await choose([{t = 'A menearse, querida. El vaivén.', id = 'l', tag = 'La mentira'}, {t = 'A contar. Hasta diez.', id = 'v', tag = 'La verdad'}])
		if c == 'l':
			await say('esposa', 'Ah. Muy bien. Que no se le olvide nunca: la espalda, siempre.')
			await say('hija', '(Te mira, y no dice nada. Ha aprendido algo más que a contar.)')
		else:
			await say('esposa', '¿A contar? ¿A una niña? Esposo… La institutriz tendrá que saberlo. Y la institutriz se lo dirá a quien se lo diga.')
			g.rel('esposa', -1); g.note('hija_cuenta', 2)
	else:
		await say('hija', '…¡ocho, nueve, diez! ¡Diez, padre! ¿Y después del diez?')
		await say('narr', 'Después del diez, le dije, viene el once. Lo que no le dije es que en mi mundo una niña que pregunta por el once es un problema de Estado.')
		g.achieve('ACH_COUNT'); g.flag('hija_diez', 1)
	for k in 10: W.remove('guij%d' % k)
	wife.ai = was_ai; wife.speed = was_sp

# C1-02 · la lluvia que orienta: fuera, sin lámina, mirar al Norte por cómo centellea la lluvia
func _rain_north() -> void:
	await say('logica', 'Antes de seguir: cierra la lámina. Aquí nadie tiene brújula. Lo que tenemos es la lluvia, y siempre viene del Norte.')
	ui.close_dlg()
	if g.auto: return
	var W := g.world
	g.set_view('eye'); g.view_lock = true; g.no_guides = true; W.rain = 1.0
	ui.note('*Lógica* — Cada gota es un centelleo en la línea. Si se desliza, la ves pasar de lado. Si se queda quieta y se aviva, viene hacia ti: estás mirando al Norte.', 12)
	g.objective('Mira al Norte, guiándote sólo por la lluvia', null)
	var st := {t = 0.0}
	await g.until(func():
		if absf(App.ang_diff(g.player.rot, PI / 2)) < 0.25: st.t += g.get_process_delta_time()
		else: st.t = 0.0
		return st.t > 1.0 or g.bot, func(): pass)
	g.objective('', null); ui.note('', 0.01); Snd.sfx('good')
	await say('logica', 'Eso es: el Norte, sin brújula. Acuérdate esta noche.')
	ui.close_dlg()
	g.view_lock = false; g.no_guides = false; g.set_view('top')

# ============ CAP. II — LA CALLE MAYOR ============
func town_folk() -> void:
	# sitios a los que va la gente: puertas, esquinas y tramos de la Calle Mayor
	var places := [Vector2(-56, 6), Vector2(-42, 2.5), Vector2(-28, -3), Vector2(-14, -9), Vector2(-4, 6.5), Vector2(7, -8.5), Vector2(18, 7), Vector2(30, -7), Vector2(40, 8), Vector2(54, 7.5), Vector2(-20, 1), Vector2(26, 1)]
	var near := func(x: float, span: float) -> Array:
		return places.filter(func(q): return absf(q.x - x) < span)
	g.add(F_mujer('dama', -18, -2, {name = 'una dama', ai = {type = 'path', pts = [Vector2(-18, -2.5), Vector2(10, -2.5), Vector2(10, 2.5), Vector2(-18, 2.5)]}, speed = 1.9}))
	g.add(F_iso('obrero', -12, 3, 8, {name = 'un obrero', ai = {type = 'stroll', pts = near.call(-10, 22)}, speed = 1.9}))
	g.add(F_penta('medico', 34, 3, {name = 'un médico', ai = {type = 'stroll', pts = near.call(36, 22)}, speed = 1.6}))
	g.add(F_iso('sold1', 50, -2, 12, {name = 'un soldado', ai = {type = 'path', pts = [Vector2(52, -3), Vector2(-55, -3), Vector2(-55, 3), Vector2(52, 3)]}, speed = 3.0}))
	g.add(F_iso('sold2', 48, -2, 12, {name = 'un soldado', ai = {type = 'follow', target = 'sold1', dist = 2.4, speed = 3.2}}))
	g.add(F_tri('trans', 20, -3, {name = 'un tendero', ai = {type = 'stroll', pts = near.call(18, 24)}, speed = 1.7}))
	# vecinos de paso: cada uno con su recado
	g.add(F_cuad('amb0', 44, 2, {name = 'un vecino', ai = {type = 'stroll', pts = places}, speed = 1.7}))
	g.add(F_tri('amb1', -50, 1, {name = 'un artesano', ai = {type = 'stroll', pts = near.call(-40, 30)}, speed = 2.0}))
	g.add(F_hexa('amb2', 8, 2, {name = 'un caballero', ai = {type = 'stroll', pts = near.call(10, 34)}, speed = 1.3}))
	g.add(F_hexa('amb3', 9, 3, {name = 'su hijo', r = 0.5, ai = {type = 'follow', target = 'amb2', dist = 1.7, speed = 2.6}}))
	var st := {t = 0.0}
	g.tick(func(dt):
		st.t += dt
		if st.t > 3.2:
			st.t = 0.0
			var d := g.npc('dama'); var p := g.player
			if d != null and p != null and Vector2(d.x - p.x, d.y - p.y).length() < 14 and not g.busy: Snd.sfx_at('peace', d.x, d.y, 0.0, 'Grito de Paz'))
	var f_dama := func():
		await say('dama', '¡Paz, paz! Buenos días, caballero. Disculpe que no me detenga: si dejo de gritar, me multan; si dejo de menearme, me denuncian.')
		await say('narr', 'El Grito de Paz. De niño me parecía el sonido mismo de la calle, como la lluvia.')
	g.on('dama', 'Saludar', f_dama)
	var f_obrero := func():
		await say('obrero', '¿Manda algo el señor? Voy al tajo. Dicen que si uno trabaja sin faltar, al hijo le crece el ángulo.')
		await say('obrero', 'Mi abuelo estuvo en una revuelta. Ciento veinte ha habido, cuentan, y todas igual: los Círculos sueltan promesas a unos cuantos, y nos acabamos pinchando entre nosotros.')
		await say('recelo', 'Lo dice sin bajar la voz. O es muy valiente o su ángulo no le da para callar.')
	g.on('obrero', 'Hablar', f_obrero)
	var f_medico := func():
		await say('medico', 'Colega. ¿Sabe que en el Hospital han enderezado a un Triángulo que se desviaba un grado entero? Compresiones, extensiones, una trepanación menor. Sobrevivió, incluso.')
		await say('narr', 'El arte de curar la Irregularidad. Se hablaba de él con orgullo, y en voz no muy alta.')
	g.on('medico', 'Hablar', f_medico)
	g.on('trans', 'Hablar', func(): await say('mercader', 'Tablillas, punzones, sal del Norte. ¿No? Otro día será, señor Cuadrado.'))
	g.on('sold1', 'Hablar', func(): await say('soldado', '¡Paso a la ronda! Disculpe el señor: de frente, que de punta no respondo.'))

func ch2() -> void:
	g.set_map(town()); g.spawn_player(-41, 13.3, -PI / 2); g.world.rain = 0.25; town_folk()
	g.add(F_hexa('noble', -30, -2.5, {name = 'un Hexágono ocioso', rot = 0.5}))
	# el comerciante tiene su puesto en la otra acera: para llegar hay que cruzar la calle (C2-02)
	g.add(F_tri('mercader', 6, 9.6, {name = 'un comerciante', rot = -PI / 2}))
	g.add({id = 'irregular', pts = [[0.95, 0], [-0.3, 0.8], [-0.62, -0.38]], voice = 'tri', x = -48, y = 2.4, name = 'un calderero', rot = 0.2})
	g.world.add_spot({id = 'voz', x = 26, y = -5.5, label = 'una voz en la niebla'})
	# presentación entre caballeros (C2-04): el médico va con un colega
	g.add(F_penta('colega', 35, 4.5, {name = 'un colega del médico', ai = {type = 'follow', target = 'medico', dist = 1.8, speed = 2.0}}))
	# el Hospital, desde fuera (C2-06)
	g.add(F_penta('celador', 56, 10.0, {name = 'el celador', rot = -PI / 2}))
	margins([['m_c2_charlatan', -8, -6.4], ['m_c2_banco', -49.5, 4.4], ['m_c2_cartel', 20, -6.2], ['m_c2_hospital', 53.6, 10.4], ['m_c2_viajeros', -92, 4.5]])
	var hs := {t = 0.0}
	g.tick(func(dt):
		hs.t -= dt
		var p := g.player
		if hs.t <= 0.0 and p != null and Vector2(p.x - 56, p.y - 14).length() < 16.0:
			hs.t = 3.0; Snd.sfx_at('compress', 56, 15, 0.0, 'golpes tras el muro'))
	g.on('celador', 'Hablar', func():
		await say('medico', '(El celador, un Pentágono de brazos cortos.) Aquí no se entra sin volante, caballero. Y con volante, tampoco se sale igual.')
		await say('recelo', 'Lo ha dicho como un chiste. No se ha reído.'))
	var f_colega := func():
		await say('medico', 'Colega, permítame pedirle que palpe y sea palpado por mi amigo el señor Pentágono, del Hospital.')
		await say('decoro', 'La presentación tiene su orden. No lo estropees.')
		var steps := [
			[{t = '(Esperar a que él se disponga, inmóvil.)', id = 'ok'}, {t = '(Tender el ángulo enseguida.)', id = 'x1'}, {t = 'Encantado, ¿y usted qué es?', id = 'x2'}],
			[{t = '(Ofrecerle tu ángulo, despacio, y dejarte palpar.)', id = 'ok'}, {t = '(Palparle tú primero.)', id = 'x1'}, {t = '(Decirle tus lados de palabra.)', id = 'x2'}],
			[{t = '(Palparle a tu vez, sin prisa, un solo ángulo.)', id = 'ok'}, {t = '(Palparle los cinco ángulos, por si acaso.)', id = 'x1'}, {t = '(No palparle: ya se ve que es un Pentágono.)', id = 'x2'}],
		]
		for k in steps.size():
			var opts: Array = steps[k].duplicate(); opts.shuffle()
			var c = await choose(opts)
			if c != 'ok':
				await say('medico', '(El colega se aparta un palmo.) …Caballero. En el Hospital somos gente de formas. Buenas tardes.')
				g.note('mala_presentacion', 1)
				return
		await say('medico', '(El colega.) Ciento ocho grados exactos, y usted noventa. Un placer. Si algún día oye usted golpes tras nuestro muro, no se alarme: sólo enderezamos.')
		await say('recelo', '«Sólo enderezamos.» Guárdatelo.')
	g.on('colega', 'Presentarse', f_colega)
	# al acercarte al puesto del comerciante, la niebla se cierra: hay que cruzar con el ojo y el oído
	var cs := {done = false}
	g.tick(func(_dt):
		var p := g.player; var m := g.npc('mercader')
		if cs.done or g.busy or p == null or m == null or g.auto: return
		if Vector2(p.x - m.x, p.y - m.y).length() < 13.0:
			cs.done = true
			var cross := func():
				g.locked = true
				await narr('El comerciante tiene su puesto en la otra acera, y la niebla de hoy no deja ver ni un ángulo. Habrá que cruzar con mi ojo. Y con los oídos.')
				g.locked = false
				var r: Dictionary = await CrossStreet.run(self, {from = Vector2(6, -9.5), to = Rect2(1, 6.6, 10, 2.6)})
				if r.pricks == 0: g.achieve('ACH_STREET')
				g.set_view('top')
				ui.note('*Lógica* — Ya estás en su acera. Preséntate.', 4)
			cross.call()
			return true)
	await intro('Capítulo II', 'La Calle Mayor', 'Donde se aprende quién es quién, y cómo averiguarlo sin perder un ángulo.', 'flat')
	await narr(tx('La Calle Mayor. Desde arriba la ves entera; yo veía rayas que se cruzaban en la niebla. Prueba a recorrerla con mi ojo ({view}), si te atreves.', 'La Calle Mayor. Desde arriba la ves entera; yo veía rayas que se cruzaban en la niebla. Prueba a recorrerla con mi ojo (el botón del ojo), si te atreves.'))

	var f_irregular := func():
		await say('irregular', 'Buenos días, señor. ¿Algún punzón que afilar? ¿Una bisagra? Llevo cuarenta años en esta esquina.')
		var c = await choose([{t = 'Hoy no, buen hombre.', id = 'n'}, {t = 'Permítame palparle, por cortesía.', id = 'p', lock = null if g.knows('tacto') else 'aún no dominas el tacto'}, {t = '¿Cuarenta años? ¿Y qué ha visto en ellos?', id = 'q'}])
		if c == 'p':
			await say('irregular', 'Ah… hoy llevo prisa, señor. Otro día. Con su permiso.')
			await say('recelo', 'Nadie con prisa lleva cuarenta años en la misma esquina.'); g.flag('sospecha', 1)
		if c == 'q':
			await say('irregular', 'He visto que a quien no molesta, a veces lo dejan en paz. Con eso me basta. Tenga: se le había caído este estilete.')
			await say('narr', 'Me devolvió un estilete que yo no había echado en falta. Recuerdo que pensé: qué equilátero tan decente.'); g.flag('amable', 1); g.rep('ciu', 1); g.rel('calderero', 1)
	g.on('irregular', 'Hablar', f_irregular)

	var f_noble := func():
		await say('noble', 'Un Cuadrado. Bien, bien. Ustedes sostienen el mundo por abajo, como una buena base. ¿Sabe por qué todo está en orden?')
		# la escala de clases, viva (C2-01): la cámara recorre la calle y se para en un ejemplo de cada una
		var talking := {on = true}
		var keys := [{t = 0.0, focus = Vector2(g.player.x, g.player.y), zoom = g.world.zoom, bands = false, stop = func(): return not talking.on}]
		var tt := 1.0
		for id in ['obrero', 'amb1', 'amb0', 'medico', 'amb2']:
			var e := g.npc(id)
			if e == null: continue
			keys.append({t = tt + 1.6, focus = Vector2(e.x, e.y), zoom = 24.0}); keys.append({t = tt + 3.4, focus = Vector2(e.x, e.y), zoom = 24.0}); tt += 3.4
		keys.append({t = tt + 1.8, focus = Vector2(g.player.x, g.player.y), zoom = g.world.base_zoom})
		Cine.play(g.world, keys, false)
		await say('noble', 'Porque cada cual sabe lo que es con sólo contarse los lados. Abajo, los Isósceles: soldados, obreros, carne de punta. Luego los Equiláteros, que venden cosas. Luego usted y los Pentágonos: médicos, letrados. Luego *nosotros*, de seis lados en adelante. Y arriba, tantos lados que ya no se cuentan: los Círculos.')
		await say('yo', '¿Y las mujeres?')
		await say('noble', 'Líneas, caballero. De la clase que sean. No tienen lados que contar.')
		var c = await choose([{t = 'Y cada hijo, un lado más que su padre. Mis nietos ya son como usted.', id = 'a'}, {t = 'Salvo los Isósceles. A ellos la ley no los sube.', id = 'b', lock = null if g.knows('herencia') else 'ignoras cómo heredan los Isósceles'}])
		if c == 'a': await say('noble', 'Je. Sí. No me lo recuerde.')
		if c == 'b':
			await say('noble', 'Medio grado por generación, si se portan. Y cuando al fin les nace un Equilátero de verdad, la Junta lo examina, lo certifica… y se lo lleva. Lo adopta una familia Regular. No vuelve a ver a los suyos.')
			await say('noble', 'Es una idea brillante de los Círculos. Les da una esperanza, ¿comprende? Uno entre mil sube, y los otros novecientos noventa y nueve se están quietos.')
			await say('recelo', 'Lo llama «brillante». Busca otra palabra, más tarde, a solas.')
		talking.on = false; g.world.focus = null; g.world.zoom = g.world.base_zoom
		g.frag(3); g.learn('clases')
	var f_mercader := func(o):
		await say('mercader', 'Señor. Soy hombre a la antigua: *permítame pedirle que me palpe y sea palpado por mí.* Así sabremos con quién tratamos.')
		await say('decoro', 'Entre gente fina, palpar es grosería. Pero él es comerciante, y tú vienes a comprar. Adelante: un solo ángulo basta.')
		await say('logica', 'Recorre su ángulo con tu lado. La abertura te dirá la clase. Y que no se mueva: un sobresalto, y su vértice te atraviesa.')
		var ok := await feel(o, '', {risky = true})
		ui.panel_info(null)
		if ok: await say('mercader', 'Sesenta grados justos. Equilátero y a mucha honra. Y usted, cuatro rectos: un caballero.')
		else:
			await say('mercader', '¡Señor! Sesenta. Tres veces sesenta. ¿Por quién me toma?')
			await say('logica', 'Menos de 60°: Isósceles. 60°: Equilátero. 90°: Cuadrado. 108°: Pentágono. 120°: Hexágono. Apréndelo.')
		g.learn('tacto')
		await say('mercader', 'Mi bisabuelo, obrero de cincuenta y nueve grados y medio, dio un respingo de reuma mientras lo palpaba un Polígono. Lo atravesó de parte a parte. La familia bajó grado y medio. Cinco generaciones tardamos en llegar a sesenta.')
		await say('narr', 'Esa misma historia se cuenta en mi familia, de mi propio antepasado. Puede que todas las familias de Planilandia tengan un abuelo que estornudó.')
		g.frag(5)
	# la voz en la niebla, jugada (C2-05): tres voces; sólo una es de un Hexágono
	var f_voz := func():
		Snd.tone(262, 0.5, 'triangle', 0.1); await ui.sleep(0.5)
		await say('logica', 'Voces en la niebla. No las ves: sólo las oyes. Una es de un Hexágono de verdad; las otras, de quien imita su voz. Apártate sólo ante la verdadera.')
		ui.close_dlg()
		var r: Array = await Voices.run(self, Vector2(26, -5.5))
		if r.count(true) == 3:
			await say('logica', 'Bien oído. Las voces imitadas tiemblan en las notas largas: el Isósceles empuja la garganta. Aun así, el oído, solo, no es de fiar.')
			g.achieve('ACH_EAR')
		else:
			await say('logica', 'Las clases bajas tienen la garganta más hábil que nosotros. El oído, solo, no es de fiar.')
		g.learn('oido')
	await g.all({
		noble = {fn = f_noble},
		mercader = {label = 'Presentarse', fn = f_mercader},
		voz = {label = 'Escuchar', fn = f_voz},
	}, 'Trata con la gente de la calle: el noble, el comerciante, la voz')

	g.begin_scene()
	var s := g.add(F_iso('guardia', g.player.x - 14, g.player.y, 16, {name = 'el sargento'})); Snd.sfx('herald')
	await s.move_to(g.player.x - 2.2, g.player.y, 7)
	await say('guardia', '¡Señor Cuadrado! Lo busco desde la Puerta Oeste. Falta el perito de vista y entra gente de las aldeas. El Prefecto dice que usted estudió en el Colegio.')
	var c = await choose([{t = 'Es mi deber. Vamos.', id = 'a'}, {t = '¿Y no pueden palparlos, sencillamente?', id = 'b'}])
	if c == 'b': await say('guardia', '¿Palpar a un Círculo de incógnito, señor? Me consumen esa misma tarde. No: hay que *verlos*. Y ver, ver… eso es cosa de ustedes.')
	await say('narr', 'Reconocer por la vista: el arte de mi clase. Me halagó que me llamaran. Eso también conviene que lo sepas.')
	s.ai = {type = 'path', pts = [Vector2(-66, 2.2)]}; s.speed = 6.0
	g.end_scene()
	await g.go_to(-64, 0, 2.5, 'Ve a la Puerta Oeste, al final de la calle')
	await outro()

# ============ CAP. III — LA PUERTA OESTE ============
func ch3() -> void:
	g.set_map(town()); g.spawn_player(-64, 0, PI); g.world.rain = 0.0; town_folk()
	var W := g.world
	g.add(F_iso('guardia', -66, 2.4, 16, {name = 'el sargento', rot = -1.0}))
	# un Polígono del Colegio practica a escondidas en la Puerta (marginalia)
	g.add(F_hexa('practicante', -58, -7.5, {name = 'un estudiante del Colegio', rot = PI}))
	margins([['m_c3_registro', -67.4, 4.0], ['m_c3_poligono', -58.9, -6.3], ['m_c3_miliar', -80, -2.6]])
	await intro('Capítulo III', 'La Puerta Oeste', 'Donde se trabaja mirando, y se mira a quien no debía ser mirado.', 'flat')
	var og := await g.talk_begin('guardia', 'Preséntate al sargento, junto a la Puerta')
	await say('guardia', 'Aquí, señor: de cara a la Puerta. Vienen de uno en uno por el camino. Usted mira, dice qué son, y yo apunto.')
	await say('logica', 'Recuerda la lección. Hay niebla: lo lejano se apaga. Si la figura viene con un vértice hacia ti, sus lados huyen hacia atrás… y cuanto más agudo el ángulo, más deprisa se oscurecen los extremos.')
	g.learn('vista')
	await say('narr', 'Te dejo una ayuda de estudiante: bajo la línea verás una *traza* dorada. Es el brillo, dibujado como altura. Los quiebros de la traza son vértices; su pendiente, el ángulo.')
	ui.close_dlg()
	g.teleport(-64, 0, PI); g.view_lock = true; g.set_view('eye'); g.locked = true; W.fog = 2.7
	await g.wait(1.4)
	await narr('Primero, el ejemplo del manual: un Comerciante. Triángulo. Mira qué deprisa se le apagan los extremos.')
	await sight_round('tri', {options = [CLASSES[2]], text = 'Un Equilátero, vértice al frente. El centro brilla; los extremos caen *muy rápido* en la niebla.', verdict = func(_a): return 'Equilátero: lados que huyen deprisa. *Compara la lámina con la línea.*'})
	await narr('Y ahora un Médico: Pentágono. Los extremos se apagan con más pereza; los lados retroceden despacio.')
	await sight_round('penta', {options = [CLASSES[4]], text = 'Un Pentágono. La traza cae *suave*: lados que retroceden despacio.', verdict = func(_a): return 'Pentágono: caída suave. *Así discierne el ojo educado.*'})
	g.frag(6)
	await narr('Ya está. Ahora, de verdad. El sargento apunta. Hay cola: vienen de las aldeas para el fin de año.')
	# la cola de la Puerta (C3-01): ocho rondas en tres tandas: de vértice y quietas, girando, de incógnito
	var rounds := [{k = 'mujer'}, {k = 'cuad'}, {k = 'iso'}, {k = 'penta', spin = 0.6}, {k = 'hexa', spin = 0.8, arc = true}, {k = 'tri', spin = 0.4},
		{k = 'circ', cloak = true, options_extra = [BOW]}, {k = 'cuad', arc = true, options_extra = [BOW]}]
	var tips := {mujer = 'Un punto que tiembla, un destello: una Mujer de frente. *Lo más peligroso es lo que menos se ve.*', cuad = 'Ángulo recto: ni tan abrupto como el Triángulo ni tan suave como el Pentágono.', iso = 'Una cuña: casi un punto, y dos lados que se pierden al instante.', hexa = 'Muy poca caída; tres lados visibles si gira un poco.', circ = 'Sin quiebros: una curva de brillo perfecta, aunque la capa le apague el brillo. *Un Círculo. Inclínate.*', penta = 'Caída suave, y al girar enseña cinco quiebros.', tri = 'Lados que huyen deprisa, aunque gire.'}
	var hits := 0; var marks := []
	var expert := g.difficulty() == 'expert'
	for n in rounds.size():
		var R: Dictionary = rounds[n]
		var k: String = R.k
		if n == 3: await narr('Ahora vienen distraídos, girando sobre sí: unas veces enseñan un lado y otras un vértice. Espera el momento.')
		if n == 6: await narr('Y los últimos, con capa de viaje. Un Círculo de incógnito es lo peor que le puede pasar a un perito: si lo confundes, ofendes; si te inclinas ante quien no lo merece, haces el ridículo.')
		var o := R.duplicate(); o.erase('k')
		if n + 1 < rounds.size(): o.next = rounds[n + 1].k
		if expert: o.trace = false
		o.verdict = func(r):
			var ok: bool = (r is String and r == k) or (k == 'circ' and r is String and r == 'bow')
			return ('Cierto. ' if ok else 'No. ') + tips[k]
		var ans = await sight_round(k, o)
		var ok: bool = (ans is String and ans == k) or (k == 'circ' and ans is String and ans == 'bow')
		if ok: hits += 1
		marks.append(ok); ui.eye_tally(marks)
		if k == 'circ' and ans is String and ans == 'hexa':
			await say('circulo', '(La capa se abre: un brillo sin un solo quiebro.) «Hexágono», me ha llamado. Su nombre, perito.')
			g.note('gate_circle_offense', 2); ui.close_dlg()
		elif k != 'circ' and ans is String and ans == 'bow':
			await say('guardia', '(El sargento se ríe por lo bajo.) Que se ha inclinado usted ante un Cuadrado, señor. Lo apunto como cortesía.')
			ui.close_dlg()
	ui.eye_tally([])
	g.flag('aciertos', hits)
	g.set_view('top'); g.locked = false; W.fog = 13.0
	# la nota del sargento (C3-02)
	if hits == 8 and expert:
		await say('guardia', 'Ocho de ocho, y sin la traza de los estudiantes. Ni en el Colegio, señor.'); g.achieve('ACH_GATE_P')
	elif hits >= 6: await say('guardia', tr('%d de ocho, señor. Con ojos así, yo sería Hexágono.') % hits)
	elif hits >= 3: await say('guardia', tr('%d de ocho. No está mal, con esta niebla.') % hits)
	else: await say('guardia', tr('%d de ocho… Hoy la niebla está muy cerrada, señor. Lo apuntaré así.') % hits)
	if hits >= 6: g.rep('aut', 1)
	g.state.stats.gate_hits = hits
	await say('guardia', 'Viene uno más. Ése me lo conozco: el calderero de la esquina. Pero la orden es mirarlos a todos.')
	ui.close_dlg(); g.set_view('eye'); g.locked = true; W.fog = 2.7; W.remove('irregular'); await g.wait(1.2)
	var dict = await sight_round('irr', {keep = true, wobble = 0.5, reveal = false, split = 3.0, title = 'Reconocimiento por la vista', text = 'La traza no es simétrica. Un lado se apaga deprisa; el otro, despacio. *El sargento espera tu dictamen.*',
		options = [{id = 'tri', label = 'Equilátero', sub = 'declararlo Regular'}, {id = 'irr', label = 'Irregular', sub = 'decir lo que ves'}, {id = 'nose', label = 'No sabría decirlo', sub = 'callar'}]})
	g.set_view('top'); g.locked = false; W.fog = 13.0; g.flag('dictamen', dict)
	var ir := g.npc('_s'); W.focus = Vector2((ir.x + g.player.x) / 2.0, 0); W.zoom = 24
	await narr('Desde arriba se ve sin esfuerzo: tres lados, ninguno igual a otro. Cuarenta años afilando punzones en una esquina, con ese secreto a cuestas.')
	if dict == 'tri':
		await say('yo', 'Equilátero. Regular. Puede pasar.')
		await say('guardia', '¿Regular…? Con perdón, señor: ése camina torcido desde que lo conozco. Voy a palparlo, que para eso no hace falta Colegio.')
		await say('guardia', 'Cincuenta y uno. Setenta y cuatro. Y el otro… cincuenta y cinco. Señor perito: o la niebla le ha engañado, o me ha engañado usted.')
		g.rep('aut', -2); g.rep('ciu', 1); g.her(1)
		g.note('gate_false_regular', 3); g.rel('calderero', 1)
	elif dict == 'irr':
		await say('yo', 'Irregular. Los lados no casan.')
		await say('guardia', 'Lo que yo decía. Buen ojo, señor.')
		g.rep('aut', 1); g.her(-1); g.rel('calderero', -1)
	else:
		await say('yo', 'La niebla… no sabría decirlo.')
		await say('guardia', 'Pues lo palpo yo, que para eso no hace falta Colegio. Cincuenta y uno. Setenta y cuatro. Cincuenta y cinco. Irregular como una piedra.')
	await say('irregular', 'Señor… usted me conoce. Esta mañana le devolví su estilete. No he pinchado a nadie en mi vida.' if g.flag('amable') else 'Señor, por caridad. Cuarenta años en esa esquina. No he pinchado a nadie en mi vida.')
	var ins := g.add(F_penta('inspector', ir.x + 16, 1.5, {name = 'el Inspector'})); await ins.move_to(ir.x + 2.4, 1.2, 6)
	await say('inspector', 'Inspector de Configuración. ¿Desviación? … Veintitrés grados. Muy por encima del margen. Al Hospital: reconfiguración, si el marco aún cede. Si no, consumo indoloro.')
	await say('irregular', 'A mi edad el marco no cede, señor Inspector. Lo sabe usted.')
	var c = await choose([
		{t = 'Inspector: este hombre no ha hecho daño alguno. ¿No basta con vigilarlo?', id = 'd', tag = 'Cuestionar'},
		{t = 'La ley es dura, pero sin Regularidad no podríamos ni saludarnos.', id = 'o', tag = 'Obedecer'},
		{t = '(Mirar la niebla. No decir nada.)', id = 's', tag = 'Callar'}])
	g.flag('irregularChoice', c)
	if c == 'd':
		await say('inspector', '«No ha hecho daño.» ¿Y cómo lo sabría usted? Usted palpa un ángulo y deduce una persona. Con éste palpa uno y no sabe nada de los otros dos. Si toleramos eso, caballero, se acabó el tacto, la vista y la confianza. Me extraña tener que explicárselo a un Cuadrado.')
		await say('recelo', 'Ha apuntado algo en su tablilla. No era el ángulo del calderero.')
		g.rep('aut', -1); g.rep('sac', -1); g.her(1)
		g.note('gate_protest', 3); g.rel('calderero', 1)
	elif c == 'o':
		await say('inspector', 'Exacto. Da gusto oír a un hombre de sus ángulos.')
		await say('irregular', '(No te mira. Mira la calle, la esquina donde ya no estará.)')
		g.rep('sac', 1); g.her(-1); g.rel('calderero', -1)
	else:
		await say('inspector', 'Bien. Firme aquí como perito.')
		g.rel('calderero', -1)
		await say('decoro', 'Has firmado. Callar también tiene letra.')
	await say('narr', 'Entonces yo lo creía. Lo escribí, incluso: que el Irregular incurable debía ser *consumido sin dolor y con misericordia*. Me parecía una frase compasiva.')
	await say('narr', 'Recuerdo que aquel día protesté. O quiero recordarlo así: en una celda, la memoria es generosa con uno mismo.' if c == 'd' else 'Aquel día no protesté. Eso sí lo recuerdo con exactitud.')
	g.frag(7); g.learn('irregulares')
	ui.close_dlg(); W.focus = null; W.zoom = W.base_zoom
	# una segunda mirada al calderero (C3-04): si fuiste amable con él, al pasar deja caer tu estilete
	var drop: bool = g.rel_of('calderero') >= 1 and g.flag('amable') != null
	if drop:
		var p := g.player
		await ir.move_to(p.x + 1.2, p.y - 1.0, 2.0)
		Snd.sfx('chalk')
		W.add_spot({id = 'estilete', x = p.x + 0.9, y = p.y - 0.6, label = 'un estilete'})
	var go1 := func():
		await ir.move_to(ir.x + 30, 1.5, 3)
		W.remove('_s')
	var go2 := func():
		await ins.move_to(ir.x + 33, 1.2, 3)
		W.remove('inspector')
	go1.call(); go2.call()
	await g.wait(2.5)
	g.talk_end(og)
	if drop:
		await g.talk_begin('estilete', 'Recoge lo que ha dejado caer', 'Recoger')
		g.state.inv.estilete = 1; g.save(); Snd.sfx('pick')
		W.remove_spot('estilete')
		await say('narr', 'Mi estilete. El que me había devuelto por la mañana. Lo dejó caer sin mirarme, como quien devuelve algo dos veces porque la primera no contó.')
		ui.toast('', 'Llevas', 'El estilete del calderero')
		g.talk_end(null)
	await narr('Se lo llevaron calle arriba, hacia el Hospital de Reconfiguración. Yo volví a casa. Llegaba tarde a cenar.')
	# volver a casa sin lámina (C3-05): anochece y la niebla se cierra
	await ui.fade(true, 0.6)
	W.set_palette('flat_night'); W.rain = 0.0; g.teleport(-64, 0, 0.0)
	await ui.fade(false, 0.8)
	await say('decoro', 'Anochece. Un caballero no camina por la calle con la mirada en otra Dimensión. Cierra la lámina y vuelve como volvía yo: a tientas.')
	await say('logica', 'Tu casa está al Nordeste, por la Calle Mayor. Tienes la lluvia, el tirón del Sur y las voces. Y la Puerta del Este de tu casa: allí te esperará alguien.')
	ui.close_dlg()
	var r: Dictionary = await Orient.run(self, {to = Vector2(-41, 13.3), r = 2.4, wife = Vector2(-18.0, 13.3)})
	if not r.helped: g.achieve('ACH_HOME')
	g.state.stats.orient_s = r.time
	await _late_supper()
	await outro()

# C3-06 · la cena tarde: la esposa, la cena fría y el nieto despierto
func _late_supper() -> void:
	var W := g.world
	await ui.fade(true, 0.5)
	ui.note('', 0.01)
	for id in W.ents.keys():
		if id != 'yo': W.remove(id)
	g.teleport(-29.5, 16.5, 0.0)
	g.add(F_mujer('esposa', -26.0, 17.2, {name = 'tu esposa', rot = PI}))
	g.add(F_hexa('nieto', -27.8, 14.8, {name = 'tu nieto menor', r = 0.6, rot = 2.4}))
	g.set_view('top'); W.focus = Vector2(-27.8, 16.2); W.zoom = 22
	await ui.fade(false, 0.6)
	g.begin_scene()
	await say('esposa', 'La cena está fría. Te he guardado un sitio del lado de los varones, como siempre.')
	await say('nieto', '¿Qué has hecho hoy, abuelo?')
	var c = await choose([{t = 'He mirado a la gente, en la Puerta. Y han consumido a un calderero que conocía.', id = 't', tag = 'La verdad'}, {t = 'Nada. Trabajo de perito. A dormir.', id = 's', tag = 'Callar'}])
	if c == 't':
		await say('nieto', '¿Al de la esquina? ¿Porque era irregular?')
		await say('nieto', '¿Y si el calderero viera con otros ojos, abuelo? ¿Y si desde algún sitio se le viera regular?')
		await say('narr', 'Le mandé a la cama. Esa noche no pude dormir, y no por el calderero. Por la pregunta.')
		g.rel('nieto', 1)
	else:
		await say('nieto', 'Siempre dices «nada». Un día te voy a palpar para saber qué has hecho.')
		await say('narr', 'Se rió, y su madre se lo llevó. Yo cené frío, solo, del lado de los varones.')
	ui.close_dlg()
	W.focus = null; W.zoom = W.base_zoom
	g.end_scene()

# minijuegos sueltos (main.gd --try=…), sobre la ciudad
func try_mini(name: String) -> void:
	g.set_map(town()); town_folk(); ui.hud.visible = true; ui.chapter_tag('Prueba · ' + name)
	match name:
		'cross':
			g.spawn_player(6, -9.5, PI / 2); g.add(F_tri('mercader', 6, 9.6, {name = 'un comerciante', rot = -PI / 2}))
			print(await CrossStreet.run(self, {from = Vector2(6, -9.5), to = Rect2(1, 6.6, 10, 2.6)}))
		'voices':
			g.spawn_player(26, -5.5, 0.0); g.begin_scene()
			print(await Voices.run(self, Vector2(26, -5.5)))
		'orient':
			g.spawn_player(-64, 0, 0.0); g.world.set_palette('flat_night')
			print(await Orient.run(self, {to = Vector2(-41, 13.3), r = 2.4, wife = Vector2(-18.0, 13.3)}))
		'rain':
			g.spawn_player(-41, 13.3, 0.0); g.world.rain = 1.0; g.world.rain_cur = 1.0
			await _rain_north()
		'angles':
			g.spawn_player(-34, 11, 0.0); g.begin_scene()
			print(await _angle_game())
		'count':
			g.set_map(town()); g.spawn_player(-23, 9, 0.0)
			g.add(F_mujer('esposa', -20.2, 17.0, {name = 'tu esposa', cry = true, cryRange = 8.0}))
			g.add(F_mujer('hija', -21.8, 9, {name = 'tu hija', r = 0.8, sway = 1.4})); g.begin_scene()
			await _count_game()
