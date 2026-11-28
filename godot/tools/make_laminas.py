#!/usr/bin/env python3
"""Genera data/laminas.json (S-16): las láminas que se trazan a pluma al empezar cada bloque.

Cada lámina: {dur, caption, strokes: [{t0, t1, w, pts, col?}], labels: [{t, x, y, text, s?}]}.
Coordenadas en el lienzo de la pizarra (640×420). t0 y t1 son fracciones de la duración.
Las figuras siguen los grabados de la edición de 1884 (dominio público), simplificadas.
"""
import json, math, os

RED = "a8392a"; GREEN = "3a7a4a"

def ngon(cx, cy, r, n, a0=0.0, close=True):
    pts = [[round(cx + r * math.cos(a0 + 2 * math.pi * i / n), 1), round(cy - r * math.sin(a0 + 2 * math.pi * i / n), 1)] for i in range(n)]
    return pts + [pts[0]] if close else pts

def S(t0, t1, pts, w=2.0, col=None):
    d = {"t0": t0, "t1": t1, "w": w, "pts": pts}
    if col: d["col"] = col
    return d

def L(t, x, y, text, s=18):
    return {"t": t, "x": x, "y": y, "text": text, "s": s}

lam = {}
# Prólogo: la moneda, desde arriba y de canto
lam["lam_0"] = {"dur": 7.0, "caption": "Una moneda sobre la mesa: desde arriba, un círculo; desde el borde de la mesa, una raya.",
    "strokes": [S(0.0, 0.35, ngon(190, 190, 90, 40)), S(0.35, 0.45, ngon(190, 190, 70, 40), 1.0),
                S(0.5, 0.75, [[360, 190], [560, 190]], 3.0), S(0.75, 0.8, [[360, 180], [360, 200]], 1.0), S(0.8, 0.85, [[560, 180], [560, 200]], 1.0)],
    "labels": [L(0.4, 140, 320, "desde arriba"), L(0.85, 410, 240, "de canto")]}
# I: la casa pentagonal con sus dos puertas
house = ngon(320, 205, 150, 5, math.pi / 2)
lam["lam_1"] = {"dur": 8.0, "caption": "La casa de cinco lados: la puerta grande, al Oeste, para los varones; la pequeña, al Este, para las mujeres.",
    "strokes": [S(0.0, 0.5, house), S(0.55, 0.65, [[215, 300], [245, 325]], 5.0, RED), S(0.65, 0.72, [[405, 305], [420, 293]], 5.0, RED),
                S(0.72, 0.8, [[320, 85], [320, 60]], 1.0), S(0.8, 0.85, [[312, 70], [320, 58], [328, 70]], 1.0)],
    "labels": [L(0.6, 90, 340, "varones"), L(0.7, 450, 340, "mujeres"), L(0.85, 300, 45, "Norte", 16)]}
# II: la escala de las clases
xs = [60, 140, 220, 300, 380, 460, 550]
cls = [S(0.0, 0.1, [[40, 220], [80, 220]], 2.5)]
iso = [[140, 175], [128, 260], [152, 260], [140, 175]]
cls.append(S(0.1, 0.22, iso))
cls.append(S(0.22, 0.34, ngon(220, 225, 38, 3, math.pi / 2)))
cls.append(S(0.34, 0.46, ngon(300, 225, 36, 4, math.pi / 4)))
cls.append(S(0.46, 0.58, ngon(380, 225, 36, 5, math.pi / 2)))
cls.append(S(0.58, 0.7, ngon(460, 225, 36, 6)))
cls.append(S(0.7, 0.85, ngon(550, 225, 38, 36)))
lam["lam_2"] = {"dur": 8.0, "caption": "De la Mujer al Círculo: cada generación, un lado más.",
    "strokes": cls, "labels": [L(0.1, 30, 300, "Mujer", 15), L(0.22, 105, 300, "Isósceles", 15), L(0.34, 185, 300, "Equilátero", 15), L(0.46, 270, 300, "Cuadrado", 15),
        L(0.58, 345, 300, "Pentágono", 15), L(0.7, 425, 300, "Hexágono", 15), L(0.85, 520, 300, "Círculo", 15)]}
# III: un ángulo en la niebla
fog = []
for k in range(6):
    a = 0.12 + k * 0.12
    fog.append(S(a, a + 0.1, [[320 - 30 * k, 120 + 30 * k], [320 - 30 * (k + 1), 120 + 30 * (k + 1)]], 3.0 - 0.45 * k))
    fog.append(S(a, a + 0.1, [[320 + 45 * k, 120 + 20 * k], [320 + 45 * (k + 1), 120 + 20 * (k + 1)]], 3.0 - 0.45 * k))
fog.append(S(0.0, 0.1, ngon(320, 120, 6, 16), 2.0, RED))
lam["lam_3"] = {"dur": 8.0, "caption": "En la niebla, los lados se apagan al alejarse. Por lo deprisa que se apagan se conoce el ángulo.",
    "strokes": fog, "labels": [L(0.85, 230, 360, "más cerca, más tinta")]}
# IV: una mujer mitad roja, mitad verde, y un Sacerdote igual
circ = ngon(400, 210, 90, 40, close=False)
lam["lam_4"] = {"dur": 7.5, "caption": "Mitad roja, mitad verde: vistas de canto, una Mujer y un Sacerdote son la misma raya.",
    "strokes": [S(0.0, 0.2, [[80, 210], [170, 210]], 4.0, RED), S(0.2, 0.4, [[170, 210], [260, 210]], 4.0, GREEN),
                S(0.4, 0.62, circ[:21], 3.0, RED), S(0.62, 0.84, circ[20:] + [circ[0]], 3.0, GREEN)],
    "labels": [L(0.4, 120, 260, "Mujer"), L(0.85, 360, 330, "Sacerdote")]}
# V: el Templo y sus filas
tem = [S(0.0, 0.35, ngon(320, 205, 170, 24))]
for r, y in enumerate([150, 190, 230, 270]):
    for i in range(5):
        x = 230 + i * 45
        tem.append(S(0.35 + r * 0.12 + i * 0.02, 0.4 + r * 0.12 + i * 0.02, ngon(x, y, 12, 4 + r, math.pi / 2), 1.2))
lam["lam_5"] = {"dur": 8.0, "caption": "El Templo: los Círculos delante, y detrás, por filas, cada cual según sus lados.",
    "strokes": tem, "labels": []}
# VI: Linealandia
ll = [S(0.0, 0.25, [[30, 210], [610, 210]], 1.0)]
pos = [(90, 30), (150, 0), (200, 45), (270, 0), (330, 80), (420, 0), (470, 35), (530, 0)]
for i, (x, h) in enumerate(pos):
    if h == 0: ll.append(S(0.25 + i * 0.07, 0.3 + i * 0.07, ngon(x, 210, 4, 10), 3.0))
    else: ll.append(S(0.25 + i * 0.07, 0.3 + i * 0.07, [[x - h, 210], [x + h, 210]], 4.0))
lam["lam_6"] = {"dur": 7.5, "caption": "Linealandia: Líneas y Puntos en una sola Recta. Nadie puede adelantar a nadie.",
    "strokes": ll, "labels": [L(0.85, 300, 180, "el Rey", 15)]}
# VII: la Esfera atraviesa el Plano
sp = [S(0.0, 0.3, ngon(170, 210, 120, 40)), S(0.3, 0.38, [[40, 150], [300, 150]], 1.0), S(0.38, 0.46, [[40, 210], [300, 210]], 1.0), S(0.46, 0.54, [[40, 270], [300, 270]], 1.0)]
for i, (y, r) in enumerate([(130, 30), (210, 70), (290, 30)]):
    sp.append(S(0.6 + i * 0.12, 0.7 + i * 0.12, ngon(470, y, r, 30), 2.0, RED))
lam["lam_7"] = {"dur": 8.0, "caption": "Una Esfera que atraviesa el Plano: un punto, un círculo que crece, que mengua, un punto.",
    "strokes": sp, "labels": []}
# VIII: Punto → Línea → Cuadrado → Cubo
cub = [S(0.0, 0.06, ngon(70, 230, 4, 10), 4.0), S(0.1, 0.25, [[130, 230], [210, 230]]),
       S(0.3, 0.5, [[260, 260], [340, 260], [340, 180], [260, 180], [260, 260]]),
       S(0.55, 0.7, [[400, 270], [480, 270], [480, 190], [400, 190], [400, 270]]),
       S(0.7, 0.85, [[440, 230], [520, 230], [520, 150], [440, 150], [440, 230]], 1.4),
       S(0.85, 0.95, [[400, 270], [440, 230]], 1.4), S(0.86, 0.96, [[480, 270], [520, 230]], 1.4), S(0.87, 0.97, [[480, 190], [520, 150]], 1.4), S(0.88, 0.98, [[400, 190], [440, 150]], 1.4)]
lam["lam_8"] = {"dur": 8.5, "caption": "Un Punto que se mueve engendra una Línea; la Línea, un Cuadrado; el Cuadrado, hacia Arriba, un Cubo.",
    "strokes": cub, "labels": [L(0.06, 52, 300, "1", 20), L(0.25, 165, 300, "2", 20), L(0.5, 295, 300, "4", 20), L(0.98, 455, 300, "8", 20)]}
# IX: un punto solo
lam["lam_9"] = {"dur": 6.0, "caption": "Puntolandia: el Abismo de Ninguna Dimensión. Ello es; y nada hay fuera de Ello.",
    "strokes": [S(0.2, 0.5, ngon(320, 210, 5, 16), 4.0)], "labels": []}
# X: el dibujo del Cubo que el Consejo no entiende
lam["lam_10"] = {"dur": 7.5, "caption": "«Un Cuadrado montado sobre otro y cuatro rayas que los cosen. Una figura Irregular de muchos lados.»",
    "strokes": [S(0.0, 0.3, [[220, 290], [370, 290], [370, 140], [220, 140], [220, 290]]),
                S(0.3, 0.6, [[290, 230], [440, 230], [440, 80], [290, 80], [290, 230]]),
                S(0.6, 0.68, [[220, 290], [290, 230]]), S(0.68, 0.76, [[370, 290], [440, 230]]), S(0.76, 0.84, [[370, 140], [440, 80]]), S(0.84, 0.92, [[220, 140], [290, 80]])],
    "labels": []}

out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "laminas.json")
with open(out, "w") as f: json.dump(lam, f, ensure_ascii=False, indent=1)
print(len(lam), "láminas →", out)
