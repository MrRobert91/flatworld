// EL OJO, segunda pasada: la línea que ve un planilandés, con su resplandor y la «traza» de estudiante.
shader_type canvas_item;
uniform sampler2D t_data : filter_linear, repeat_disable;
uniform float u_half = 0.03; uniform float u_bg = 1.0; uniform float u_alpha = 1.0;
uniform float u_trace = 0.0; uniform float u_time = 0.0; uniform float u_strip = 0.0;
uniform vec3 bg_col = vec3(0.012, 0.027, 0.039);
void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	vec4 s = texture(t_data, vec2(uv.x, 0.5));
	float d = abs(uv.y - 0.5) / u_half;
	float core = 1.0 - smoothstep(0.55, 1.0, d);
	float glow = exp(-d * d * 0.11) * 0.34 + exp(-d * 0.45) * 0.10 * (1.0 - u_strip);
	float flick = 0.96 + 0.04 * sin(u_time * 7.0 + uv.x * 40.0);
	vec3 c = s.rgb * (core * 1.15 + glow) * flick;
	float lum = max(s.r, max(s.g, s.b));
	float base_y = 0.30; float ty = base_y + lum * 0.17;
	float tl = 1.0 - smoothstep(0.0, 0.0035, abs(uv.y - ty));
	float below = step(uv.y, 0.5 - u_half * 1.5) * (1.0 - u_strip);
	c += vec3(0.90, 0.74, 0.43) * tl * u_trace * below * (0.25 + lum) * 0.9;
	float base = 1.0 - smoothstep(0.0, 0.002, abs(uv.y - base_y));
	c += vec3(0.3, 0.4, 0.4) * base * u_trace * 0.25 * (1.0 - u_strip);
	float vig = 1.0 - smoothstep(0.3, 0.5, abs(uv.x - 0.5)) * 0.55;
	float m = max(c.r, max(c.g, c.b));
	float a = max(u_bg, min(1.0, m * 1.4));
	COLOR = vec4(mix(bg_col, c, min(1.0, m * 2.0)) * vig + c * 0.3, a * u_alpha);
}
