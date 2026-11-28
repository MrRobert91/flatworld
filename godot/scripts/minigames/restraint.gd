# M-14 · Contenerse (C10-02). Mientras el conferenciante dice algo que sabes falso, una barra sube sola
# (speed por segundo) y el jugador la frena manteniendo {act} (−0,6/s). Si llega arriba, se rompe: hablas.
# Con speed ≥ 2 se rompe siempre (la tercera vez). Devuelve si aguantó.
class_name Restraint extends RefCounted

static func run(c: Ch, speed: float, sec := 5.0) -> bool:
	var g := c.g; var ui := c.ui
	if g.auto: return speed < 2.0
	var st := {v = 0.0, t = 0.0}
	g.need_act = 'Callar'
	var text := c.tx('Mantén {act} para callar.', 'Mantén pulsado el botón de acción para callar.')
	await g.tick_until(func(dt) -> bool:
		st.t += dt
		var held := g.act_held() or (g.bot and speed < 2.0)
		st.v = clampf(st.v + (speed - (0.6 if held else 0.0)) * dt, 0.0, 1.0)
		var n := int(round(st.v * 20.0))
		ui.panel_info('Contenerte', '[' + '|'.repeat(n) + '·'.repeat(20 - n) + ']\n' + ui.T(text))
		if st.v >= 1.0: return true
		return st.t >= sec)
	g.need_act = ''; ui.panel_info(null)
	if st.v >= 1.0:
		Snd.sfx('chalk_break'); App.rumble(0.4, 0.7, 0.2); ui.flash(0.15)
		return false
	return true
