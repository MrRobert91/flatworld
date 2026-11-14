// EL OJO, primera pasada: trazado de rayos 2D en la GPU. Cada columna de píxeles es un rayo
// lanzado dentro del plano contra los segmentos del mundo (textura de datos, relativa al ojo).
shader_type canvas_item;
render_mode unshaded, blend_disabled;
uniform sampler2D segs : filter_nearest, repeat_disable;
uniform int count = 0;
uniform float fog = 13.0;
uniform float ambient = 0.035;
uniform float fov_tan = 1.2;
uniform vec2 facing = vec2(1.0, 0.0);
void fragment() {
	float u = 1.0 - 2.0 * UV.x;
	vec2 l = normalize(vec2(1.0, -u * fov_tan));
	vec2 d = vec2(l.x * facing.x + l.y * facing.y, l.x * facing.y - l.y * facing.x);
	float bt = 1.0e9; int best = -1;
	for (int k = 0; k < count; k++) {
		vec4 s = texelFetch(segs, ivec2(k, 0), 0);
		vec2 e = s.zw - s.xy;
		float den = d.x * e.y - d.y * e.x;
		if (abs(den) < 1.0e-9) continue;
		float t = (s.x * e.y - s.y * e.x) / den;
		if (t < 0.02 || t >= bt) continue;
		float v = (s.x * d.y - s.y * d.x) / den;
		if (v < 0.0 || v > 1.0) continue;
		bt = t; best = k;
	}
	vec3 c = vec3(110.0, 150.0, 150.0) / 255.0 * ambient;
	if (best >= 0) {
		vec4 m = texelFetch(segs, ivec2(best, 1), 0);
		c = ambient * vec3(0.5, 0.6, 0.6) + m.rgb * exp(-bt / fog) * m.a;
	}
	COLOR = vec4(min(c, vec3(1.0)), 1.0);
}
