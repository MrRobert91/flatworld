# Modo Colegio (§7.2): la sala del Colegio de Vista con los minijuegos sueltos, cinco rondas de dificultad
# creciente y tres medallas en tinta (bronce, plata y oro). Se abre al terminar el juego (C10-09).
# Las medallas se guardan en Profile.data.college.
class_name College extends Ch

const MEDAL := ['', 'bronce', 'plata', 'oro']
const STATIONS := {
	vista = {x = 14.0, y = 22.5, label = 'Reconocimiento por la Vista'},
	tacto = {x = 22.0, y = 22.5, label = 'Reconocimiento por el Tacto'},
	calle = {x = 14.0, y = 17.5, label = 'Cruzar la Calle Mayor'},
	secciones = {x = 22.0, y = 17.5, label = 'Las secciones del Cubo'},
}

static func medal_of(score: int) -> int:
	return 3 if score >= 5 else (2 if score >= 4 else (1 if score >= 3 else 0))

func _medal_text(id: String) -> String:
	var m := int(Profile.data.get('college', {}).get(id, 0))
	return ui.T('sin medalla') if m == 0 else ui.T('medalla de %s') % ui.T(MEDAL[m])

func run() -> void:
	g.set_map(town({school = true})); g.world.reveal('school'); g.spawn_player(18, 20, PI / 2)
	ui.hud.visible = true; ui.chapter_tag('Modo Colegio'); Snd.drone('flat')
	g.add(F_hexa('archivero', 18, 24.5, {name = 'el viejo archivero', r = 0.95, rot = -PI / 2}))
	await ui.fade(false, 0.6)
	await say('archivero', 'Bienvenido al Colegio, perito. Aquí se practica sin que nadie apunte nada. Cinco rondas en cada mesa, cada una más difícil.')
	# el autómata de pruebas pasa por las cuatro mesas, una vez, y sale
	var queue := STATIONS.keys() + ['salir'] if (g.auto or g.bot) else []
	while true:
		var done := {pick = ''}
		for id in STATIONS:
			var S: Dictionary = STATIONS[id]
			if g.world.spots.has('st_' + id): g.world.remove_spot('st_' + id)
			g.world.add_spot({id = 'st_' + id, x = S.x, y = S.y, label = ui.T(S.label) + ' · ' + _medal_text(id)})
			g.on('st_' + id, 'Practicar', func(): done.pick = id)
		g.on('archivero', 'Salir', func(): done.pick = 'salir')
		g.objective('Elige una mesa')
		if not queue.is_empty(): done.pick = queue.pop_front()
		await g.until(func(): return done.pick != '')
		g.objective('', null)
		for id in STATIONS: g.off('st_' + id)
		g.off('archivero')
		if done.pick == 'salir': break
		var score := await _play(done.pick)
		var m := medal_of(score)
		var best := int(Profile.data.get('college', {}).get(done.pick, 0))
		if not Profile.data.has('college'): Profile.data.college = {}
		if m > best: Profile.data.college[done.pick] = m; Profile.touch(0.0)
		g.begin_scene()
		await say('archivero', ui.T('%d de cinco. ') % score + (ui.T('Eso es una medalla de %s.') % ui.T(MEDAL[m]) if m > 0 else ui.T('Sin medalla, esta vez.')))
		g.end_scene()
		g.teleport(18, 20, PI / 2)

func _play(id: String) -> int:
	match id:
		'vista': return await _vista()
		'tacto': return await _tacto()
		'calle': return await _calle()
		_: return await _secciones()

# cinco figuras, cada vez más difíciles: de frente, girando, en arco, de incógnito y un Polígono lejano
func _vista() -> int:
	g.begin_scene(); g.set_view('eye'); g.view_lock = true; g.eye.trace = 1.0
	var W := g.world; var f0 := W.fog; W.fog = 6.0
	var R := [['tri', {}], ['cuad', {spin = 0.25}], ['penta', {arc = true}], ['circ', {cloak = true, options_extra = [BOW]}], [['poli10', 'poli11', 'poli12'].pick_random(), {far = 8.5, spin = 0.3}]]
	var hits := 0
	for r in R:
		var k: String = r[0]; var o: Dictionary = r[1].duplicate()
		if k.begins_with('poli'):
			o.options = [{id = 'poli10', label = 'Decágono', sub = '10'}, {id = 'poli11', label = 'Endecágono', sub = '11'}, {id = 'poli12', label = 'Dodecágono', sub = '12'}]
			var nm: String = {poli10 = 'un Decágono', poli11 = 'un Endecágono', poli12 = 'un Dodecágono'}[k]
			o.verdict = func(r): return (ui.T('Cierto: %s.') if r == k else ui.T('No: era %s.')) % ui.T(nm)
		if g.difficulty() == 'expert': o.trace = false
		var ans = await sight_round(k, o)
		if (ans is String and ans == k) or (k == 'circ' and ans is String and ans == 'bow'): hits += 1; Snd.sfx('good')
		else: Snd.sfx('bad')
	W.fog = f0; g.set_view('top'); g.view_lock = false; g.end_scene()
	return hits

# cinco ángulos, con riesgo: el agudo hiere si se palpa deprisa
func _tacto() -> int:
	var p := g.player
	var kinds := ['hexa', 'penta', 'cuad', 'tri', 'iso']
	var hits := 0
	g.begin_scene()
	for k in kinds:
		var d: Dictionary
		match k:
			'iso': d = F_iso('pieza', p.x + cos(p.rot) * 1.6, p.y + sin(p.rot) * 1.6, 9.0)
			'tri': d = F_tri('pieza', p.x + cos(p.rot) * 1.6, p.y + sin(p.rot) * 1.6)
			'cuad': d = F_cuad('pieza', p.x + cos(p.rot) * 1.6, p.y + sin(p.rot) * 1.6)
			'penta': d = F_penta('pieza', p.x + cos(p.rot) * 1.6, p.y + sin(p.rot) * 1.6)
			_: d = F_hexa('pieza', p.x + cos(p.rot) * 1.6, p.y + sin(p.rot) * 1.6)
		d.noCollide = true; d.rot = p.rot + PI
		g.add(d)
		var r: Dictionary = await Feel.run(self, g.npc('pieza'), {risky = true})
		if r.ok and int(r.pricks) == 0: hits += 1
		g.world.remove('pieza')
	g.end_scene()
	return hits

# la calle, con cinco mujeres: cinco puntos menos cada pinchazo
func _calle() -> int:
	g.teleport(6, -9.5, PI / 2)
	var r: Dictionary = await CrossStreet.run(self, {women = 5})
	g.teleport(18, 20, PI / 2)
	return maxi(0, 5 - int(r.pricks))

# tres pasadas del Cubo y el sólido oculto; el quinto punto, por hacerlo todo
func _secciones() -> int:
	var W := g.world; var p := g.player
	var at := Vector2(18, 20)
	var was := {cam = W.cam_mode, strip = g.show_strip}
	W.cam_mode = 'free'; W.free = {yaw = 0.0, pitch = 0.55, dist = 16.0}; W._free_intro = 1.0
	p.alt = 7.0; p.y = at.y - 6.0; p.x = at.x; p.no_collide = true; g.alt_min = 3.0; g.alt_max = 12.0
	var cube := Space.make_cube(); W.add_child(cube)
	var cm: ShaderMaterial = cube.material_override
	cm.set_shader_parameter('col', Vector3(0.98, 0.96, 0.89)); cm.set_shader_parameter('edge_col', World._v3(W.pal.edge))
	g.begin_scene()
	var r: Dictionary = await CubeSections.run(self, cube, at)
	g.end_scene()
	cube.queue_free()
	W.cam_mode = was.cam; p.alt = 0.0; p.no_collide = false
	var s: int = int(r.pred) + (1 if r.hidden else 0)
	return s + (1 if s == 4 else 0)
