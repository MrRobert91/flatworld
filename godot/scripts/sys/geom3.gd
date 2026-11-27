# Geometría de secciones (S-12). Sin dependencias y estática, para poder probarla sin interfaz.
# Parte 2D (M3): la sección de un polígono del Plano por la Recta y = 0 (Linealandia) y la de una
# esfera por el Plano. Los poliedros, sus secciones y sus sombras llegan con el VIII (M4).
class_name Geom3 extends RefCounted

# Sección de un polígono (puntos del Plano, en orden) por la Recta y = 0: Vector2(x_min, x_max).
# Si no la corta, x_min > x_max (Vector2(INF, -INF)). Un vértice que toca la Recta cuenta.
static func line_section(pts: Array) -> Vector2:
	var lo := INF; var hi := -INF
	var n := pts.size()
	for i in n:
		var a: Vector2 = pts[i]; var b: Vector2 = pts[(i + 1) % n]
		if absf(a.y) < 1e-6: lo = minf(lo, a.x); hi = maxf(hi, a.x)
		if (a.y > 0.0) != (b.y > 0.0) and absf(a.y - b.y) > 1e-9:
			var x := a.x + (b.x - a.x) * (-a.y / (b.y - a.y))
			lo = minf(lo, x); hi = maxf(hi, x)
	return Vector2(lo, hi)

# largo de esa sección (0 si no corta)
static func line_len(pts: Array) -> float:
	var s := line_section(pts)
	return maxf(0.0, s.y - s.x)

# Sección de una esfera de radio R con el centro a altura h sobre el Plano: radio del círculo (0 si no corta)
static func sphere_section(R: float, h: float) -> float:
	return sqrt(R * R - h * h) if absf(h) < R else 0.0

# ---------- Poliedros (M4): {verts: PackedVector3Array, edges: Array[Vector2i]} en coordenadas locales ----------
# El eje y es la Altura: el Plano es y = 0 y sus coordenadas son (x, -z).
static func cube(l := 1.0) -> Dictionary:
	var h := l / 2.0; var V := PackedVector3Array(); var E := []
	for i in 8: V.append(Vector3(h if i & 1 else -h, h if i & 2 else -h, h if i & 4 else -h))
	for i in 8:
		for b in 3:
			if not (i & (1 << b)): E.append(Vector2i(i, i | (1 << b)))
	return {verts = V, edges = E}

# pirámide de base cuadrada (lado l) y altura h, con la base centrada en y = -h/2
static func pyramid(l := 1.0, h := 1.2) -> Dictionary:
	var a := l / 2.0
	var V := PackedVector3Array([Vector3(-a, -h / 2, -a), Vector3(a, -h / 2, -a), Vector3(a, -h / 2, a), Vector3(-a, -h / 2, a), Vector3(0, h / 2, 0)])
	return {verts = V, edges = [Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 0), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]}

# prisma de n lados (un cilindro, con n = 24), de eje vertical
static func prism_n(n: int, r := 0.8, h := 1.6) -> Dictionary:
	var V := PackedVector3Array(); var E := []
	for k in 2:
		for i in n: V.append(Vector3(r * cos(TAU * i / n), (k - 0.5) * h, r * sin(TAU * i / n)))
	for i in n:
		E.append(Vector2i(i, (i + 1) % n)); E.append(Vector2i(n + i, n + (i + 1) % n)); E.append(Vector2i(i, n + i))
	return {verts = V, edges = E}

# cono de n lados, con el vértice arriba
static func cone_n(n: int, r := 0.8, h := 1.6) -> Dictionary:
	var V := PackedVector3Array(); var E := []
	for i in n: V.append(Vector3(r * cos(TAU * i / n), -h / 2, r * sin(TAU * i / n)))
	V.append(Vector3(0, h / 2, 0))
	for i in n: E.append(Vector2i(i, (i + 1) % n)); E.append(Vector2i(i, n))
	return {verts = V, edges = E}

static func _to_plane(v: Vector3) -> Vector2:
	return Vector2(v.x, -v.z)

# Sección por el Plano (y = 0) de un poliedro convexo transformado: polígono convexo en coordenadas del
# Plano, ordenado en sentido antihorario, o vacío si no corta.
static func section(poly: Dictionary, xf: Transform3D) -> PackedVector2Array:
	var W := PackedVector3Array()
	for v in poly.verts: W.append(xf * v)
	var pts: Array = []
	var add := func(p: Vector2):
		for q in pts:
			if (q as Vector2).distance_to(p) < 1e-4: return
		pts.append(p)
	for v in W:
		if absf(v.y) < 1e-4: add.call(_to_plane(v))
	for e in poly.edges:
		var a: Vector3 = W[e.x]; var b: Vector3 = W[e.y]
		if a.y * b.y < 0.0:
			add.call(_to_plane(a + (b - a) * (a.y / (a.y - b.y))))
	if pts.size() < 3: return PackedVector2Array()
	var c := Vector2.ZERO
	for p in pts: c += p
	c /= pts.size()
	pts.sort_custom(func(p, q): return (p - c).angle() < (q - c).angle())
	return PackedVector2Array(pts)

static func area(pts: PackedVector2Array) -> float:
	var s := 0.0
	for i in pts.size(): s += pts[i].cross(pts[(i + 1) % pts.size()])
	return absf(s) / 2.0

# Sombra sobre el Plano: cada arista proyectada desde una luz puntual (light.w = 1, en light.xyz) o
# direccional (light.w = 0, dirección light.xyz). [[Vector2, Vector2], ...]
static func shadow(poly: Dictionary, xf: Transform3D, light: Vector4) -> Array:
	var L := Vector3(light.x, light.y, light.z)
	var proj := func(v: Vector3) -> Vector2:
		var d: Vector3 = (v - L) if light.w > 0.5 else L
		if absf(d.y) < 1e-6: return _to_plane(v)
		var t := -v.y / d.y
		return _to_plane(v + d * t)
	var out := []
	for e in poly.edges:
		out.append([proj.call(xf * poly.verts[e.x]), proj.call(xf * poly.verts[e.y])])
	return out
