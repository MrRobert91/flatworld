# Base de los capítulos: reparto, figuras, mapa de la ciudad y minijuegos compartidos.
class_name Ch extends RefCounted

const CAST := {
	esposa = {name = 'Tu esposa', color = '#f0c9d2', voice = 'mujer'}, hija = {name = 'Tu hija', color = '#f0c9d2', voice = 'mujer'},
	nieto = {name = 'Tu nieto, el Hexágono', color = '#a8dcc0', voice = 'nino'}, hijo = {name = 'Tu hijo mayor, Pentágono', color = '#c9d6a0', voice = 'penta'},
	criado = {name = 'El criado, Isósceles', color = '#c8a98a', voice = 'iso'}, mayordomo = {name = 'El mayordomo', color = '#c8a98a', voice = 'tri'},
	mercader = {name = 'Comerciante Equilátero', color = '#d9c28f', voice = 'tri'}, noble = {name = 'Hexágono ocioso', color = '#a8c8e0', voice = 'hexa'},
	soldado = {name = 'Soldado Isósceles', color = '#c8a98a', voice = 'iso'}, guardia = {name = 'Sargento de la Puerta', color = '#c8a98a', voice = 'iso'},
	dama = {name = 'Una dama', color = '#f0c9d2', voice = 'mujer'}, obrera = {name = 'Mujer del obrero', color = '#f0c9d2', voice = 'mujer'},
	obrero = {name = 'Obrero Isósceles', color = '#c8a98a', voice = 'iso'}, medico = {name = 'Médico Pentágono', color = '#c9d6a0', voice = 'penta'},
	irregular = {name = 'El calderero', color = '#e0b0a0', voice = 'tri'}, inspector = {name = 'Inspector de Configuración', color = '#c9d6a0', voice = 'penta'},
	archivero = {name = 'El viejo archivero', color = '#a8c8e0', voice = 'hexa'}, estudiante = {name = 'Estudiante', color = '#a8dcc0', voice = 'nino'},
	cromatistes = {name = 'Cromatistes', color = '#ffb36b', voice = 'penta'}, pantociclo = {name = 'Pantociclo, Círculo Supremo', color = '#ffffff', voice = 'circ'},
	agitador = {name = 'El tribuno del Color', color = '#ff8f7a', voice = 'iso'}, voces = {name = 'La multitud', color = '#c8a98a', voice = 'iso'},
	circulo = {name = 'Círculo oficiante', color = '#ffffff', voice = 'circ'}, novicio = {name = 'Círculo joven', color = '#e6e6f5', voice = 'circ'},
	madre = {name = 'La madre', color = '#f0c9d2', voice = 'mujer'}, padre = {name = 'El padre Isósceles', color = '#c8a98a', voice = 'iso'},
	rey = {name = 'El Rey de Linealandia', color = '#d4c4ff', voice = 'rey'}, esfera = {name = 'El Forastero', color = '#9fe8e0', voice = 'esfera'},
	hermano = {name = 'Tu hermano', color = '#d8d0b8', voice = 'cuad'}, presidente = {name = 'El Presidente del Consejo', color = '#ffffff', voice = 'circ'},
	punto = {name = 'El Punto', color = '#ffe9a8', voice = 'punto'}, heraldo = {name = 'Heraldo', color = '#d9c28f', voice = 'tri'},
	prefecto = {name = 'El Prefecto', color = '#a8c8e0', voice = 'hexa'}, orador = {name = 'El conferenciante', color = '#c9d6a0', voice = 'penta'},
}
const CLASSES := [
	{id = 'mujer', label = 'Mujer', icon = 2}, {id = 'iso', label = 'Isósceles', icon = 1}, {id = 'tri', label = 'Equilátero', icon = 3},
	{id = 'cuad', label = 'Cuadrado', icon = 4}, {id = 'penta', label = 'Pentágono', icon = 5}, {id = 'hexa', label = 'Hexágono', icon = 6}, {id = 'circ', label = 'Círculo', icon = 24},
]
const NAME := {mujer = 'Mujer', iso = 'Isósceles', tri = 'Equilátero', cuad = 'Cuadrado', penta = 'Pentágono', hexa = 'Hexágono', circ = 'Círculo'}

var g: Game
var ui: UIRoot
var a: Ch                # capítulos A (intro, outro, celda, gente de la calle)
var _sn := 0

func _init(game: Game, u: UIRoot) -> void:
	g = game; ui = u

func say(w: String, t: String) -> void: await ui.say(w, t)
func choose(o: Array, e := true): return await ui.choose(o, e)
func narr(t: String, w := false) -> void: await ui.narrate(t, w)
# texto según el dispositivo: teclado, mando o pantalla táctil. Devuelve la plantilla sin rellenar:
# la interfaz la traduce y sustituye después {act}, {view}, {move}… por los glifos del dispositivo (S-01)
func tx(kb: String, touch: String, pad := '') -> String:
	if ui.touch: return touch
	return pad if Glyphs.pad() and pad != '' else kb

# notas al margen del capítulo (S-04): [[id, x, y], ...]. Fuera del camino obligatorio; --auto no las coge
func margins(list: Array) -> void:
	for m in list:
		var id: String = m[0]
		if g.state.margins.has(id): continue
		g.world.add_spot({id = id, x = m[1], y = m[2], margin = true, label = 'una nota al margen'})
		g.on(id, 'Examinar', func(): await g.margin(id))

# ---------- figuras ----------
func _f(base: Dictionary, o: Dictionary) -> Dictionary:
	base.merge(o, true); return base
func F_mujer(id: String, x: float, y: float, o := {}) -> Dictionary: return _f({id = id, woman = true, r = 0.95, voice = 'mujer', x = x, y = y, name = 'Mujer'}, o)
func F_iso(id: String, x: float, y: float, deg := 14.0, o := {}) -> Dictionary: return _f({id = id, iso = deg, r = 0.9, n = 3, voice = 'iso', x = x, y = y, name = 'Isósceles'}, o)
func F_tri(id: String, x: float, y: float, o := {}) -> Dictionary: return _f({id = id, n = 3, r = 0.82, voice = 'tri', x = x, y = y, name = 'Equilátero'}, o)
func F_cuad(id: String, x: float, y: float, o := {}) -> Dictionary: return _f({id = id, n = 4, r = 0.78, voice = 'cuad', x = x, y = y, name = 'Cuadrado'}, o)
func F_penta(id: String, x: float, y: float, o := {}) -> Dictionary: return _f({id = id, n = 5, r = 0.82, voice = 'penta', x = x, y = y, name = 'Pentágono'}, o)
func F_hexa(id: String, x: float, y: float, o := {}) -> Dictionary: return _f({id = id, n = 6, r = 0.85, voice = 'hexa', x = x, y = y, name = 'Hexágono'}, o)
func F_poli(id: String, x: float, y: float, n: int, o := {}) -> Dictionary: return _f({id = id, n = n, r = 0.9, voice = 'hexa', x = x, y = y, name = 'Polígono'}, o)
func F_circ(id: String, x: float, y: float, o := {}) -> Dictionary: return _f({id = id, n = 30, r = 0.95, voice = 'circ', x = x, y = y, name = 'Círculo', noEye = true}, o)

# ---------- la ciudad ----------
func town(open := {}) -> Dictionary:
	var house := func(id: String, x: float, y: float, R: float, label = null) -> Dictionary:
		var h := {id = id, x = x, y = y, R = R, n = 5, rot = 90}
		if label != null: h.label = label
		return h
	var hospital: Dictionary = house.call('hospital', 56, 18, 8, 'Hospital de Reconfiguración'); hospital.labelSize = 0.7
	return {
		bounds = {x0 = -120, y0 = -46, x1 = 76, y1 = 46}, fog = 13.0,
		# el campo al Oeste de la Puerta, con árboles (§2, C2-07)
		trees = [[-78, 9, 1.4], [-83, 15, 1.2], [-88, 7, 1.5], [-92, 18, 1.3], [-97, 10, 1.4], [-103, 14, 1.2], [-108, 6, 1.5],
			[-80, -10, 1.3], [-86, -16, 1.4], [-91, -8, 1.2], [-96, -19, 1.5], [-101, -11, 1.3], [-106, -17, 1.2], [-112, -9, 1.4]],
		walls = [[-70, -46, -70, -3.4], [-70, 3.4, -70, 46]],
		buildings = [
			{id = 'home', x = -28, y = 17, R = 12, n = 5, rot = 90, sealed = false, label = 'Tu casa', labelDy = -8.4, labelSize = 0.8,
				doors = [{id = 'homeW', side = 1, t = 0.55, w = 2.6, open = open.get('homeW', true) != false}, {id = 'homeE', side = 3, t = 0.45, w = 1.8, open = false}],
				inner = [[-11.18, 3, -1.3, 3], [1.3, 3, 11.18, 3], [-3.6, 3, -3.6, -2.0], [-3.6, -4.6, -3.6, -9.71], [3.6, 3, 3.6, -2.0], [3.6, -4.6, 3.6, -9.71],
					[4.8, 4.0, 6.6, 4.0], [6.6, 4.0, 6.6, 5.6], [6.6, 5.6, 4.8, 5.6], [4.8, 5.6, 4.8, 4.0]]},
			{id = 'school', x = 18, y = 20, R = 11, n = 6, rot = 0, label = 'Colegio de Vista', doors = [{id = 'school', side = 4, t = 0.5, w = 2.8, open = open.get('school', false)}]},
			{id = 'temple', x = 30, y = -25, R = 15, n = 24, rot = 7.5, label = 'Templo de los Círculos', labelSize = 1.3, doors = [{id = 'temple', side = 5, t = 0.5, w = 3.2, open = open.get('temple', false)}]},
			{id = 'palace', x = -14, y = -25, R = 13, n = 8, rot = 22.5, label = 'Palacio del Prefecto', doors = [{id = 'palace', side = 1, t = 0.5, w = 3.0, open = open.get('palace', false)}]},
			hospital,
			{id = 'barracks', x = 60, y = -20, R = 9.5, n = 3, rot = 90, label = 'Cuartel'},
			house.call('h1', -56, 17, 8), house.call('h2', -4, 16, 7.5), house.call('h3', 40, 17, 7), house.call('h4', -58, -17, 7.5), house.call('h5', -41, -17, 6.5), house.call('h6', 7, -17, 5.5),
		],
		labels = [{t = 'Calle Mayor', x = 2, y = 3.6, s = 1.5, a = 0.22}, {t = 'Puerta Oeste', x = -70, y = 6, s = 0.9, a = 0.5}, {t = 'Norte: de allí viene la lluvia', x = -28, y = 32, s = 0.75, a = 0.3, it = true},
			{t = 'camino de las aldeas', x = -78, y = -2.2, s = 0.6, a = 0.3, it = true},
			{t = 'estudio', x = -28, y = 25.4, s = 0.8, a = 0.45, it = true}, {t = 'salón', x = -28, y = 18.4, s = 0.8, a = 0.45, it = true}, {t = 'varones', x = -34.4, y = 18.6, s = 0.7, a = 0.45, it = true}, {t = 'mujeres', x = -21.6, y = 18.6, s = 0.7, a = 0.45, it = true},
			{t = 'puerta de los varones', x = -42.6, y = 15, s = 0.62, a = 0.45, it = true}, {t = 'puerta de las mujeres', x = -13.6, y = 15, s = 0.62, a = 0.45, it = true}],
	}

# ---------- Reconocimiento por la Vista (M-02) ----------
# Una figura emerge de la niebla frente al jugador. Devuelve la respuesta elegida.
#   o: options, options_extra, title, text, verdict(Callable), reveal, keep, near, turn, wobble, colors, deg
#      spin (rad/s: la figura gira mientras se acerca), cloak (capa de viaje: apaga su brillo),
#      arc (llega en curva), next (clase de la figura que espera en la cola), trace (forzar/quitar la traza),
#      ok (Callable ans -> bool), split (s de plano partido antes de responder, C3-03)
const BOW := {id = 'bow', label = 'Inclinarse', sub = 'ante un Círculo'}
const YIELD := {id = 'yield', label = 'Ceder el paso', sub = 'a una Mujer'}

func _sight_def(kind: String, o := {}) -> Dictionary:
	var big := {r = 1.45}
	if kind.begins_with('poli'): return F_poli('_s', 0, 0, int(kind.substr(4)), {r = 1.45, name = 'un Polígono'})
	match kind:
		'mujer': return F_mujer('_s', 0, 0, {r = 1.5})
		'iso': return F_iso('_s', 0, 0, o.get('deg', 12.0), big)
		'tri': return F_tri('_s', 0, 0, big)
		'cuad': return F_cuad('_s', 0, 0, big)
		'penta': return F_penta('_s', 0, 0, big)
		'hexa': return F_hexa('_s', 0, 0, big)
		'circ': return F_circ('_s', 0, 0, {r = 1.5})
	return {id = '_s', pts = [[1.5, 0], [-0.5, 1.25], [-1.0, -0.55]], voice = 'tri', name = 'Irregular'}

func sight_round(kind: String, o := {}):
	var p := g.player; var W := g.world; var dir := p.rot
	if g.auto:
		if o.get('keep', false):
			var irr := _sight_def('irr'); irr.x = p.x + cos(dir) * 3.4; irr.y = p.y + sin(dir) * 3.4; irr.noCollide = true; g.add(irr)
		if o.has('options'): return (o.options[1] if o.options.size() > 1 else o.options[0]).id
		return kind
	W.remove('_q')
	var d := _sight_def(kind, o)
	d.noCollide = true
	_sn += 1
	d.id = '_s' if o.get('keep', false) else '_s%d' % _sn
	var sid: String = d.id
	if o.get('cloak', false): d.noEye = true; d.lum = 0.55
	var far: float = o.get('far', 15.0); var near: float = o.get('near', 3.4)
	var side := dir + PI / 2
	var sx := (cos(side) * 5.0 if o.get('arc', false) else 0.0); var sy := (sin(side) * 5.0 if o.get('arc', false) else 0.0)
	d.x = p.x + cos(dir) * far + sx; d.y = p.y + sin(dir) * far + sy; d.rot = dir + PI + o.get('turn', 0.0)
	var e := g.add(d)
	if o.has('colors'): e.set_colors(o.colors)
	# la cola de la Puerta: la siguiente figura espera más atrás, en la niebla
	if o.has('next'):
		var q := _sight_def(o.next); q.id = '_q'; q.noCollide = true; q.lum = 0.7
		q.x = p.x + cos(dir) * 19.0 - sx; q.y = p.y + sin(dir) * 19.0 - sy; q.rot = dir + PI
		g.add(q)
	var trace_was := g.eye.trace
	if o.has('trace'): g.eye.trace = 1.0 if o.trace else 0.0
	var base := e.rot; var st := {t = 0.0, wait = 0.0, chimed = 0}
	var wob: float = o.get('wobble', 0.22); var spin: float = o.get('spin', 0.0)
	var stop := g.tick(func(dt):
		st.t += dt
		if e.woman: return
		if spin != 0.0: e.rot = base + st.t * spin
		else: e.rot = base + sin(st.t * 0.7) * wob
		# la campanilla de la cola: el sargento se impacienta (sin castigo)
		if ui.picking:
			st.wait += dt
			if st.wait > 15.0 + 10.0 * st.chimed: st.chimed += 1; Snd.sfx('chime'))
	var approach := func():
		if o.get('arc', false): await e.move_to(p.x + cos(dir) * 8.0 + sx * 0.6, p.y + sin(dir) * 8.0 + sy * 0.6, 3.2)
		await e.move_to(p.x + cos(dir) * near, p.y + sin(dir) * near, 3.2)
		if spin == 0.0: e.rot = base
	approach.call()
	if e.woman: Snd.sfx_at('peace', e.x, e.y, 0.0, 'Grito de Paz')
	if o.has('split'):
		await g.wait(3.8)
		ui.split_view(true, Vector2((e.x + p.x) / 2.0, (e.y + p.y) / 2.0), 14.0)
		await g.wait(float(o.split))
		ui.split_view(false)
	var opts: Array = o.get('options', CLASSES).duplicate()
	opts.append_array(o.get('options_extra', []))
	var is_ok := func(a) -> bool:
		if o.has('ok'): return o.ok.call(a)
		if kind == 'circ': return a is String and (a == 'circ' or a == 'bow')
		return a is String and a == kind
	var ans = await ui.panel(o.get('title', 'Reconocimiento por la vista'), o.get('text', '¿Qué figura se acerca? Observa cómo se apagan sus extremos en la niebla.'), opts)
	# deducciones relajadas: una segunda oportunidad, con una pista
	if o.get('reveal', true) and not is_ok.call(ans) and g.difficulty() == 'relaxed':
		Snd.sfx('bad')
		await say('logica', 'Mira otra vez cómo caen los extremos: deprisa, ángulo agudo; despacio, muchos lados. Y si no cae nada, inclínate.')
		ui.close_dlg()
		ans = await ui.panel(o.get('title', 'Reconocimiento por la vista'), o.get('text', '¿Qué figura se acerca?'), opts)
	stop.call(); e.mv = null
	if spin == 0.0: e.rot = base
	g.eye.trace = trace_was
	if o.get('reveal', true):
		g.set_view('top'); W.focus = Vector2((e.x + p.x) / 2.0, (e.y + p.y) / 2.0); W.zoom = 20
		var ok: bool = is_ok.call(ans)
		Snd.sfx('good' if ok else 'bad')
		var msg: String
		if o.has('verdict'): msg = o.verdict.call(ans)
		elif ok: msg = tr('Cierto: %s. *La lámina te lo confirma.*') % tr(NAME[kind])
		else: msg = tr('No: era %s %s. *Mírala desde arriba y compara con la línea.*') % [tr('una') if kind == 'mujer' else tr('un'), tr(NAME[kind])]
		ui.note(msg, 4)
		await g.wait(3.6)
		g.set_view('eye'); W.focus = null; W.zoom = W.base_zoom
	if not o.get('keep', false):
		var leave := func():
			await e.move_to(e.x + cos(side) * 3 - cos(dir) * 12, e.y + sin(side) * 3 - sin(dir) * 12, 6)
			W.remove(sid)
		leave.call()
		await g.wait(0.9)
	return ans

# ---------- Reconocimiento por el Tacto ----------
# (M-01, minigames/feel.gd) Devuelve si se acertó el ángulo.
func feel(e: Ent, text := '', opts := {}) -> bool:
	if text != '': opts.text = text
	var r: Dictionary = await Feel.run(self, e, opts)
	return r.ok

# Pizarra: anima un dibujo de tiza. draw(board, t 0..1)
func slate_anim(cap: String, sec: float, draw: Callable) -> void:
	if g.auto: return
	var b := ui.slate(true, cap)
	await g.tween(sec, func(t): b.paint(draw, t))

func slate_off() -> void:
	ui.slate(false)
