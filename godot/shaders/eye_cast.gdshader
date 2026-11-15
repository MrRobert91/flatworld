// EL OJO, primera pasada: trazado de rayos 2D en la GPU. Cada columna de píxeles es un rayo lanzado
// dentro del plano contra los segmentos del mundo (textura de datos, relativa al ojo).
// Fila superior: color de la tinta. Fila inferior: r = claridad, g = identidad del lado, b = distancia.
//
// La claridad sigue al libro: la niebla apaga lo lejano. Aquí se exagera dentro de cada figura (el lado
// que se aleja del punto más cercano se apaga deprisa) y se añade un sombreado leve según la inclinación
// del lado respecto a la mirada, para que los ángulos se puedan leer.
shader_type canvas_item;
render_mode unshaded, blend_disabled;
uniform sampler2D segs : filter_nearest, repeat_disable;
uniform int count = 0;
uniform float fog = 13.0;
uniform float fov_tan = 1.2;
uniform float reach = 70.0;
uniform vec2 facing = vec2(1.0, 0.0);
void fragment() {
	float u = 1.0 - 2.0 * UV.x;
	vec2 l = normalize(vec2(1.0, -u * fov_tan));
	vec2 d = vec2(l.x * facing.x + l.y * facing.y, l.x * facing.y - l.y * facing.x);
	float bt = 1.0e9; int best = -1; float inc = 1.0;
	for (int k = 0; k < count; k++) {
		vec4 s = texelFetch(segs, ivec2(k, 0), 0);
		vec2 e = s.zw - s.xy;
		float den = d.x * e.y - d.y * e.x;
		if (abs(den) < 1.0e-9) continue;
		float t = (s.x * e.y - s.y * e.x) / den;
		if (t < 0.02 || t >= bt) continue;
		float v = (s.x * d.y - s.y * d.x) / den;
		if (v < 0.0 || v > 1.0) continue;
		bt = t; best = k; inc = abs(den) / max(length(e), 1.0e-6);
	}
	vec3 c = vec3(0.0); vec3 info = vec3(0.0, 0.0, 1.0);
	if (best >= 0) {
		vec4 m = texelFetch(segs, ivec2(best, 1), 0);
		vec4 x = texelFetch(segs, ivec2(best, 2), 0);   // x: distancia mínima de la figura, y: 0 muro / 1 figura
		float k_loc = mix(0.14, 1.1, x.y);
		float local = exp(-max(bt - x.x, 0.0) * k_loc);
		float shade = mix(0.62, 1.0, pow(clamp(inc, 0.0, 1.0), 0.7));
		float I = pow(exp(-bt / fog), 0.45) * mix(1.0, local, mix(0.7, 0.72, x.y)) * shade * mix(0.8, 1.0, x.y) * clamp(m.a + 0.25, 0.0, 1.0);
		c = m.rgb;
		float id = (float(best % 100) + 0.5) / 200.0 + 0.5 * x.y;
		info = vec3(clamp(I, 0.0, 1.0), id, clamp(bt / reach, 0.0, 1.0));
	}
	COLOR = vec4(UV.y < 0.5 ? c : info, 1.0);
}
