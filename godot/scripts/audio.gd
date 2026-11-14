# Sonido enteramente procedural: ambiente, voces por clase social y efectos.
# Los tonos se sintetizan una vez (PCM) y se guardan; los ambientes se generan poco a poco
# en segundo plano para no detener nunca la imagen.
extends Node

const VOICES := {
	yo = [196, "triangle"], narr = [110, "sine"], inner = [330, "sine"],
	mujer = [620, "sine"], iso = [130, "sawtooth"], tri = [165, "square"],
	cuad = [185, "triangle"], penta = [220, "triangle"], hexa = [262, "triangle"],
	nino = [392, "triangle"], circ = [98, "sine"], esfera = [247, "sine"],
	rey = [147, "square"], punto = [880, "sine"],
}
# efecto → lista de tonos [f, dur, tipo, vol, slide, retraso]
const SFX := {
	ui = [[520, 0.05, "sine", 0.06]], pick = [[660, 0.07, "sine", 0.07]],
	frag = [[392, 0.5, "sine", 0.09, 0, 0.0], [494, 0.5, "sine", 0.09, 0, 0.09], [587, 0.5, "sine", 0.09, 0, 0.18], [784, 0.5, "sine", 0.09, 0, 0.27]],
	know = [[523, 0.25, "triangle", 0.08], [784, 0.4, "triangle", 0.08, 0, 0.12]],
	good = [[440, 0.15, "sine", 0.08], [660, 0.25, "sine", 0.08, 0, 0.1]],
	bad = [[196, 0.3, "sawtooth", 0.06, 0.7]],
	her = [[311, 0.6, "sine", 0.08], [466, 0.8, "sine", 0.06, 0, 0.1], [740, 1.0, "sine", 0.04, 0, 0.2]],
	door = [[90, 0.2, "square", 0.06, 0.6]],
	peace = [[900, 0.09, "sine", 0.05, 1.25], [1150, 0.12, "sine", 0.04, 0.85, 0.1]],
	gavel = [[70, 0.5, "square", 0.16, 0.5], [50, 0.9, "sine", 0.2, 0.8]],
	sphere = [[220, 2.2, "sine", 0.05, 0, 0.0], [277, 2.2, "sine", 0.05, 0, 0.07], [330, 2.2, "sine", 0.05, 0, 0.14], [415, 2.2, "sine", 0.05, 0, 0.21], [554, 2.2, "sine", 0.05, 0, 0.28]],
	rise = [[80, 3.5, "sine", 0.16, 9], [120, 3.5, "triangle", 0.07, 9, 0.1]],
	fall = [[900, 2.4, "sine", 0.12, 0.05]],
	bell = [[880, 1.6, "sine", 0.08], [1320, 1.2, "sine", 0.04], [440, 2.0, "sine", 0.05]],
	herald = [[294, 0.3, "square", 0.06, 0, 0.0], [294, 0.3, "square", 0.06, 0, 0.22], [392, 0.3, "square", 0.06, 0, 0.44]],
	stab = [[1400, 0.12, "sawtooth", 0.07, 0.3]],
	chalk = [[2000, 0.03, "triangle", 0.02]],
}
const DRONES := {
	flat = [[55, "sine", .5], [82.4, "sine", .28], [164.8, "triangle", .05], [165.6, "sine", .05]],
	home = [[65.4, "sine", .45], [98, "sine", .25], [196, "sine", .06], [246.9, "sine", .04]],
	temple = [[49, "sine", .5], [73.4, "sine", .35], [98, "sine", .2], [146.8, "sine", .1], [147.5, "sine", .1]],
	dream = [[61.7, "sine", .4], [92.5, "triangle", .12], [185, "sine", .08], [277.2, "sine", .06], [278.4, "sine", .05]],
	space = [[87.3, "sine", .35], [130.8, "sine", .25], [196, "sine", .14], [329.6, "sine", .1], [493.9, "sine", .07], [495.5, "sine", .06]],
	color = [[110, "sine", .3], [164.8, "triangle", .1], [277.2, "sine", .12], [329.6, "sine", .1], [415.3, "sine", .07]],
	cell = [[41.2, "sine", .6], [43.6, "sine", .25]],
}
const GAIN := 2.6
const D_RATE := 8000
const D_LEN := 8.0

var muted := false
var _cache := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _queue := []          # [retraso, stream, pitch]
var _warm := []           # tonos por presintetizar
var _drones := {}         # modo → AudioStreamWAV
var _job = null           # generación de ambiente en curso
var _want := "none"
var _mode := "none"
var _dp: Array[AudioStreamPlayer] = []
var _dv := [0.0, 0.0]
var _dt := [0.0, 0.0]
var _cur := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 16:
		var p := AudioStreamPlayer.new(); add_child(p); _pool.append(p)
	for i in 2:
		var p := AudioStreamPlayer.new(); p.volume_db = -80; add_child(p); _dp.append(p)
	for k in SFX:
		for t in SFX[k]: _warm.append(t)
	for v in VOICES: _warm.append([VOICES[v][0], 0.055, VOICES[v][1], 0.07 if VOICES[v][1] == "sine" else 0.035])

func toggle_mute() -> bool:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	return muted

func _synth(f: float, dur: float, type: String, vol: float, slide: float) -> AudioStreamWAV:
	var key := "%s|%s|%s|%s|%s" % [f, dur, type, vol, slide]
	if _cache.has(key): return _cache[key]
	var sr := 11025 if dur > 1.2 and f < 1000 else 22050
	var n := int((dur + 0.02) * sr)
	var bytes := PackedByteArray(); bytes.resize(n * 2)
	var ph := 0.0; var k := 0.0008 / maxf(vol, 0.001)
	for i in n:
		var t := float(i) / sr
		var fr := f
		if slide > 0.0: fr = maxf(20.0, f * pow(slide, minf(t / dur, 1.0)))
		ph += fr / sr
		var p := ph - floorf(ph)
		var s := 0.0
		match type:
			"sine": s = sin(TAU * p)
			"triangle": s = 4.0 * absf(p - 0.5) - 1.0
			"square": s = 0.55 if p < 0.5 else -0.55
			_: s = (2.0 * p - 1.0) * 0.6
		var env := t / 0.012 if t < 0.012 else pow(k, minf(1.0, (t - 0.012) / maxf(dur - 0.012, 0.001)))
		bytes.encode_s16(i * 2, int(clampf(s * env * vol * GAIN, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = sr; w.stereo = false; w.data = bytes
	_cache[key] = w
	return w

func tone(f: float, dur := 0.2, type := "sine", vol := 0.15, slide := 0.0, delay := 0.0, pitch := 1.0) -> void:
	var s := _synth(f, dur, type, vol, slide)
	if delay > 0.0: _queue.append([delay, s, pitch])
	else: _play(s, pitch)

func _play(s: AudioStream, pitch: float) -> void:
	var p := _pool[_next]; _next = (_next + 1) % _pool.size()
	p.stream = s; p.pitch_scale = pitch; p.play()

func blip(voice := "yo") -> void:
	var v: Array = VOICES.get(voice, VOICES.yo)
	tone(v[0], 0.055, v[1], 0.07 if v[1] == "sine" else 0.035, 0.0, 0.0, 0.94 + randf() * 0.14)
	if voice == "circ" or voice == "esfera": tone(v[0] * 1.5, 0.07, "sine", 0.03)

func sfx(n: String) -> void:
	for t in SFX.get(n, []):
		tone(t[0], t[1], t[2], t[3], t[4] if t.size() > 4 else 0.0, t[5] if t.size() > 5 else 0.0, 0.9 + randf() * 0.3 if n == "chalk" else 1.0)

# ambiente: 'flat' | 'home' | 'dream' | 'space' | 'cell' | 'temple' | 'color' | 'none'
func drone(mode: String) -> void:
	_want = mode

func _process(dt: float) -> void:
	for i in range(_queue.size() - 1, -1, -1):
		_queue[i][0] -= dt
		if _queue[i][0] <= 0.0:
			_play(_queue[i][1], _queue[i][2]); _queue.remove_at(i)
	if not _warm.is_empty():
		var t: Array = _warm.pop_back()
		_synth(t[0], t[1], t[2], t[3], t[4] if t.size() > 4 else 0.0)
	_gen_step()
	if _want != _mode and (_want == "none" or _drones.has(_want)):
		_mode = _want
		_dt[_cur] = 0.0
		if _mode != "none":
			_cur = 1 - _cur
			_dp[_cur].stream = _drones[_mode]; _dp[_cur].play(); _dv[_cur] = 0.0; _dt[_cur] = 1.0
	for i in 2:
		if _dv[i] != _dt[i]:
			_dv[i] = move_toward(_dv[i], _dt[i], dt / (1.5 if _dt[i] > 0 else 2.5))
			_dp[i].volume_db = linear_to_db(maxf(_dv[i], 0.0001))
			if _dv[i] <= 0.0: _dp[i].stop()

# genera los ambientes a trozos: primero el que se ha pedido
func _gen_step() -> void:
	if _job == null:
		var pick := ""
		if _want != "none" and not _drones.has(_want): pick = _want
		else:
			for m in DRONES:
				if not _drones.has(m): pick = m; break
		if pick == "": return
		var n := int(D_RATE * D_LEN)
		var oscs := []
		for o in DRONES[pick]:
			oscs.append([roundf(o[0] * D_LEN) / D_LEN / D_RATE, o[1] == "triangle", o[2] * 0.5, o[2] * 0.18, randf() * TAU, 0.0])
		var bytes := PackedByteArray(); bytes.resize(n * 2)
		_job = {mode = pick, n = n, i = 0, oscs = oscs, bytes = bytes}
	var j: Dictionary = _job
	var end: int = mini(j.n, j.i + (4000 if _want == j.mode else 1500))
	var bytes: PackedByteArray = j.bytes
	var i: int = j.i
	while i < end:
		var blk := mini(end, i + 64)
		var lf: float = TAU * float(i) / j.n
		var amps := []
		for o in j.oscs: amps.append(o[2] + o[3] * sin(lf + o[4]))
		while i < blk:
			var s := 0.0; var q := 0
			for o in j.oscs:
				var p: float = o[5] + o[0]
				p -= floorf(p); o[5] = p
				s += amps[q] * ((4.0 * absf(p - 0.5) - 1.0) if o[1] else sin(TAU * p))
				q += 1
			bytes.encode_s16(i * 2, int(clampf(s * 0.75, -1.0, 1.0) * 32767.0))
			i += 1
	j.i = i
	if i >= j.n:
		var w := AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = D_RATE; w.stereo = false; w.data = bytes
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD; w.loop_begin = 0; w.loop_end = j.n
		_drones[j.mode] = w; _job = null
