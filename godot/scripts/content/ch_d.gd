# Capítulos VIII–X: Espaciolandia, Puntolandia, el nieto, el juicio y la celda.
class_name ChD extends Ch

func _anger(sph: MeshInstance3D, v: float) -> void:
	(sph.material_override as ShaderMaterial).set_shader_parameter('anger', v)

# ============ CAP. VIII — ESPACIOLANDIA ============
const ALACENA_RECT := Rect2(-23.2, 21.0, 1.8, 1.6)    # el interior de la alacena (C1-01, C7-04, C8-03)
const HOSPITAL_RECT := Rect2(53.4, 15.8, 5.2, 3.8)    # la sala cerrada del Hospital (C8-04)

# posición de cámara a cierta distancia de un punto, como la cámara libre (yaw, inclinación, distancia)
static func _cam_at(tgt: Vector3, yaw: float, pitch: float, dist: float) -> Vector3:
	return tgt + Vector3(sin(yaw) * cos(pitch) * dist, sin(pitch) * dist, cos(yaw) * cos(pitch) * dist)

func ch8() -> void:
	var map := town({palace = true, hospital_room = true}); g.set_map(map)   # la misma lámina de Planilandia, vista desde Arriba
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
	# la alacena: dos cofres y una tablilla; la otra, en el suelo del salón, donde la dejó la Esfera (C8-03)
	var cc := Vector2(-22.3, 21.8)
	g.add({id = 'cofre1', n = 4, r = 0.3, rot = 0.785, x = cc.x - 0.5, y = cc.y - 0.35, name = 'un cofre', noCollide = true, noGuts = true})
	g.add({id = 'cofre2', n = 4, r = 0.3, rot = 0.785, x = cc.x + 0.5, y = cc.y - 0.35, name = 'un cofre', noCollide = true, noGuts = true})
	g.add({id = 'tab1', pts = [[0.32, 0.12], [-0.32, 0.12], [-0.32, -0.12], [0.32, -0.12]], x = cc.x - 0.45, y = cc.y + 0.4, name = 'una tablilla', noCollide = true, noGuts = true, noEye = true})
	g.add({id = 'tab2', pts = [[0.32, 0.12], [-0.32, 0.12], [-0.32, -0.12], [0.32, -0.12]], x = -30.2, y = 8.6, name = 'tu tablilla', noCollide = true, noGuts = true, noEye = true, carryable = true})
	# la tablilla del nieto, bajo su almohada
	g.add({id = 'tabn', pts = [[0.26, 0.1], [-0.26, 0.1], [-0.26, -0.1], [0.26, -0.1]], x = -33.6, y = 7.9, name = 'la tablilla del nieto', noCollide = true, noGuts = true, noEye = true})
	# el cofre del Prefecto, en el Palacio, con el acta ya escrita
	g.add({id = 'cofrep', n = 4, r = 0.45, rot = 0.785, x = -6.4, y = -31.0, name = 'el cofre del Prefecto', noCollide = true, noGuts = true})
	# el Hospital (C8-04): el calderero, según lo que hiciste en la Puerta
	var protest: bool = g.flag('irregularChoice') == 'd'
	if protest: g.add({id = 'calderero', pts = [[0.95, 0], [-0.3, 0.8], [-0.62, -0.38]], voice = 'tri', x = 56, y = 17.6, name = 'el calderero', rot = 0.2, noCollide = true})
	else: W.fx_add('cross', 56, 17.6, 9999.0, 0.5)
	if g.state.get('inv', {}).has('estilete'):
		g.add({id = 'estilete', pts = [[0.4, 0], [-0.4, 0.05], [-0.4, -0.05]], x = -27.2, y = 23.6, name = 'el estilete del calderero', noCollide = true, noGuts = true, noEye = true, carryable = true})
	# dos marginalia de este capítulo tienen figura: una mujer encinta y un Círculo que se mide
	g.add(F_mujer('vecina', -4, 16.5, {r = 0.8, sway = 0.0}))
	g.add(F_poli('circsolo', 40, 17, 14, {name = 'un Círculo', r = 1.1}))
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
	var st := {free = true, time = 0.0, busy_m = false}
	var stop_space := g.tick(func(dt):
		st.time += dt
		var spin: Array = bd.get_meta('spin')
		for i in spin.size(): spin[i].rotation.x += dt * 0.07 * (1 + i % 3); spin[i].rotation.y += dt * 0.1
		if st.free:
			var y: float = W.free.yaw
			sph.position = sph.position.lerp(Vector3(p.x + cos(y) * 4.5, p.alt + 1.2 + sin(st.time) * 0.3, -p.y - sin(y) * 4.5 - 1), minf(1.0, dt * 3.0))
		# marginalia en vuelo: basta con pasar cerca y bajo (S-04 en el Espacio)
		if not g.auto and not g.busy and not st.busy_m:
			for s in W.spots.values():
				if s.margin and not s.hid and Vector2(p.x - s.x, p.y - s.y).length() < 4.0 and p.alt < 8.0:
					st.busy_m = true
					var take := func(id: String):
						g.begin_scene(); await g.margin(id); g.end_scene(); st.busy_m = false
					take.call(s.id)
					break)
	margins([['m_c8_embarazada', -4, 16.5], ['m_c8_circulo', 40, 17], ['m_c8_sala', -14, -27.5]])
	g.show_strip = false; g.view_lock = true; W.cam_mode = 'free'; W.free = {yaw = 0.0, pitch = 1.05, dist = 38.0}; p.alt = 0.4; p.no_collide = true; g.alt_min = 0.4; g.alt_max = 0.4
	ui.chapter_tag('Capítulo VIII · Espaciolandia'); Snd.drone('none')
	await narr('Un horror indecible. Oscuridad. Luego una sensación mareante de una vista que no era ver: vi una Línea que no era Línea; un Espacio que no era Espacio. Yo era yo y no lo era.', true)
	await narr('Grité: «¡Esto es la locura, o es el Infierno!»', true)
	await ui.lamina('lam_8')
	await ui.title('Capítulo VIII', 'Espaciolandia', '«Ni lo uno ni lo otro. Es el Conocimiento; son las Tres Dimensiones. Abre el ojo de nuevo y procura mirar con firmeza.»', 4.0)
	W.show_guts = true
	for e in W.ents.values(): e.guts.visible = true
	# C8-01 · el vértigo: a ras del Plano la ciudad es una raya; la cámara sube y la raya se abre
	var P0 := Vector3(p.x, 0.0, -p.y)
	var keys := [
		{t = 0.0, pos = _cam_at(P0, 0.0, 0.02, 30.0), look = P0, fov = 42.0, ease = 'linear'},
		{t = 3.0, pos = _cam_at(P0, 0.0, 0.03, 30.0), look = P0, fov = 42.0},
		{t = 6.0, pos = _cam_at(P0 + Vector3(0, 6, 0), 0.0, 0.4, 30.0), look = P0 + Vector3(0, 6, 0), fov = 42.0},
		{t = 9.0, pos = _cam_at(P0 + Vector3(0, 13, 0), 0.0, 1.05, 38.0), look = P0 + Vector3(0, 13, 0), fov = 42.0},
	]
	ui.fade(false, 2.0)
	g.after(3.2, func(): Snd.drone('space'); Snd.sfx('rise'))
	g.tween(9.0, func(t): p.alt = 0.4 + clampf((t - 0.33) / 0.67, 0.0, 1.0) * 12.6)
	await Cine.play(W, keys, true)
	p.alt = 13.0; W._free_intro = 1.0; W.rail = {}
	g.alt_min = 4; g.alt_max = 20
	g.begin_scene()
	await say('esfera', 'Mira. No con el borde de tu ojo: con todo él. Lo que hay debajo de ti es tu mundo. Entero.')
	await say('asombro', 'Tu casa. No su raya: *su forma*. Los cinco lados a la vez. Y dentro de ella, sin pared que lo impida, todo.')
	await say('narr', 'Y vi a la Esfera. No una rebanada: él. Lo que yo había tomado por un Círculo era una cosa con un *dentro* que no se veía y un *fuera* por todas partes. Era hermoso de un modo para el que aún no tengo palabra.')
	g.end_scene()
	ui.note(tx('Arrastra el ratón para mirar alrededor · {move} para volar · {rise} / {sink} para subir y bajar · rueda: acercar', 'Palanca para volar · arrastra por la derecha para mirar · botones para subir y bajar · pellizca para acercar', 'Stick derecho para mirar alrededor · stick izquierdo para volar · {rise} / {sink} para subir y bajar'), 14)
	# C8-02 · ver por dentro: tres hallazgos obligatorios (y las marginalia, si se pasa cerca)
	await _finds({
		h_alacena = {x = -24.5, y = 18.0, fn = func():
			await say('yo', 'Mis hijos, dormidos en sus cuartos del Oeste. Mis dos nietos. Mi hija. Los criados. Y… veo dentro de *ellos*. Sus entrañas. Les late algo.')
			await say('yo', 'Y mi alacena, abierta como un plato: dos cofres y *una* tablilla. La otra sigue en el suelo del salón, donde la dejó él.')
			await say('esfera', 'Desde Arriba no hay dentro que se esconda. Así vi yo tu alacena. Así te toqué el estómago.')
			await say('logica', 'Tu esposa recorre el salón de punta a punta. Para ella has desaparecido sin cruzar ninguna puerta. Como el Forastero. Como tú ante el Rey de la Línea.')},
		h_nieto = {x = -33.6, y = 8.2, fn = func():
			await say('yo', 'Mi nieto pequeño, dormido. Y bajo su almohada, una tablilla: tres cuadrados de tres por tres, uno al lado del otro, y una palabra: «pisos».')
			await say('asombro', 'Lo intentó a escondidas. Como tú esta noche. Él tampoco tenía dónde poner el «encima».')},
		h_acta = {x = -6.4, y = -31.0, fn = func():
			await say('yo', 'El cofre del Prefecto. Dentro, un acta con la fecha de hoy, ya firmada. «Se resuelve: prisión perpetua para el Escribano.» Y el Consejo aún no se ha reunido.')
			await say('recelo', 'Mil años repitiendo la misma resolución. Ni siquiera hace falta la sesión.')},
	}, 'Mira dentro de lo que nunca has visto')
	# C8-03 · coger desde Arriba
	var stop_carry := Carry.enable(self, func(e):
		if e.id == 'estilete' and HOSPITAL_RECT.has_point(Vector2(e.x, e.y)) and not g.flag('estilete_hospital'):
			g.flag('estilete_hospital', 1); g.state.inv.erase('estilete'); g.note('hospital_miracle', 3)
			ui.note('*Dentro de la sala cerrada, junto al calderero, cae un estilete que nadie ha traído.*', 5.0))
	g.begin_scene()
	await say('esfera', 'Ahora hazlo tú. Lo que yo hice con tu alacena. Baja hasta casi tocar tu tablilla, tómala y déjala donde estaba.')
	g.end_scene()
	ui.note(tx('Baja con {sink} hasta la tablilla y mantén {act} para tomarla; suéltalo para dejarla caer.', 'Baja hasta la tablilla y mantén el botón de acción para tomarla; suéltalo para dejarla caer.', 'Baja con {sink} hasta la tablilla y mantén {act} para tomarla; suéltalo para dejarla caer.'), 10.0)
	g.alt_min = 1.5
	await Carry.run(self, 'tab2', func(e): return ALACENA_RECT.has_point(Vector2(e.x, e.y)), 'Devuelve la tablilla a tu alacena cerrada', ALACENA_RECT.get_center())
	g.achieve('ACH_CUPBOARD')
	g.begin_scene()
	await say('asombro', 'Cerrada por sus cuatro lados. Y dentro, dos tablillas. Mañana la contarás de memoria y no faltará ninguna.')
	await say('esfera', 'Ya lo ves: no es magia. Es un sitio más.')
	if g.state.get('inv', {}).has('estilete'): await say('recelo', 'Llevas aún el estilete del calderero, en el estudio. El Hospital está al Este. Nadie vigila el techo de una sala cerrada.')
	await say('esfera', 'Ven. Hay algo que debes oír. Es la primera hora del primer día del año 2000, y el Alto Consejo de tu país está reunido, como lo estuvo hace mil años, y hace dos mil.')
	g.end_scene()
	# C8-04 · el calderero, desde Arriba (opcional: se ve si se pasa por encima del Hospital)
	var tinker := {seen = false}
	var stop_tinker := g.tick(func(_dt):
		if tinker.seen or g.busy or g.auto: return
		if Vector2(p.x - 56, p.y - 17.6).length() < 5.0 and p.alt < 10.0:
			tinker.seen = true
			var see := func():
				g.begin_scene()
				if protest:
					await say('yo', 'El Hospital. En una sala cerrada, en una camilla, el calderero. Lo tienen metido en un marco que le fuerza los ángulos. Está vivo.')
					await say('asombro', 'Desde aquí se ve que sus tres lados están bien. Sólo son distintos.')
				else:
					await say('yo', 'El Hospital. Una sala cerrada, vacía. En el suelo, marcas en el papel, como las de la plaza.')
					await say('recelo', 'Firmaste como perito. O miraste la niebla.')
				g.achieve('ACH_TINKER'); g.end_scene()
			see.call())
	await g.fly_to(-14, -24, 6.5, 12.0, 'Vuela hacia el sur: la Sala del Consejo, en el Palacio')
	stop_tinker.call()
	g.begin_scene()
	g.tween(2.5, func(t): p.x = lerpf(p.x, -14, t * 0.2); p.y = lerpf(p.y, -20, t * 0.2); p.alt = lerpf(p.alt, 11, t * 0.2); W.free.dist = lerpf(W.free.dist, 30, t * 0.2))
	await say('yo', '¡Mi hermano! Es el Escribano Mayor del Consejo. Está leyendo.')
	Snd.motif('hermano', '', false, -12.0)
	await say('hermano', '«…considerando que cada milenio han turbado a los Estados gentes mal intencionadas que pretenden haber recibido revelaciones de Otro Mundo…»')
	await say('hermano', '«…se resuelve: que en el primer día de cada milenio los Prefectos busquen a tales extraviados; que se destruya sin examen al que sea Isósceles; se azote y encarcele al Equilátero; se envíe al Manicomio al Cuadrado o Pentágono; y se arreste a cualquiera de rango superior.»')
	await say('esfera', 'Ya oyes tu destino. Y, sin embargo, voy a decírselo a ellos también. Mira cómo me ven.')
	st.free = false; Snd.sfx('sphere')
	var sec := g.add(F_circ('secc', -14, -25.5, {r = 1.7, tint = Color('9fe8e0'), noGuts = true, noCollide = true})); sec.sc = 0.001
	var from := sph.position
	var section := func():
		var h := sph.position.y
		sec.sc = maxf(0.001, Geom3.sphere_section(1.0, h / 1.7))
	await g.tween(3.2, func(t):
		var k := App.ease(t)
		sph.position = Vector3(lerpf(from.x, -14, k), lerpf(from.y, 0, k), lerpf(from.z, 25.5, k)); section.call())
	await say('esfera', '¡Consejeros de Planilandia! Vengo a proclamar que existe una tierra de Tres Dimensiones.')
	for c in cons: c.move_to(c.x + (c.x + 14) * 0.25, c.y + (c.y + 25.5) * 0.2, 4)
	await say('narr', 'Desde arriba vi lo que ellos veían: un Círculo surgido de la nada en mitad de la sala. Los consejeros jóvenes retrocedieron. El Presidente no se movió.')
	Snd.tension(0.6)
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
	stop_carry.call()
	g.alt_max = 44; g.objective(tx('Asciende (mantén {rise}) hasta dejar la ciudad muy abajo', 'Asciende (mantén el botón de subir) hasta dejar la ciudad muy abajo'), null)
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
	var spin := {on = true}
	var stop_spin := g.tick(func(dt):
		if spin.on and is_instance_valid(cube): cube.rotation.y += dt * 0.5; cube.rotation.x += dt * 0.23)
	await say('logica', 'Fíjate en cómo lo ves: unas caras más claras, otras más oscuras. Luz y sombra. Así se ve la profundidad desde fuera, igual que tú leías los ángulos en la niebla.')
	g.ledger('3d.ve')
	g.learn('solidos'); g.learn('altura')
	await say('narr', 'Lo adoré. No hay otra palabra. Le llamé Maestro, y lo era.')
	# C8-05 · las secciones del Cubo: bajamos con él hasta la Calle Mayor
	await say('esfera', 'Ahora mira lo que ven tus compatriotas cuando un Cubo atraviesa su mundo. Bajemos.')
	spin.on = false
	var at := Vector2(2.0, 6.0)
	var obs: Ent = g.add(F_penta('testigo', at.x + 7.0, at.y, {name = 'un Pentágono que pasaba', rot = PI}))
	g.eye_src = obs; g.eye_src_all = true; g.strip_in_space = true
	g.alt_min = 3.0
	await g.tween(2.5, func(t):
		var k := App.ease(t)
		p.x = lerpf(p.x, at.x, k * 0.3); p.y = lerpf(p.y, at.y - 6.0, k * 0.3); p.alt = lerpf(p.alt, 7.0, k * 0.3)
		W.free.yaw = 0.0; W.free.pitch = lerpf(0.35, 0.55, k); W.free.dist = lerpf(24.0, 16.0, k))
	p.x = at.x; p.y = at.y - 6.0; p.alt = 7.0
	await say('logica', 'Arriba, la línea de ese Pentágono: lo que él ve. Abajo, el Plano. Lo que cruce el Plano, lo verá él.')
	ui.close_dlg()
	var res: Dictionary = await CubeSections.run(self, cube, at, L)
	g.flag('cube_pred', res.pred); g.flag('hidden_ok', 1 if res.hidden else 0)
	if res.pred >= 3 and res.hidden: g.achieve('ACH_SECTIONS')
	g.learn('secciones')
	await say('asombro', 'Un hexágono, salido de un Cubo. Y tú, en el salón, mirando cómo un Círculo crecía y menguaba. Ahora sabes qué era.')
	# C8-06 · la sombra del Cubo
	await say('esfera', 'Hay otra manera de que te vean sin cruzar tu Plano. Mira: enciendo una luz.')
	ui.close_dlg()
	await ShadowTurn.run(self, cube, at, L)
	g.learn('sombras')
	await say('esfera', 'Esto es lo único que tus compatriotas podrían ver de él: su sombra. Dos cuadrados y cuatro rayas. Recuérdala.')
	g.eye_src = null; g.eye_src_all = false; g.strip_in_space = false; W.remove('testigo')
	# de vuelta arriba, para la Cuarta
	await g.tween(2.5, func(t):
		var k := App.ease(t)
		p.alt = lerpf(7.0, 34.0, k); W.free.pitch = lerpf(0.55, 0.35, k); W.free.dist = lerpf(16.0, 24.0, k))
	g.alt_min = 30
	cube.transform = Transform3D(Basis().scaled(Vector3.ONE * L), Vector3(p.x, p.alt + 2.5, -p.y - 9))
	cube.visible = true; spin.on = true
	# --- la Cuarta ---
	await say('yo', 'Maestro: me habéis mostrado las entrañas de mis compatriotas desde la tierra de Tres Dimensiones. Llevadme ahora a la de Cuatro.')
	await say('esfera', '¿Qué dices?')
	c = await choose([{t = 'Desde allí miraríamos este Espacio y veríamos el interior de todo Sólido. Vuestras propias entrañas.', id = 'a'}, {t = '(Callar. Has visto bastante.)', id = 's'}])
	if c == 's': await say('narr', 'Pude callar. Había visto más que nadie en mil años. No callé: un Cuadrado que ha contado hasta tres quiere contar hasta cuatro.')
	await say('esfera', 'No existe tal tierra. La sola idea es inconcebible.')
	g.ledger('3d.no_concibe')
	_anger(sph, 0.2)
	# C8-07 · el teseracto, manejable
	var tess := Space.make_lines(W.ink(Color('b79cf0'))); W.add_child(tess)
	var ts := {sc = 0.01}
	await say('yo', 'Vuestra propia Analogía, Maestro. Punto, Línea, Cuadrado, Cubo: uno, dos, cuatro, ocho puntos terminales. ¿Qué sigue?')
	c = await choose([{t = 'Dieciséis.', id = 16}, {t = 'Diez.', id = 10}, {t = 'Doce.', id = 12}])
	Snd.sfx('her')
	var stop_tess := Tesseract.start(self, tess, cube.position, ts)
	var held := {cube = cube}   # el Cubo puede borrarse antes de que acabe esta animación suelta
	g.tween(4, func(t):
		ts.sc = App.ease(t)
		if is_instance_valid(held.cube): cm.set_shader_parameter('dim', 1.0 - t * 0.6); held.cube.scale = Vector3.ONE * L * (1.0 - 0.45 * App.ease(t)))
	await say('yo', 'Dieciséis. Y sus límites: dos Puntos, cuatro Líneas, seis Cuadrados… *ocho Cubos*. Un Cubo movido en una dirección nueva. ¡Casi lo veo!' if c == 16 else 'No… el doble cada vez: *dieciséis*. Y sus límites: dos Puntos, cuatro Líneas, seis Cuadrados… ocho Cubos. ¡Casi lo veo!')
	g.learn('cuarta')
	for k in ['habitante', 've', 'limites', 'no_concibe', 'rechazo']: g.ledger('4d.' + k)
	g.ledger('3d.desde_arriba')
	await say('asombro', 'Eso que gira ahí no está en el Espacio. Está en ti. Es la sombra de una sombra, igual que la sombra del Cubo en tu Plano. Y es lo más grande que has pensado nunca.')
	_anger(sph, 0.45)
	await say('esfera', 'Basta. Son fantasías. Analogías sin objeto.')
	c = await choose([{t = '¿No es cierto que en vuestro país se han visto Seres entrar en cuartos cerrados, como vos en el mío?', id = 'a'}, {t = '(Ceder.) Perdonad, Maestro.', id = 's'}])
	if c == 's': await say('narr', 'No cedí. Tú has elegido la prudencia dos veces y yo te he desmentido dos veces: así fue. No sabía parar.')
	await say('esfera', '…Se cuenta. Visiones. Cosas del cerebro de quien las ve. Nadie las cree.')
	g.ledger('3d.rechazo')
	await say('logica', '«Un truco de mago.» «Visiones del cerebro.» El Rey, tú, la Esfera. Cada mundo tiene su frase para lo que le queda por encima.')
	_anger(sph, 0.75); g.her(1); Snd.tension(0.55)
	await say('yo', '¡Entonces existe! ¡Y más allá, la Quinta, la Sexta, la Séptima Dimensión! ¡Llevadme! ¡Hacia Arriba de Arriba!')
	_anger(sph, 1.0); Snd.sfx('gavel'); App.rumble(0.8, 1.0, 0.2)
	await say('esfera', '¡SILENCIO!')
	g.frag(19); ui.close_dlg(); stop_tess.call(); stop_spin.call(); tess.queue_free(); cube.queue_free()
	# C8-08 · la caída: la cámara cae girando y la ciudad se cierra otra vez en una raya
	Snd.sfx('fall'); Snd.tension(0.0); g.alt_min = 0
	var P1 := Vector3(p.x, 0.0, -p.y)
	var fall := [
		{t = 0.0, pos = W.cam.global_position, look = Vector3(p.x, p.alt, -p.y), fov = 42.0, ease = 'in'},
		{t = 2.0, pos = _cam_at(P1 + Vector3(0, 8, 0), 1.6, 0.5, 30.0), look = P1 + Vector3(0, 4, 0), fov = 42.0, ease = 'linear'},
		{t = 4.0, pos = _cam_at(P1, 3.1, 0.015, 30.0), look = P1, fov = 42.0, hold = true},
	]
	g.tween(4.0, func(t): p.alt = lerpf(34, 0.2, t * t); p.rot += 0.3)
	g.after(3.0, func(): ui.fade(true, 1.0))
	await Cine.play(W, fall, false)
	await ui.fade(true, 0.3)
	W.rail = {}
	stop_space.call(); sph.queue_free(); bd.queue_free()
	W.cam_mode = 'follow'; g.show_strip = true; g.view_lock = false; W.show_guts = false; W.known = {home = true, school = W.known.get('school', false), temple = true}
	await narr('Un estrépito. Y me hallé de nuevo en mi estudio, en el Plano, oyendo acercarse el Grito de Paz de mi esposa.', true)

# C8-02 · hallazgos en vuelo: se registran al sobrevolarlos de cerca (a menos de 4 u y por debajo de 8 u)
func _finds(list: Dictionary, text: String) -> void:
	var W := g.world; var p := g.player
	for id in list: W.add_spot({id = id, x = list[id].x, y = list[id].y}); W.mark(id)
	g.objective(text, list.keys()[0])
	var left := list.keys()
	while not left.is_empty():
		var st := {hit = null}   # las claves del diccionario son StringName: no se mezclan con String
		if g.auto or g.bot:
			st.hit = left[0]; p.x = list[st.hit].x; p.y = list[st.hit].y
		else:
			await g.until(func():
				for id in left:
					if Vector2(p.x - list[id].x, p.y - list[id].y).length() < 4.0 and p.alt < 8.0:
						st.hit = id; return true
				return false)
		var hit = st.hit
		if hit == null or not left.has(hit): break
		left.erase(hit); W.unmark(hit); W.remove_spot(hit); Snd.sfx('pick')
		W.target = left[0] if not left.is_empty() else null
		g.begin_scene()
		await list[hit].fn.call()
		g.end_scene()
	g.objective('', null)

# ============ CAP. IX — PUNTOLANDIA Y EL NIETO ============
func ch9() -> void:
	# --- visión: Puntolandia ---
	g.set_map({bounds = {x0 = -40, y0 = -40, x1 = 40, y1 = 40}, palette = 'space', fog = 10.0})
	var W := g.world; g.spawn_player(8, -8, 2.3); var p := g.player; W.ground.visible = false
	var pt := Space.make_point(); pt.scale = Vector3.ONE * 1.6; W.add_child(pt)
	var sph := Space.make_sphere(); W.add_child(sph)
	g.actors['esfera'] = sph; g.actors['punto'] = pt
	# el Punto, también como figura del Plano: así lo ve el ojo (C9-01)
	g.add({id = 'punto_e', n = 16, r = 0.22, x = 0, y = 0, tint = Color('ffe9a8'), noEye = true, noGuts = true, noCollide = true, name = 'el Punto'})
	var st := {time = 0.0, hum = 0.0, flood = false, moved = false, was = false}
	var stop := g.tick(func(dt):
		st.time += dt
		sph.position = sph.position.lerp(Vector3(p.x + 3.5, p.alt + 1, -p.y - 3), minf(1.0, dt * 3.0))
		pt.scale = Vector3.ONE * (1.5 + 0.25 * sin(st.time * 6))
		st.hum -= dt
		if st.hum < 0:
			st.hum = 1.4
			var d := Vector3(p.x, p.y, p.alt).length()
			if d < 22: Snd.tone(880, 0.5, 'sine', snappedf(0.05 * (1 - d / 22), 0.01) + 0.005)
		# C9-01 · al acercarse, la lente pasa sola al Ojo del Punto: la pantalla entera, un solo color
		if not st.flood and Vector2(p.x, p.y).length() < 6.0:
			st.flood = true; g.lenses = ['flood']; g.strip_in_space = true; g.set_view('flood')
			p.rot = atan2(-p.y, -p.x)
			for k in ['habitante', 've', 'limites', 'no_concibe', 'rechazo', 'desde_arriba']: g.ledger('0d.' + k)
		if st.flood:
			# nadie entra en el Punto: a menos de 2 u, se queda en el borde (y lo sigue mirando)
			var pv := Vector2(p.x, p.y)
			if pv.length() < 2.0: pv = (pv if pv.length() > 0.01 else Vector2(1, -1)).normalized() * 2.0; p.x = pv.x; p.y = pv.y
			p.rot = atan2(-p.y, -p.x)
			# cualquier entrada del jugador es, para el Punto, un pensamiento suyo
			var any := g.axis().length() > 0.3 or g.act_held() or g.up_held() or g.down_held()
			if any and not st.was:
				g.eye.hue = fmod(g.eye.hue + (0.03 if randf() < 0.5 else -0.03) + 1.0, 1.0)
				if not st.moved: st.moved = true; ui.note(ui.T('*El Punto:* «%s»') % ui.T('¡Ah, Ello se ha movido en Ello!'), 3.5)
			st.was = any)
	g.show_strip = false; g.view_lock = true; W.cam_mode = 'free'; W.free = {yaw = 0.0, pitch = 0.3, dist = 16.0}; p.alt = 5; p.no_collide = true; g.alt_min = 1; g.alt_max = 14
	ui.chapter_tag('Capítulo IX · Hacia Arriba, no hacia el Norte'); Snd.drone('dream')
	ui.fade(false, 0.5)
	await ui.lamina('lam_9')
	await ui.title('Capítulo IX', 'Hacia Arriba, no hacia el Norte', 'Donde se visita el reino más pequeño y más feliz, y se pierde a un discípulo.')
	await narr('Aquella noche soñé. La Esfera estaba otra vez a mi lado, y su brillo ya no mostraba enojo. «Te he tratado con dureza», dijo. «Ven: te debo una última lección.»', true)
	await g.go_to(0, 0, 4.5, 'Acércate a esa luz diminuta')
	if g.auto: g.ledger('0d.habitante')
	g.begin_scene()
	await say('esfera', 'Contempla Puntolandia: el Abismo de Ninguna Dimensión. Esa criatura es un Ser como nosotros, pero no conoce largo, ni ancho, ni alto. No conoce siquiera el número Dos. Él es su Mundo, su Universo. Escúchalo.')
	await say('punto', '¡Infinita beatitud de la existencia! Ello es; y nada hay fuera de Ello.')
	await say('punto', 'Ello llena todo el Espacio, y lo que llena, lo es. Lo que piensa, lo dice; lo que dice, lo oye; Ello es Pensador, Palabra y Oyente; el Uno, y sin embargo el Todo en Todo. ¡Ah, la dicha de Ser!')
	# C9-02 · las tres respuestas, todas; y después, callar
	var all_o := [{t = '¡Calla, criatura! No eres el Todo: eres la Nada. Un punto.', id = 'a'}, {t = 'Escucha: hay otros. Hay líneas, planos, sólidos. Yo vengo de fuera de ti.', id = 'b'}, {t = 'Hola. ¿Me oyes?', id = 'c'}]
	var said := {}
	while true:
		var opts := all_o.filter(func(o): return not said.has(o.id))
		if not said.is_empty(): opts.append({t = '(Callar.)', id = 's'})
		var c = await choose(opts)
		said[c] = 1
		if c == 'a': await say('punto', '¡Ah, el gozo, el gozo del Pensamiento! ¿Qué no alcanzará Ello pensando? Su propio Pensamiento viene a Ello sugiriéndole su menosprecio, para realzar con ello su dicha. ¡Dulce rebelión que acaba en triunfo!')
		if c == 'b': await say('punto', '«Otros.» «Fuera.» ¡Qué fecunda es la mente de Ello, que inventa palabras sin objeto para deleitarse en su propia unidad! ¡Ah, el poder creador del Todo en Uno!')
		if c == 'c': await say('punto', '«¿Me oyes?», se pregunta Ello a sí mismo, pues no hay otro a quien preguntar. Y se responde: sí. ¡Ah, la dicha de la conversación perfecta!')
		if c == 's':
			await say('punto', '¡Silencio! Ello descansa en Ello. ¡Ah, la perfección de no decir!')
			Snd.motif('esfera', 'bell'); g.after(0.5, func(): Snd.motif('esfera', 'bell', false, 12.0))
			await say('narr', 'Y la Esfera, por primera y última vez en mi presencia, se rió.')
			g.achieve('ACH_SILENT')
			break
		if said.size() >= 4: break
	await say('esfera', 'Ya ves lo poco que logran tus palabras. Todo lo que oye, cree haberlo pensado él. Nada que tú o yo hagamos lo sacará de su contento.')
	await say('esfera', 'Aprende esto: estar satisfecho de uno mismo es ser vil e ignorante. Aspirar es mejor que ser ciega e impotentemente feliz.')
	var c2 = await choose([{t = 'El Punto, el Rey de la Línea… ¿y yo, ante vos? ¿Y vos, ante la Cuarta?', id = 'h', tag = 'Atreverse'}, {t = 'Lo he comprendido, Maestro.', id = 'o'}])
	if c2 == 'h': await say('esfera', '…Vuelve a tu mundo. Enseña lo que has visto. Y sí: quizá por eso te elegí a ti y no a un Círculo.'); g.her(1)
	else: await say('esfera', 'Vuelve a tu mundo. Enseña lo que has visto. No esperes que te lo agradezcan.')
	g.frag(20); g.learn('punto')
	g.end_scene()
	await a.outro()
	stop.call(); pt.queue_free(); sph.queue_free(); W.ground.visible = true; W.cam_mode = 'follow'; g.eye.hue = 0.0

	# --- despertar ---
	g.set_map(town()); g.spawn_player(-28, 22.5, -PI / 2); g.show_strip = true; g.view_lock = false; W.rain = 0.2
	g.add(F_mujer('esposa', -26, 12, {name = 'tu esposa', rot = 2.0}))
	var kid := g.add(F_hexa('nieto', -34.3, 11.6, {name = 'tu nieto menor', r = 0.6}))
	g.add(F_penta('hijo', -33, 13.5, {name = 'tu hijo mayor', rot = -1.0}))
	var her := g.add(F_tri('heraldo', -60, 1.5, {name = 'un heraldo', ai = {type = 'path', pts = [Vector2(-20, 1.5), Vector2(-60, 1.5)]}, speed = 2.5}))
	margins([['m_c9_voz', -26.6, 23.4], ['m_c9_trampilla', -29.4, 14.6], ['m_c9_tablero', -35.8, 10.4]])
	ui.chapter_tag('Capítulo IX · Hacia Arriba, no hacia el Norte'); Snd.drone('home'); await ui.fade(false)
	await narr('Desperté gozoso. Iba a evangelizar a toda Planilandia, de las mujeres a los Círculos. Empezaría por mi esposa.')
	g.begin_scene()
	Snd.sfx('herald')
	await say('heraldo', '(En la calle.) ¡Oíd, oíd! ¡Resolución del Alto Consejo! Todo aquel que pervierta las mentes del pueblo con delirios, pretendiendo revelaciones de Otro Mundo, será arrestado, encarcelado o ejecutado, según su número de lados.')
	if g.flag('estilete_hospital'):
		await say('heraldo', '¡Y oíd también! En el Hospital de Reconfiguración ha aparecido un estilete dentro de una sala cerrada. ¡Quien sepa algo, que hable al Prefecto!')
		await say('asombro', 'Un milagro en el Hospital, que nadie se explica. Tú sí.')
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
	var close := g.rel_of('nieto') >= 1
	o = await g.talk_begin('nieto', 'Enséñale a tu nieto lo que has visto')
	await say('yo', 'Ven, pequeño. Cierra la puerta. ¿Recuerdas lo que dijiste de 3³? Tenías razón. Y hay más. Mira.')
	# C9-03 · primer intento: las secciones (un círculo que crece y mengua)
	ui.close_dlg()
	await _circle_demo()
	await say('nieto', 'Es un círculo que cambia de tamaño, abuelo. ¿Y dónde está el resto de él?' if close else 'Es un círculo que cambia de tamaño, abuelo.')
	# segundo intento: la sombra del Cubo
	await say('yo', 'Entonces mira esto. Es la sombra de una cosa que no cabe en ninguna tablilla.')
	ui.close_dlg()
	await Brother.draw_shadow(self, 'tablilla de lecciones', 'Dibuja la sombra del Cubo', 40.0)
	await say('nieto', 'Son dos cuadrados cosidos. Como los que dibujas cuando te aburres. …Pero ¿por qué los coses así, abuelo? ¿Qué hay entre los dos?' if close else 'Son dos cuadrados cosidos. Como los que dibujas cuando te aburres.')
	# tercero: el de siempre, «hacia Arriba»
	await say('yo', 'Mira este cuadrado. Vamos a moverlo, no hacia el Norte, sino hacia Arriba.')
	ui.close_dlg()
	ui.panel_info('La lección', tx('Mueve el cuadrado hacia Arriba. *({move} / flechas)*', 'Mueve el cuadrado hacia Arriba. *(usa la palanca)*', 'Mueve el cuadrado hacia Arriba. *(stick izquierdo)*'))
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
						L.tried[d[0]] = 1; ui.note(tr('*Tu nieto:* «%s»') % tr(d[3]), 3); Snd.blip('nino')
			if g.other_held() and L.tm - L.said > 2:
				L.said = L.tm; ui.note(tx('*No ocurre nada. No hay tecla para lo que quieres decir.*', '*No ocurre nada. No hay botón para lo que quieres decir.*', '*No ocurre nada. No hay botón para lo que quieres decir.*'), 3); Snd.sfx('bad')
			return L.tried.size() >= 3 or L.tm > 16)
		g.need_stick = false; g.need_act = ''
	ui.panel_info(null); await g.wait(1.2)
	Snd.sfx('herald')
	await say('heraldo', '(En la calle, otra vez.) …¡arrestado, encarcelado o ejecutado!')
	await say('nieto', 'Abuelito… lo de 3³ era sólo una broma. Claro que no quería decir nada. Y entonces no sabíamos nada de la Ley nueva. Y yo no dije nada de la Tercera Dimensión.')
	# C9-04 · antes de reír, el nieto mira la puerta: al otro lado del muro, el heraldo
	if close and not g.auto:
		ui.close_dlg()
		kid.face(-41, 13.3); W.focus = Vector2(her.x, her.y); W.zoom = 34
		Snd.motif('nieto', '', true, 0.3)
		await g.wait(2.0)
		W.focus = null; W.zoom = W.base_zoom
	await say('nieto', 'Y seguro que no dije ni una palabra de «hacia Arriba, no hacia el Norte», porque sería una tontería. ¿Cómo va a moverse una cosa hacia Arriba y no hacia el Norte? Ni un bebé sería tan bobo. ¡Ja, ja, ja!')
	Snd.motif('nieto', '', true, 0.3)
	g.ledger('2d.rechazo')
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
	if close: await say('narr', 'Abrió la puerta y huyó. Diez años, y ya sabía lo que yo iba a tardar un año entero en olvidar: cuándo conviene reírse. No me traicionaba. Me protegía.')
	else: await say('narr', 'Abrió la puerta y huyó. Diez años, y ya sabía lo que yo iba a tardar un año entero en olvidar: cuándo conviene reírse.')
	g.frag(21)
	g.talk_end(o)
	await _eleven_months()   # C9-05
	await a.outro()

# C9-03 · el círculo que crece y mengua: lo que el Cuadrado vio de la Esfera, hecho con el stick
func _circle_demo() -> void:
	if g.auto or g.bot: return
	var st := {r = 0.15, t = 0.0, span = 0.0, lo = 1.0, hi = 0.0}
	var b := ui.slate(true, 'tablilla de lecciones')
	var help := ui.T(tx('Haz crecer y menguar el círculo con {move_up} y {move_down}.', 'Haz crecer y menguar el círculo con la palanca.', 'Haz crecer y menguar el círculo con el stick.'))
	var draw := func(cx: SlateBoard, _t: float):
		var c := Vector2(320, 200) * cx.k
		cx.draw_arc(c, 150.0 * st.r * cx.k, 0, TAU, 48, App.INK, maxf(1.0, 2.0 * cx.k), true)
		cx.text(help, 30, 34, 15)
	g.need_stick = true
	await g.tick_until(func(dt) -> bool:
		st.t += dt
		st.r = clampf(st.r + g.axis().y * 0.6 * dt, 0.02, 1.0)
		st.lo = minf(st.lo, st.r); st.hi = maxf(st.hi, st.r)
		b.paint(draw, 1.0)
		return (st.hi - st.lo > 0.6 and st.t > 4.0) or st.t > 14.0)
	g.need_stick = false
	await g.wait(0.6)
	slate_off()

# C9-05 · los once meses: tres planos sin diálogo
func _eleven_months() -> void:
	if g.auto or g.bot: return
	await ui.fade(true, 0.8)
	ui.chapter_tag('Los once meses')
	# 1. dibujar el Cubo: todo trazo cae en la tablilla
	var b := ui.draw_board(true, 'el tratado')
	var anc := PackedVector2Array()
	for j in 4:
		for i in 4: anc.append(Vector2(170 + i * 100, 340 - j * 90))
	b.reset(anc, 'reject')
	b.hint = func(bd: SlateBoard): bd.text(ui.T('Mes segundo. Intenta dibujar el Cubo.'), 30, 34, 15)
	var st := {t = 0.0, n = 0}
	var on_rej := func(): st.n += 1
	b.rejected.connect(on_rej)
	await g.tick_until(func(dt) -> bool:
		st.t += dt
		return st.t > 12.0 or st.n >= 3)
	b.rejected.disconnect(on_rej)
	# 2. recordar el Cubo con el ojo cerrado: cada vez más borroso
	var s := ui.slate(true, 'el ojo cerrado')
	for k in 3:
		var blur := 1.0 + k * 3.5; var a := 1.0 - k * 0.28
		var cube := func(cx: SlateBoard, _t: float):
			var pts := [[220, 290], [370, 290], [370, 140], [220, 140]]
			for rep in 4:
				var o := Vector2(randf_range(-blur, blur), randf_range(-blur, blur))
				for sq in [Vector2.ZERO, Vector2(70, -60)]:
					for i in 4:
						var p0: Vector2 = Vector2(pts[i][0], pts[i][1]) + sq + o; var p1: Vector2 = Vector2(pts[(i + 1) % 4][0], pts[(i + 1) % 4][1]) + sq + o
						cx.line(p0.x, p0.y, p1.x, p1.y, a / 3.0)
				for i in 4:
					var q: Vector2 = Vector2(pts[i][0], pts[i][1]) + o
					cx.line(q.x, q.y, q.x + 70, q.y - 60, a / 3.0)
			cx.text(ui.T(['Mes cuarto.', 'Mes séptimo.', 'Mes décimo.'][k]), 30, 34, 15)
		s.paint(cube, 1.0)
		await g.wait(3.2)
		s.paint(func(_cx, _t): pass, 1.0)
		await g.wait(0.8)
	# 3. el título del tratado, letra a letra
	var title := ui.T('De Planilandia a Pensamientolandia')
	await g.tween(5.0, func(t):
		s.paint(func(cx: SlateBoard, _t: float):
			cx.text(ui.T('Mes undécimo.'), 30, 34, 15)
			cx.text(title.substr(0, int(title.length() * t)), 90, 220, 32), 1.0))
	await g.wait(2.0)
	slate_off()

# ============ CAP. X — EL JUICIO ============
func ch10() -> void:
	g.set_map(town({palace = true})); var W := g.world; W.reveal('palace'); g.spawn_player(-28, 22.5, -PI / 2)
	var gone := ['prefecto', 'orador']
	g.add(F_poli('prefecto', -14, -33, 12, {name = 'el Prefecto', r = 1.2, rot = PI / 2}))
	g.add(F_penta('orador', -14, -29, {name = 'el conferenciante', rot = PI / 2}))
	var aq := [[-19, -23], [-16.5, -22], [-11.5, -22], [-9, -23], [-20, -26.5], [-8, -26.5]]
	for i in 6:
		var id := 'au%d' % i; gone.append(id)
		g.add(F_hexa(id, aq[i][0], aq[i][1], {rot = -PI / 2}) if i % 2 else F_penta(id, aq[i][0], aq[i][1], {rot = -PI / 2}))
	margins([['m_c10_banco', -17.6, -20.4]])
	await a.intro('Capítulo X', 'El juicio', 'Donde se pregunta a un Cuadrado hacia dónde cae Arriba.', 'flat')
	await narr('Callé once meses. Escribí en secreto un tratado, «De Planilandia a Pensamientolandia», fingiendo hablar de una tierra imaginaria.')
	await _treatise()   # C10-01
	await narr('Lo peor era mirar. Veía una raya y sabía que era un Cuadrado; veía mi casa y recordaba sus cinco lados a la vez. Cerraba el ojo para volver a ver el Cubo, y cada noche lo veía un poco peor.')
	await narr('Y un día acudí a una sesión de la Sociedad Especulativa local, en el palacio del Prefecto.')
	await g.go_to(-14, -22, 1.6, 'Entra en el Palacio y toma asiento en la Sociedad Especulativa')
	g.begin_scene()
	g.player.rot = -PI / 2; W.focus = Vector2(-14, -26); W.zoom = 40
	# C10-02 · callar, con el pulgar
	await say('orador', '…y queda así demostrado, señores, por qué la Providencia ha limitado a Dos el número de las Dimensiones, y por qué el atributo de verlo todo, la omnividencia, pertenece sólo al Ser Supremo.')
	ui.close_dlg(); await Restraint.run(self, 0.3, 4.5)
	var c = await choose([{t = '(Callar.)', id = 's'}, {t = '(Carraspear.)', id = 'a'}])
	await say('orador', 'Pues ¿quién de nosotros podría ver el interior de una casa cerrada? ¿Quién, el interior de su prójimo? Sería tanto como ver *desde ningún sitio*.')
	await say('asombro', 'Tú. Tú lo has visto. Tu casa. Tus hijos. Sus entrañas latiendo.')
	ui.close_dlg(); await Restraint.run(self, 0.5, 5.0)
	c = await choose([{t = '(Callar.)', id = 's'}, {t = '(Callar, con más esfuerzo.)', id = 's2'}])
	await say('orador', 'Una tercera dirección es, por tanto, no ya falsa: es *impensable*. Ninguna mente sana ha podido jamás concebirla.')
	ui.close_dlg(); await Restraint.run(self, 2.0, 5.0)
	await say('narr', 'Aquí puedes elegir lo que quieras. Te aviso de que no servirá.')
	c = await choose([{t = '(Callar.)', id = 's'}, {t = 'Supongamos, como fábula, que alguien la hubiera visto…', id = 'a'}, {t = '(Marcharte.)', id = 'm'}])
	if c == 's': await say('narr', 'Callé, sí. Unos tres granos de arena. Luego me oí decir: «Supongamos, como fábula, que alguien la hubiera visto…».')
	elif c == 'm': await say('narr', 'Llegué hasta la puerta. Con el perímetro ya en el umbral me oí decir: «Supongamos, como fábula, que alguien la hubiera visto…».')
	await say('yo', 'Un personaje ficticio, digamos. Una noche lo arrancan del Plano. Ve su ciudad por dentro. Ve el Consejo. Ve una Figura hecha de Círculos…')
	await say('yo', '…y no era ficticio. ¡Era yo! ¡Lo vi! Existe la Tercera Dimensión: ¡hacia Arriba, no hacia el Norte! ¡Sacudíos el prejuicio y creed!')
	await say('prefecto', 'Guardias. Al Consejo.')
	Snd.sfx('gavel'); g.her(1)
	if g.state.get('inv', {}).has('estilete'): g.note('estilete_en_poder', 2)
	await say('narr', 'Me olvidé de mí mismo. Es la expresión exacta: por una vez me olvidé del Cuadrado prudente que firmaba, aplaudía y callaba.')
	g.end_scene()
	await a.outro()

	# --- el Consejo ---
	for id in gone: W.remove(id)
	W.remove_spot('m_c10_banco'); g.off('m_c10_banco')
	g.teleport(-14, -24.5, -PI / 2)
	g.add(F_circ('presidente', -14, -33.5, {name = 'el Presidente', r = 1.5, rot = PI / 2}))
	var cx := [-22, -19, -9, -6]
	for i in 4: g.add(F_circ('co%d' % i, cx[i], -30 + absf(cx[i] + 14) * 0.35, {rot = PI / 2}))
	var low := [g.add(F_iso('lg0', -18, -19, 3, {name = 'un guardia de dos grados', rot = -1.57})), g.add(F_iso('lg1', -10, -19, 3, {name = 'un guardia de dos grados', rot = -1.57}))]
	# C10-05 · el sargento de la Puerta, entre los guardias del fondo
	var sarge: Ent = g.add(F_iso('sargento', -20.5, -17.5, 14, {name = 'el sargento de la Puerta', rot = -1.2}))
	ui.chapter_tag('Capítulo X · El juicio'); W.focus = Vector2(-14, -27); W.zoom = 42; Snd.drone('temple'); await ui.fade(false)
	await narr('A la mañana siguiente me hallé en el mismo punto de la sala donde, un año antes, se había posado la Esfera. Me dejaron contarlo todo sin interrumpirme.')
	g.begin_scene()
	await say('logica', 'Fíjate en los guardias. Han cambiado a los de rango por Isósceles de dos o tres grados. Sabes lo que significa: quien te oiga hoy no llegará a la noche.')
	Snd.tension(0.45)
	# C10-03 · el Presidente lee el expediente
	await say('presidente', 'Antes de oírle, el Consejo ha leído lo que de usted se sabe.')
	var top := g.record_top(5)
	if top.is_empty():
		await say('presidente', 'Nada. Un Cuadrado ejemplar. Eso es lo que más nos inquieta.')
		g.achieve('ACH_FILE')
	else:
		for r in top:
			var who: String = r.get('who', 'presidente')
			if not ui.SPEAKERS.has(who): who = 'presidente'
			await say(who, g.record_text(r))
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
				ui.note(tr('*El Presidente:* «Eso es %s, caballero.»') % tr(m), 3.5); Snd.blip('circ'); p.x = x0; p.y = y0; g.vel = Vector2.ZERO
			if g.other_held() and Q.tm - Q.said > 2.5:
				Q.said = Q.tm; g.set_view('top'); ui.note('*Nada. Tu cuerpo no tiene con qué.*', 3); Snd.sfx('bad')
			return Q.tries >= 3 or Q.tm > 22)
		g.need_act = ''
	ui.panel_info(null)
	g.begin_scene()
	g.player.x = x0; g.player.y = y0; W.focus = Vector2(-14, -27); W.zoom = 42
	await say('yo', 'No puedo señalarla. Pero existe.')
	await say('presidente', 'La segunda. ¿Puede, con diagramas o descripciones —que no sean enumerar lados y ángulos imaginarios—, mostrarnos esa Figura que llama Cubo?')
	# C10-04 · dibuja tú el Cubo; la guía tenue es la sombra que elegiste en el VIII
	ui.close_dlg()
	var drawn := await Brother.draw_shadow(self, 'tablilla del acusado', 'Dibuja el Cubo para el Consejo', 75.0)
	match drawn:
		'cube_shadow': await say('presidente', 'Veo un Cuadrado montado sobre otro y cuatro rayas que los cosen. Una figura Irregular de muchos lados. ¿Eso es su Cubo?')
		'hexagon': await say('presidente', 'Un Hexágono. ¿Pretende usted que un Cuadrado engendra Hexágonos?')
		'square': await say('presidente', 'Un Cuadrado. Usted mismo, caballero. Eso ya lo teníamos.')
		_: await say('presidente', 'Rayas, caballero.')
	await say('narr', 'Tú, lector, has visto un cubo en ese dibujo. Tú puedes. Lo has dibujado tú. Imagina ahora tener la verdad entera y ningún papel donde quepa.' if drawn == 'cube_shadow' else 'Tú, lector, sabes qué querías dibujar. Imagina tener la verdad entera y ningún papel donde quepa.')
	c = await choose([{t = 'Nada más puedo decir. Me encomiendo a la Verdad, cuya causa acabará por prevalecer.', id = 'a'}, {t = 'Retiro lo dicho. Fue la fiebre.', id = 'r', tag = 'Retractarse'}])
	if c == 'r': await say('narr', 'Pensé en decirlo. La frase estaba hecha, con sus cinco lados y ninguna ventana. No la dije. Es de lo poco de lo que estoy seguro.')
	Snd.tension(0.7)
	await say('presidente', 'El Consejo comparte su confianza en la Verdad. Si ella quiere que salga usted de la cárcel a evangelizar el mundo, ella proveerá. Prisión perpetua. Sin más rigor que el necesario para que no escape. Podrá ver a su hermano, que le precedió.')
	Snd.sfx('gavel')
	for i in 2: low[i].move_to(g.player.x + (1.8 if i else -1.8), g.player.y, 5)
	# el sargento que te apuntó ocho de ocho baja la cabeza
	if int(g.state.stats.get('gate_hits', 0)) >= 7:
		ui.close_dlg(); W.focus = Vector2(sarge.x, sarge.y); W.zoom = 30
		await g.tween(1.2, func(t): sarge.rot = lerpf(-1.2, -2.6, App.ease(t)))
		sarge.pause = 3.0; await g.wait(3.0)
		W.focus = Vector2(-14, -27); W.zoom = 42
	g.end_scene()
	await a.outro()

	# --- epílogo: siete años, tres visitas (C10-06) ---
	var args: Array = g.state.get('argumentos', [])
	if args.is_empty(): args = ['analogia']
	for k in 3:
		var year: int = [1, 4, 7][k]
		g.set_map(a.cell(year)); g.spawn_player(0, -1, PI / 2); W = g.world
		var bro := g.add(F_cuad('hermano', -2.2, 1.6, {name = 'tu hermano', rot = -0.6}))
		if year == 7:
			bro.sc = 0.92; bro.speed = 0.6
			margins([['m_c10_silla', -2.9, 2.4], ['m_c10_muesca', 3.2, 3.0]])
		ui.chapter_tag(tr('Epílogo · Año %d') % year); Snd.drone('cell'); Snd.tension(0.0)
		await ui.fade(false, 1.2)
		Snd.motif('hermano', 'strings', false, -12.0)
		if k == 0:
			await narr('Siete años. Mi hermano viene cada semana. Es de lo poco que me permiten, y lo que más me duele.')
			var o := await g.talk_begin('hermano', 'Habla con tu hermano')
			await say('yo', 'Hermano: tú estabas allí. La viste aparecer en la sala. Un punto, un Círculo que crecía, que menguaba. Oíste lo que dijo.')
			await say('hermano', 'Vi un Círculo que cambiaba de tamaño, sí. Y por haberlo visto estoy aquí. ¿Qué más quieres que haya visto?')
			await Brother.run(self, args[k % args.size()], year)
			g.talk_end(o)
		elif k == 1:
			await narr('El cuarto año le hablé de otra cosa. Siempre de otra cosa.')
			var o := await g.talk_begin('hermano', 'Habla con tu hermano')
			await say('hermano', 'Te veo flaco, hermano. Cuéntame qué has pensado esta semana. Pero despacio.')
			await Brother.run(self, args[k % args.size()], year)
			g.talk_end(o)
		else:
			await narr('El séptimo año llegó más despacio. Tenía los ángulos más blandos, como si el tiempo los hubiera palpado demasiado.')
			var o := await g.talk_begin('hermano', 'Habla con tu hermano')
			await say('hermano', 'Cuéntame otra vez lo del Cubo. Me gusta cómo se te iluminan los lados cuando lo cuentas.')
			await Brother.run(self, args[k % args.size()], year)
			await say('hermano', 'No te creo, hermano. Lo siento. ¿Cómo va a moverse algo hacia Arriba y no hacia el Norte? …Pero la semana que viene vuelve a contármelo.')
			g.achieve('ACH_BROTHER')
			g.talk_end(o)
		var go := func():
			await bro.move_to(-3.2, 2.6, 1)
			bro.hid = true
		go.call()
		await g.wait(1.0)
		if k < 2: await ui.fade(true, 1.0)
	await say('narr', 'No tengo un solo converso. La Revelación del milenio se hizo para mí, y para nada. Prometeo fue encadenado por bajar el fuego a los mortales; yo, pobre Prometeo de Planilandia, estoy preso por no haberles bajado nada.')
	W.add_spot({id = 'tablilla', x = 2.2, y = -2.2, label = 'el manuscrito'})
	var o2 := await g.talk_begin('tablilla', 'Vuelve al manuscrito', 'Escribir')
	# C10-07 · el cierre del manuscrito, con lo que hiciste
	for e in g.book.get('epilogue', []):
		if _epi(String(e['if'])): await say('narr', e.text)
	g.frag(22)
	await say('narr', 'Y sin embargo existo con la esperanza de que estas memorias lleguen, no sé cómo, a las mentes de la humanidad de Alguna Dimensión, y susciten una raza de rebeldes que se nieguen a ser confinados en una Dimensionalidad limitada.')
	g.talk_end(o2)
	g.view_lock = true; g.set_view('eye'); g.hide_eye_hint = true; g.locked = true; await g.wait(2.5)
	await narr('Esa es la esperanza de mis horas más luminosas. Ay, no siempre es así.', true)
	await narr('Hay momentos en que no puedo decir con honradez que recuerde la forma exacta del Cubo, una vez visto y tantas veces añorado. Y el precepto, «hacia Arriba, no hacia el Norte», me persigue como una Esfinge que devora el alma.', true)
	var fog0 := W.fog
	g.tween(14, func(t): W.fog = lerpf(fog0, 0.5, t))
	await narr('Hay horas de flaqueza en que Cubos y Esferas se desvanecen hacia el fondo de lo apenas posible; en que la Tierra de las Tres Dimensiones parece casi tan visionaria como la de Una o la de Ninguna…', true)
	await narr('…en que hasta este muro que me priva de la libertad, estas tablillas en que escribo, y todas las realidades sustanciales de Planilandia, no parecen más que el engendro de una imaginación enferma, o la tela sin fundamento de un sueño.', true)
	await ui.fade(true, 2.5)
	g.locked = false; g.hide_eye_hint = false
	# C10-08 · la mesa del lector, al revés
	var fr := ChFrame.new(g, ui); fr.a = a
	await fr.closing()
	var n: int = g.state.frags.size()
	await ui.title('Hacia Arriba, no hacia el Norte.', 'Planilandia', 'El manuscrito está completo: 22 de 22 secciones. Alguien, en Alguna Dimensión, lo ha leído.' if n >= 22 else tr('Has recuperado %d de 22 secciones del manuscrito. Las que faltan esperan en sus capítulos.') % n, 6.0)
	await ui.title('Edwin A. Abbott', 'Flatland, 1884', 'Un romance de muchas dimensiones.', 5.0)
	# C10-09 · tras los créditos
	Profile.unlock_gallery('prefacio'); Profile.unlock_mode('college')
	if not g.auto: ui.toast('frag', tr('Galería'), tr('El Prefacio del Editor a la segunda edición'))

# las condiciones del cierre del manuscrito (book.epilogue): flag:x · rel:x>=n · rep:x>=n · her>=n · choice:x=v · always
func _epi(cond: String) -> bool:
	var S: Dictionary = g.state
	if cond == 'always': return true
	var re := RegEx.new(); re.compile('^(flag|rel|rep|her|choice):?([a-zA-Z_]*)(>=|<=|!=|=)?(.*)$')
	var m := re.search(cond)
	if m == null: return false
	var kind := m.get_string(1); var key := m.get_string(2); var op := m.get_string(3); var val := m.get_string(4)
	var v
	match kind:
		'flag': return bool(S.flags.get(key, false))
		'rel': v = int(S.get('rel', {}).get(key, 0))
		'rep': v = int(S.get('rep', {}).get(key, 0))
		'her': v = int(S.get('her', 0))
		'choice': v = str(S.flags.get(key, ''))
	if v is int:
		var n := int(val)
		return v >= n if op == '>=' else (v <= n if op == '<=' else (v != n if op == '!=' else v == n))
	return v != val if op == '!=' else v == val

# C10-01 · el tratado: con qué argumentos lo escribe (dos; tres si el archivero le prestó una tablilla)
func _treatise() -> void:
	var pool := ['analogia', 'secciones', 'sombras', 'lineal', 'punto'].filter(func(k): return g.knows(k))
	if pool.is_empty(): pool = ['analogia']
	var n := 3 if g.rel_of('archivero') >= 1 else 2
	if n == 3: await narr('El viejo archivero me hizo llegar, sin una palabra, una tablilla en blanco. Cabía un argumento más.')
	var A: Dictionary = g.book.get('argumentos', {})
	var picked := []
	while picked.size() < mini(n, pool.size()):
		var cards := []
		for k in pool:
			if not picked.has(k): cards.append({id = k, label = A.get(k, {}).get('title', k), sub = str(cards.size() + 1)})
		var ch = await ui.panel('El tratado', ui.T('Elige con qué argumentos lo escribes (%d de %d).') % [picked.size() + 1, mini(n, pool.size())], cards)
		if not picked.has(ch): picked.append(ch)
	g.state.argumentos = picked; g.save()

# --try=ascent|sections|shadow|carry|tess: piezas sueltas del VIII
func try_mini(name: String) -> void:
	ui.hud.visible = true; ui.chapter_tag('Prueba · ' + name)
	# piezas del IX y el X (M5)
	match name:
		'lamina':
			for i in [1, 7, 10]: await ui.lamina('lam_%d' % i)
			return
		'restraint':
			g.set_map(town({palace = true})); g.spawn_player(-14, -22, -PI / 2); g.begin_scene()
			for sp in [0.3, 2.0]: print('contención ', await Restraint.run(self, sp, 4.0))
			return
		'brother':
			g.set_map(a.cell(4)); g.spawn_player(0, -1, PI / 2); g.add(F_cuad('hermano', -2.2, 1.6, {rot = -0.6})); g.begin_scene()
			for k in ['sombras', 'analogia']: await Brother.run(self, k, 4)
			return
		'closing':
			var fr := ChFrame.new(g, ui); fr.a = a
			await fr.closing()
			return
		'treatise':
			await _treatise(); print('argumentos ', g.state.argumentos)
			return
	var map := town({palace = true, hospital_room = true}); g.set_map(map); var W := g.world
	for b in map.buildings: W.known[b.id] = true
	W.rebuild()
	var p := g.spawn_player(-27.6, 12, -PI / 2)
	g.show_strip = false; g.view_lock = true; W.cam_mode = 'free'; W.free = {yaw = 0.0, pitch = 1.05, dist = 38.0}; p.no_collide = true
	W.show_guts = true; W._free_intro = 1.0; p.alt = 13.0; g.alt_min = 4; g.alt_max = 20
	var bd := Space.backdrop(false); W.add_child(bd); Snd.drone('space')
	match name:
		'ascent':
			p.alt = 0.4; W._free_intro = 0.0
			var P0 := Vector3(p.x, 0.0, -p.y)
			g.tween(9.0, func(t): p.alt = 0.4 + clampf((t - 0.33) / 0.67, 0.0, 1.0) * 12.6)
			await Cine.play(W, [{t = 0.0, pos = _cam_at(P0, 0.0, 0.02, 30.0), look = P0, ease = 'linear'}, {t = 3.0, pos = _cam_at(P0, 0.0, 0.03, 30.0), look = P0},
				{t = 6.0, pos = _cam_at(P0 + Vector3(0, 6, 0), 0.0, 0.4, 30.0), look = P0 + Vector3(0, 6, 0)}, {t = 9.0, pos = _cam_at(P0 + Vector3(0, 13, 0), 0.0, 1.05, 38.0), look = P0 + Vector3(0, 13, 0)}], true)
			W._free_intro = 1.0; await g.wait(1.0)
		'sections', 'shadow':
			var cube := Space.make_cube(); W.add_child(cube)
			var cm: ShaderMaterial = cube.material_override
			cm.set_shader_parameter('col', Vector3(0.98, 0.96, 0.89)); cm.set_shader_parameter('edge_col', World._v3(W.pal.edge))
			var at := Vector2(2.0, 6.0)
			var obs: Ent = g.add(F_penta('testigo', at.x + 7.0, at.y, {rot = PI}))
			g.eye_src = obs; g.eye_src_all = true; g.strip_in_space = true; g.show_strip = true
			p.x = at.x; p.y = at.y - 6.0; p.alt = 7.0; g.alt_min = 3.0; W.free = {yaw = 0.0, pitch = 0.55, dist = 16.0}
			g.begin_scene()
			if name == 'sections': print('secciones ', await CubeSections.run(self, cube, at))
			else: print('sombra ', await ShadowTurn.run(self, cube, at))
		'carry':
			g.add({id = 'tab2', pts = [[0.32, 0.12], [-0.32, 0.12], [-0.32, -0.12], [0.32, -0.12]], x = -30.2, y = 8.6, noCollide = true, noGuts = true, noEye = true, carryable = true})
			var stop := Carry.enable(self)
			g.alt_min = 1.5; p.alt = 3.0
			print('alacena ', await Carry.run(self, 'tab2', func(e): return ALACENA_RECT.has_point(Vector2(e.x, e.y)), 'Devuelve la tablilla a tu alacena cerrada', ALACENA_RECT.get_center()))
			stop.call()
		'tess':
			var tess := Space.make_lines(W.ink(Color('b79cf0'))); W.add_child(tess)
			var stop := Tesseract.start(self, tess, Vector3(p.x, p.alt + 2.0, -p.y - 9), {sc = 1.0})
			W.free = {yaw = 0.0, pitch = 0.35, dist = 24.0}
			await g.wait(8.0); stop.call()
