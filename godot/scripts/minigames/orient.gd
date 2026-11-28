# M-05 · Volver a casa sin lámina (C3-05, §2). Anochece y la niebla se cierra: sólo el ojo, sin brújula,
# sin flecha y sin rumbo. Para orientarse: la lluvia (que empieza a mitad de camino y cae del Norte),
# un tirón leve hacia el Sur, las voces de la calle y, al final, el Grito de Paz de tu esposa en la
# puerta del Este. Si pasan 90 s, el criado sale con un farol a buscarte y te llama desde la casa.
#   opts: to (Vector2: la puerta Oeste de casa), r (radio), wife (Vector2: la puerta del Este)
# Devuelve {time, helped}.
class_name Orient extends RefCounted

static func run(c: Ch, opts := {}) -> Dictionary:
	var g := c.g; var ui := c.ui; var W := g.world
	var to: Vector2 = opts.get("to", Vector2(-41, 13.3))
	var r: float = opts.get("r", 2.4)
	if g.auto:
		g.teleport(to.x, to.y); return {time = 0.0, helped = false}
	var p := g.player
	var start := Vector2(p.x, p.y); var total := start.distance_to(to)
	g.set_view('eye'); g.view_lock = true; g.no_guides = true; W.target = null
	g.pull = Vector2(0, -0.35)
	var fog_was := W.fog; W.fog = 9.0
	var wife_at: Vector2 = opts.get("wife", Vector2(-18.2, 13.3))
	var wife := g.add(c.F_mujer('esposa_noche', wife_at.x, wife_at.y, {name = 'tu esposa', rot = PI, cry = true, cryRange = 22.0, noCollide = true}))
	g.objective('Vuelve a casa por la puerta del Oeste. Sin lámina', null)
	var st := {t = 0.0, rumble = 0.0, rain = false, helped = false, call = 0.0}
	await g.tick_until(func(dt) -> bool:
		st.t += dt
		var q := g.player
		if g.bot and st.t > 1.0: g.teleport(to.x, to.y)
		var here := Vector2(q.x, q.y)
		# el tirón del Sur, en el mando: una vibración muy suave cada 4 s
		st.rumble -= dt
		if st.rumble <= 0.0: st.rumble = 4.0; App.rumble(0.08, 0.0, 0.12)
		# a mitad de camino empieza a llover, del Norte
		if not st.rain and here.distance_to(to) < total * 0.6:
			st.rain = true; W.rain = 0.8
			ui.note('*Lógica* — Llueve. Ya sabes de dónde viene.', 4)
		# a los 90 s, el criado sale a buscarte con un farol
		if st.t > 90.0:
			if not st.helped:
				st.helped = true; ui.note('«¡Señor! ¡Señor! ¡Por aquí, señor!»', 4)
			st.call -= dt
			if st.call <= 0.0:
				st.call = 2.0; Snd.voice_at('iso', to.x, to.y, 0.0, 2.0)
		return here.distance_to(to) < r)
	g.objective('', null)
	W.remove('esposa_noche')
	g.pull = Vector2.ZERO; g.no_guides = false; g.view_lock = false
	W.fog = fog_was
	Snd.sfx('door')
	return {time = st.t, helped = st.helped}
