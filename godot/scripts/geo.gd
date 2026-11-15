# Geometría plana: puntos de las figuras y constructor de mallas (posición + color + uv).
class_name Geo

static func make_points(d: Dictionary) -> Array:
	if d.has("pts"):
		var out := []
		for p in d.pts: out.append(Vector2(p[0], p[1]) if p is Array else p)
		return out
	if d.get("woman", false):
		var L: float = d.get("r", 0.95)
		return [Vector2(L, 0), Vector2(-L, 0)]
	if d.has("iso"): # isósceles: ápice hacia +x
		var L2: float = d.get("r", 1.0) * 1.7
		var a := deg_to_rad(d.iso) / 2.0
		var hh := L2 * cos(a); var b := L2 * sin(a)
		return [Vector2(hh * 0.62, 0), Vector2(-hh * 0.38, b), Vector2(-hh * 0.38, -b)]
	var n: int = d.get("n", 4); var r: float = d.get("r", 0.75)
	var pts := []
	for i in n: pts.append(Vector2(r * cos(TAU * i / n), r * sin(TAU * i / n)))
	return pts

static func v3(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, -p.y)

class MB:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	func tri(a: Vector3, b: Vector3, d: Vector3, col: Color, u := Vector2.ZERO) -> void:
		v.append(a); v.append(b); v.append(d)
		c.append(col); c.append(col); c.append(col)
		uv.append(u); uv.append(u); uv.append(u)
	# polígono relleno (abanico desde el centroide)
	func fan(pts: Array, y: float, col: Color, u := Vector2.ZERO) -> void:
		var n := pts.size(); var cen := Vector2.ZERO
		for p in pts: cen += p / n
		for i in n: tri(Geo.v3(cen, y), Geo.v3(pts[i], y), Geo.v3(pts[(i + 1) % n], y), col, u)
	# borde interior de grosor w; colors: un color por lado (o null → base)
	func ring(pts: Array, w: float, y: float, colors, base: Color, alpha := 1.0) -> void:
		var n := pts.size(); var cen := Vector2.ZERO
		for p in pts: cen += p / n
		var inr := 1e9
		for i in n:
			var a: Vector2 = pts[i]; var b: Vector2 = pts[(i + 1) % n]
			var l := maxf(a.distance_to(b), 1e-6)
			inr = minf(inr, absf((b.x - a.x) * (a.y - cen.y) - (a.x - cen.x) * (b.y - a.y)) / l)
		var k := clampf(1.0 - w / maxf(inr, 1e-4), 0.0, 1.0)
		for i in n:
			var j := (i + 1) % n
			var a: Vector2 = pts[i]; var b: Vector2 = pts[j]
			var ai: Vector2 = cen + (a - cen) * k; var bi: Vector2 = cen + (b - cen) * k
			var col: Color = App.col(colors[i % colors.size()]) if colors else base
			col.a = alpha
			tri(Geo.v3(a, y), Geo.v3(b, y), Geo.v3(bi, y), col)
			tri(Geo.v3(a, y), Geo.v3(bi, y), Geo.v3(ai, y), col)
	# segmento grueso a→b
	func quad(a: Vector2, b: Vector2, w: float, y: float, col: Color) -> void:
		var d := b - a; var l := maxf(d.length(), 1e-6)
		var nn := Vector2(-d.y, d.x) / l * w / 2.0; var e := d / l * w / 2.0
		var A := a - e + nn; var B := b + e + nn; var C := b + e - nn; var D := a - e - nn
		tri(Geo.v3(A, y), Geo.v3(B, y), Geo.v3(C, y), col)
		tri(Geo.v3(A, y), Geo.v3(C, y), Geo.v3(D, y), col)
	func disc(cen: Vector2, r: float, y: float, col: Color, n := 12) -> void:
		for i in n:
			var a := TAU * i / n; var b := TAU * (i + 1) / n
			tri(Geo.v3(cen, y), Geo.v3(cen + Vector2(cos(a), sin(a)) * r, y), Geo.v3(cen + Vector2(cos(b), sin(b)) * r, y), col)
	func commit() -> ArrayMesh:
		var m := ArrayMesh.new()
		if v.is_empty(): return m
		var arr := []; arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v; arr[Mesh.ARRAY_COLOR] = c; arr[Mesh.ARRAY_TEX_UV] = uv
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		return m
