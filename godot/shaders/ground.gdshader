// El suelo de Planilandia: una lámina de papel milimetrado. Fibra y manchas del papel, cuadrícula fina
// y maestra y el marco de la lámina en los confines.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform vec3 u_a; uniform vec3 u_b; uniform vec3 u_line; uniform vec3 u_fog; uniform vec3 u_bg; uniform vec3 u_ink;
uniform float u_rain = 0.0; uniform float u_fade = 0.0; uniform vec4 u_bounds = vec4(-10.0, -10.0, 10.0, 10.0);
varying vec2 vw;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p) { float a = 0.5, s = 0.0; for (int i = 0; i < 4; i++) { s += a * n(p); p *= 2.1; a *= 0.5; } return s; }
void vertex() { vec4 w = MODEL_MATRIX * vec4(VERTEX, 1.0); vw = vec2(w.x, -w.z); }
// línea de anchura constante en pantalla sobre una coordenada del mundo
float rule(float v, float px) { float w = fwidth(v) * px; return 1.0 - smoothstep(w * 0.5, w * 1.5, abs(v)); }
void fragment() {
	// papel: nubes suaves, fibra alargada y grano
	float f = fbm(vw * 0.09);
	vec3 c = mix(u_a, u_b, f);
	float fib = n(vec2(vw.x * 1.3, vw.y * 14.0)) * 0.6 + n(vec2(vw.x * 17.0, vw.y * 2.1)) * 0.4;
	c *= 0.975 + 0.05 * fib;
	c *= 0.985 + 0.03 * h(floor(vw * 34.0));
	// cuadrícula: fina cada unidad, maestra cada cinco; se desvanece si se aleja la cámara
	float d = min(min(vw.x - u_bounds.x, u_bounds.z - vw.x), min(vw.y - u_bounds.y, u_bounds.w - vw.y));
	float inside = smoothstep(-0.02, 0.02, d);
	vec2 g1 = abs(fract(vw + 0.5) - 0.5);
	vec2 g5 = abs(fract(vw / 5.0 + 0.5) - 0.5) * 5.0;
	float fine = max(rule(g1.x, 1.0), rule(g1.y, 1.0)) * (1.0 - smoothstep(0.035, 0.11, fwidth(vw.x)));
	float major = max(rule(g5.x, 1.4), rule(g5.y, 1.4));
	c = mix(c, u_line, (fine * 0.20 + major * 0.42) * inside);
	// el margen de la lámina: papel sin cuadrícula, un filete grueso y otro fino
	c = mix(mix(u_fog, c, 0.35), c, inside);
	float w = fwidth(d);
	float frame = 1.0 - smoothstep(0.09, 0.09 + w, abs(d + 0.12));
	float frame2 = 1.0 - smoothstep(0.02, 0.02 + w, abs(d + 0.75));
	c = mix(c, u_ink, max(frame * 0.9, frame2 * 0.6));
	c = mix(c, u_bg, u_fade);
	ALBEDO = max(c, vec3(0.0));
	ALPHA = 1.0;
}
