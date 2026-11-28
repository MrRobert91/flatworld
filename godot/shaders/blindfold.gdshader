// Venda: oscurece la pantalla salvo un círculo en el centro (palpar con los ojos cerrados, C1-03).
shader_type canvas_item;
uniform float radius = 0.14;
uniform float alpha = 1.0;
uniform float aspect = 1.7778;
void fragment() {
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	float m = smoothstep(radius, radius * 1.9, length(p));
	COLOR = vec4(0.055, 0.065, 0.075, alpha * m);
}
