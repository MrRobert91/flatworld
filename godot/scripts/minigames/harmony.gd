# M-09 · El matrimonio por armonía (C6-04). Tres voces: el Rey (110 Hz), la soprano (330 Hz) y una tercera
# que el jugador mueve entre 120 y 200 Hz con el stick o las flechas (o arrastrando en la pizarra). El
# acorde «casa» cuando la tercera queda a 5/4 o a 3/2 del Rey (±12 centésimas; ±25 en relajado) durante 1 s.
# Las cuerdas de la pizarra tiemblan más cuanto más áspera es la mezcla. Dura como mucho 30 s.
class_name Harmony extends RefCounted

const KING := 110.0
const SOP := 330.0

static func cents(f: float, ref: float) -> float:
	return 1200.0 * log(f / ref) / log(2.0)

# distancia (centésimas) a la consonancia más cercana: 5/4 o 3/2 del Rey
static func off(f: float) -> float:
	return minf(absf(cents(f, KING * 1.25)), absf(cents(f, KING * 1.5)))

static func run(c: Ch) -> bool:
	var g := c.g; var ui := c.ui
	if g.auto: return true
	var tol := 25.0 if g.difficulty() == 'relaxed' else 12.0
	var st := {f = 124.0, t = 0.0, ok = 0.0, beat = 0.0, drag = false}
	var b := ui.slate(true, 'las tres voces')
	var help := ui.T(c.tx('Mueve tu voz con {move_left} y {move_right} hasta que las tres casen.', 'Arrastra el dedo sobre la escala de abajo hasta que las tres voces casen.', 'Mueve tu voz con el stick hasta que las tres casen.'))
	var draw := func(cx: SlateBoard, _t: float):
		var rough: float = clampf(off(st.f) / 120.0, 0.0, 1.0)
		var rows := [[KING, 'el Rey', 0.15], [SOP, 'la soprano', 0.15], [st.f, 'tu voz', rough]]
		for r in 3:
			var y := 110.0 + r * 100.0
			var amp: float = 4.0 + 26.0 * float(rows[r][2])
			var prev := Vector2(80, y)
			for i in 1 + 56:
				var x := 80.0 + i * 9.0
				var w := sin(i * 0.9 + st.t * (8.0 + r * 3.0)) * amp * sin(PI * i / 56.0)
				var p := Vector2(x, y + w)
				cx.line(prev.x, prev.y, p.x, p.y, 0.9 if r == 2 else 0.5); prev = p
			cx.text(ui.T(rows[r][1]), 82, y - 30, 18)
		# la tercera voz: una muesca en su escala (120–200 Hz)
		var u: float = (st.f - 120.0) / 80.0
		cx.line(80, 380, 590, 380, 0.4)
		cx.dot(80 + 510 * u, 380, 7)
		if st.ok > 0.0: cx.text(ui.T('casan…'), 470, 345, 20)
		cx.text(help, 82, 42, 16)
	g.need_stick = true
	var won := false
	await g.tick_until(func(dt) -> bool:
		st.t += dt; st.beat -= dt
		var ax := g.axis().x
		if g.bot: st.f = move_toward(st.f, KING * 1.25, dt * 30.0)
		st.f = clampf(st.f + ax * 22.0 * dt, 120.0, 200.0)
		# en táctil o con ratón: arrastrar sobre la escala
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var lp := b.get_local_mouse_position() / maxf(b.k, 0.01)
			if lp.y > 330 and lp.y < 420: st.f = clampf(120.0 + (lp.x - 80.0) / 510.0 * 80.0, 120.0, 200.0)
		if st.beat <= 0.0:
			st.beat = 0.4
			Snd.tone(KING, 0.7, 'square', 0.035); Snd.tone(SOP, 0.7, 'sine', 0.03)
			Snd.tone(st.f, 0.7, 'triangle', 0.04)
		if off(st.f) <= tol: st.ok += dt
		else: st.ok = 0.0
		b.paint(draw, 1.0)
		if st.ok >= 1.0: won = true
		return won or st.t > 30.0)
	g.need_stick = false
	if won:
		Snd.chord_once(45, [0, 4, 7, 12, 19]); await g.wait(1.2)
	c.slate_off()
	return won
