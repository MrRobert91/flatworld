# M-06 · El cántico (C5-02). «A-TIEN-de a tu Con-fi-gu-RA-ción»: cuatro sílabas tónicas, a tiempo con la
# asamblea, en el compás del Templo (54 pulsos por minuto). El órgano cuenta dos pulsos y después marca
# cada sílaba. Pulsar la acción dentro de la ventana (±150 ms; ±250 en relajado) es fundirse con el coro.
# Devuelve los aciertos (0–4).
class_name Hymn extends RefCounted

const BPM := 54.0
const WORDS := ['A-TIEN-de', 'a tu', 'Con-fi-gu-', 'RA-ción']

static func run(c: Ch) -> int:
	var g := c.g; var ui := c.ui
	if g.auto: return 4
	var beat := 60.0 / BPM
	var win := 0.25 if g.difficulty() == 'relaxed' else 0.15
	var times := []
	for k in 4: times.append(beat * (2 + k))     # dos pulsos de cuenta y luego las cuatro sílabas
	var st := {t = 0.0, hits = [false, false, false, false], used = [false, false, false, false], down = false, next = 0}
	var show := func():
		var out := ''
		for k in 4:
			var w: String = ui.T(WORDS[k])
			if st.hits[k]: out += '*' + w + '*'
			elif st.t > times[k] + win: out += '·'
			else: out += w
			if k < 3: out += '   '
		ui.panel_info('El cántico', out + '\n' + c.tx('Pulsa {act} en cada sílaba, a la vez que la asamblea.', 'Toca el botón de acción en cada sílaba, a la vez que la asamblea.'))
	g.need_act = 'Cantar'
	show.call()
	await g.tick_until(func(dt) -> bool:
		var before: float = st.t
		st.t += dt
		# el órgano: los pulsos de cuenta y cada sílaba
		for k in 6:
			var bt := beat * k
			if before < bt and st.t >= bt:
				Snd.note('organ', 57 if k < 2 else [57, 60, 64, 69][k - 2], 2.0, 0.0, false)
				if k >= 2: Snd.perc('timpani', -8.0)
		var held := g.act_held()
		if g.bot: held = false
		if held and not st.down:
			for k in 4:
				if not st.used[k] and absf(st.t - times[k]) <= win:
					st.used[k] = true; st.hits[k] = true; Snd.blip('yo'); break
		st.down = held
		show.call()
		return st.t > times[3] + 1.0)
	g.need_act = ''
	ui.panel_info(null)
	var n := 0
	for h in st.hits: if h: n += 1
	return n
