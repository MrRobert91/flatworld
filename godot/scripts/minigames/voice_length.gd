# M-08 · Medir con el oído (C6-02). Tres súbditos cantan por turnos su par de notas, una por cada boca:
# la grave y, después, la tenor. El retraso entre las dos crece con el largo del que canta
# (0,2 + 0,6·largo s). El jugador dice quién es el más corto y, de los otros dos, quién es el más largo.
# Con «subtítulos de sonido», el intervalo se ve además como un trazo (accesibilidad).
# En relajado, un fallo da un segundo intento con una pista. Devuelve si el orden es correcto.
class_name VoiceLength extends RefCounted

const ORD := ['Primera voz', 'Segunda voz', 'Tercera voz']

static func sing(c: Ch, e: Ent, delay: float, n := 0) -> void:
	var g := c.g
	c.ui.panel_info('Medir con el oído', c.ui.T('Escucha: %s') % c.ui.T(ORD[n]).to_lower())
	g.world.mark(e.id)
	var L: float = float(e.def.get('r', 0.5)) * 2.0
	var gap := 0.2 + 0.6 * L
	var cap := bool(App.cfg.get('sound_captions', true))
	if not g.auto:
		Snd.note('organ', 45, 2.0, delay, false); Snd.note('organ', 52, 0.0, delay + gap, false)
	await g.wait(delay)
	e.talk = 1.0
	if cap: c.ui.caption('♪ ' + '·'.repeat(int(gap * 10.0)) + ' ♪', 0.0)
	await g.wait(gap)
	e.talk = 1.0
	await g.wait(0.9)
	g.world.unmark(e.id); c.ui.panel_info(null)

static func run(c: Ch, ids: Array) -> bool:
	var g := c.g; var ui := c.ui
	if g.auto: return true
	var order := ids.duplicate(); order.shuffle()
	var ents := order.map(func(id): return g.npc(id))
	var lens := ents.map(func(e): return float(e.def.get('r', 0.5)))
	var tries := 2 if g.difficulty() == 'relaxed' else 1
	for attempt in tries:
		for i in ents.size(): await sing(c, ents[i], 0.3, i)
		var picked := []
		while picked.size() < 2:
			var opts := []
			for i in ents.size():
				if not picked.has(i): opts.append({id = i, label = ORD[i], sub = ''})
			opts.append({id = -1, label = 'Otra vez', sub = 'escuchar'})
			var q := 'El Rey: «¿Quién es el más *corto*?»' if picked.is_empty() else 'El Rey: «¿Y de esos dos, quién es el más *largo*?»'
			var ch = await ui.panel('Medir con el oído', q, opts)
			if g.bot: ch = lens.find(lens.min()) if picked.is_empty() else lens.find(lens.max())
			if ch == -1:
				for i in ents.size(): await sing(c, ents[i], 0.3, i)
				continue
			picked.append(ch)
		var shortest := lens.find(lens.min()); var longest := lens.find(lens.max())
		if picked[0] == shortest and picked[1] == longest: return true
		if attempt < tries - 1:
			ui.note('*Lógica:* ' + ui.T('Escucha el hueco entre las dos notas: cuanto más tarda la segunda, más largo es el que canta.'), 6.0)
	return false
