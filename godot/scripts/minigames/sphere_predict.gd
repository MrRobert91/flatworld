# M-10 · Predice la sección de la Esfera (C7-02). «Si me elevo h de mi radio, ¿qué tamaño tendré para
# ti?» Tres círculos: el bueno (√(1 − h²), la sección de una esfera) y dos tentaciones: el error lineal
# (1 − h) y 1 − h². Tras elegir, la Esfera sube a esa altura y su círculo en el Plano —y en la línea del
# ojo— se ajusta al tamaño real. En relajado, un fallo da otro intento. Devuelve los aciertos.
class_name SpherePredict extends RefCounted

static func run(c: Ch, sph: Ent, rounds: Array) -> int:
	var g := c.g; var ui := c.ui
	var hits := 0
	for h in rounds:
		var right := Geom3.sphere_section(1.0, h)
		var opts := [{id = 'ok', circle = right}, {id = 'lin', circle = 1.0 - h}, {id = 'sq', circle = 1.0 - h * h}]
		opts.shuffle()
		for i in opts.size(): opts[i].label = ''; opts[i].sub = str(i + 1)
		var how: String = {0.5: 'la mitad de mi radio', 0.9: 'nueve décimas de mi radio'}.get(h, 'un poco')
		var tries := 2 if g.difficulty() == 'relaxed' else 1
		var got := false
		for attempt in tries:
			var q := ui.T('«Si me elevo %s, ¿qué tamaño tendré para ti?»') % ui.T(how)
			var ans = await ui.panel('La sección de la Esfera', q + '\n' + ui.T('(el círculo punteado es mi tamaño de ahora)'), opts)
			if g.auto or g.bot: ans = 'ok'
			if ans == 'ok': got = true; break
			if attempt < tries - 1:
				ui.note(ui.T('*Lógica:* %s') % ui.T('Piensa en tu sección ante el Rey: casi toda la diagonal seguía dentro aunque te apartaras un poco del centro.'), 6.0)
		# la Esfera sube: su círculo se ajusta al tamaño real
		Snd.tone(330.0 + 220.0 * h, 1.6, 'sine', 0.06, 1.0 + h)
		var s0 := sph.sc
		await g.tween(1.6, func(t): sph.sc = lerpf(s0, maxf(right, 0.001), App.ease(t)))
		if got:
			hits += 1; Snd.sfx('good')
			ui.note(ui.T('*La Esfera:* «%s»') % ui.T('Exacto: casi nada menos, aunque haya subido la mitad.' if h < 0.7 else 'Exacto. Al final, muy deprisa: así menguo hasta un punto.'), 4.0)
		else:
			Snd.sfx('bad')
			ui.note(ui.T('*La Esfera:* «%s»') % ui.T('No. Mírame: este es mi tamaño a esa altura. Menos de lo que crees al principio, mucho más deprisa al final.'), 5.0)
		await g.wait(1.6)
	return hits
