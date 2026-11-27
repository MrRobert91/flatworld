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
