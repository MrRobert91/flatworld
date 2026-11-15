// Grano de papel sobre toda la imagen (multiplica): fibra, mota y bordes algo más oscuros.
shader_type canvas_item;
render_mode blend_mul, unshaded;
uniform float u_str = 1.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y); }
void fragment() {
	vec2 p = FRAGCOORD.xy;
	float g = n(p * 0.55) * 0.45 + n(vec2(p.x * 0.05, p.y * 0.8)) * 0.3 + h(floor(p * 0.5)) * 0.25;
	vec2 q = UV - 0.5;
	float v = 1.0 - smoothstep(0.42, 0.78, length(q * vec2(1.0, 1.15))) * 0.20;
	float k = (0.94 + 0.085 * g) * v;
	COLOR = vec4(vec3(mix(1.0, k, u_str)), 1.0);
}
