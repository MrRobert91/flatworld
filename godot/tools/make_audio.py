# Sintetiza los instrumentos de la música y los efectos de sonido de Planilandia (OGG en assets/audio/).
#   python3 godot/tools/make_audio.py        (necesita numpy, scipy y ffmpeg)
# El juego no sintetiza estos sonidos: los secuencia (scripts/audio.gd), así que se oyen igual en
# la web, en el móvil y en el escritorio, sin coste de CPU.
import os, subprocess, tempfile
import numpy as np
from scipy import signal

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(1884)


def t_(dur):
	return np.arange(int(dur * SR)) / SR


def mtof(m):
	return 440.0 * 2 ** ((m - 69) / 12)


def lp(x, fc, order=2):
	b, a = signal.butter(order, min(fc / (SR / 2), 0.99), "low")
	return signal.lfilter(b, a, x)


def hp(x, fc, order=2):
	b, a = signal.butter(order, fc / (SR / 2), "high")
	return signal.lfilter(b, a, x)


def bp(x, lo, hi, order=2):
	b, a = signal.butter(order, [lo / (SR / 2), min(hi / (SR / 2), 0.99)], "band")
	return signal.lfilter(b, a, x)


def env(n, a=0.005, r=0.05):
	e = np.ones(n)
	na = max(1, min(int(a * SR), n // 2)); nr = max(1, min(int(r * SR), n - na))
	e[:na] = np.linspace(0, 1, na) ** 1.5
	e[-nr:] *= np.linspace(1, 0, nr) ** 2
	return e


def saw_add(f, t, maxf=7000, phase=0.0, vib=None):
	# diente de sierra aditivo (sin aliasing)
	ph = 2 * np.pi * f * t if vib is None else 2 * np.pi * np.cumsum(f * (1 + vib)) / SR
	out = np.zeros_like(t)
	k = 1
	while k * f < maxf and k < 60:
		out += np.sin(k * ph + phase * k) / k
		k += 1
	return out * 0.6


def reverb(x, secs=1.6, mix=0.25, damp=3500):
	n = int(secs * SR)
	ir = rng.standard_normal(n) * np.exp(-np.linspace(0, 7, n))
	ir = lp(ir, damp)
	ir[: int(0.012 * SR)] = 0
	ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
	wet = signal.fftconvolve(np.concatenate([x, np.zeros(n)]), ir)[: len(x) + n]
	dry = np.concatenate([x, np.zeros(n)])
	return dry * (1 - mix) + wet * mix * 0.6


def norm(x, peak=0.85):
	m = np.max(np.abs(x)) + 1e-9
	return x / m * peak


def trim(x, thr=1e-3):
	if len(x) == int(6.0 * SR): return x
	idx = np.where(np.abs(x) > thr)[0]
	if len(idx) == 0: return x
	end = min(len(x), idx[-1] + int(0.02 * SR))
	y = x[:end].copy()
	f = min(len(y), int(0.03 * SR))
	y[-f:] *= np.linspace(1, 0, f)
	return y


def write(name, x, peak=0.85, q=4):
	x = norm(trim(np.asarray(x, dtype=np.float64)), peak)
	pcm = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
	path = os.path.join(OUT, name + ".ogg")
	subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", "-",
		"-c:a", "libvorbis", "-q:a", str(q), path], input=pcm, check=True)


# ---------------- instrumentos ----------------
def harp(f, dur=3.2):
	# Karplus-Strong con dos cuerdas casi al unísono y un cuerpo resonante
	n = int(dur * SR)
	out = np.zeros(n)
	for det, amp in ((1.0, 1.0), (1.0017, 0.55)):
		N = int(round(SR / (f * det)))
		buf = lp(rng.uniform(-1, 1, N), min(6000, f * 9))
		y = np.zeros(n)
		y[:N] = buf
		damp = 0.4985 + 0.0012 * min(1.0, 200 / f)
		for i in range(N, n):
			y[i] = damp * (y[i - N] + y[i - N + 1])
		out += y * amp
	out = hp(lp(out, 5200) + 0.25 * bp(out, 180, 900), 45)
	return out * env(n, 0.002, 0.4)


def pad(f, dur=6.5):
	t = t_(dur); n = len(t)
	x = np.zeros(n)
	for det in (-0.009, -0.004, 0.0, 0.0045, 0.0095):
		x += saw_add(f * (1 + det), t, maxf=4500, phase=rng.uniform(0, 6.28))
	# filtro que respira
	x = lp(x, 900 + f * 2) * 0.8 + lp(x, 2400) * 0.2
	e = env(n, 1.1, 2.0)
	return x * e * (1 + 0.08 * np.sin(2 * np.pi * 0.3 * t))


def organ(f, dur=6.0):
	t = t_(dur); n = len(t)
	x = sum(a * np.sin(2 * np.pi * f * k * t + rng.uniform(0, 6)) for k, a in ((0.5, .5), (1, 1), (2, .6), (3, .35), (4, .25), (6, .12), (8, .08)))
	x *= 1 + 0.03 * np.sin(2 * np.pi * 5.6 * t)
	return lp(x, 3000) * env(n, 0.5, 1.8)


def bell(f, dur=4.0):
	t = t_(dur)
	idx = 2.4 * np.exp(-t * 2.5) + 0.25
	x = np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * 3.5 * t))
	x += 0.35 * np.sin(2 * np.pi * f * 2.0 * t) * np.exp(-t * 1.6)
	x += 0.2 * np.sin(2 * np.pi * f * 4.07 * t) * np.exp(-t * 4)
	return x * np.exp(-t * 1.1) * env(len(t), 0.002, 0.3)


def celesta(f, dur=2.8):
	t = t_(dur)
	x = np.sin(2 * np.pi * f * t) * np.exp(-t * 1.7)
	x += 0.3 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 6)
	x += 0.12 * np.sin(2 * np.pi * f * 2.01 * t) * np.exp(-t * 3)
	click = bp(rng.standard_normal(len(t)), 2000, 6000) * np.exp(-t * 120) * 0.15
	return (x + click) * env(len(t), 0.001, 0.2)


def bass(f, dur=2.6):
	t = t_(dur)
	x = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(4 * np.pi * f * t) + 0.12 * np.sin(6 * np.pi * f * t)
	x = np.tanh(1.6 * x) * (0.4 + 0.6 * np.exp(-t * 2.2))
	return lp(x, 900) * env(len(t), 0.006, 0.5)


def strings(f, dur=4.5):
	t = t_(dur); n = len(t)
	vib = 0.004 * np.sin(2 * np.pi * 5.3 * t) * np.clip(t / 0.6, 0, 1)
	x = sum(saw_add(f * (1 + d), t, maxf=5000, vib=vib) for d in (-0.006, 0.0, 0.0065))
	x = lp(x, 1800) + 0.3 * bp(x, 600, 1400)
	return x * env(n, 0.45, 1.3)


def flute(f, dur=1.9):
	t = t_(dur); n = len(t)
	vib = 0.006 * np.sin(2 * np.pi * 5.0 * t) * np.clip((t - 0.25) / 0.4, 0, 1)
	ph = 2 * np.pi * np.cumsum(f * (1 + vib)) / SR
	x = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.06 * np.sin(3 * ph)
	breath = bp(rng.standard_normal(n), f * 0.8, f * 2.5) * 0.12
	return (x + breath) * env(n, 0.07, 0.35)


def glass(f, dur=5.0):
	t = t_(dur); n = len(t)
	x = np.sin(2 * np.pi * f * t) + 0.45 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 0.8) + 0.2 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 1.5)
	x *= 1 + 0.25 * np.sin(2 * np.pi * 3.1 * t)
	return x * env(n, 0.6, 2.2)


def heart(dur=0.9):
	t = t_(dur); x = np.zeros(len(t))
	for off, a in ((0.0, 1.0), (0.26, 0.7)):
		tt = np.clip(t - off, 0, None)
		f = 38 + 40 * np.exp(-tt * 30)
		ph = 2 * np.pi * np.cumsum(f) / SR
		x += a * np.sin(ph) * np.exp(-tt * 9) * (t >= off)
	return lp(x, 400)


def timpani(dur=2.2):
	t = t_(dur)
	f = 73 * (1 + 0.05 * np.exp(-t * 8))
	ph = 2 * np.pi * np.cumsum(f) / SR
	x = np.sin(ph) * np.exp(-t * 2.2) + 0.4 * np.sin(1.5 * ph) * np.exp(-t * 3.5)
	x += lp(rng.standard_normal(len(t)), 700) * np.exp(-t * 25) * 0.6
	return x * env(len(t), 0.002, 0.3)


def tick(dur=0.09):
	t = t_(dur)
	return bp(rng.standard_normal(len(t)), 4000, 11000) * np.exp(-t * 60)


def shaker(dur=0.18):
	t = t_(dur)
	e = np.clip(t / 0.03, 0, 1) * np.exp(-t * 28)
	return bp(rng.standard_normal(len(t)), 5000, 12000) * e


# ---------------- efectos ----------------
def seq(parts, dur):
	out = np.zeros(int(dur * SR))
	for at, x, g in parts:
		i = int(at * SR); x = x[: len(out) - i]
		out[i:i + len(x)] += x * g
	return out


def sfx():
	S = {}
	t = t_(0.06)
	S["ui"] = bp(rng.standard_normal(len(t)), 1500, 5000) * np.exp(-t * 140) * 0.6 + np.sin(2 * np.pi * 1900 * t) * np.exp(-t * 90) * 0.3
	S["pick"] = reverb(seq([(0, harp(mtof(69), 1.2), 1.0), (0.05, harp(mtof(76), 1.2), 0.7)], 1.3), 1.2, 0.25)
	t = t_(0.22)
	S["page"] = bp(rng.standard_normal(len(t)), 1800, 7000) * np.sin(np.pi * t / 0.22) ** 2 * (0.6 + 0.4 * np.sin(2 * np.pi * 37 * t)) * 0.5
	notes = [67, 71, 74, 78, 81, 86]
	S["frag"] = reverb(seq([(i * 0.09, harp(mtof(m), 2.0), 0.8) for i, m in enumerate(notes)] + [(0.5, glass(mtof(86), 2.5), 0.25), (0.3, celesta(mtof(91), 2.0), 0.35)], 3.0), 2.4, 0.35)
	S["know"] = reverb(seq([(0, celesta(mtof(84)), 0.8), (0.14, celesta(mtof(91)), 0.8), (0.0, bell(mtof(72), 2.0), 0.3)], 2.4), 2.0, 0.3)
	S["good"] = reverb(seq([(0, harp(mtof(72), 1.2), 0.9), (0.1, harp(mtof(76), 1.2), 0.9), (0.2, harp(mtof(79), 1.4), 0.9)], 1.5), 1.2, 0.25)
	b = seq([(0, strings(mtof(40), 1.2), 0.6), (0, strings(mtof(46), 1.2), 0.5), (0, heart(0.5)[: int(0.4 * SR)], 0.8)], 1.3)
	S["bad"] = reverb(b * np.linspace(1, 0.7, len(b)), 1.0, 0.2)
	S["her"] = reverb(seq([(0, glass(mtof(75), 2.6), 0.6), (0.15, glass(mtof(81), 2.6), 0.5), (0.3, glass(mtof(88), 2.4), 0.3), (0, strings(mtof(51), 2.4), 0.3)], 3.2), 2.6, 0.4)
	t = t_(0.45)
	S["door"] = lp(rng.standard_normal(len(t)), 500) * np.exp(-t * 18) * 0.8 + np.sin(2 * np.pi * 85 * t) * np.exp(-t * 14) + bp(rng.standard_normal(len(t)), 1200, 3000) * np.exp(-t * 60) * 0.2
	t = t_(0.75)
	f = 1050 * (1 + 0.18 * t / 0.75) * (1 + 0.012 * np.sin(2 * np.pi * 9 * t))
	ph = 2 * np.pi * np.cumsum(f) / SR
	S["peace"] = reverb((np.sin(ph) + 0.1 * np.sin(2 * ph)) * env(len(t), 0.05, 0.3) * 0.6 + bp(rng.standard_normal(len(t)), 900, 2600) * 0.05, 0.9, 0.25)
	def knock():
		t = t_(0.3)
		return lp(rng.standard_normal(len(t)), 1800) * np.exp(-t * 35) + np.sin(2 * np.pi * 180 * t) * np.exp(-t * 25) * 0.8 + np.sin(2 * np.pi * 95 * t) * np.exp(-t * 12) * 0.6
	S["gavel"] = reverb(seq([(0, knock(), 1.0), (0.32, knock(), 0.8)], 0.8), 2.2, 0.35)
	S["sphere"] = reverb(seq([(i * 0.11, glass(mtof(m), 3.0), 0.5) for i, m in enumerate([60, 64, 67, 71, 74, 79])] + [(0, pad(mtof(48), 3.0), 0.5)], 3.6), 2.8, 0.4)
	t = t_(3.6)
	sweep = np.zeros(len(t))
	noise = rng.standard_normal(len(t))
	for k in range(36):
		a, b2 = int(k * len(t) / 36), int((k + 1) * len(t) / 36)
		fc = 200 * (1 + k / 4) ** 1.6
		sweep[a:b2] = bp(noise, fc, fc * 2.5)[a:b2]
	fr = 90 * 2 ** (t * 1.2)
	S["rise"] = reverb(sweep * (t / 3.6) ** 1.5 * 0.7 + np.sin(2 * np.pi * np.cumsum(fr) / SR) * 0.4 * (t / 3.6) * env(len(t), 0.5, 0.4), 2.0, 0.3)
	t = t_(2.6)
	fr = 900 * 2 ** (-t * 2.2)
	S["fall"] = reverb(np.sin(2 * np.pi * np.cumsum(fr) / SR) * env(len(t), 0.02, 0.8) * 0.6 + lp(rng.standard_normal(len(t)), 1500) * np.exp(-t * 1.5) * 0.25, 2.0, 0.35)
	S["bell"] = reverb(seq([(0, bell(mtof(64), 4.5), 1.0), (0, bell(mtof(76), 3.0), 0.35)], 4.5), 3.0, 0.4)
	def brass(m, d):
		t = t_(d); f = mtof(m)
		x = saw_add(f, t, maxf=6000)
		fe = 600 + 2600 * np.exp(-t * 6) * np.clip(t / 0.03, 0, 1)
		y = np.zeros_like(x)
		# filtro de envolvente por tramos
		for k in range(12):
			a, b2 = int(k * len(t) / 12), int((k + 1) * len(t) / 12)
			y[a:b2] = lp(x, fe[a])[a:b2]
		return y * env(len(t), 0.03, 0.12)
	S["herald"] = reverb(seq([(0, brass(62, 0.22), 0.8), (0.24, brass(62, 0.22), 0.8), (0.48, brass(67, 0.7), 1.0), (0.48, brass(59, 0.7), 0.5)], 1.4), 2.0, 0.3)
	t = t_(0.6)
	S["stab"] = reverb(sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) for f, d in ((2350, 9), (3170, 12), (4410, 15), (5830, 20))) * 0.3 + hp(rng.standard_normal(len(t)), 3000) * np.exp(-t * 30) * 0.5 + np.sin(2 * np.pi * 70 * t) * np.exp(-t * 20), 1.0, 0.25)
	t = t_(0.14)
	S["chalk"] = bp(rng.standard_normal(len(t)), 2500, 6000) * (0.5 + 0.5 * np.sin(2 * np.pi * 70 * t)) * env(len(t), 0.01, 0.05) * 0.5
	t = t_(0.5)
	S["hurt"] = reverb(np.sin(2 * np.pi * np.cumsum(220 * 2 ** (-t * 3)) / SR) * np.exp(-t * 8) + 0.5 * np.sin(2 * np.pi * np.cumsum(233 * 2 ** (-t * 3)) / SR) * np.exp(-t * 8) + lp(rng.standard_normal(len(t)), 900) * np.exp(-t * 25), 0.6, 0.2)
	t = t_(1.2)
	noise = rng.standard_normal(len(t)); wh = np.zeros(len(t))
	for k in range(24):
		a, b2 = int(k * len(t) / 24), int((k + 1) * len(t) / 24)
		fc = 300 + 2200 * np.sin(np.pi * k / 24)
		wh[a:b2] = bp(noise, fc, fc * 1.8)[a:b2]
	S["whoosh"] = wh * np.sin(np.pi * t / 1.2) ** 2 * 0.8
	S["slay"] = reverb(seq([(0, S["stab"][: int(0.5 * SR)], 0.8), (0.05, timpani(1.6), 0.9), (0.1, strings(mtof(37), 1.4), 0.4)], 1.8), 1.8, 0.3)
	S["title"] = reverb(seq([(0, bell(mtof(60), 4.0), 0.6), (0.0, pad(mtof(48), 4.0), 0.4), (0.0, pad(mtof(55), 4.0), 0.3), (0.35, celesta(mtof(79), 2.4), 0.3)], 4.6), 3.0, 0.4)
	# lluvia: rumor de banda ancha con gotas sueltas; los extremos se funden para que el bucle no se note
	L = 6.0; t = t_(L + 1.0); n = len(t)
	x = bp(rng.standard_normal(n), 400, 7000) * 0.35 + lp(rng.standard_normal(n), 700) * 0.25
	x *= 1 + 0.15 * np.sin(2 * np.pi * 0.23 * t)
	for k in range(260):
		i = rng.integers(0, n - 2000); f = rng.uniform(2500, 7000); dd = t_(0.03)
		x[i:i + len(dd)] += np.sin(2 * np.pi * f * dd) * np.exp(-dd * 160) * rng.uniform(0.1, 0.4)
	m = int(L * SR); fade = n - m
	y = x[:m].copy(); w = np.linspace(0, 1, fade)
	y[:fade] = x[m:] * (1 - w) + x[:fade] * w
	S["rain"] = y
	return S


# Efectos añadidos en el hito M1. Se escriben como WAV (no necesitan ffmpeg): el juego carga .ogg o .wav.
#   python3 godot/tools/make_audio.py --extra
def extra_sfx():
	S = {}
	r2 = np.random.default_rng(1999)
	# cerrojo: un clic metálico doble y el giro de la llave
	t = t_(0.42)
	click = lambda d: bp(r2.standard_normal(len(t_(d))), 2500, 7000) * np.exp(-t_(d) * 90) + np.sin(2 * np.pi * 1800 * t_(d)) * np.exp(-t_(d) * 70) * 0.4
	S["lock"] = reverb(seq([(0, click(0.08), 0.9), (0.06, lp(r2.standard_normal(int(0.2 * SR)), 900) * np.linspace(0.5, 0, int(0.2 * SR)), 0.5), (0.28, click(0.1), 1.0)], 0.42), 0.4, 0.15)
	# pluma: un trazo rasgado sobre el papel
	t = t_(0.55)
	scr = bp(r2.standard_normal(len(t)), 3000, 8000) * (0.55 + 0.45 * np.sin(2 * np.pi * 23 * t) ** 2)
	S["quill"] = scr * np.sin(np.pi * t / 0.55) ** 1.5 * 0.55
	# compresiones del Hospital: golpes sordos rítmicos y un quejido
	def thud():
		d = t_(0.35)
		return lp(r2.standard_normal(len(d)), 300) * np.exp(-d * 14) + np.sin(2 * np.pi * 55 * d) * np.exp(-d * 9)
	g = t_(1.0); f = 180 * (1 - 0.25 * g)
	groan = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(g), 0.15, 0.5) * 0.25 * (1 + 0.3 * np.sin(2 * np.pi * 5 * g))
	S["compress"] = reverb(seq([(0, thud(), 1.0), (0.45, thud(), 1.0), (0.9, thud(), 1.0), (0.6, lp(groan, 1200), 0.8)], 1.8), 1.2, 0.3)
	# campanilla de la cola de la Puerta
	S["chime"] = reverb(seq([(0, bell(mtof(88), 1.4), 0.7), (0.12, bell(mtof(95), 1.2), 0.4)], 1.4), 1.0, 0.25)
	# lámpara y reloj de la mesa del lector
	t = t_(2.0)
	hum = (np.sin(2 * np.pi * 100 * t) + 0.4 * np.sin(2 * np.pi * 200 * t) + 0.15 * np.sin(2 * np.pi * 300 * t)) * 0.18
	S["hum"] = hum * np.minimum(1, np.minimum(t / 0.05, (2.0 - t) / 0.05))
	return S


def write_wav(name, x, peak=0.8):
	from scipy.io import wavfile
	y = norm(trim(x), peak)
	wavfile.write(os.path.join(OUT, name + ".wav"), SR, (y * 32767).astype(np.int16))


def main():
	import sys
	if "--extra" in sys.argv:
		for k, x in extra_sfx().items():
			write_wav("s_" + k, x); print("s_" + k + ".wav")
		return
	os.makedirs(OUT, exist_ok=True)
	inst = {
		"harp": (harp, [48, 60, 72]), "pad": (pad, [48, 60]), "organ": (organ, [48, 60]), "bell": (bell, [72, 84]),
		"celesta": (celesta, [72, 84]), "bass": (bass, [36]), "strings": (strings, [36, 48, 60]), "flute": (flute, [72]),
		"glass": (glass, [72, 84]),
	}
	for name, (fn, roots) in inst.items():
		for m in roots:
			write("m_%s_%d" % (name, m), fn(mtof(m)), 0.8, 3)
			print("m_%s_%d" % (name, m))
	write("m_heart", heart(), 0.9, 3); write("m_timpani", timpani(), 0.9, 3); write("m_tick", tick(), 0.6, 3); write("m_shaker", shaker(), 0.6, 3)
	for k, x in sfx().items():
		write("s_" + k, x, 0.8, 4); print("s_" + k)


if __name__ == "__main__":
	main()
