// Todo lo plano: figuras, muros, marcas. Un solo material por capa (una llamada de dibujo por figura).
// COLOR = color «de pantalla» + alfa.  UV.x > 0 → relleno rayado (UV.x = densidad, UV.y = fuerza).
// UV.x < 0 → banda de patrón (C4-07): el rayado propio del tono de COLOR, sin fondo (UV.y = densidad).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
#include "res://shaders/pattern.gdshaderinc"
uniform vec3 fill_col = vec3(0.016, 0.031, 0.039);
uniform float alpha_mul = 1.0;
uniform vec3 tint = vec3(1.0);
varying vec2 vp;
void vertex() { vp = VERTEX.xz; }
void fragment() {
	vec3 c = COLOR.rgb;
	float a = COLOR.a * alpha_mul;
	if (UV.x < -0.5) {
		a *= pat_mask(vp * UV.y, pat_index(pat_hue(c))) * 0.9;
	} else if (UV.x > 0.0) {
		float v = (vp.x + vp.y) * UV.x;
		float l = abs(fract(v) - 0.5);
		float w = fwidth(v);
		float h = 1.0 - smoothstep(0.10 - w, 0.10 + w, l);
		c = mix(fill_col, COLOR.rgb, h * UV.y);
	}
	ALBEDO = max(c * tint, vec3(0.0));
	ALPHA = a;
}
