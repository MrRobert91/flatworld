// El suelo de Planilandia: papel grabado a buril, cuadrícula, lluvia del Norte y niebla en los confines.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform vec3 u_a; uniform vec3 u_b; uniform vec3 u_line; uniform vec3 u_fog; uniform vec3 u_bg;
uniform float u_rain = 0.0; uniform float u_fade = 0.0; uniform vec4 u_bounds = vec4(-10.0, -10.0, 10.0, 10.0);
varying vec2 vw;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p) { float a = 0.5, s = 0.0; for (int i = 0; i < 4; i++) { s += a * n(p); p *= 2.1; a *= 0.5; } return s; }
void vertex() { vec4 w = MODEL_MATRIX * vec4(VERTEX, 1.0); vw = vec2(w.x, -w.z); }
void fragment() {
	float f = fbm(vw * 0.11 + vec2(TIME * 0.012, 0.0));
	vec3 c = mix(u_a, u_b, f);
	c += (h(floor(vw * 38.0)) - 0.5) * 0.016;
	float st = abs(fract(vw.y * 2.2 + f * 1.5) - 0.5);
	c += u_line * (1.0 - smoothstep(0.0, 0.07, st)) * 0.022;
	vec2 g = abs(fract(vw / 6.0) - 0.5) * 6.0;
	float w = fwidth(vw.x) * 1.3;
	float l = 1.0 - smoothstep(0.0, w + 0.015, min(g.x, g.y));
	c = mix(c, u_line, l * 0.11);
	float rx = floor(vw.x * 2.6);
	float ry = fract(vw.y * 0.09 + TIME * 0.55 + h(vec2(rx, 1.0)));
	float fx = fract(vw.x * 2.6);
	c += u_line * smoothstep(0.86, 1.0, ry) * step(0.6, h(vec2(rx, 7.0))) * smoothstep(0.0, 0.08, fx) * smoothstep(0.22, 0.12, fx) * u_rain * 0.5;
	float d = min(min(vw.x - u_bounds.x, u_bounds.z - vw.x), min(vw.y - u_bounds.y, u_bounds.w - vw.y));
	float fog = 1.0 - smoothstep(-3.0, 12.0, d + fbm(vw * 0.2 + TIME * 0.03) * 6.0);
	c = mix(c, u_fog, fog * 0.85);
	c = mix(c, u_bg, u_fade);
	ALBEDO = max(c, vec3(0.0));
	ALPHA = 1.0;
}
