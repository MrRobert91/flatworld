# Música y sonido. La música es generativa: un secuenciador toca instrumentos muestreados
# (assets/audio/m_*.ogg, hechos con tools/make_audio.py) siguiendo el ánimo de cada escena —armonía,
# tempo, instrumentos— y una «tensión» de 0 a 1 que añade latido, bajo insistente, timbales y armonía
# oscura cuando la historia aprieta. Nunca se repite igual. Los efectos son muestras (s_*.ogg).
extends Node

const VOICES := {
	yo = [196, "triangle"], narr = [110, "sine"], inner = [330, "sine"],
	mujer = [620, "sine"], iso = [130, "sawtooth"], tri = [165, "square"],
	cuad = [185, "triangle"], penta = [220, "triangle"], hexa = [262, "triangle"],
	nino = [392, "triangle"], circ = [98, "sine"], esfera = [247, "sine"],
	rey = [147, "square"], punto = [880, "sine"],
}
const GAIN := 2.6

# instrumento → [raíces muestreadas (midi), volumen base en dB]
const INST := {
	harp = [[48, 60, 72], -8.0], pad = [[48, 60], -19.0], organ = [[48, 60], -19.0], bell = [[72, 84], -15.0],
	celesta = [[72, 84], -11.0], bass = [[36], -13.0], strings = [[36, 48, 60], -16.0], flute = [[72], -14.0],
	glass = [[72, 84], -21.0],
}
const PERC := {heart = -5.0, timpani = -8.0, tick = -21.0, shaker = -22.0}
const SFX_DB := {ui = -16.0, pick = -11.0, page = -14.0, frag = -6.0, know = -8.0, good = -9.0, bad = -8.0, her = -7.0, door = -8.0,
	peace = -12.0, gavel = -4.0, sphere = -6.0, rise = -5.0, fall = -6.0, bell = -6.0, herald = -6.0, stab = -6.0, chalk = -18.0,
	hurt = -6.0, whoosh = -12.0, slay = -5.0, title = -8.0}
# cuánto aprieta cada efecto a la música
const SPIKE := {gavel = 0.45, stab = 0.55, slay = 0.7, herald = 0.2, bad = 0.12, hurt = 0.4, fall = 0.3}

# Ánimos: tónica (midi), escala, tempo, progresión (acordes: [semitonos desde la tónica, tipo]),
# progresión oscura (con tensión alta) e instrumentos de cada capa.
const MOODS := {
	flat = {root = 50, scale = [0, 2, 3, 5, 7, 9, 10], bpm = 74, prog = [[0, "m9"], [8, "M7"], [3, "M"], [10, "add9"]],
		dark = [[0, "m"], [1, "M"], [0, "m"], [11, "dim"]], pad = "pad", arp = "harp", lead = "flute", bass = true, perc = "", dens = 0.42, pat = "up"},
	home = {root = 53, scale = [0, 2, 4, 5, 7, 9, 11], bpm = 68, prog = [[0, "M7"], [9, "m7"], [5, "M7"], [7, "sus4"]],
		dark = [[0, "m"], [8, "M"], [5, "m"], [7, "M"]], pad = "pad", arp = "harp", lead = "celesta", bass = true, perc = "", dens = 0.38, pat = "updown"},
	temple = {root = 45, scale = [0, 1, 3, 5, 7, 8, 10], bpm = 54, prog = [[0, "m"], [1, "M"], [0, "m"], [10, "m"]],
		dark = [[0, "m"], [1, "M"], [6, "dim"], [0, "m"]], pad = "organ", arp = "bell", lead = "", bass = true, perc = "", dens = 0.22, pat = "up"},
	dream = {root = 52, scale = [0, 2, 4, 6, 7, 9, 11], bpm = 62, prog = [[0, "add9"], [2, "M"], [9, "m7"], [7, "M"]],
		dark = [[0, "m"], [1, "M"], [6, "dim"], [0, "m"]], pad = "glass", arp = "celesta", lead = "bell", bass = false, perc = "", dens = 0.34, pat = "updown"},
	space = {root = 48, scale = [0, 2, 4, 6, 7, 9, 11], bpm = 60, prog = [[0, "M7"], [2, "M"], [4, "m7"], [9, "m7"]],
		dark = [[0, "m"], [8, "M"], [3, "M"], [11, "dim"]], pad = "pad", pad2 = "glass", arp = "celesta", lead = "bell", bass = true, perc = "", dens = 0.55, pat = "up", fast = true},
	color = {root = 55, scale = [0, 2, 4, 5, 7, 9, 10], bpm = 96, prog = [[0, "M"], [5, "M"], [10, "M"], [5, "M"]],
		dark = [[0, "m"], [8, "M"], [1, "M"], [0, "m"]], pad = "pad", arp = "harp", lead = "flute", bass = true, perc = "shaker", dens = 0.6, pat = "updown"},
	cell = {root = 47, scale = [0, 1, 3, 5, 6, 8, 10], bpm = 50, prog = [[0, "m"], [8, "M"], [0, "m"], [1, "M"]],
		dark = [[0, "m"], [1, "M"], [6, "dim"], [0, "m"]], pad = "strings", arp = "harp", lead = "", bass = false, perc = "", dens = 0.14, pat = "down"},
}
const CHORD := {M = [0, 4, 7], m = [0, 3, 7], M7 = [0, 4, 7, 11], m7 = [0, 3, 7, 10], m9 = [0, 3, 7, 10, 14], add9 = [0, 4, 7, 14],
	sus2 = [0, 2, 7], sus4 = [0, 5, 7], dim = [0, 3, 6]}
# antiguo sintetizador: tonos sueltos que piden los capítulos (con deslizamiento)
const FALLBACK := {chalk = [[2000, 0.03, "triangle", 0.02]]}

var muted := false
var _cache := {}
var _samples := {}        # nombre → AudioStream
var _mus: Array[AudioStreamPlayer] = []
var _sfx: Array[AudioStreamPlayer] = []
var _next_m := 0
var _next_s := 0
var _queue := []          # [retraso, stream, pitch, db, bus]
var _want := "none"
var _mood := "none"
var _mv := 0.0            # volumen de la música (0..1)
var _base_t := 0.0        # tensión que pide la escena
var _spike := 0.0         # tensión momentánea (golpes, pinchazos)
var _tens := 0.0          # tensión efectiva (suavizada)
var _acc := 0.0
var _step := 0
var _bar := 0
var _chord := []          # notas del acorde actual (midi)
var _prev_pad := []
var _motif := []          # [paso, grado] de la frase de la melodía
var _phrase_on := false
var _arp_i := 0
var _bus_m := -1
var _bus_s := -1
var _muffle := 0.0
var _duck := 0.0
var _dbg := 0.0
var _rain_p: AudioStreamPlayer
var _rain_v := 0.0
var _rain_cur := 0.0

func snd_r(v: float) -> float:
	return snappedf(v, 0.01)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_buses()
	for i in 32:
		var p := AudioStreamPlayer.new(); p.bus = "Music"; add_child(p); _mus.append(p)
	for i in 18:
		var p := AudioStreamPlayer.new(); p.bus = "Sfx"; add_child(p); _sfx.append(p)

func _exit_tree() -> void:
	for p in _mus + _sfx: p.stop(); p.stream = null
	if _rain_p: _rain_p.stop(); _rain_p.stream = null
	_samples.clear(); _cache.clear(); _queue.clear()

func _make_buses() -> void:
	# limitador en la salida: nada satura aunque coincidan música y golpes
	if AudioServer.get_bus_effect_count(0) == 0:
		var lim := AudioEffectHardLimiter.new(); lim.ceiling_db = -1.0; lim.pre_gain_db = 0.0
		AudioServer.add_bus_effect(0, lim)
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus(); _bus_m = AudioServer.bus_count - 1; AudioServer.set_bus_name(_bus_m, "Music")
		var lp := AudioEffectLowPassFilter.new(); lp.cutoff_hz = 20000; AudioServer.add_bus_effect(_bus_m, lp)
		var rv := AudioEffectReverb.new(); rv.room_size = 0.78; rv.damping = 0.45; rv.spread = 0.8; rv.wet = 0.32; rv.dry = 0.85; rv.predelay_msec = 40
		AudioServer.add_bus_effect(_bus_m, rv)
		AudioServer.set_bus_volume_db(_bus_m, -80)
	_bus_m = AudioServer.get_bus_index("Music")
	if AudioServer.get_bus_index("Sfx") < 0:
		AudioServer.add_bus(); _bus_s = AudioServer.bus_count - 1; AudioServer.set_bus_name(_bus_s, "Sfx")
		var rv := AudioEffectReverb.new(); rv.room_size = 0.45; rv.damping = 0.6; rv.wet = 0.14; rv.dry = 1.0
		AudioServer.add_bus_effect(_bus_s, rv)
	_bus_s = AudioServer.get_bus_index("Sfx")
	_rain_p = AudioStreamPlayer.new(); _rain_p.bus = "Sfx"; _rain_p.volume_db = -80; add_child(_rain_p)

# lluvia: un rumor continuo que sube y baja con la intensidad del aguacero
func rain(v: float) -> void:
	_rain_v = v

func toggle_mute() -> bool:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	return muted

func _sample(name: String) -> AudioStream:
	if _samples.has(name): return _samples[name]
	var path := "res://assets/audio/%s.ogg" % name
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_samples[name] = s
	return s

func _player(pool: Array[AudioStreamPlayer], music: bool) -> AudioStreamPlayer:
	# primero uno libre; si no, el siguiente en la rueda
	var n := pool.size()
	var start := _next_m if music else _next_s
	for k in n:
		var p := pool[(start + k) % n]
		if not p.playing:
			if music: _next_m = (start + k + 1) % n
			else: _next_s = (start + k + 1) % n
			return p
	var p := pool[start]
	if music: _next_m = (start + 1) % n
	else: _next_s = (start + 1) % n
	return p

func _play_on(s: AudioStream, pitch: float, db: float, music: bool) -> void:
	if s == null: return
	var p := _player(_mus if music else _sfx, music)
	p.stream = s; p.pitch_scale = clampf(pitch, 0.25, 4.0); p.volume_db = db; p.play()

# una nota de un instrumento muestreado
func note(inst: String, midi: float, db := 0.0, delay := 0.0, music := true) -> void:
	var I: Array = INST.get(inst, INST.harp)
	var best: int = I[0][0]
	for r in I[0]:
		if absf(midi - r) < absf(midi - best): best = r
	var s := _sample("m_%s_%d" % [inst, best])
	var pitch := pow(2.0, (midi - best) / 12.0)
	var v: float = I[1] + db
	if delay > 0.0: _queue.append([delay, s, pitch, v, music])
	else: _play_on(s, pitch, v, music)

func perc(n: String, db := 0.0, pitch := 1.0) -> void:
	_play_on(_sample("m_" + n), pitch, PERC.get(n, -10.0) + db, true)

# ---------- voces ----------
func _synth(f: float, dur: float, type: String, vol: float, slide: float) -> AudioStreamWAV:
	var key := "%s|%s|%s|%s|%s" % [f, dur, type, vol, slide]
	if _cache.has(key): return _cache[key]
	var sr := 22050
	var n := int((dur + 0.02) * sr)
	var bytes := PackedByteArray(); bytes.resize(n * 2)
	var ph := 0.0; var k := 0.0008 / maxf(vol, 0.001)
	var lp := 0.0
	for i in n:
		var t := float(i) / sr
		var fr := f
		if slide > 0.0: fr = maxf(20.0, f * pow(slide, minf(t / dur, 1.0)))
		ph += fr / sr
		var p := ph - floorf(ph)
		var s := 0.0
		match type:
			"sine": s = sin(TAU * p) + 0.12 * sin(TAU * 2.0 * p)
			"triangle": s = 4.0 * absf(p - 0.5) - 1.0
			"square": s = 0.55 if p < 0.5 else -0.55
			_: s = (2.0 * p - 1.0) * 0.6
		# un filtro suave quita la aspereza de las ondas cuadradas y de sierra
		lp += (s - lp) * 0.28
		var env := t / 0.008 if t < 0.008 else pow(k, minf(1.0, (t - 0.008) / maxf(dur - 0.008, 0.001)))
		bytes.encode_s16(i * 2, int(clampf(lp * env * vol * GAIN, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = sr; w.stereo = false; w.data = bytes
	_cache[key] = w
	return w

# Tono suelto (lo piden los capítulos). Sin deslizamiento se toca con un instrumento muestreado.
func tone(f: float, dur := 0.2, type := "sine", vol := 0.15, slide := 0.0, delay := 0.0, pitch := 1.0) -> void:
	var db := linear_to_db(maxf(vol, 0.001) * 6.0)
	if slide == 0.0 and dur >= 0.25:
		var midi := 69.0 + 12.0 * log(f * pitch / 440.0) / log(2.0)
		var inst := "harp"
		match type:
			"sine": inst = "bell" if f > 500 else ("glass" if dur > 1.5 else "celesta")
			"triangle": inst = "harp"
			"square": inst = "organ"
			_: inst = "strings"
		note(inst, midi, db + 4.0, delay, false)
		return
	var s := _synth(f, dur, type, vol, slide)
	if delay > 0.0: _queue.append([delay, s, pitch, -6.0, false])
	else: _play_on(s, pitch, -6.0, false)

func blip(voice := "yo") -> void:
	var v: Array = VOICES.get(voice, VOICES.yo)
	tone(v[0], 0.055, v[1], 0.06 if v[1] == "sine" else 0.03, 0.0, 0.0, 0.94 + randf() * 0.14)
	if voice == "circ" or voice == "esfera": tone(v[0] * 1.5, 0.07, "sine", 0.03)

# murmullo mientras se escribe un parlamento: una sílaba suave
func talk(voice := "yo") -> void:
	var v: Array = VOICES.get(voice, VOICES.yo)
	var s := _synth(v[0], 0.045, v[1], 0.03 if v[1] == "sine" else 0.016, 0.0)
	_play_on(s, 0.9 + randf() * 0.25, -9.0, false)

func sfx(n: String) -> void:
	var s := _sample("s_" + n)
	if s != null:
		var pitch := 1.0
		if n in ["chalk", "ui", "page", "door", "pick"]: pitch = 0.92 + randf() * 0.16
		_play_on(s, pitch, SFX_DB.get(n, -8.0), false)
	else:
		for t in FALLBACK.get(n, []):
			tone(t[0], t[1], t[2], t[3], t[4] if t.size() > 4 else 0.0, t[5] if t.size() > 5 else 0.0)
	if SPIKE.has(n): spike(SPIKE[n])

# ---------- música ----------
# ánimo: 'flat' | 'home' | 'dream' | 'space' | 'cell' | 'temple' | 'color' | 'none'
func drone(mode: String) -> void:
	_want = mode if (mode == "none" or MOODS.has(mode)) else "flat"
	if _want != "none" and _mood == "none":
		_mood = _want; _step = 0; _bar = 0; _acc = 0.0; _new_bar()

# tensión de la escena (0 = calma, 1 = peligro)
func tension(v: float) -> void:
	_base_t = clampf(v, 0.0, 1.0)

# un golpe de tensión que se desvanece en unos segundos
func spike(v: float) -> void:
	_spike = maxf(_spike, clampf(v, 0.0, 1.0))

# la vista del plano amortigua la música (el mundo se oye desde dentro de la línea)
func muffle(v: float) -> void:
	_muffle = v

# baja la música un momento (rótulos, momentos solemnes)
func duck(v: float) -> void:
	_duck = maxf(_duck, v)

func _process(dt: float) -> void:
	for i in range(_queue.size() - 1, -1, -1):
		_queue[i][0] -= dt
		if _queue[i][0] <= 0.0:
			var q: Array = _queue[i]
			_play_on(q[1], q[2], q[3], q[4]); _queue.remove_at(i)
	if App.args.has("audiolog"):
		_dbg += dt
		if _dbg > 2.0:
			_dbg = 0.0
			print("snd mood=", _mood, " want=", _want, " mv=", snd_r(_mv), " t=", snd_r(_tens), " playing=", _mus.filter(func(p): return p.playing).size(), " busdb=", snd_r(AudioServer.get_bus_volume_db(_bus_m)))
	_spike = maxf(0.0, _spike - dt * 0.09)
	var tt := maxf(_base_t, _spike)
	_tens = move_toward(_tens, tt, dt * (0.6 if tt > _tens else 0.12))
	_duck = maxf(0.0, _duck - dt * 0.5)
	_rain_cur = move_toward(_rain_cur, _rain_v, dt * 0.5)
	if _rain_cur > 0.01:
		if not _rain_p.playing:
			var rs := _sample("s_rain")
			if rs is AudioStreamOggVorbis: rs.loop = true
			_rain_p.stream = rs; _rain_p.play()
		_rain_p.volume_db = linear_to_db(_rain_cur) - 13.0
	elif _rain_p.playing: _rain_p.stop()
	# volumen y filtro del bus de música
	var target := 0.0 if _want == "none" else 1.0
	_mv = move_toward(_mv, target, dt / (1.8 if target > _mv else 3.0))
	if _bus_m >= 0:
		AudioServer.set_bus_volume_db(_bus_m, linear_to_db(maxf(_mv * (1.0 - 0.55 * _duck), 0.0001)) - 3.0)
		var lp: AudioEffectLowPassFilter = AudioServer.get_bus_effect(_bus_m, 0)
		lp.cutoff_hz = lerpf(20000.0, 900.0, pow(_muffle, 0.7))
	if _mood == "none":
		return
	if _mv <= 0.0 and _want == "none":
		_mood = "none"; return
	var M: Dictionary = MOODS[_mood]
	# con tensión, el pulso se acelera un poco
	var step_dur := 30.0 / (float(M.bpm) * (1.0 + 0.12 * _tens))
	_acc += dt
	var guard := 0
	while _acc >= step_dur and guard < 4:
		_acc -= step_dur; guard += 1
		_do_step(M)

func _new_bar() -> void:
	if _want != "none" and _want != _mood:
		_mood = _want; _bar = 0; _phrase_on = false
	if _mood == "none": return
	var M: Dictionary = MOODS[_mood]
	var prog: Array = M.dark if _tens > 0.5 else M.prog
	var c: Array = prog[_bar % prog.size()]
	var root: int = M.root + c[0]
	_chord = []
	for iv in CHORD[c[1]]: _chord.append(root + iv)

func _do_step(M: Dictionary) -> void:
	var s := _step % 8
	if s == 0 and _step > 0:
		_bar += 1; _new_bar()
		if _mood == "none": return
		M = MOODS[_mood]
	var t := _tens
	var calm := 1.0 - t
	var hum := randf_range(-1.5, 0.5)
	if s == 0:
		_pad(M)
		if M.bass: note("bass", _low(_chord[0], 36), hum - 2.0 * t)
		if t > 0.68: perc("timpani", -2.0 + 4.0 * (t - 0.68) + hum)
		if _bar % 2 == 0: _phrase(M)
	# latido: primero en cada compás, luego cada medio compás
	if t > 0.3 and (s == 0 or (t > 0.62 and s == 4)): perc("heart", -10.0 + 10.0 * t + hum)
	# bajo insistente con tensión: negras, luego corcheas
	if t > 0.42 and (s % 2 == 0 or t > 0.78) and not (s == 0 and M.bass):
		note("bass", _low(_chord[0], 36) + (12 if s % 4 == 2 and t > 0.78 else 0), -9.0 + 6.0 * t + hum)
	if M.bass and t <= 0.42 and s == 4 and randf() < 0.45: note("bass", _low(_chord[2 % _chord.size()], 36), -5.0 + hum)
	# arpegio
	var dens: float = M.dens * (0.8 + 0.7 * t)
	if randf() < dens or (M.get("fast", false) and randf() < dens * 0.5):
		var notes := _arp_notes()
		var n: int = notes[_arp_i % notes.size()]
		_arp_i += 1
		note(M.arp, n, hum - 3.0 * calm * randf())
		if M.get("fast", false) and randf() < 0.5:
			note(M.arp, notes[_arp_i % notes.size()], hum - 5.0, 30.0 / float(M.bpm) * 0.5)
	# melodía (callada cuando todo aprieta)
	if M.lead != "" and _phrase_on and t < 0.6:
		for ev in _motif:
			if ev[0] == (_bar % 2) * 8 + s:
				note(M.lead, ev[1], -1.0 - 6.0 * t + hum)
	if M.perc != "" and t < 0.5 and s % 2 == 1 and randf() < 0.7: perc(M.perc, hum - (0.0 if s == 3 or s == 7 else 4.0))
	if t > 0.55 and s % 2 == 1 and randf() < 0.35: perc("tick", -4.0 + hum)
	_step += 1

func _low(m: int, floor_m: int) -> int:
	while m >= floor_m + 12: m -= 12
	while m < floor_m: m += 12
	return m

# acorde del colchón: la inversión más cercana a la anterior (conducción de voces)
func _pad(M: Dictionary) -> void:
	var best := []
	var best_d := 1e9
	for inv in 3:
		var v := []
		for i in _chord.size():
			v.append(_low(_chord[i], 52) + (12 if i < inv else 0))
		v.sort()
		var d := 0.0
		for i in mini(v.size(), _prev_pad.size()): d += absf(v[i] - _prev_pad[i])
		if _prev_pad.is_empty(): d = absf(v[0] - 55)
		if d < best_d: best_d = d; best = v
	_prev_pad = best
	var k := 0
	for n in best:
		note(M.pad, n, -2.0 - (k * 1.5), k * 0.03); k += 1
	if M.has("pad2"): note(M.pad2, best[-1] + 12, -2.0)
	# con tensión, cuerdas graves sostenidas
	if _tens > 0.5: note("strings", _low(_chord[0], 40), -6.0 + 6.0 * (_tens - 0.5))

func _arp_notes() -> Array:
	var base := []
	for n in _chord: base.append(_low(n, 60))
	base.sort()
	var up := base.duplicate()
	for n in base: up.append(n + 12)
	var M: Dictionary = MOODS[_mood]
	match M.pat:
		"down": up.reverse()
		"updown":
			var d := up.duplicate(); d.reverse(); d.pop_front(); d.pop_back(); up.append_array(d)
	return up

# melodía: una frase de dos compases que se repite con variaciones (el oído reconoce el tema)
func _phrase(M: Dictionary) -> void:
	if M.lead == "": _phrase_on = false; return
	if not _motif.is_empty() and randf() < 0.55:
		# repite el tema, ajustado al acorde nuevo
		var shift := _nearest_tone(_motif[0][1]) - int(_motif[0][1])
		for ev in _motif: ev[1] = _snap(int(ev[1]) + shift, M)
		_phrase_on = randf() < 0.85
		return
	_phrase_on = randf() < 0.65
	if not _phrase_on: return
	var rhythms := [[0, 2, 3, 4, 8, 12], [0, 3, 4, 6, 8], [0, 4, 6, 7, 8, 11, 12], [2, 3, 4, 8, 10, 12], [0, 1, 2, 4, 8]]
	var r: Array = rhythms.pick_random()
	var deg := randi() % 3 * 2
	var scale: Array = M.scale
	_motif = []
	for st in r:
		deg += [-1, 1, 1, 2, -2, 0, 1, -1].pick_random()
		deg = clampi(deg, -2, 9)
		var oct := floori(deg / 7.0)
		var m: int = M.root + 24 + scale[posmod(deg, 7)] + 12 * oct
		if st % 4 == 0: m = _nearest_tone(m)
		_motif.append([st, m])

func _nearest_tone(m) -> int:
	var best := int(m); var bd := 99
	for c in _chord:
		for o in [-24, -12, 0, 12, 24]:
			var n: int = c + o
			if absi(n - int(m)) < bd: bd = absi(n - int(m)); best = n
	return best

func _snap(m: int, M: Dictionary) -> int:
	var rel := posmod(m - int(M.root), 12)
	var best := m; var bd := 99
	for iv in M.scale:
		var d := absi(int(iv) - rel)
		if d < bd: bd = d; best = m - rel + int(iv)
	return best
