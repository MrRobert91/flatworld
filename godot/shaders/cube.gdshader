// El Cubo: caras sombreadas (luz y sombra delatan la profundidad) y aristas doradas trazadas por UV.
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 col = vec3(0.925, 0.898, 0.816);
uniform vec3 edge_col = vec3(0.902, 0.741, 0.431);
uniform float dim = 1.0;
varying vec3 wn;
void vertex() { wn = normalize(mat3(MODEL_MATRIX) * NORMAL); }
void fragment() {
	float d = 0.25 + 0.75 * max(0.0, dot(normalize(wn), normalize(vec3(0.4, 0.8, 0.45))));
	vec2 e = min(UV, 1.0 - UV);
	vec2 w = fwidth(UV) * 1.6 + 0.004;
	float l = 1.0 - min(smoothstep(0.0, w.x, e.x), smoothstep(0.0, w.y, e.y));
	vec3 c = mix(col * d * dim, edge_col, l);
	ALBEDO = max(c, vec3(0.0));
}
