// La Esfera: irisación de borde y un enojo que la enrojece.
shader_type spatial;
render_mode unshaded;
uniform float anger = 0.0;
void fragment() {
	vec3 n = normalize(NORMAL);
	float f = pow(1.0 - max(dot(n, normalize(VIEW)), 0.0), 2.2);
	float d = 0.5 + 0.5 * dot(n, normalize(vec3(0.35, 0.85, 0.4)));
	vec3 base = mix(vec3(0.06, 0.2, 0.24), vec3(0.7, 1.0, 0.95), d * d);
	base += 0.22 * cos(6.283 * (f * 1.4 + d * 0.6 + vec3(0.0, 0.33, 0.67)) + TIME * 0.4) * f * 1.6;
	base += f * 0.5;
	base = mix(base, vec3(0.9, 0.2, 0.12) * (0.3 + d), anger);
	ALBEDO = max(base, vec3(0.0));
}
