# Lo que el jugador dibuja en la pizarra (S-11): un grafo de anclajes unidos por trazos.
# classify() reconoce la sombra de un Cubo (8 vértices de grado 3 y 12 aristas, en cualquier perspectiva),
# un hexágono, un cuadrado, la pizarra vacía o «otra cosa».
class_name Sketch extends RefCounted

# segments: Array de Vector2i (pares de índices de anclaje). Los repetidos y los nulos no cuentan.
static func edges(segments: Array) -> Array:
	var seen := {}; var out := []
	for s in segments:
		var a: int = mini(s.x, s.y); var b: int = maxi(s.x, s.y)
		if a == b: continue
		var k := "%d-%d" % [a, b]
		if seen.has(k): continue
		seen[k] = 1; out.append(Vector2i(a, b))
	return out

static func classify(segments: Array) -> String:
	var E := edges(segments)
	if E.is_empty(): return "empty"
	var deg := {}; var adj := {}
	for e in E:
		for v in [e.x, e.y]:
			deg[v] = int(deg.get(v, 0)) + 1
			if not adj.has(v): adj[v] = []
		adj[e.x].append(e.y); adj[e.y].append(e.x)
	var V := deg.keys()
	var all_deg := func(d: int) -> bool:
		for v in V:
			if deg[v] != d: return false
		return true
	if V.size() == 8 and E.size() == 12 and all_deg.call(3) and _connected(V, adj): return "cube_shadow"
	if V.size() == 6 and E.size() == 6 and all_deg.call(2) and _connected(V, adj): return "hexagon"
	if V.size() == 4 and E.size() == 4 and all_deg.call(2) and _connected(V, adj): return "square"
	return "other"

static func _connected(V: Array, adj: Dictionary) -> bool:
	var seen := {V[0]: 1}; var st := [V[0]]
	while not st.is_empty():
		var v = st.pop_back()
		for w in adj[v]:
			if not seen.has(w): seen[w] = 1; st.append(w)
	return seen.size() == V.size()
