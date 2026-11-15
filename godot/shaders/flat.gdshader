// Todo lo plano: figuras, muros, marcas. Un solo material por capa (una llamada de dibujo por figura).
// COLOR = color «de pantalla» + alfa.  UV.x > 0 → relleno rayado (UV.x = densidad, UV.y = fuerza).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform vec3 fill_col = vec3(0.016, 0.031, 0.039);
uniform float alpha_mul = 1.0;
uniform vec3 tint = vec3(1.0);
varying vec2 vp;
void vertex() { vp = VERTEX.xz; }
void fragment() {
	vec3 c = COLOR.rgb;
	if (UV.x > 0.0) {
		float v = (vp.x + vp.y) * UV.x;
		float l = abs(fract(v) - 0.5);
		float w = fwidth(v);
		float h = 1.0 - smoothstep(0.10 - w, 0.10 + w, l);
		c = mix(fill_col, COLOR.rgb, h * UV.y);
	}
	ALBEDO = max(c * tint, vec3(0.0));
	ALPHA = COLOR.a * alpha_mul;
}
