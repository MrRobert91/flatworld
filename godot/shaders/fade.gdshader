// Fundido de papel: la hoja nueva «empapa» la pantalla desde manchas de tinta, con un filete oscuro
// en el borde que avanza. COLOR.a es el progreso (0 = transparente, 1 = cubierto).
shader_type canvas_item;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p) { float a = 0.5, s = 0.0; for (int i = 0; i < 5; i++) { s += a * n(p); p *= 2.03; a *= 0.5; } return s; }
void fragment() {
	float k = COLOR.a;
	vec2 p = FRAGCOORD.xy / 90.0;
	// manchas que crecen desde el centro y desde la fibra del papel
	float field = fbm(p) * 0.75 + (1.0 - length(UV - 0.5) * 1.1) * 0.35;
	float thr = 0.97 - k * 0.9;
	float edge = 0.045;
	float cover = smoothstep(thr - edge, thr + edge * 0.3, field);
	float rim = smoothstep(thr - edge * 2.5, thr - edge, field) * (1.0 - cover);
	vec3 paper = COLOR.rgb * (0.97 + 0.05 * n(FRAGCOORD.xy * 0.6));
	vec3 ink = vec3(0.09, 0.13, 0.17);
	float a = max(cover, rim * 0.55);
	if (k >= 0.999) { a = 1.0; }
	if (k <= 0.001) { a = 0.0; }
	COLOR = vec4(mix(ink, paper, cover), a);
}
