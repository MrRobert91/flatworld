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
# texto según el dispositivo: teclado o pantalla táctil
func tx(kb: String, touch: String) -> String: return touch if ui.touch else kb

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
		bounds = {x0 = -84, y0 = -46, x1 = 76, y1 = 46}, fog = 13.0,
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

# ---------- Reconocimiento por la Vista ----------
# Una figura emerge de la niebla frente al jugador. Devuelve la respuesta elegida.
func sight_round(kind: String, o := {}):
	var p := g.player; var W := g.world; var dir := p.rot; var big := {r = 1.45}
	var irr := {id = '_s', pts = [[1.5, 0], [-0.5, 1.25], [-1.0, -0.55]], voice = 'tri', name = 'Irregular'}
	if g.auto:
		if o.get('keep', false):
			irr.x = p.x + cos(dir) * 3.4; irr.y = p.y + sin(dir) * 3.4; irr.noCollide = true; g.add(irr)
		if o.has('options'): return (o.options[1] if o.options.size() > 1 else o.options[0]).id
		return kind
	var d: Dictionary
	match kind:
		'mujer': d = F_mujer('_s', 0, 0, {r = 1.5})
		'iso': d = F_iso('_s', 0, 0, o.get('deg', 12.0), big)
		'tri': d = F_tri('_s', 0, 0, big)
		'cuad': d = F_cuad('_s', 0, 0, big)
		'penta': d = F_penta('_s', 0, 0, big)
		'hexa': d = F_hexa('_s', 0, 0, big)
		'circ': d = F_circ('_s', 0, 0, {r = 1.5})
		_: d = irr
	d.noCollide = true
	_sn += 1
	d.id = '_s' if o.get('keep', false) else '_s%d' % _sn
	var sid: String = d.id
	var far := 15.0; var near: float = o.get('near', 3.4)
	d.x = p.x + cos(dir) * far; d.y = p.y + sin(dir) * far; d.rot = dir + PI + o.get('turn', 0.0)
	var e := g.add(d)
	if o.has('colors'): e.set_colors(o.colors)
	var base := e.rot; var st := {t = 0.0}
	var wob: float = o.get('wobble', 0.22)
	var stop := g.tick(func(dt):
		st.t += dt
		if not e.woman: e.rot = base + sin(st.t * 0.7) * wob)
	var approach := func():
		await e.move_to(p.x + cos(dir) * near, p.y + sin(dir) * near, 3.2)
		e.rot = base
	approach.call()
	if e.woman: Snd.sfx('peace')
	var ans = await ui.panel(o.get('title', 'Reconocimiento por la vista'), o.get('text', '¿Qué figura se acerca? Observa cómo se apagan sus extremos en la niebla.'), o.get('options', CLASSES))
	stop.call(); e.mv = null; e.rot = base
	if o.get('reveal', true):
		g.set_view('top'); W.focus = Vector2((e.x + p.x) / 2.0, (e.y + p.y) / 2.0); W.zoom = 20
		var ok: bool = ans is String and ans == kind
		Snd.sfx('good' if ok else 'bad')
		var msg: String
		if o.has('verdict'): msg = o.verdict.call(ans)
		elif ok: msg = 'Cierto: %s. *La lámina te lo confirma.*' % NAME[kind]
		else: msg = 'No: era %s %s. *Mírala desde arriba y compara con la línea.*' % ['una' if kind == 'mujer' else 'un', NAME[kind]]
		ui.note(msg, 4)
		await g.wait(3.6)
		g.set_view('eye'); W.focus = null; W.zoom = W.base_zoom
	if not o.get('keep', false):
		var side := dir + PI / 2
		var leave := func():
			await e.move_to(e.x + cos(side) * 3 - cos(dir) * 12, e.y + sin(side) * 3 - sin(dir) * 12, 6)
			W.remove(sid)
		leave.call()
		await g.wait(0.9)
	return ans

# ---------- Reconocimiento por el Tacto ----------
func feel(e: Ent, text := '') -> bool:
	if g.auto: return true
	var W := g.world; var p := g.player
	ui.close_dlg()
	# vértice más cercano
	var pts := e.world_pts(); var bi := 0; var bd := 1e9
	for i in pts.size():
		var dd: float = (pts[i] as Vector2).distance_to(Vector2(p.x, p.y))
		if dd < bd: bd = dd; bi = i
	var n := pts.size(); var v: Vector2 = pts[bi]; var pa: Vector2 = pts[(bi + n - 1) % n]; var pb: Vector2 = pts[(bi + 1) % n]
	var a0 := atan2(pa.y - v.y, pa.x - v.x); var a1 := atan2(pb.y - v.y, pb.x - v.x)
	var da := App.ang_diff(a0, a1)
	var arc := MeshInstance3D.new(); arc.mesh = ImmediateMesh.new(); arc.material_override = W.mat(3); W.fx.add_child(arc)
	W.focus = v; W.zoom = 13
	ui.panel_info('Reconocimiento por el tacto', text if text != '' else tx('Mantén pulsada E para recorrer el ángulo con tu lado. *Despacio: un ángulo agudo hiere.*', 'Mantén pulsado el botón «Palpar» para recorrer el ángulo con tu lado. *Despacio: un ángulo agudo hiere.*'))
	g.need_act = 'Palpar'
	var st := {prog = 0.0}
	await g.tick_until(func(dt) -> bool:
		if g.bot: st.prog = 1.0
		if g.act_held():
			st.prog = minf(1.0, st.prog + dt * 0.7)
			if randf() < 0.3: Snd.sfx('chalk')
		var im: ImmediateMesh = arc.mesh
		im.clear_surfaces()
		var steps := 24; var cnt := int(steps * st.prog)
		if cnt > 0:
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in cnt:
				var t0 := a0 + da * i / steps; var t1 := a0 + da * (i + 1) / steps
				var q := [Vector2(cos(t0), sin(t0)) * 0.34, Vector2(cos(t1), sin(t1)) * 0.34, Vector2(cos(t1), sin(t1)) * 0.42, Vector2(cos(t0), sin(t0)) * 0.34, Vector2(cos(t1), sin(t1)) * 0.42, Vector2(cos(t0), sin(t0)) * 0.42]
				for k in q:
					im.surface_set_color(World.GAS); im.surface_set_uv(Vector2.ZERO); im.surface_add_vertex(Geo.v3(v + k, 0.05))
			im.surface_end()
		return st.prog >= 1.0)
	g.need_act = ''
	ui.panel_info(null)
	var deg := roundi(absf(da) * 180.0 / PI)
	var opts := [{id = 'iso', label = 'Agudo, menor de 60°', sub = 'Isósceles'}, {id = 60, label = '60°', sub = 'Equilátero'}, {id = 90, label = '90°', sub = 'Cuadrado'}, {id = 108, label = '108°', sub = 'Pentágono'}, {id = 120, label = '120°', sub = 'Hexágono'}]
	var ans = await ui.panel('Has palpado el ángulo', '¿Cuánto mide la abertura que has recorrido?', opts)
	var ok: bool
	if deg < 58: ok = ans is String
	else: ok = ans is int and absi(ans - deg) < 4
	arc.queue_free(); W.focus = null; W.zoom = W.base_zoom
	Snd.sfx('good' if ok else 'bad')
	return ok

# Pizarra: anima un dibujo de tiza. draw(board, t 0..1)
func slate_anim(cap: String, sec: float, draw: Callable) -> void:
	if g.auto: return
	var b := ui.slate(true, cap)
	await g.tween(sec, func(t): b.paint(draw, t))

func slate_off() -> void:
	ui.slate(false)
