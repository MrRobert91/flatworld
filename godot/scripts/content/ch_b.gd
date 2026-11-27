# Capítulos IV–V: la Sedición Cromática (teatro de la memoria) y el Templo.
class_name ChB extends Ch

const HUES := ['#ff5a4f', '#ffa53b', '#ffe14d', '#59d98e', '#3fc4ff', '#7b74ff', '#e56bff', '#ff8fb0']
const RED := '#ff4a43'
const GREEN := '#3fd97a'

func paint(e: Ent) -> bool:
	if e.woman or e.n >= 20 or e.side_colors != null: return false
	var k := randi() % 8; var cols := []
	for i in e.local.size(): cols.append(HUES[(k + i * 3) % 8])
	e.set_colors(cols)
	return true

func agora() -> Dictionary:
	return {bounds = {x0 = -44, y0 = -28, x1 = 44, y1 = 28}, fog = 16.0, palette = 'color', zoom = 56.0,
		walls = [[-6, 16, 6, 16], [-6, 16, -8, 19], [6, 16, 8, 19]],
		labels = [{t = 'Mercado', x = -16, y = -8, s = 1.6, a = 0.25}, {t = 'Tribuna', x = 0, y = 18.4, s = 0.9, a = 0.5}, {t = 'teatro de la memoria · hace muchos siglos', x = 0, y = -24, s = 0.7, a = 0.4, it = true}]}

func crowd(n: int, mix: Array) -> Array:
	var out := []
	for i in n:
		var k: String = mix[i % mix.size()]; var x := -30.0 + randf() * 60.0; var y := -16.0 + randf() * 26.0; var id := 'c%d' % i
		var d: Dictionary
		match k:
			'iso': d = F_iso(id, x, y, 6.0 + randf() * 14.0)
			'mujer': d = F_mujer(id, x, y)
			'tri': d = F_tri(id, x, y)
			'cuad': d = F_cuad(id, x, y)
			'penta': d = F_penta(id, x, y)
			'circ': d = F_circ(id, x, y)
			_: d = F_hexa(id, x, y)
		d.ai = {type = 'wander', home = Vector2(x, y), r = 6.0}; d.speed = 1.3 + randf()
		out.append(g.add(d))
	return out

func ch4() -> void:
	# --- el Colegio ---
	g.set_map(town({school = true})); g.spawn_player(-41, 13.3, -PI / 2); a.town_folk()
	var W := g.world
	g.add(F_hexa('archivero', 18, 23, {name = 'el viejo archivero', r = 0.95, rot = -1.57}))
	for i in 3:
		var d := F_poli('e%d' % (i + 1), 13 + i * 4, 17 + (i % 2) * 2, 6 + i, {r = 0.55, name = 'un estudiante'})
		d.ai = {type = 'wander', home = Vector2(14 + i * 4, 17), r = 2.5}; d.speed = 1.6
		g.add(d)
	g.on('e1', 'Hablar', func(): await say('estudiante', 'Si suspendo el examen final de Vista, señor, no seré ni noble ni plebeyo. A los suspendidos no los quiere nadie. Dicen que de ahí salen todos los revoltosos.'))
	g.on('e2', 'Hablar', func(): await say('estudiante', 'Tres años para distinguir un Decágono de un Dodecágono en movimiento. Mi padre dice que es lo único que nos separa de los que palpan.'))
	await a.intro('Capítulo IV', 'El tiempo de los colores', 'Donde un viejo recuerda que el mundo no siempre fue una línea gris.', 'flat')
	var ic = g.flag('irregularChoice')
	if ic == null or ic == 's': await narr('No dormí bien. A la mañana siguiente fui al Colegio de Vista, con el pretexto de consultar un tratado. En realidad quería que alguien me dijera que mirar y callar era lo correcto.')
	elif ic == 'o': await narr('Dormí bien, lo confieso. A la mañana siguiente fui al Colegio de Vista a consultar un tratado. Me sentía un buen ciudadano.')
	else: await narr('No dormí. A la mañana siguiente fui al Colegio de Vista; quería saber si siempre habíamos sido así.')
	await g.go_to(18, 12.5, 2.2, 'Ve al Colegio de Vista, al este por la Calle Mayor')
	W.reveal('school')
	# el examen final del Colegio (C4-01), opcional; y las notas al margen del Colegio
	W.add_spot({id = 'examen', x = 12.6, y = 22.5, label = 'el tribunal de Vista'})
	g.on('examen', 'Presentarse de oyente', func(): await _exam())
	a.margins([['m_c4_pasquin', 11.5, 25.0], ['m_c4_vitrina', 24.6, 25.6]])
	var o := await g.talk_begin('archivero', 'Habla con el viejo archivero')
	await say('archivero', 'El perito de la Puerta. Ya se sabe por aquí lo del calderero. ¿Viene a por absolución? No la doy: soy archivero.')
	await say('archivero', 'Doy otra cosa. ¿Sabe usted que hubo un tiempo en que no hacía falta mirar con tanto esfuerzo, ni palpar a nadie? Un tiempo en que cada cual llevaba escrito por fuera lo que era… o lo que quería ser.')
	var c = await choose([{t = 'El Color. Sé que está prohibido nombrarlo.', id = 'a'}, {t = 'Cuentos de viejos.', id = 'b'}])
	await say('archivero', 'Aquí dentro, entre tablillas, se puede nombrar. Flojito.' if c == 'a' else 'Cuentos, sí. Con ciento cuarenta mil muertos al final. Siéntese.')
	await say('archivero', 'Cierre el ojo. Los del Colegio lo llamamos el Teatro de la Memoria. Durante un rato será usted otro: un Pentágono al que la historia llama Cromatistes.')
	g.talk_end(o)
	await a.outro()

	# --- teatro de la memoria: Cromatistes ---
	g.set_map(agora()); g.spawn_player(-20, -12, 0.4, {n = 5, r = 0.85, name = 'Cromatistes'})
	var folk := crowd(34, ['iso', 'tri', 'cuad', 'hexa', 'iso', 'penta', 'mujer', 'tri', 'iso', 'circ'])
	a.margins([['m_c4_poema', -27.0, 6.0]])
	ui.chapter_tag('Teatro de la memoria · Cromatistes'); Snd.drone('color'); g.set_view('top'); await ui.fade(false)
	await narr('Mira: el mismo mundo, siglos atrás. Todo líneas pálidas, como hoy. Y tú, un Pentágono cualquiera que una tarde, revolviendo tierras y óxidos en su taller, da con algo que no tiene nombre.')
	if not g.auto:
		var cols := []
		var sw := []
		for h in HUES: sw.append({swatch = h, id = h})
		for i in 5:
			var pick = await ui.panel('Los pigmentos', tr('Elige un color para tu lado %s.') % tr(['primero', 'segundo', 'tercero', 'cuarto', 'quinto'][i]), sw)
			cols.append(pick)
			var all_c := cols.duplicate()
			while all_c.size() < 5: all_c.append('#3a2f24')
			g.player.set_colors(all_c); Snd.tone(300 + i * 80, 0.5, 'sine', 0.1)
			if i == 0:
				# el primer color de un mundo gris (C4-02): de cerca, y un acorde que nunca ha sonado
				var p := g.player
				W.focus = Vector2(p.x, p.y); W.zoom = 8; W.zoom_cur = 9
				Snd.chord_once(60)
				await g.wait(1.8)
				W.focus = null; W.zoom = W.base_zoom
	else: g.player.set_colors(HUES.slice(0, 5))
	await narr('Primero pintaste tu casa. Luego a tus esclavos, a tu padre, a tus hijos, a tus nietos. Por último, a ti. Y saliste al mercado.')
	var st := {painted = 0}
	g.objective('Pasea por el mercado. Que te vean.')
	var stop := g.tick(func(_dt):
		var p := g.player
		for e in folk:
			if Vector2(e.x - p.x, e.y - p.y).length() < 3.6 and paint(e):
				st.painted += 1; Snd.tone(400 + st.painted * 35, 0.4, 'sine', 0.07))
	var paint_all := func():
		for e in folk: paint(e)
	await g.until(func(): return st.painted >= 12, paint_all)
	stop.call(); paint_all.call(); g.objective('')
	await narr('Nadie tropezaba contigo. Nadie tenía que palparte ni calcular tus ángulos: te *veían*. En dos generaciones no quedaba figura sin pintar, salvo las Mujeres y los Sacerdotes, que no tienen lados.')
	g.begin_scene()
	g.set_view('eye'); await g.wait(1.5)
	await narr('Míralo con el ojo de un planilandés. Ya no es una raya gris: cada cual lleva su clase a la vista. Fue la infancia del Arte. Inmoral, anárquica… y bellísima.')
	ui.close_dlg()
	# la comparación (C4-03): la misma escena en gris y en color, dos veces
	await g.tween(6.0, func(t): g.eye.desat = 0.5 + 0.5 * cos(t * 3.0 * PI))
	g.eye.desat = 0.0
	await say('asombro', 'Ahora lo ves todo a la primera. Tú, que tardaste años en el Colegio.')
	ui.close_dlg()
	await g.wait(1.0); g.set_view('top')
	g.end_scene()
	g.frag(8)
	await narr('Pero si un soldado se pinta como un noble, ¿en qué se distinguen? El Reconocimiento por la Vista dejó de estudiarse. Y los de abajo empezaron a decir, cada vez con más razón, que eran iguales a los de arriba.')

	# --- el Proyecto de Ley ---
	var ag_pts := []
	for i in 26:
		var an := i / 26.0 * TAU
		ag_pts.append([cos(an) * (1 + 0.13 * cos(an * 2 + 0.5)), sin(an) * 0.9])
	g.add({id = 'agitador', pts = ag_pts, noEye = true, voice = 'iso', x = 0, y = 14, rot = -1.57, name = 'el tribuno'}).set_colors(HUES)
	var pri := g.add(F_circ('cura', 9, 12, {name = 'un Sacerdote', rot = -2.0})); var dam := g.add(F_mujer('damaC', -8, 12, {name = 'una mujer', rot = -1.0}))
	o = await g.talk_begin('agitador', 'Años después. Escucha al tribuno, junto a la Tribuna', 'Escuchar')
	await say('agitador', '¡Ciudadanos de todos los ángulos! ¿Quién sigue sin color en Planilandia? ¡Ellos! Los Círculos, que nos gobiernan. Y ellas, que no tienen voto ni lados.')
	await say('agitador', 'Proyecto de Ley del Color Universal: ¡que todos se pinten! Y como ni mujeres ni sacerdotes tienen lados, sea roja la mitad de cada cual que lleva el ojo y la boca, y verde la otra mitad.')
	var pc := []
	for i in 30: pc.append(RED if (i < 8 or i > 22) else GREEN)
	pri.set_colors(pc); dam.set_colors([RED, GREEN, GREEN, RED]); Snd.sfx('her')
	await say('logica', 'Piensa lo que eso significa visto *de canto*. Una mujer: línea mitad roja, mitad verde. Un sacerdote: línea mitad roja, mitad verde.')
	await say('agitador', '¡Cualquier mujer podrá ser tomada por un Círculo, y tratada como tal! ¡Y cualquier Círculo, por una mujer! ¿Quién se opondrá? ¿Vuestras esposas?')
	await say('narr', 'Era diabólico, y era brillante. Lo ideó un Círculo Irregular, a quien una indulgencia insensata perdonó la vida de niño. Las mujeres apoyaron la Ley en masa. Tres años estuvo el Estado al borde del abismo.')
	c = await choose([{t = '(Gritar con la multitud.) ¡Color para todos!', id = 'h', tag = 'Herejía'}, {t = '(Callar.) Esto acabará en sangre.', id = 's'}, {t = '(Abuchear.) ¡Demagogo irregular!', id = 'o'}])
	if c == 'h': await say('voces', '¡Color! ¡Color! ¡Color!'); g.her(1); g.note('college_color', 1)
	elif c == 'o': await say('voces', '(Te empujan. Aquí eres minoría.)'); g.her(-1)
	g.frag(9)
	g.talk_end(o)
	await _woman_or_priest()

	# --- el fraude ---
	await narr('Un ejército de Isósceles había vencido ya a los Polígonos. Entonces ocurrió, aquí mismo, en el mercado, un incidente pequeño. Míralo tú. Con el ojo.')
	g.begin_scene()
	g.player.x = -14; g.player.y = -6; g.player.rot = 0; W.cam_x = -14; W.cam_y = -6
	for e in folk:
		if absf(e.y + 6) < 4 and e.x > -16: e.y += 9; e.ai.home.y += 9
	g.view_lock = true; g.set_view('eye'); var f0 := W.fog; W.fog = 4.0; await g.wait(1.3)
	var twelve := []
	for i in 12: twelve.append(HUES[(i * 3) % 8])
	g.add(F_mujer('doncella', -6.0, -3.2, {name = 'una doncella', rot = PI}))
	var fraud = await sight_round('iso', {deg = 9.0, colors = twelve, near = 3.0, title = 'En el mercado', text = 'Se te acerca alguien con doce colores y la voz redonda de un gran señor. ¿Qué es?',
		options = [{id = 'dode', label = 'Dodecágono', sub = 'doce colores'}, {id = 'iso', label = 'Isósceles', sub = 'una cuña'}, {id = 'hexa', label = 'Hexágono', sub = 'un noble menor'}],
		verdict = func(r): return 'Lo has calado: un Isósceles de cuatro grados, pintado con los doce colores de un Dodecágono.' if r == 'iso' else 'Era un Isósceles de cuatro grados, pintado con los doce colores de un Dodecágono. *El color miente mejor que la voz.*'})
	W.fog = f0; g.set_view('top'); g.view_lock = false
	if fraud is String and fraud == 'iso':
		# el fraude con consecuencias (C4-05): la doncella te oye y se aparta… en el teatro
		var dz := g.npc('doncella')
		if dz != null: dz.move_to(-12.0, -14.0, 3.0)
		await say('yo', '(En voz alta.) Señora: ése es un Isósceles de cuatro grados, pintado.')
		await narr('Ese día, en el teatro, la salvé. En la historia, no la salvó nadie.')
	await narr('Así engañó a una doncella, huérfana de un noble Polígono. Hubo boda. Cuando ella descubrió el fraude, se quitó la vida. La noticia corrió de casa en casa, y las mujeres empezaron a mirar la Ley con otros ojos.')
	g.end_scene()

	# --- Pantociclo ---
	var pan := g.add(F_circ('pantociclo', 0, 22, {name = 'Pantociclo', r = 1.5, rot = -1.57})); await pan.move_to(0, 13.2, 3)
	g.npc('agitador').move_to(-5, 11, 2)
	var guards := []
	for i in 4: guards.append(g.add(F_iso('pg%d' % i, -9 + i * 6, 20, 14, {name = 'un preso armado', rot = -1.57})))
	Snd.tension(0.25)
	o = await g.talk_begin('pantociclo', 'Asamblea extraordinaria. Acude ante el Círculo Supremo', 'Escuchar')
	Snd.tension(0.4)
	await say('pantociclo', 'Ciudadanos. Los Círculos hemos decidido ceder. Aceptamos la Ley del Color. Sólo os pido, antes de votar, que me escuchéis una última vez.')
	await say('narr', 'Habló casi un día entero. Nadie supo después repetir sus frases, sólo lo que hicieron.')
	# el discurso en tres planos (C4-06): la cámara va a quien le habla
	var centroid := func(list: Array) -> Vector2:
		var cc := Vector2.ZERO; var n := 0
		for e in list:
			if is_instance_valid(e) and not e.hid: cc += Vector2(e.x, e.y); n += 1
		return cc / maxf(n, 1)
	var artisans := folk.filter(func(e): return not e.woman and not e.def.has('iso') and e.n < 20)
	var women_l := folk.filter(func(e): return e.woman)
	W.focus = centroid.call(artisans); W.zoom = 34
	for e in artisans: e.pause = 6.0
	await say('pantociclo', 'Artesanos: hoy vuestros hijos pueden nacer Equiláteros y subir. Cuando nada distinga a un noble de un obrero, ¿a qué subirán? Lo que ganáis en pintura lo perdéis en hijos.')
	W.focus = centroid.call(women_l); W.zoom = 30
	# las mujeres giran de punta hacia los soldados: en la lámina se ve venir
	var isos_l := folk.filter(func(e): return e.def.has('iso'))
	for e in women_l:
		e.ai = null
		var best = null; var bd := 1e9
		for q in isos_l:
			var dd := Vector2(q.x - e.x, q.y - e.y).length()
			if dd < bd: bd = dd; best = q
		if best != null:
			var to_rot := atan2(best.y - e.y, best.x - e.x); var from_rot: float = e.rot; var ee: Ent = e
			g.tween(2.0, func(t): if is_instance_valid(ee): ee.rot = from_rot + App.ang_diff(from_rot, to_rot) * t)
	await say('pantociclo', 'Mujeres: recordad a la doncella del mercado. Con el Color, ningún honor de esposa está a salvo de un impostor de cuatro grados.')
	c = await choose([{t = '(Mirar a las mujeres. Están girando.)', id = 'a'}, {t = '(Mirar a los presos armados junto a la Tribuna.)', id = 'b'}, {t = '(Gritar.) ¡Es una trampa!', id = 'c', tag = 'Cuestionar'}])
	if c == 'a':
		W.focus = centroid.call(women_l); W.zoom = 22
		await say('logica', 'Todas de punta. Todas hacia un soldado. Nadie se lo ha mandado en voz alta.')
	elif c == 'b':
		W.focus = Vector2(0, 19); W.zoom = 22
		await say('logica', 'Cuatro presos, armados, junto a las salidas. Alguien les ha abierto la celda esta mañana.')
	if c == 'c': await say('logica', 'Nadie te oye. Un día entero de discurso lo ha preparado todo; tu grito llega con un día de retraso.')
	W.focus = Vector2(0, 12); W.zoom = 40
	await say('pantociclo', '¡Antes la muerte que el Color!')
	Snd.sfx('gavel'); Snd.tension(1.0)
	ui.close_dlg()
	# la matanza
	# la cámara se abre sobre toda la plaza; los presos caen sobre el tribuno
	W.focus = Vector2(0, 3); W.zoom = 66
	for gd in guards: gd.move_to(-5 + randf() * 2, 11 + randf(), 9)
	await g.wait(0.8); W.slay(g.npc('agitador')); Snd.sfx('stab'); g.off('agitador')
	var isos := folk.filter(func(e): return e.def.has('iso'))
	var women := folk.filter(func(e): return e.woman)
	# artesanos y nobles se apartan hacia los bordes de la plaza
	for e in folk:
		if e.woman or e.def.has('iso'): continue
		e.ai = {type = 'wander', home = Vector2(clampf(e.x * 1.8, -39, 39), clampf(e.y * 1.8 - 4, -24, 12)), r = 2.0}; e.speed = 4.5
	# los Isósceles corren sin saber adónde; las mujeres retroceden de punta sobre ellos, los presos rematan
	var k := 0
	for e in isos:
		e.speed = 6.5; e.ai = {type = 'wander', home = Vector2(randf() * 16 - 8, randf() * 10 - 5), r = 7.0}
		var killer: Ent = women[k % women.size()] if k % 2 == 0 and not women.is_empty() else guards[k % guards.size()]
		g.after(0.4 + k * 0.45, func():
			if not is_instance_valid(e) or not is_instance_valid(killer): return
			killer.ai = null; killer.move_to(e.x, e.y, 14)
			g.after(0.32, func():
				if is_instance_valid(e): W.slay(e); Snd.sfx('stab')))
		k += 1
	await g.wait(1.4 + isos.size() * 0.45)
	W.focus = null; W.zoom = W.base_zoom
	await narr('A una señal, las mujeres retrocedieron de punta sobre los soldados. Los artesanos las imitaron. Los presos tomaron las salidas. Los Isósceles, creyéndose traicionados, se revolvieron unos contra otros.')
	await narr('En media hora no quedaba ninguno. Ciento cuarenta mil, muertos por los ángulos de sus compañeros.')
	ui.close_dlg()
	# después de la matanza, el silencio (C4-08): la plaza vacía, las marcas en el papel, la lluvia
	Snd.tension(0.0); Snd.drone('none'); W.rain = 0.5
	W.focus = Vector2(0, 0); W.zoom = 64
	await g.wait(12.0)
	# luego el color se va, lado a lado
	var painted := W.ents.values().filter(func(e): return e.side_colors != null and not e.hid)
	for step in 12:
		for e in painted:
			if not is_instance_valid(e) or e.side_colors == null: continue
			var cols: Array = (e.side_colors as Array).duplicate()
			for j in cols.size():
				if j <= step * cols.size() / 11: cols[j] = '#8d959a'
			e.set_colors(cols)
		await g.wait(0.3)
	W.rain = 0.0
	for e in W.ents.values():
		if e.side_colors != null: e.set_colors(null)
	W.set_palette('flat'); Snd.drone('cell'); Snd.tension(0.15); Snd.sfx('fall')
	await g.wait(1.5)
	Snd.tension(0.0); Snd.drone('flat')
	await narr('Después vinieron las purgas: todo Triángulo sospechoso, destruido sin medición. Y el Color quedó abolido. Hoy sólo un viviente conoce el secreto de fabricarlo: el Círculo Supremo.')
	g.frag(10); g.learn('color')
	g.talk_end(o)
	await a.outro()

	# --- de vuelta ---
	g.set_map(town({school = true})); W.reveal('school'); g.spawn_player(18, 20.5, PI / 2)
	g.add(F_hexa('archivero', 18, 23, {name = 'el viejo archivero', r = 0.95, rot = -1.57}))
	ui.chapter_tag('Capítulo IV · El tiempo de los colores'); await ui.fade(false)
	o = await g.talk_begin('archivero', 'Abre el ojo. Habla con el archivero')
	await say('archivero', 'Ya está. Vuelve usted a ser una raya gris entre rayas grises. ¿Qué le ha parecido?')
	c = await choose([{t = 'Que era hermoso. Y que nos lo quitaron.', id = 'h', tag = 'Herejía'}, {t = 'Que el Color era una mentira peligrosa. Hicieron bien.', id = 'o', tag = 'Ortodoxia'}, {t = 'Que Pantociclo no convenció a nadie: los enfrentó.', id = 'l', lock = null if g.knows('clases') else 'requiere conocer las clases'}])
	if c == 'h': await say('archivero', 'Baje la voz. …Sí. Yo también lo pienso, los días de lluvia.'); g.her(1); g.rel('archivero', 1)
	if c == 'o': await say('archivero', 'Eso dice el manual. Tiene usted buena memoria para los manuales.'); g.her(-1); g.rep('sac', 1); g.rel('archivero', -1)
	if c == 'l': await say('archivero', 'Ah. Un Cuadrado que mira la mano y no la boca. Tenga cuidado con ese ojo, perito: aquí se premia ver ángulos, no ver *eso*.'); g.her(1); g.rel('archivero', 1)
	await say('archivero', 'Mañana hay ceremonia en el Templo. Vaya. Conviene que lo vean a usted allí, después de lo de la Puerta.')
	g.talk_end(o)
	await a.outro()

# ============ CAP. V — EL TEMPLO ============
func ch5() -> void:
	var map := town({temple = true})
	for q in [['Círculos', -33], ['Nobleza', -29.6], ['Profesionales', -26], ['Equiláteros', -22.4], ['Isósceles', -18.8]]:
		map.labels.append({t = q[0], x = 19.4, y = q[1], s = 0.55, a = 0.5, it = true})
	map.labels.append({t = 'mujeres', x = 41.2, y = -19.5, s = 0.55, a = 0.5, it = true})
	map.labels.append({t = 'Gimnasio Neoterapéutico', x = 47, y = -11.5, s = 0.6, a = 0.45, it = true})
	g.set_map(map); var W := g.world; W.reveal('temple'); g.spawn_player(-26.5, 15.0, PI)
	# por la mañana, en casa: el nieto y la tablilla rota (C5-04)
	g.add(F_hexa('nieto', -29.5, 15.2, {name = 'tu nieto menor', r = 0.6, rot = 0.0}))
	var up := {rot = -PI / 2}
	g.add(F_circ('circulo', 30, -37, {name = 'el Círculo oficiante', r = 1.5, rot = PI / 2}))
	var i := 0
	for x in [24, 27, 33, 36]: g.add(F_circ('tc%d' % i, x, -33, up)); i += 1
	i = 0
	for x in [23, 26, 29, 32, 35]: g.add(F_poli('tn%d' % i, x, -29.6, 6 + (x % 5), up)); i += 1
	i = 0
	for x in [23, 25.5, 28, 34.5, 37]:
		g.add(F_penta('tp%d' % i, x, -26, up) if fmod(x, 2.0) != 0.0 else F_cuad('tp%d' % i, x, -26, up)); i += 1
	i = 0
	for x in [22, 24.5, 27, 29.5, 32, 34.5, 37]: g.add(F_tri('tt%d' % i, x, -22.4, up)); i += 1
	i = 0
	for x in [23, 25, 27, 29, 31, 33, 35, 37]: g.add(F_iso('ti%d' % i, x, -18.8, 8 + (x % 9), up)); i += 1
	i = 0
	for y in [-28, -25, -22, -19]: g.add(F_mujer('tm%d' % i, 41.2, y, {rot = PI, sway = 1.3})); i += 1
	# tu hermano, Escribano Mayor del Consejo, en la fila de los Profesionales (C5-01)
	g.add(F_cuad('hermano', 32.2, -26, {name = 'tu hermano', rot = -PI / 2}))
	margins([['m_c5_ujier', 19.5, -27.6], ['m_c5_lados', 26.0, -35.0], ['m_c5_mujeres', 39.6, -23.5]])
	await a.intro('Capítulo V', 'Atiende a tu Configuración', 'Donde los Círculos explican por qué nadie tiene la culpa, y a quién se castiga de todos modos.', 'temple')
	var ex := await _excuse()
	await narr('Después fui al Templo, como me había aconsejado el archivero. El Templo de los Círculos: tantos lados que desde dentro la pared parece no tener ninguno.')
	await g.go_to(30, -12, 2, 'Ve al Templo, al sur de la Calle Mayor, y entra')
	await narr('Cada clase tiene su fila; más cerca del altar cuantos más lados. Busca la tuya.')
	var st := {scold = false}
	var stop := g.tick(func(_dt):
		if not st.scold and g.player.y < -27.9 and absf(g.player.x - 30) < 11:
			st.scold = true; ui.note('*Un ujier te cierra el paso con un ángulo muy educado.* «La fila de los Profesionales está detrás, caballero.»', 5); g.rep('sac', -1); g.player.y = -27.0)
	var oh := await g.talk_begin('hermano', 'Tu hermano te guarda sitio en la fila de los Profesionales')
	await _brother()
	g.talk_end(oh)
	g.teleport(30, -26, -PI / 2)
	stop.call()
	g.begin_scene()
	W.focus = Vector2(30, -29); W.zoom = 44
	await say('circulo', 'Hijos del Plano. Hay una sola ley, y cabe en cuatro palabras. Decidlas conmigo.')
	var c = await choose([{t = '(Cantar con la asamblea.)', id = 'o'}, {t = '(Susurrar.) ¿Y quién atiende a la del calderero?', id = 'h', tag = 'Herejía', lock = null if g.flag('irregularChoice') else true}])
	if c == 'o':
		# el cántico con ritmo (C5-02): cuatro sílabas, a tiempo con la asamblea
		ui.close_dlg()
		var hits := await Hymn.run(self)
		g.flag('himno', hits)
		await say('voces', '«ATIENDE A TU CONFIGURACIÓN.»')
		if hits == 0:
			await say('decoro', 'Tu silencio se ha oído. En un Templo, callar a destiempo también es una voz.')
			g.note('temple_silent', 1)
		elif hits >= 3:
			await say('decoro', 'Te has fundido con el coro. Nadie podría distinguir tu voz de la de los demás. De eso se trata.')
			g.rep('sac', 1)
			if hits == 4: g.achieve('ACH_HYMN')
		else: await say('decoro', 'Un poco a destiempo, pero entre tantas voces nadie lo nota. Casi nadie.')
	else:
		await say('voces', '«ATIENDE A TU CONFIGURACIÓN.»')
		# tu hermano te pisa el lado, discretamente
		var h := g.npc('hermano'); var p := g.player
		if h != null:
			var d := Vector2(p.x - h.x, p.y - h.y).normalized() * 0.3
			h.x += d.x; h.y += d.y; h.shake = 0.6; p.shake = 0.4
		await say('hermano', '(Te pisa el lado, sin mirarte.) Aquí no, hermano.')
		await say('decoro', 'El Pentágono de tu izquierda se ha apartado medio paso. Te ha oído.')
		g.her(1); g.rep('sac', -1); g.note('temple_whisper', 2); g.rel('hermano', -1)
	await say('circulo', 'Lo que sois, lo sois por vuestros ángulos. El ladrón Isósceles no elige robar: su vértice roba por él. No lo culpamos. No culpamos a nadie.')
	await say('circulo', 'Y como él no puede evitar ser un daño para sus vecinos, el Magistrado no puede evitar hacerlo consumir. Así, sin culpa y sin rencor, todo queda en orden.')
	await say('logica', 'Sigue el razonamiento: si nadie es culpable, nadie merece castigo. Y sin embargo castigan. El silogismo cojea de un lado. Irregular, diríase.')
	await say('narr', 'Los llamamos Círculos, pero ninguno lo es. Son Polígonos de lados tan numerosos y pequeños que no se distinguen. Del Círculo Supremo se dice, por cortesía, que tiene diez mil. Palparlo para comprobarlo sería impensable.')
	g.frag(11); g.learn('config')
	# presentación del recién nacido
	var pa := g.add(F_iso('padre', 27, -14, 58, {name = 'el padre'})); var ma := g.add(F_mujer('madre', 29, -13.5, {name = 'la madre'})); var be := g.add(F_tri('bebe', 28, -14.6, {r = 0.38, name = 'el niño'}))
	Snd.sfx('bell')
	await say('circulo', 'Hoy hay júbilo. A un obrero de cincuenta y nueve grados y medio le ha nacido un hijo. Que lo traigan.')
	await g.moves([[pa, 28.6, -34.6, 3.5], [ma, 31.6, -34.4, 3.5], [be, 30, -34.8, 3.5]])
	W.focus = Vector2(30, -31); W.zoom = 38
	await _measure(be)
	await say('circulo', 'La Junta Sanitaria y Social ha medido. Sesenta grados. Sesenta. Sesenta. Lo declaramos Regular: un Equilátero.')
	await say('asombro', 'Lo mismo que hiciste tú con el comerciante. Un ángulo palpado. Hoy decide la vida de una familia.')
	await say('voces', '(Un murmullo de fila en fila. En la de los Isósceles, algo parecido a un sollozo de orgullo.)')
	await say('padre', 'Gracias, Reverencia. Gracias. Cien generaciones, y me ha tocado a mí verlo.')
	var ad := g.npc('tt3'); await ad.move_to(30, -31.5, 3)
	await say('circulo', 'Un Regular no puede criarse entre puntas. Será adoptado por este Equilátero sin hijos. Padre: jura no volver a verlo.')
	await say('padre', '…Lo juro.')
	await say('madre', '¿Adónde lo llevan? Esposo, ¿adónde llevan al niño?')
	var c2 = await choose([{t = '(Aplaudir con la asamblea.)', id = 'o'}, {t = '(Bajar el ojo.)', id = 's'}, {t = '(En voz alta.) ¡Dejad al menos que la madre lo visite!', id = 'h', tag = 'Cuestionar'}])
	be.ai = {type = 'follow', target = 'tt3', dist = 1.0, speed = 4.0}
	var leave := func():
		await ad.move_to(30, -11, 3)
		ad.hid = true; be.hid = true
	leave.call()
	if c2 == 'o': await say('narr', 'Aplaudí. Era un día de fiesta, y yo un ciudadano que sabía cuándo se aplaude.'); g.rep('sac', 1); g.her(-1)
	if c2 == 's': await say('narr', 'Miré al suelo, que en mi mundo es mirar a ninguna parte.')
	if c2 == 'h':
		await say('circulo', 'El caballero de cuatro lados confunde la piedad con la Geometría. La madre lo habrá olvidado antes de la cena: su Configuración no retiene. ¿No es una misericordia?')
		await say('madre', '¿Qué niño?')
		await say('recelo', 'No. Ha dicho «¿qué niño?» porque tres ujieres la están mirando.'); g.her(1); g.rep('sac', -2); g.rep('ciu', 1); g.note('temple_mother', 3)
	await say('narr', 'Esa es la esperanza que sostiene a los de abajo: que un día les nazca un hijo que les quiten. Los Círculos la llaman válvula de seguridad.')
	await g.moves([[pa, 27, -18.8, 3], [ma, 41.2, -16.5, 3]])
	await say('circulo', 'Id en orden. Atended a vuestra Configuración.')
	W.focus = null; W.zoom = W.base_zoom
	g.end_scene()
	g.add(F_circ('novicio', 38, -13.5, {name = 'un Círculo joven', r = 0.85, rot = 2.5}))
	var o := await g.talk_begin('novicio', 'Un Círculo joven te hace una seña junto a la salida')
	await say('novicio', 'Lo he observado durante el oficio, Cuadrado. Tiene usted el perímetro inquieto. Pregunte: prefiero una duda dicha que una pensada.')
	var asked := 0; var done := {}
	while asked < 2:
		var opts := []
		if not done.has('a'): opts.append({t = 'Si la falta es de la Configuración, ¿por qué reprendo a mi nieto?', id = 'a'})
		if not done.has('b'): opts.append({t = '¿Por qué no se enseña a leer a las mujeres?', id = 'b'})
		if not done.has('c'): opts.append({t = '¿Cuántos lados tiene usted, en verdad?', id = 'c', tag = 'Osadía'})
		opts.append({t = 'Nada más, Reverencia.', id = 'x'})
		c = await choose(opts)
		if c == 'x': break
		done[c] = 1; asked += 1
		if c == 'a':
			await say('yo', 'Esta mañana mi nieto rompió una tablilla. Alegó que un cambio de temperatura fue demasiado para su perímetro: que la culpa era de su Configuración.')
			await say('novicio', '¿Y qué le respondió usted?')
			if ex == 'r':
				await say('yo', 'Que, en ese caso, una buena reprimenda le fortalecería la Configuración.')
				await say('novicio', 'Je. Heterodoxo, pero práctico. Así gobernamos también nosotros, sólo que sin reírnos.')
			elif ex == 'n':
				await say('yo', 'Que tenía razón: que nadie tiene la culpa. Y me ha prometido romper otra.')
				await say('novicio', 'Ha llevado usted la doctrina hasta el final, y el final se le ha reído en la cara. Por eso nosotros nunca llegamos hasta el final.')
			else:
				await say('yo', 'Nada. La arreglamos juntos.')
				await say('novicio', '…Eso no está en ningún manual. Y por eso no tiene respuesta. Qué incómodo.')
		if c == 'b':
			await say('novicio', 'Hace trescientos años, el Círculo Supremo decretó que, siendo ellas pobres en Razón y ricas en Emoción, educarlas era malgastar la tablilla. Desde entonces no leen ni cuentan.')
			await say('logica', 'Y desde entonces tú hablas dos lenguas. Con ella: «amor», «deber», «piedad». Con ellos: «anticipación de beneficios», «necesidad». Dos idiomas, casi dos mentes.')
			var d = await choose([{t = 'Temo que esa doble carga sea excesiva para los jóvenes. Humildemente, pido que se reconsidere.', id = 'h', tag = 'Apelar'}, {t = 'Una disposición sabia.', id = 'o'}])
			if d == 'h': await say('novicio', 'Humildemente anotado. No lo repita ante el oficiante: él no distingue una apelación de una sedición, y a veces tiene razón.'); g.her(1); g.flag('apelo', 1); g.note('temple_appeal', 2)
			else: await say('novicio', 'Eso decimos.'); g.her(-1)
			g.learn('bilingue')
		if c == 'c':
			await say('novicio', 'Qué pregunta tan de palpador. Unos cuatrocientos. Mi padre tenía trescientos cincuenta; entre nosotros no rige eso de un lado por generación.')
			await say('novicio', 'A mi hermano mayor lo llevaron de niño al Gimnasio Neoterapéutico, a que le fracturasen el marco para ganar lados. Sobrevive uno de cada diez. Él no fue ése.')
			await say('asombro', 'Lo dice con la misma voz con que antes dijo «misericordia».'); g.rep('sac', -1)
	await say('novicio', 'Vaya a casa. Faltan dos noches para el milenio; dicen que en esas fechas la gente ve cosas. Usted no vea nada.')
	g.frag(12)
	g.talk_end(o)
	# el Gimnasio, de reojo (C5-05): si le preguntaste por sus lados, se detiene ante esa puerta
	var nov := g.npc('novicio')
	if nov != null:
		var walk := func():
			await nov.move_to(44, -8, 2.2)
			if done.has('c'): nov.pause = 0.6; await g.wait(0.6)
			await nov.move_to(52, -4, 2.2)
			nov.hid = true
		walk.call()
	await narr('Volví a casa bajo una niebla espesa. Era el penúltimo día del año 1999. Me entretuve hasta tarde con mi vicio de siempre, la Geometría, y me dormí sobre las tablillas.')
	await _bridge()

# C5-01 · tu hermano: cálido, irónico y prudente
func _brother() -> void:
	Snd.motif('hermano')
	await say('hermano', '¡Hermano! Te he guardado sitio. Aquí, entre un Pentágono que ronca y otro que reza, que es lo mismo pero más alto.')
	await say('hermano', 'Tú y yo, cuatro lados cada uno, y sin embargo a ti te llaman a la Puerta y a mí me dejan copiando actas del Consejo.')
	var c = await choose([{t = 'Me llamaron. Y ojalá no lo hubieran hecho.', id = 'p'}, {t = 'Alguien tiene que copiar las actas.', id = 'b'}])
	if c == 'p':
		await say('hermano', 'Ya me lo han contado. El calderero. …No digas nada aquí. Aquí las paredes tienen tantos lados que todas oyen.')
		g.rel('hermano', 1)
	else: await say('hermano', 'Eso me digo yo cada mañana, mientras afilo el punzón. Y cada mañana me lo creo un poco menos.')
	await say('hermano', 'Ven mañana, el primer día del año 2000, a casa, después de la sesión del Consejo. Habrá sopa y ninguna geometría.')
	await say('hermano', 'Dicen que con el milenio saldrán los iluminados a contar visiones. El Consejo ya tiene la sala preparada. Nosotros, a la sopa.')
	await say('recelo', 'Lo ha dicho riendo.')

# C5-03 · la medición del niño: el mismo arco que trazaste tú palpando al comerciante
func _measure(be: Ent) -> void:
	if g.auto or be == null: return
	var W := g.world
	ui.close_dlg()
	var pts := be.world_pts(); var v: Vector2 = pts[0]; var pa: Vector2 = pts[2]; var pb: Vector2 = pts[1]
	var a0 := atan2(pa.y - v.y, pa.x - v.x); var da := App.ang_diff(a0, atan2(pb.y - v.y, pb.x - v.x))
	W.focus = v; W.zoom = 9
	var arc := MeshInstance3D.new(); arc.mesh = ImmediateMesh.new(); arc.material_override = W.mat(3); W.fx.add_child(arc)
	await g.tween(1.5, func(t):
		var im: ImmediateMesh = arc.mesh
		im.clear_surfaces()
		var cnt := int(24 * t)
		if cnt <= 0: return
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in cnt:
			var t0 := a0 + da * i / 24.0; var t1 := a0 + da * (i + 1) / 24.0
			for q in [Vector2(cos(t0), sin(t0)) * 0.2, Vector2(cos(t1), sin(t1)) * 0.2, Vector2(cos(t1), sin(t1)) * 0.26, Vector2(cos(t0), sin(t0)) * 0.2, Vector2(cos(t1), sin(t1)) * 0.26, Vector2(cos(t0), sin(t0)) * 0.26]:
				im.surface_set_color(W.pal.acc); im.surface_set_uv(Vector2.ZERO); im.surface_add_vertex(Geo.v3(v + q, 0.05))
		im.surface_end())
	Snd.sfx('chalk')
	await g.wait(1.0)
	arc.queue_free(); W.focus = Vector2(30, -31); W.zoom = 38

# C5-04 · la excusa de la temperatura, jugada (§12). Devuelve 'r' (reprimenda), 'n' (nadie) o 'a' (arreglar)
func _excuse() -> String:
	var W := g.world
	var T := Vector2(-28.6, 13.4)
	var A := [[-0.6, -0.35], [0.6, -0.35], [0.6, 0.0], [-0.6, 0.2]]
	var B := [[-0.6, 0.2], [0.6, 0.0], [0.6, 0.35], [-0.6, 0.35]]
	g.add({id = 'tabA', pts = A, x = T.x, y = T.y, name = 'media tablilla', noCollide = true, noGuts = true, noEye = true})
	var hb := g.add({id = 'tabB', pts = B, x = T.x + 0.9, y = T.y - 0.5, rot = 0.9, name = 'media tablilla', noCollide = true, noGuts = true, noEye = true})
	var o := await g.talk_begin('nieto', 'Por la mañana. Tu nieto te espera en el salón, con cara de culpa')
	W.focus = T; W.zoom = 16
	await say('nieto', 'Abuelo… se ha roto la tablilla de mi hermano. Pero no fue culpa mía: un cambio brusco de temperatura fue demasiado para mi perímetro. La culpa es de mi Configuración.')
	await say('logica', 'Lo ha aprendido en el Templo. Palabra por palabra.')
	var c = await choose([
		{t = 'Entonces una buena reprimenda te fortalecerá la Configuración.', id = 'r'},
		{t = 'Tienes razón: nadie tiene la culpa.', id = 'n', tag = 'Ortodoxia'},
		{t = 'Lo que importa no es de quién es la culpa, sino que se arregle.', id = 'a'}])
	g.flag('excusa', c)
	if c == 'r':
		await say('nieto', '¿Una reprimenda… para la Configuración? Abuelo, eso es trampa. …Vale. Lo siento.')
	elif c == 'n':
		await say('nieto', '¡Entonces tampoco me castigarás si rompo otra!')
		await say('narr', 'Y salió corriendo, encantado con la teología. Me quedé con las dos mitades en la mano.')
	else:
		await say('nieto', '¿Arreglarla? ¿Se puede? A ver… tú gira esa mitad y yo la sujeto.')
		ui.close_dlg()
		await _mend(hb, T)
		await say('nieto', '¡Encaja! Abuelo, se ve la raya, pero encaja. Como cuando palpas: hay que ir despacio.')
		g.rel('nieto', 1)
	ui.close_dlg()
	W.focus = null; W.zoom = W.base_zoom
	g.talk_end(o)
	W.remove('tabA'); W.remove('tabB')
	return c

# unir las dos mitades: girar la suelta (izquierda/derecha) hasta que encaje (menos de 6°); 15 s
func _mend(hb: Ent, T: Vector2) -> void:
	if g.auto: return
	ui.panel_info('La tablilla', tx('Gira la mitad suelta con {move_left} / {move_right} hasta que encaje.', 'Gira la mitad suelta con la palanca hasta que encaje.', 'Gira la mitad suelta con el stick izquierdo hasta que encaje.'))
	var st := {t = 0.0}
	await g.tick_until(func(dt) -> bool:
		st.t += dt
		if g.bot: hb.rot = 0.0
		hb.rot -= g.axis().x * 1.4 * dt
		var off := absf(App.ang_diff(0.0, hb.rot))
		# cuanto más cerca del ángulo, más se acerca a su sitio
		var k := clampf(off / 0.9, 0.0, 1.0)
		hb.x = T.x + 0.9 * k; hb.y = T.y - 0.5 * k
		if off < deg_to_rad(6.0) or st.t > 15.0:
			hb.rot = 0.0; hb.x = T.x; hb.y = T.y; Snd.sfx('lock'); return true
		return false)
	ui.panel_info(null)

# C5-06 · el puente a la noche: el Cuadrado dibuja una Línea en su tablilla, y la Línea se alarga
func _bridge() -> void:
	g.objective('', null)
	await ui.fade(true, 0.6)
	g.set_map(town()); g.spawn_player(-28, 24.5, PI / 2); g.set_view('top')
	g.world.focus = Vector2(-28, 24.5); g.world.zoom = 14
	await ui.fade(false, 0.6)
	await slate_anim('mi tablilla, de madrugada', 4.0, func(b: SlateBoard, t: float):
		var L := 40.0 + 540.0 * App.ease(t)
		b.line(320 - L / 2.0, 210, 320 + L / 2.0, 210, 1.0)
		b.dot(320 - L / 2.0, 210, 4); b.dot(320 + L / 2.0, 210, 4))
	await g.wait(0.6)
	# fundido al papel de calco del sueño, no al negro
	ui.fade_r.color = Color(World.PAL.dream.bg, ui.fade_r.color.a)
	await ui.fade(true, 1.4)
	slate_off()
	ui.close_dlg()

# C4-01 · el examen final del Colegio: Decágono, Endecágono o Dodecágono, en movimiento
func _exam() -> void:
	var W := g.world
	await say('estudiante', '(Un examinando, temblando.) …¿Decágono? No, no: ¡Dodecágono! …¿Puedo volver a mirar?')
	await say('archivero', '(Desde su mesa.) El tribunal admite oyentes, perito. Pruebe usted. Tres figuras. Sin palpar.')
	ui.close_dlg()
	g.teleport(12.5, 20.0, 0.0); g.view_lock = true; g.set_view('eye'); g.locked = true
	var f0 := W.fog; W.fog = 4.5
	await g.wait(1.0)
	var kinds := ['poli10', 'poli11', 'poli12']; kinds.shuffle()
	var opts := [{id = 'poli10', label = 'Decágono', sub = 'diez lados'}, {id = 'poli11', label = 'Endecágono', sub = 'once lados'}, {id = 'poli12', label = 'Dodecágono', sub = 'doce lados'}]
	var names := {poli10 = 'Decágono', poli11 = 'Endecágono', poli12 = 'Dodecágono'}
	var hits := 0
	for k in kinds:
		var ans = await sight_round(k, {far = 8.5, near = 3.0, arc = true, spin = 0.3, options = opts, title = 'Examen final de Vista',
			text = '¿Cuántos lados? La traza apenas cae: con tantos lados, todo es casi un Círculo.',
			verdict = func(r): return ('Cierto: ' if r == k else 'No: era un ') + names[k] + '.'})
		if ans is String and ans == k: hits += 1
	W.fog = f0; g.set_view('top'); g.view_lock = false; g.locked = false
	if hits == 3:
		await say('archivero', 'Tres de tres. Le darían el título, si no lo tuviera ya. Ahora entiende usted por qué el Color fue un alivio.')
		g.achieve('ACH_TRIBUNAL')
	else:
		await say('archivero', tr('%s de tres. No se apure: tres años de Colegio para esto. En color lo habría acertado un niño.') % tr(['Ninguno', 'Uno', 'Dos'][hits]))
	ui.close_dlg()
	await g.margin('m_c4_examen')

# C4-04 · ¿Mujer o Sacerdote? Con la Ley aprobada «en el ensayo», tres figuras mitad rojas y mitad verdes
# se acercan de canto. En el ojo son idénticas: no se puede saber. Ése era el plan.
func _woman_or_priest() -> void:
	var W := g.world
	await narr('Imagínalo un momento: la Ley aprobada. Estás en el mercado, con el ojo de siempre. Vienen tres figuras, de canto, mitad rojas y mitad verdes.')
	ui.close_dlg()
	g.teleport(-14, -6, 0.0); g.view_lock = true; g.set_view('eye'); g.locked = true
	var f0 := W.fog; W.fog = 9.0
	for e in W.ents.values():
		if e.id != 'yo' and absf(e.y + 6) < 4 and e.x > -16 and e.ai != null: e.y += 9; e.ai.home.y += 9
	await g.wait(1.0)
	var pc := []
	for i in 30: pc.append(RED if (i < 8 or i > 22) else GREEN)
	var kinds := ['mujer', 'circ', 'mujer'] if randf() < 0.5 else ['circ', 'mujer', 'circ']
	var hits := 0
	for k in kinds:
		var cols: Array = [RED, GREEN, GREEN, RED] if k == 'mujer' else pc
		var ans = await sight_round(k, {turn = PI / 2, colors = cols, wobble = 0.0, options = [BOW, YIELD], title = '¿Mujer o Sacerdote?',
			text = 'Mitad roja, mitad verde, de canto. ¿Te inclinas ante un Sacerdote o cedes el paso a una Mujer?',
			ok = func(r): return (r == 'yield') == (k == 'mujer'),
			verdict = func(r):
				if k == 'mujer': return 'Era una Mujer.' + (' *Se ríe de tu reverencia.*' if r == 'bow' else '')
				return 'Era un Sacerdote.' + (' *«¿Me cede el paso? ¡De rodillas!»*' if r == 'yield' else '')})
		if (ans == 'yield') == (k == 'mujer'): hits += 1
	W.fog = f0; g.set_view('top'); g.view_lock = false; g.locked = false
	await say('logica', 'No es que no sepas. Es que *no se puede saber*. Eso era la Ley: borrar la diferencia.')
	ui.close_dlg()

# minijuegos sueltos (main.gd --try=…)
func try_mini(name: String) -> void:
	ui.hud.visible = true; ui.chapter_tag('Prueba · ' + name)
	match name:
		'exam':
			g.set_map(town({school = true})); g.world.reveal('school'); g.spawn_player(12.6, 21.5, 0.0); g.begin_scene()
			g.add(F_hexa('archivero', 18, 23, {name = 'el viejo archivero', r = 0.95, rot = -1.57}))
			await _exam()
		'woman':
			g.set_map(agora()); g.spawn_player(-14, -6, 0.0); crowd(20, ['iso', 'tri', 'cuad', 'hexa']); g.begin_scene()
			await _woman_or_priest()
		'hymn':
			g.set_map(town({temple = true})); g.world.reveal('temple'); g.spawn_player(30, -26, -PI / 2); g.begin_scene()
			print('himno ', await Hymn.run(self))
		'bridge':
			await _bridge()
			await g.wait(2.0)
		'mend':
			g.set_map(town()); g.spawn_player(-26.5, 15.0, PI)
			g.add(F_hexa('nieto', -29.5, 15.2, {name = 'tu nieto menor', r = 0.6}))
			print('excusa ', await _excuse())
