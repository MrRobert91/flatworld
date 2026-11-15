# Capítulos VIII–X: Espaciolandia, Puntolandia, el nieto, el juicio y la celda.
class_name ChD extends Ch

func _anger(sph: MeshInstance3D, v: float) -> void:
	(sph.material_override as ShaderMaterial).set_shader_parameter('anger', v)

# ============ CAP. VIII — ESPACIOLANDIA ============
func ch8() -> void:
	var map := town({palace = true}); g.set_map(map)   # la misma lámina de Planilandia, vista desde Arriba
	var W := g.world
	for b in map.buildings: W.known[b.id] = true
	W.rebuild()
	g.spawn_player(-27.6, 12, -PI / 2); var p := g.player
	# la casa dormida
	g.add(F_mujer('esposa', -28, 10, {ai = {type = 'wander', home = Vector2(-28, 10.5), r = 2.6}, speed = 2.4}))
	var hj := [[-35, 13], [-34.6, 10.6], [-33.2, 16.5], [-36, 15.6]]
	for i in 4: g.add(F_penta('hj%d' % i, hj[i][0], hj[i][1], {rot = float(i)}))
	g.add(F_hexa('n1', -33.6, 8.5, {r = 0.6})); g.add(F_hexa('n2', -32.6, 9.8, {r = 0.66, rot = 1.0}))
	g.add(F_mujer('hija', -22.4, 8.8, {r = 0.8, sway = 0.0})); g.add(F_iso('cr1', -21, 15.5, 10)); g.add(F_tri('cr2', -21.6, 11.4, {r = 0.6}))
	# el Consejo
	g.add(F_circ('presidente', -14, -33.5, {r = 1.5, rot = PI / 2}))
	var cons := []
	var cx := [-22, -19, -9, -6]
	for i in 4: cons.append(g.add(F_circ('co%d' % i, cx[i], -30 + absf(cx[i] + 14) * 0.35, {rot = PI / 2})))
	cons.append(g.add(F_poli('co4', -21, -24, 14, {rot = 0.0}))); cons.append(g.add(F_poli('co5', -7, -24, 16, {rot = PI})))
	var bro := g.add(F_cuad('hermano', -10.5, -28.5, {name = 'tu hermano', rot = 2.4}))
	var gu := []
	var gq := [[-17, -15.5], [-11, -15.5], [-19, -18], [-9, -18]]
	for i in 4: gu.append(g.add(F_iso('gu%d' % i, gq[i][0], gq[i][1], 14, {rot = -PI / 2})))
	var street := [F_mujer('dama', -10, 1), F_iso('obrero', 4, 1), F_penta('medico', 18, 1)]
	for i in 3:
		street[i].ai = {type = 'wander', home = Vector2(-10 + i * 14, 0), r = 4.0}; street[i].speed = 1.5; g.add(street[i])
	var sph := Space.make_sphere(); var bd := Space.backdrop(false); W.add_child(sph); W.add_child(bd)
	g.actors['esfera'] = sph
	var st := {free = true, time = 0.0}
	var stop_space := g.tick(func(dt):
		st.time += dt
		var spin: Array = bd.get_meta('spin')
		for i in spin.size(): spin[i].rotation.x += dt * 0.07 * (1 + i % 3); spin[i].rotation.y += dt * 0.1
		if st.free:
			var y: float = W.free.yaw
			sph.position = sph.position.lerp(Vector3(p.x + cos(y) * 4.5, p.alt + 1.2 + sin(st.time) * 0.3, -p.y - sin(y) * 4.5 - 1), minf(1.0, dt * 3.0)))
	g.show_strip = false; g.view_lock = true; W.cam_mode = 'free'; W.free = {yaw = 0.0, pitch = 0.5, dist = 26.0}; p.alt = 0.4; p.no_collide = true; g.alt_min = 0.4; g.alt_max = 0.4
	ui.chapter_tag('Capítulo VIII · Espaciolandia'); Snd.drone('space')
	await narr('Un horror indecible. Oscuridad. Luego una sensación mareante de una vista que no era ver: vi una Línea que no era Línea; un Espacio que no era Espacio. Yo era yo y no lo era.', true)
	await narr('Grité: «¡Esto es la locura, o es el Infierno!»', true)
	await ui.title('Capítulo VIII', 'Espaciolandia', '«Ni lo uno ni lo otro. Es el Conocimiento; son las Tres Dimensiones. Abre el ojo de nuevo y procura mirar con firmeza.»', 4.0)
	W.show_guts = true
	for e in W.ents.values(): e.guts.visible = true
	ui.fade(false, 2.0)
	await g.tween(5, func(t):
		var k := App.ease(t)
		p.alt = 0.4 + k * 13; W.free.pitch = 0.5 + k * 0.55; W.free.dist = 26 + k * 12; W.free.yaw = 0.0)
	g.alt_min = 4; g.alt_max = 20
	g.begin_scene()
	await say('esfera', 'Mira. No con el borde de tu ojo: con todo él. Lo que hay debajo de ti es tu mundo. Entero.')
	await say('asombro', 'Tu casa. No su raya: *su forma*. Los cinco lados a la vez. Y dentro de ella, sin pared que lo impida, todo.')
	await say('narr', 'Y vi a la Esfera. No una rebanada: él. Lo que yo había tomado por un Círculo era una cosa con un *dentro* que no se veía y un *fuera* por todas partes. Era hermoso de un modo para el que aún no tengo palabra.')
	g.end_scene()
	ui.note(tx('Arrastra el ratón para mirar alrededor · WASD para volar · R / F para subir y bajar · rueda: acercar', 'Palanca para volar · arrastra por la derecha para mirar · botones para subir y bajar · pellizca para acercar'), 14)
	await g.go_to(-28, 17, 6, 'Vuela sobre tu casa y mírala por dentro')
	g.begin_scene()
	await say('yo', 'Mis hijos, dormidos en sus cuartos del Oeste. Mis dos nietos. Mi hija. Los criados. Y… veo dentro de *ellos*. Sus entrañas. Les late algo.')
	await say('esfera', 'Desde Arriba no hay dentro que se esconda. Así vi yo tu alacena. Así te toqué el estómago.')
	await say('yo', 'Y mi esposa. Recorre el salón de punta a punta. Me busca.')
	await say('logica', 'Para ella has desaparecido sin cruzar ninguna puerta. Como el Forastero. Como tú ante el Rey de la Línea.')
	await say('esfera', 'Ven. Hay algo que debes oír. Es la primera hora del primer día del año 2000, y el Alto Consejo de tu país está reunido, como lo estuvo hace mil años, y hace dos mil.')
	g.end_scene()
	await g.go_to(-14, -24, 6.5, 'Vuela hacia el sur: la Sala del Consejo, en el Palacio')
	g.begin_scene()
	g.tween(2.5, func(t): p.x = lerpf(p.x, -14, t * 0.2); p.y = lerpf(p.y, -20, t * 0.2); p.alt = lerpf(p.alt, 11, t * 0.2); W.free.dist = lerpf(W.free.dist, 30, t * 0.2))
	await say('yo', '¡Mi hermano! Es el Escribano Mayor del Consejo. Está leyendo.')
	await say('hermano', '«…considerando que cada milenio han turbado a los Estados gentes mal intencionadas que pretenden haber recibido revelaciones de Otro Mundo…»')
	await say('hermano', '«…se resuelve: que en el primer día de cada milenio los Prefectos busquen a tales extraviados; que se destruya sin examen al que sea Isósceles; se azote y encarcele al Equilátero; se envíe al Manicomio al Cuadrado o Pentágono; y se arreste a cualquiera de rango superior.»')
	await say('esfera', 'Ya oyes tu destino. Y, sin embargo, voy a decírselo a ellos también. Mira cómo me ven.')
	st.free = false; Snd.sfx('sphere')
	var sec := g.add(F_circ('secc', -14, -25.5, {r = 1.7, tint = Color('9fe8e0'), noGuts = true, noCollide = true})); sec.sc = 0.001
	var from := sph.position
	var section := func():
		var h := sph.position.y
		sec.sc = maxf(0.001, sqrt(1.0 - pow(h / 1.7, 2))) if absf(h) < 1.7 else 0.001
	await g.tween(3.2, func(t):
		var k := App.ease(t)
		sph.position = Vector3(lerpf(from.x, -14, k), lerpf(from.y, 0, k), lerpf(from.z, 25.5, k)); section.call())
	await say('esfera', '¡Consejeros de Planilandia! Vengo a proclamar que existe una tierra de Tres Dimensiones.')
	for c in cons: c.move_to(c.x + (c.x + 14) * 0.25, c.y + (c.y + 25.5) * 0.2, 4)
	await say('narr', 'Desde arriba vi lo que ellos veían: un Círculo surgido de la nada en mitad de la sala. Los consejeros jóvenes retrocedieron. El Presidente no se movió.')
	await say('presidente', 'Guardias.')
	for i in 4: gu[i].move_to(-14 + cos(i * 1.57) * 2.2, -25.5 + sin(i * 1.57) * 2.2, 9)
	Snd.sfx('herald')
	await g.tween(1.6, func(t): sph.position.y = App.ease(t) * 9; section.call())
	W.remove('secc'); st.free = true
	await say('presidente', 'Ha vuelto a ocurrir, como en el año mil y en el año cero. No ha ocurrido nada. Los guardias que lo han visto serán destruidos. El Escribano, que también lo ha visto, y cuyo rango impide destruirlo: prisión perpetua.')
	Snd.sfx('gavel')
	for i in 4:
		var s: Ent = gu[i]
		g.after(0.4 + i * 0.3, func(): s.hid = true)
	var esc := [g.add(F_iso('e1', -14, -13, 3, {rot = -1.57})), g.add(F_iso('e2', -13, -13, 3, {rot = -1.57}))]
	for i in 2: esc[i].move_to(bro.x + (1.6 if i else -1.6), bro.y + 0.5, 8)
	await say('hermano', 'Excelencia… yo sólo leía el acta.')
	var c = await choose([{t = '¡Hermano! ¡Déjame bajar, Esfera! Yo se lo explicaré al Consejo.', id = 'a'}, {t = '(Mirar. Como miraste en la Puerta.)', id = 'b'}])
	if c == 'a': await say('esfera', 'No. Nada que digas hoy lo salvaría, y a ti te perdería. Tu misión no es morir en esa sala.')
	else: await say('recelo', 'Esta vez no hay sargento que apunte tu silencio. Sólo tú.')
	var bro_go := func():
		await bro.move_to(-14, -13.5, 2.5)
		bro.hid = true
	bro_go.call()
	for s in esc: s.ai = {type = 'follow', target = 'hermano', dist = 1.6, speed = 3.0}
	await say('narr', 'Mi hermano. El mejor de los Cuadrados: justo, sensato, alegre. Condenado por haber visto.')
	g.frag(18)
	await say('esfera', 'Sube conmigo. Más alto. Te enseñaré de qué estás hecho, y de qué estoy hecho yo.')
	g.end_scene()
	g.alt_max = 44; g.objective(tx('Asciende (mantén R) hasta dejar la ciudad muy abajo', 'Asciende (mantén el botón de subir) hasta dejar la ciudad muy abajo'), null)
	await g.until(func(): return p.alt > 32, func(): p.alt = 34.0)
	g.objective('', null); g.alt_min = 30
	# --- los Sólidos ---
	var cube := Space.make_cube(); W.add_child(cube)
	var cm: ShaderMaterial = cube.material_override
	cm.set_shader_parameter('col', Vector3(0.98, 0.96, 0.89)); cm.set_shader_parameter('edge_col', World._v3(W.pal.edge))
	var L := 4.0; cube.scale = Vector3(0.08, 0.08, 0.08)
	g.begin_scene()
	cube.position = Vector3(p.x, p.alt + 0.5, -p.y - 9); W.free.yaw = 0.0; W.free.pitch = 0.35; W.free.dist = 24.0
	await say('esfera', 'Aquí tienes un Punto.')
	await g.tween(2, func(t): cube.scale = Vector3(lerpf(0.08, L, App.ease(t)), 0.08, 0.08))
	Snd.sfx('know')
	await say('esfera', 'Lo muevo: una Línea. Dos puntos terminales.')
	await g.tween(2, func(t): cube.scale = Vector3(L, 0.08, lerpf(0.08, L, App.ease(t))))
	Snd.sfx('know')
	await say('esfera', 'La muevo paralela a sí misma: un Cuadrado. Cuatro puntos terminales. Eres tú.')
	await say('esfera', 'Y ahora lo muevo en la dirección que tu nieto intuyó y tú mandaste a la cama. Hacia Arriba.')
	Snd.sfx('sphere')
	var base_y := p.alt + 0.5
	await g.tween(3, func(t): cube.scale = Vector3(L, lerpf(0.08, L, App.ease(t)), L); cube.position.y = base_y + L / 2 * App.ease(t))
	await say('yo', 'Ocho puntos terminales. Seis lados, y cada uno es… un Cuadrado. Tres pulgadas en todos los sentidos. *Tres al cubo.*')
	var stop_spin := g.tick(func(dt): cube.rotation.y += dt * 0.5; cube.rotation.x += dt * 0.23)
	await say('logica', 'Fíjate en cómo lo ves: unas caras más claras, otras más oscuras. Luz y sombra. Así se ve la profundidad desde fuera, igual que tú leías los ángulos en la niebla.')
	g.learn('solidos'); g.learn('altura')
	await say('narr', 'Lo adoré. No hay otra palabra. Le llamé Maestro, y lo era.')
	# --- la Cuarta ---
	await say('yo', 'Maestro: me habéis mostrado las entrañas de mis compatriotas desde la tierra de Tres Dimensiones. Llevadme ahora a la de Cuatro.')
	await say('esfera', '¿Qué dices?')
	c = await choose([{t = 'Desde allí miraríamos este Espacio y veríamos el interior de todo Sólido. Vuestras propias entrañas.', id = 'a'}, {t = '(Callar. Has visto bastante.)', id = 's'}])
	if c == 's': await say('narr', 'Pude callar. Había visto más que nadie en mil años. No callé: un Cuadrado que ha contado hasta tres quiere contar hasta cuatro.')
	await say('esfera', 'No existe tal tierra. La sola idea es inconcebible.')
	_anger(sph, 0.2)
	# teseracto imaginado
	var tess := Space.make_lines(W.ink(Color('b79cf0'))); W.add_child(tess)
	var V := []; var E := []
	for i in 16: V.append([1.0 if i & 1 else -1.0, 1.0 if i & 2 else -1.0, 1.0 if i & 4 else -1.0, 1.0 if i & 8 else -1.0])
	for i in 16:
		for b in 4:
			if not (i & (1 << b)): E.append([i, i | (1 << b)])
	var ts := {a = 0.0, sc = 0.01}
	var cpos := cube.position
	var stop_tess := g.tick(func(dt):
		ts.a += dt * 0.6
		var ca := cos(ts.a); var sa := sin(ts.a); var cb := cos(ts.a * 0.6); var sb := sin(ts.a * 0.6)
		var im: ImmediateMesh = tess.mesh
		im.clear_surfaces(); im.surface_begin(Mesh.PRIMITIVE_LINES)
		for e in E:
			for vi in e:
				var v: Array = V[vi]
				var x: float = v[0] * ca - v[3] * sa; var w: float = v[0] * sa + v[3] * ca
				var y: float = v[1] * cb - v[2] * sb; var z: float = v[1] * sb + v[2] * cb
				var k: float = 2.6 / (3.2 - w) * ts.sc * 2.6
				im.surface_add_vertex(cpos + Vector3(x, y, z) * k)
		im.surface_end())
	await say('yo', 'Vuestra propia Analogía, Maestro. Punto, Línea, Cuadrado, Cubo: uno, dos, cuatro, ocho puntos terminales. ¿Qué sigue?')
	c = await choose([{t = 'Dieciséis.', id = 16}, {t = 'Diez.', id = 10}, {t = 'Doce.', id = 12}])
	Snd.sfx('her')
	var held := {cube = cube}   # el Cubo puede borrarse antes de que acabe esta animación suelta
	g.tween(4, func(t):
		ts.sc = App.ease(t)
		if is_instance_valid(held.cube): cm.set_shader_parameter('dim', 1.0 - t * 0.6); held.cube.scale = Vector3.ONE * L * (1.0 - 0.45 * App.ease(t)))
	await say('yo', 'Dieciséis. Y sus límites: dos Puntos, cuatro Líneas, seis Cuadrados… *ocho Cubos*. Un Cubo movido en una dirección nueva. ¡Casi lo veo!' if c == 16 else 'No… el doble cada vez: *dieciséis*. Y sus límites: dos Puntos, cuatro Líneas, seis Cuadrados… ocho Cubos. ¡Casi lo veo!')
	g.learn('cuarta')
	await say('asombro', 'Eso que gira ahí no está en el Espacio. Está en ti. Es la sombra de una sombra, y es lo más grande que has pensado nunca.')
	_anger(sph, 0.45)
	await say('esfera', 'Basta. Son fantasías. Analogías sin objeto.')
	c = await choose([{t = '¿No es cierto que en vuestro país se han visto Seres entrar en cuartos cerrados, como vos en el mío?', id = 'a'}, {t = '(Ceder.) Perdonad, Maestro.', id = 's'}])
	if c == 's': await say('narr', 'No cedí. Tú has elegido la prudencia dos veces y yo te he desmentido dos veces: así fue. No sabía parar.')
	await say('esfera', '…Se cuenta. Visiones. Cosas del cerebro de quien las ve. Nadie las cree.')
	await say('logica', '«Un truco de mago.» «Visiones del cerebro.» El Rey, tú, la Esfera. Cada mundo tiene su frase para lo que le queda por encima.')
	_anger(sph, 0.75); g.her(1)
	await say('yo', '¡Entonces existe! ¡Y más allá, la Quinta, la Sexta, la Séptima Dimensión! ¡Llevadme! ¡Hacia Arriba de Arriba!')
	_anger(sph, 1.0); Snd.sfx('gavel'); Input.vibrate_handheld(200)
	await say('esfera', '¡SILENCIO!')
	g.frag(19); ui.close_dlg(); stop_tess.call(); stop_spin.call(); tess.queue_free(); cube.queue_free()
	Snd.sfx('fall'); g.alt_min = 0; ui.fade(true, 1.9)
	await g.tween(2.0, func(t): p.alt = lerpf(34, 0.2, t * t); p.rot += 0.3; W.free.pitch = lerpf(0.35, 1.2, t))
	g.end_scene()
	stop_space.call(); sph.queue_free(); bd.queue_free()
	W.cam_mode = 'follow'; g.show_strip = true; g.view_lock = false; W.show_guts = false; W.known = {home = true, school = W.known.get('school', false), temple = true}
	await narr('Un estrépito. Y me hallé de nuevo en mi estudio, en el Plano, oyendo acercarse el Grito de Paz de mi esposa.', true)

# ============ CAP. IX — PUNTOLANDIA Y EL NIETO ============
func ch9() -> void:
	# --- visión: Puntolandia ---
	g.set_map({bounds = {x0 = -40, y0 = -40, x1 = 40, y1 = 40}, palette = 'space', fog = 10.0})
	var W := g.world; g.spawn_player(8, -8, 2.3); var p := g.player; W.ground.visible = false
	var pt := Space.make_point(); pt.scale = Vector3.ONE * 1.6; W.add_child(pt)
	var sph := Space.make_sphere(); W.add_child(sph)
	g.actors['esfera'] = sph; g.actors['punto'] = pt
	var st := {time = 0.0, hum = 0.0}
	var stop := g.tick(func(dt):
		st.time += dt
		sph.position = sph.position.lerp(Vector3(p.x + 3.5, p.alt + 1, -p.y - 3), minf(1.0, dt * 3.0))
		pt.scale = Vector3.ONE * (1.5 + 0.25 * sin(st.time * 6))
		st.hum -= dt
		if st.hum < 0:
			st.hum = 1.4
			var d := Vector3(p.x, p.y, p.alt).length()
			if d < 22: Snd.tone(880, 0.5, 'sine', snappedf(0.05 * (1 - d / 22), 0.01) + 0.005))
	g.show_strip = false; g.view_lock = true; W.cam_mode = 'free'; W.free = {yaw = 0.0, pitch = 0.3, dist = 16.0}; p.alt = 5; p.no_collide = true; g.alt_min = 1; g.alt_max = 14
	ui.chapter_tag('Capítulo IX · Hacia Arriba, no hacia el Norte'); Snd.drone('dream')
	ui.fade(false, 0.5)
	await ui.title('Capítulo IX', 'Hacia Arriba, no hacia el Norte', 'Donde se visita el reino más pequeño y más feliz, y se pierde a un discípulo.')
	await narr('Aquella noche soñé. La Esfera estaba otra vez a mi lado, y su brillo ya no mostraba enojo. «Te he tratado con dureza», dijo. «Ven: te debo una última lección.»', true)
	await g.go_to(0, 0, 4.5, 'Acércate a esa luz diminuta')
	g.begin_scene()
	await say('esfera', 'Contempla Puntolandia: el Abismo de Ninguna Dimensión. Esa criatura es un Ser como nosotros, pero no conoce largo, ni ancho, ni alto. No conoce siquiera el número Dos. Él es su Mundo, su Universo. Escúchalo.')
	await say('punto', '¡Infinita beatitud de la existencia! Ello es; y nada hay fuera de Ello.')
	await say('punto', 'Ello llena todo el Espacio, y lo que llena, lo es. Lo que piensa, lo dice; lo que dice, lo oye; Ello es Pensador, Palabra y Oyente; el Uno, y sin embargo el Todo en Todo. ¡Ah, la dicha de Ser!')
	var all_o := [{t = '¡Calla, criatura! No eres el Todo: eres la Nada. Un punto.', id = 'a'}, {t = 'Escucha: hay otros. Hay líneas, planos, sólidos. Yo vengo de fuera de ti.', id = 'b'}, {t = 'Hola. ¿Me oyes?', id = 'c'}]
	for n in 2:
		var c = await choose(all_o.slice(1, 3) if n else all_o.slice(0, 2))
		if c == 'a': await say('punto', '¡Ah, el gozo, el gozo del Pensamiento! ¿Qué no alcanzará Ello pensando? Su propio Pensamiento viene a Ello sugiriéndole su menosprecio, para realzar con ello su dicha. ¡Dulce rebelión que acaba en triunfo!')
		if c == 'b': await say('punto', '«Otros.» «Fuera.» ¡Qué fecunda es la mente de Ello, que inventa palabras sin objeto para deleitarse en su propia unidad! ¡Ah, el poder creador del Todo en Uno!')
		if c == 'c': await say('punto', '«¿Me oyes?», se pregunta Ello a sí mismo, pues no hay otro a quien preguntar. Y se responde: sí. ¡Ah, la dicha de la conversación perfecta!')
	await say('esfera', 'Ya ves lo poco que logran tus palabras. Todo lo que oye, cree haberlo pensado él. Nada que tú o yo hagamos lo sacará de su contento.')
	await say('esfera', 'Aprende esto: estar satisfecho de uno mismo es ser vil e ignorante. Aspirar es mejor que ser ciega e impotentemente feliz.')
	var c2 = await choose([{t = 'El Punto, el Rey de la Línea… ¿y yo, ante vos? ¿Y vos, ante la Cuarta?', id = 'h', tag = 'Atreverse'}, {t = 'Lo he comprendido, Maestro.', id = 'o'}])
	if c2 == 'h': await say('esfera', '…Vuelve a tu mundo. Enseña lo que has visto. Y sí: quizá por eso te elegí a ti y no a un Círculo.'); g.her(1)
	else: await say('esfera', 'Vuelve a tu mundo. Enseña lo que has visto. No esperes que te lo agradezcan.')
	g.frag(20); g.learn('punto')
	g.end_scene()
	await a.outro()
	stop.call(); pt.queue_free(); sph.queue_free(); W.ground.visible = true; W.cam_mode = 'follow'

	# --- despertar ---
	g.set_map(town()); g.spawn_player(-28, 22.5, -PI / 2); g.show_strip = true; g.view_lock = false; W.rain = 0.2
	g.add(F_mujer('esposa', -26, 12, {name = 'tu esposa', rot = 2.0}))
	var kid := g.add(F_hexa('nieto', -34.3, 11.6, {name = 'tu nieto menor', r = 0.6}))
	g.add(F_penta('hijo', -33, 13.5, {name = 'tu hijo mayor', rot = -1.0}))
	g.add(F_tri('heraldo', -60, 1.5, {name = 'un heraldo', ai = {type = 'path', pts = [Vector2(-20, 1.5), Vector2(-60, 1.5)]}, speed = 2.5}))
	ui.chapter_tag('Capítulo IX · Hacia Arriba, no hacia el Norte'); Snd.drone('home'); await ui.fade(false)
	await narr('Desperté gozoso. Iba a evangelizar a toda Planilandia, de las mujeres a los Círculos. Empezaría por mi esposa.')
	g.begin_scene()
	Snd.sfx('herald')
	await say('heraldo', '(En la calle.) ¡Oíd, oíd! ¡Resolución del Alto Consejo! Todo aquel que pervierta las mentes del pueblo con delirios, pretendiendo revelaciones de Otro Mundo, será arrestado, encarcelado o ejecutado, según su número de lados.')
	await say('recelo', 'Lo oíste leer anoche, desde arriba, de boca de tu hermano. Ahora suena distinto: suena desde tu altura.')
	g.end_scene()
	var f_hijo := func():
		await say('hijo', 'Buenos días, padre. ¿Ha oído el pregón? Ya era hora. La semana pasada un Triángulo decía en mi consulta que oía voces de «fuera». Lo denuncié, naturalmente.')
		await say('narr', 'Mis hijos. Pentágonos de carácter y posición. Me habrían entregado al Prefecto con lágrimas sinceras.')
	g.on('hijo', 'Hablar', f_hijo)
	var o := await g.talk_begin('esposa', 'Habla con tu esposa')
	await say('esposa', '¡Esposo! Anoche desapareciste. Te busqué por toda la casa. ¿Dónde estabas?')
	var c = await choose([{t = 'Fuera del Plano, querida. Arriba. He visto nuestra casa por dentro, toda a la vez.', id = 'h', tag = 'La verdad'}, {t = 'Me caí por la trampilla del sótano y quedé sin sentido.', id = 'o', tag = 'La mentira'}])
	if c == 'h': await say('narr', 'Estuve a un grano de arena de decírselo. El heraldo volvió a pasar bajo el muro. Dije: «Me caí por la trampilla del sótano».'); g.her(1)
	await say('esposa', 'Pero, esposo… nuestra casa no tiene sótano.')
	await say('esposa', 'Tienes fiebre. Acuéstate. Y no hables así delante de los chicos.')
	await say('logica', 'Ella no sabe leer ni contar. La ley se ocupó de eso. Tus hijos sí saben, y no preguntan. Te queda uno: el que preguntó por 3³.')
	g.talk_end(o)
	var mov := g.add(F_cuad('movil', -33.4, 9.6, {name = 'un cuadrado móvil', r = 0.42, noEye = true, noGuts = true}))
	o = await g.talk_begin('nieto', 'Enséñale a tu nieto lo que has visto')
	await say('yo', 'Ven, pequeño. Cierra la puerta. ¿Recuerdas lo que dijiste de 3³? Tenías razón. Mira este cuadrado. Vamos a moverlo, no hacia el Norte, sino hacia Arriba.')
	ui.close_dlg()
	ui.panel_info('La lección', tx('Mueve el cuadrado hacia Arriba. *(WASD / flechas)*', 'Mueve el cuadrado hacia Arriba. *(usa la palanca)*'))
	if not (g.auto or g.bot):
		var L := {tried = {}, tm = 0.0, said = 0.0}
		g.need_stick = true; g.need_act = 'Arriba'
		var dirs := [['N', 0, 1, 'Eso es el Norte.'], ['S', 0, -1, 'Eso es el Sur.'], ['E', 1, 0, 'Eso es el Este.'], ['O', -1, 0, 'Eso es el Oeste.']]
		await g.tick_until(func(dt) -> bool:
			L.tm += dt
			var ax := g.axis()
			for d in dirs:
				if ax.dot(Vector2(d[1], d[2])) > 0.5:
					mov.x = clampf(mov.x + d[1] * 3 * dt, -34.6, -32.3); mov.y = clampf(mov.y + d[2] * 3 * dt, 8, 11.5)
					if not L.tried.has(d[0]):
						L.tried[d[0]] = 1; ui.note('*Tu nieto:* «%s»' % d[3], 3); Snd.blip('nino')
			if g.other_held() and L.tm - L.said > 2:
				L.said = L.tm; ui.note(tx('*No ocurre nada. No hay tecla para lo que quieres decir.*', '*No ocurre nada. No hay botón para lo que quieres decir.*'), 3); Snd.sfx('bad')
			return L.tried.size() >= 3 or L.tm > 16)
		g.need_stick = false; g.need_act = ''
	ui.panel_info(null); await g.wait(1.2)
	Snd.sfx('herald')
	await say('heraldo', '(En la calle, otra vez.) …¡arrestado, encarcelado o ejecutado!')
	await say('nieto', 'Abuelito… lo de 3³ era sólo una broma. Claro que no quería decir nada. Y entonces no sabíamos nada de la Ley nueva. Y yo no dije nada de la Tercera Dimensión.')
	await say('nieto', 'Y seguro que no dije ni una palabra de «hacia Arriba, no hacia el Norte», porque sería una tontería. ¿Cómo va a moverse una cosa hacia Arriba y no hacia el Norte? Ni un bebé sería tan bobo. ¡Ja, ja, ja!')
	c = await choose([{t = '¡No es ninguna bobada! Mira: lo muevo… no así, sino… ¡de algún modo!', id = 'a'}, {t = '(Soltar el cuadrado.) Tienes razón. Era una broma.', id = 's'}])
	if c == 'a':
		await g.tween(1.5, func(t): mov.x = -33.4 + sin(t * 30) * 0.5; mov.y = 9.6 + cos(t * 23) * 0.5; mov.rot += 0.3)
		await say('narr', 'Agité aquel cuadrado como un loco, sin propósito alguno. El niño se reía cada vez más alto, para que se oyera desde la calle.')
	else: await say('narr', 'No lo solté. Lo agité como un loco, sin propósito alguno, mientras el niño se reía cada vez más alto, para que se oyera desde la calle.')
	await say('nieto', '¡El abuelo no me está enseñando, está jugando conmigo!')
	var flee := func():
		await kid.move_to(-36.8, 12.8, 6)
		await kid.move_to(-44, 13, 6)
		kid.hid = true
	flee.call()
	await say('narr', 'Abrió la puerta y huyó. Diez años, y ya sabía lo que yo iba a tardar un año entero en olvidar: cuándo conviene reírse.')
	g.frag(21)
	g.talk_end(o)
	await a.outro()

# ============ CAP. X — EL JUICIO ============
func ch10() -> void:
	g.set_map(town({palace = true})); var W := g.world; W.reveal('palace'); g.spawn_player(-14, -6, -PI / 2)
	var gone := ['prefecto', 'orador']
	g.add(F_poli('prefecto', -14, -33, 12, {name = 'el Prefecto', r = 1.2, rot = PI / 2}))
	g.add(F_penta('orador', -14, -29, {name = 'el conferenciante', rot = PI / 2}))
	var aq := [[-19, -23], [-16.5, -22], [-11.5, -22], [-9, -23], [-20, -26.5], [-8, -26.5]]
	for i in 6:
		var id := 'au%d' % i; gone.append(id)
		g.add(F_hexa(id, aq[i][0], aq[i][1], {rot = -PI / 2}) if i % 2 else F_penta(id, aq[i][0], aq[i][1], {rot = -PI / 2}))
	await a.intro('Capítulo X', 'El juicio', 'Donde se pregunta a un Cuadrado hacia dónde cae Arriba.', 'flat')
	await narr('Callé once meses. Escribí en secreto un tratado, «De Planilandia a Pensamientolandia», fingiendo hablar de una tierra imaginaria. No pude dibujar un solo diagrama: en mi mundo no hay tablillas, sólo líneas.')
	await narr('Lo peor era mirar. Veía una raya y sabía que era un Cuadrado; veía mi casa y recordaba sus cinco lados a la vez. Cerraba el ojo para volver a ver el Cubo, y cada noche lo veía un poco peor.')
	await narr('Y un día acudí a una sesión de la Sociedad Especulativa local, en el palacio del Prefecto.')
	await g.go_to(-14, -22, 1.6, 'Entra en el Palacio y toma asiento en la Sociedad Especulativa')
	g.begin_scene()
	g.player.rot = -PI / 2; W.focus = Vector2(-14, -26); W.zoom = 40
	await say('orador', '…y queda así demostrado, señores, por qué la Providencia ha limitado a Dos el número de las Dimensiones, y por qué el atributo de verlo todo, la omnividencia, pertenece sólo al Ser Supremo.')
	var c = await choose([{t = '(Callar.)', id = 's'}, {t = '(Carraspear.)', id = 'a'}])
	await say('orador', 'Pues ¿quién de nosotros podría ver el interior de una casa cerrada? ¿Quién, el interior de su prójimo? Sería tanto como ver *desde ningún sitio*.')
	await say('asombro', 'Tú. Tú lo has visto. Tu casa. Tus hijos. Sus entrañas latiendo.')
	c = await choose([{t = '(Callar.)', id = 's'}, {t = '(Callar, con más esfuerzo.)', id = 's2'}])
	await say('orador', 'Una tercera dirección es, por tanto, no ya falsa: es *impensable*. Ninguna mente sana ha podido jamás concebirla.')
	await say('narr', 'Aquí puedes elegir lo que quieras. Te aviso de que no servirá.')
	c = await choose([{t = '(Callar.)', id = 's'}, {t = 'Supongamos, como fábula, que alguien la hubiera visto…', id = 'a'}, {t = '(Marcharte.)', id = 'm'}])
	if c == 's': await say('narr', 'Callé, sí. Unos tres granos de arena. Luego me oí decir: «Supongamos, como fábula, que alguien la hubiera visto…».')
	elif c == 'm': await say('narr', 'Llegué hasta la puerta. Con el perímetro ya en el umbral me oí decir: «Supongamos, como fábula, que alguien la hubiera visto…».')
	await say('yo', 'Un personaje ficticio, digamos. Una noche lo arrancan del Plano. Ve su ciudad por dentro. Ve el Consejo. Ve una Figura hecha de Círculos…')
	await say('yo', '…y no era ficticio. ¡Era yo! ¡Lo vi! Existe la Tercera Dimensión: ¡hacia Arriba, no hacia el Norte! ¡Sacudíos el prejuicio y creed!')
	await say('prefecto', 'Guardias. Al Consejo.')
	Snd.sfx('gavel'); g.her(1)
	await say('narr', 'Me olvidé de mí mismo. Es la expresión exacta: por una vez me olvidé del Cuadrado prudente que firmaba, aplaudía y callaba.')
	g.end_scene()
	await a.outro()

	# --- el Consejo ---
	for id in gone: W.remove(id)
	g.teleport(-14, -24.5, -PI / 2)
	g.add(F_circ('presidente', -14, -33.5, {name = 'el Presidente', r = 1.5, rot = PI / 2}))
	var cx := [-22, -19, -9, -6]
	for i in 4: g.add(F_circ('co%d' % i, cx[i], -30 + absf(cx[i] + 14) * 0.35, {rot = PI / 2}))
	var low := [g.add(F_iso('lg0', -18, -19, 3, {name = 'un guardia de dos grados', rot = -1.57})), g.add(F_iso('lg1', -10, -19, 3, {name = 'un guardia de dos grados', rot = -1.57}))]
	ui.chapter_tag('Capítulo X · El juicio'); W.focus = Vector2(-14, -27); W.zoom = 42; Snd.drone('temple'); await ui.fade(false)
	await narr('A la mañana siguiente me hallé en el mismo punto de la sala donde, un año antes, se había posado la Esfera. Me dejaron contarlo todo sin interrumpirme.')
	g.begin_scene()
	await say('logica', 'Fíjate en los guardias. Han cambiado a los de rango por Isósceles de dos o tres grados. Sabes lo que significa: quien te oiga hoy no llegará a la noche.')
	await say('presidente', 'El Consejo ha escuchado. Le haré sólo dos preguntas, Cuadrado. La primera: usted repite «hacia Arriba, no hacia el Norte». Sea tan amable de *indicarnos esa dirección*. Muévase hacia ella.')
	g.end_scene()
	W.focus = Vector2(-14, -27.5); W.zoom = 50
	var x0 := g.player.x; var y0 := g.player.y
	ui.panel_info('Primera pregunta', 'Muévete hacia Arriba.')
	if not (g.auto or g.bot):
		var Q := {tm = 0.0, tries = 0, said = -9.0}
		g.need_act = 'Arriba'
		await g.tick_until(func(dt) -> bool:
			Q.tm += dt
			var p := g.player; var dx := p.x - x0; var dy := p.y - y0
			if Vector2(dx, dy).length() > 1.6:
				Q.tries += 1
				var m := ('el Este' if dx > 0 else 'el Oeste') if absf(dx) > absf(dy) else ('el Norte' if dy > 0 else 'el Sur')
				ui.note('*El Presidente:* «Eso es %s, caballero.»' % m, 3.5); Snd.blip('circ'); p.x = x0; p.y = y0; g.vel = Vector2.ZERO
			if g.other_held() and Q.tm - Q.said > 2.5:
				Q.said = Q.tm; g.set_view('top'); ui.note('*Nada. Tu cuerpo no tiene con qué.*', 3); Snd.sfx('bad')
			return Q.tries >= 3 or Q.tm > 22)
		g.need_act = ''
	ui.panel_info(null)
	g.begin_scene()
	g.player.x = x0; g.player.y = y0; W.focus = Vector2(-14, -27); W.zoom = 42
	await say('yo', 'No puedo señalarla. Pero existe.')
	await say('presidente', 'La segunda. ¿Puede, con diagramas o descripciones —que no sean enumerar lados y ángulos imaginarios—, mostrarnos esa Figura que llama Cubo?')
	await slate_anim('tablilla del acusado', 6, func(b: SlateBoard, t: float):
		var k1 := minf(1.0, t / 0.3); var k2 := clampf((t - 0.35) / 0.3, 0.0, 1.0); var d := clampf((t - 0.7) / 0.3, 0.0, 1.0)
		for q in [[200.0, 150.0, k1], [270.0, 90.0, k2]]:
			var x: float = q[0]; var y: float = q[1]; var k: float = q[2]
			if k <= 0: continue
			b.line(x, y, x + 150 * minf(1.0, k * 4), y)
			if k > 0.25: b.line(x + 150, y, x + 150, y + 150 * minf(1.0, (k - 0.25) * 4))
			if k > 0.5: b.line(x + 150, y + 150, x + 150 - 150 * minf(1.0, (k - 0.5) * 4), y + 150)
			if k > 0.75: b.line(x, y + 150, x, y + 150 - 150 * (k - 0.75) * 4)
		if d > 0:
			for q in [[200, 150], [350, 150], [200, 300], [350, 300]]: b.line(q[0], q[1], q[0] + 70 * d, q[1] - 60 * d)
		b.text('Un Cuadrado…' if t < 0.34 else ('…otro Cuadrado, más «arriba»…' if t < 0.68 else '…y unidos. ¿No lo veis?'), 210, 380))
	await say('presidente', 'Veo un Cuadrado montado sobre otro y cuatro rayas que los cosen. Una figura Irregular de muchos lados. ¿Eso es su Cubo?')
	slate_off()
	await say('narr', 'Tú, lector, has visto un cubo en ese dibujo. Tú puedes. Imagina ahora tener la verdad entera y ningún papel donde quepa.')
	c = await choose([{t = 'Nada más puedo decir. Me encomiendo a la Verdad, cuya causa acabará por prevalecer.', id = 'a'}, {t = 'Retiro lo dicho. Fue la fiebre.', id = 'r', tag = 'Retractarse'}])
	if c == 'r': await say('narr', 'Pensé en decirlo. La frase estaba hecha, con sus cinco lados y ninguna ventana. No la dije. Es de lo poco de lo que estoy seguro.')
	await say('presidente', 'El Consejo comparte su confianza en la Verdad. Si ella quiere que salga usted de la cárcel a evangelizar el mundo, ella proveerá. Prisión perpetua. Sin más rigor que el necesario para que no escape. Podrá ver a su hermano, que le precedió.')
	Snd.sfx('gavel')
	for i in 2: low[i].move_to(g.player.x + (1.8 if i else -1.8), g.player.y, 5)
	g.end_scene()
	await a.outro()

	# --- epílogo: la celda ---
	g.set_map(a.cell()); g.spawn_player(0, -1, PI / 2); W.add_spot({id = 'tablilla', x = 2.2, y = -2.2, label = 'el manuscrito'})
	var bro := g.add(F_cuad('hermano', -2.2, 1.6, {name = 'tu hermano', rot = -0.6}))
	ui.chapter_tag('Epílogo · La celda'); Snd.drone('cell'); await ui.fade(false, 1.2)
	await narr('Siete años. Mi hermano viene cada semana. Es de lo poco que me permiten, y lo que más me duele.')
	var o := await g.talk_begin('hermano', 'Habla con tu hermano')
	await say('yo', 'Hermano: tú estabas allí. La viste aparecer en la sala. Un punto, un Círculo que crecía, que menguaba. Oíste lo que dijo.')
	await say('hermano', 'Vi un Círculo que cambiaba de tamaño, sí. Y por haberlo visto estoy aquí. ¿Qué más quieres que haya visto?')
	await say('yo', 'Te lo he explicado cada semana, durante siete años. La Analogía. El Cubo.')
	await say('hermano', 'Y cada semana te escucho con gusto, porque eres mi hermano. Pero no. No creo en tu Esfera. Lo siento. ¿Cómo va a moverse algo hacia Arriba y no hacia el Norte?')
	await say('narr', 'No tengo un solo converso. La Revelación del milenio se hizo para mí, y para nada. Prometeo fue encadenado por bajar el fuego a los mortales; yo, pobre Prometeo de Planilandia, estoy preso por no haberles bajado nada.')
	g.talk_end(o)
	var bro_go := func():
		await bro.move_to(-3.2, 2.6, 1)
		bro.hid = true
	bro_go.call()
	o = await g.talk_begin('tablilla', 'Vuelve al manuscrito', 'Escribir')
	var S: Dictionary = g.state
	if S.flags.get('hijaCuenta'): await say('narr', 'Dicen que mi hija sabe contar hasta diez. Es lo único que he enseñado en mi vida que ha prendido.')
	if S.rep.ciu >= 2: await say('narr', 'El hijo de mi antiguo criado, el de diez grados y medio, pasa algunas tardes bajo el muro y dice mi nombre en voz alta. Es toda mi fama.')
	if S.rep.aut <= -2: await say('narr', 'El Prefecto no tuvo que buscar testigos contra mí: mi tablilla estaba llena desde lo de la Puerta Oeste. De eso, al menos, no me avergüenzo.')
	elif S.flags.get('irregularChoice') != 'd': await say('narr', 'Pienso a veces en el calderero. En que dictaminé su raya con el mismo aplomo con que el Consejo dictaminó la mía.')
	if S.her >= 3: await say('narr', 'No me arrepiento de haber hablado. Me arrepiento de los años en que no pregunté.')
	elif S.her <= -2: await say('narr', 'A veces pienso que habría sido mejor aplaudir y callar, como sabía hacer tan bien. Luego recuerdo el Cubo, y se me pasa. Casi siempre.')
	else: await say('narr', 'Dudé toda mi vida en voz baja. Sólo una vez hablé en voz alta, y fue ésta.')
	g.frag(22)
	await say('narr', 'Y sin embargo existo con la esperanza de que estas memorias lleguen, no sé cómo, a las mentes de la humanidad de Alguna Dimensión, y susciten una raza de rebeldes que se nieguen a ser confinados en una Dimensionalidad limitada.')
	g.talk_end(o)
	g.view_lock = true; g.set_view('eye'); g.hide_eye_hint = true; g.locked = true; await g.wait(2.5)
	await narr('Esa es la esperanza de mis horas más luminosas. Ay, no siempre es así.', true)
	await narr('Hay momentos en que no puedo decir con honradez que recuerde la forma exacta del Cubo, una vez visto y tantas veces añorado. Y el precepto, «hacia Arriba, no hacia el Norte», me persigue como una Esfinge que devora el alma.', true)
	var fog0 := W.fog
	g.tween(14, func(t): W.fog = lerpf(fog0, 0.5, t))
	await narr('Hay horas de flaqueza en que Cubos y Esferas se desvanecen hacia el fondo de lo apenas posible; en que la Tierra de las Tres Dimensiones parece casi tan visionaria como la de Una o la de Ninguna…', true)
	await narr('…en que hasta este muro que me priva de la libertad, estas tablillas en que escribo, y todas las realidades sustanciales de Planilandia, no parecen más que el engendro de una imaginación enferma, o la tela sin fundamento de un sueño.', true)
	await ui.fade(true, 2.5)
	var n: int = g.state.frags.size()
	await ui.title('FIN', 'Planilandia', 'El manuscrito está completo: 22 de 22 secciones. Alguien, en Alguna Dimensión, lo ha leído.' if n >= 22 else 'Has recuperado %d de 22 secciones del manuscrito. Las que faltan esperan en sus capítulos.' % n, 6.0)
	await ui.title('Edwin A. Abbott', 'Flatland, 1884', 'Hacia Arriba, no hacia el Norte.', 5.0)
