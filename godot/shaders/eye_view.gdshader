// EL OJO, segunda pasada: la línea que ve un planilandés, dibujada a tinta sobre el papel.
// Más tinta = más cerca. Los vértices dejan una marca leve; los muros llevan un rayado fino;
// debajo, una regla graduada en grados y, cuando se ha aprendido, el perfil de claridad.
shader_type canvas_item;
#include "res://shaders/pattern.gdshaderinc"
uniform sampler2D t_data : filter_linear, repeat_disable;
uniform float u_half = 0.03; uniform float u_bg = 1.0; uniform float u_alpha = 1.0;
uniform float u_trace = 0.0; uniform float u_time = 0.0; uniform float u_strip = 0.0;
uniform float u_flip = 0.0; uniform float u_dark = 0.0; uniform float fov_tan = 1.2; uniform float u_px = 1.0;
uniform float u_patterns = 1.0;   // rayado por tono en la línea (C4-07)
uniform float u_desat = 0.0;      // la línea en gris (C4-03: lo que se ganó con el Color)
// lentes (S-06): la línea se encoge hacia el centro (u_squeeze 0→1) hasta ser un punto (el ojo del Rey);
// el punto crece (u_grow 0→1) hasta llenar la pantalla con el color medio (el ojo del Punto)
uniform float u_squeeze = 0.0; uniform float u_grow = 0.0; uniform vec2 u_size = vec2(1280.0, 720.0);
uniform float u_hue = 0.0;        // el Punto «piensa»: cada entrada del jugador gira un poco el tono (C9-01)
vec3 hue_rot(vec3 c, float a) {
	const vec3 k = vec3(0.57735);
	float ca = cos(a);
	return c * ca + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - ca);
}
uniform vec3 bg_col = vec3(0.925, 0.894, 0.812);
uniform vec3 ink_col = vec3(0.09, 0.13, 0.17);
uniform vec3 acc_col = vec3(0.66, 0.22, 0.16);
vec3 info_at(float x, float ry) { return texture(t_data, vec2(x, ry)).rgb; }
void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	float rc = mix(0.25, 0.75, u_flip); float ri = 1.0 - rc;
	float sx = max(1.0 - u_squeeze, 0.004);
	float inside = step(abs(uv.x - 0.5), sx * 0.5) * (1.0 - smoothstep(0.85, 1.0, u_squeeze));
	float ux = 0.5 + (uv.x - 0.5) / sx;
	vec3 col = texture(t_data, vec2(ux, rc)).rgb;
	float sat0 = pat_sat(col);
	int pk = pat_index(pat_hue(col));
	col = mix(col, vec3(dot(col, vec3(0.3, 0.59, 0.11))), u_desat);
	vec3 inf = info_at(ux, ri);
	float tx = 1.0 / 1024.0;
	vec3 a = info_at(ux - tx * 1.6, ri); vec3 b = info_at(ux + tx * 1.6, ri);
	float I = inf.r * inside;
	float hit = step(0.004, max(a.r, b.r));
	float id_jump = step(0.004, abs(a.g - b.g));
	float dz = abs(a.b - b.b);
	float crease = id_jump * (1.0 - smoothstep(0.004, 0.02, dz)) * hit;      // vértice: dos lados que se tocan
	float sil = id_jump * smoothstep(0.006, 0.03, dz) * hit;                 // contorno: una figura delante de otra
	float wall = 1.0 - step(0.5, inf.g);
	float d = abs(uv.y - 0.5) / u_half;
	float aa = fwidth(d) * 1.2;
	float core = 1.0 - smoothstep(1.0 - aa, 1.0, d);
	// tinta: nunca del todo invisible si hay algo; curva suave para separar los grises
	float ink = I > 0.003 ? 0.18 + 0.82 * pow(I, 0.8) : 0.0;
	float hatch = step(0.5, fract((FRAGCOORD.x + FRAGCOORD.y) / (5.0 * u_px)));
	ink *= mix(1.0, mix(0.80, 1.0, hatch), wall * (1.0 - u_strip));
	ink = mix(ink, min(1.0, ink * 1.25 + 0.16), crease * 0.8);
	ink *= 1.0 - sil * 0.85;
	vec3 c = mix(bg_col, col, ink * core);
	// cada tono, con su rayado: el color nunca es la única pista
	float pm = pat_mask(FRAGCOORD.xy / (4.0 * u_px), pk) * step(0.3, sat0) * (1.0 - u_desat) * u_patterns;
	c = mix(c, c * 0.45, pm * 0.6 * ink * core);
	// la línea del horizonte, apenas un trazo de lápiz
	float hl = 1.0 - smoothstep(0.0, fwidth(uv.y) * 1.2, abs(uv.y - 0.5));
	c = mix(c, ink_col, hl * 0.16 * (1.0 - ink * core) * (1.0 - u_squeeze));
	// marca de vértice: asoma un poco fuera de la línea
	float tick = crease * (1.0 - smoothstep(1.45, 1.55, d)) * (1.0 - core) * (1.0 - u_strip);
	c = mix(c, ink_col, tick * 0.42);
	// regla graduada (cada 5°, más larga cada 15°)
	float full = (1.0 - u_strip) * (1.0 - u_squeeze);
	float ang = degrees(atan((1.0 - 2.0 * uv.x) * fov_tan));
	float w5 = fwidth(ang);
	float t5 = 1.0 - smoothstep(0.0, w5 * 1.2, abs(fract(ang / 5.0 + 0.5) - 0.5) * 5.0);
	float t15 = 1.0 - smoothstep(0.0, w5 * 1.4, abs(fract(ang / 15.0 + 0.5) - 0.5) * 15.0);
	float t0 = 1.0 - smoothstep(0.0, w5 * 1.6, abs(ang));
	float below = (0.5 - uv.y) / u_half;   // 1 = borde inferior de la línea
	float r5 = step(2.2, below) * step(below, 2.7);
	float r15 = step(2.2, below) * step(below, 3.3);
	float r0 = step(2.2, below) * step(below, 4.0);
	float rl = 1.0 - smoothstep(0.0, fwidth(below) * 1.2, abs(below - 2.2));
	float ruler = max(max(t5 * r5 * 0.6, t15 * r15 * 0.8), max(t0 * r0, rl * 0.5));
	c = mix(c, ink_col, ruler * 0.45 * full);
	// perfil de claridad (Reconocimiento por la Vista): la curva de un cuaderno de laboratorio
	float base_y = 0.24; float ty = base_y + I * 0.19;
	float lw = fwidth(uv.y) * 1.6;
	float tl = 1.0 - smoothstep(lw * 0.6, lw * 1.6, abs(uv.y - ty));
	float fill = step(base_y, uv.y) * step(uv.y, ty) * step(0.5, fract((FRAGCOORD.x - FRAGCOORD.y) / (7.0 * u_px)));
	float base = 1.0 - smoothstep(0.0, lw, abs(uv.y - base_y));
	float tr = u_trace * full;
	c = mix(c, acc_col, fill * 0.16 * tr);
	c = mix(c, ink_col, base * 0.5 * tr);
	c = mix(c, acc_col, tl * 0.9 * tr * step(0.003, I));
	float alpha = mix(u_bg, 1.0, clamp(ink * core * 2.0, 0.0, 1.0));
	// el punto: el brillo de lo que queda justo delante; al crecer, el color medio de toda la línea
	if (u_squeeze > 0.5) {
		vec3 c0 = texture(t_data, vec2(0.5, rc)).rgb; float I0 = texture(t_data, vec2(0.5, ri)).r;
		vec3 avg = vec3(0.0); float ai = 0.0;
		for (int k = 0; k < 32; k++) {
			float x = (float(k) + 0.5) / 32.0;
			float ik = texture(t_data, vec2(x, ri)).r;
			avg += texture(t_data, vec2(x, rc)).rgb * ik; ai += ik;
		}
		avg = ai > 0.001 ? avg / ai : bg_col; ai /= 32.0;
		vec3 pc = mix(c0, avg, u_grow); float pi = mix(I0, min(ai * 8.0, 1.0), u_grow);
		float pink = pi > 0.003 ? 0.18 + 0.82 * pow(min(pi, 1.0), 0.8) : 0.0;
		vec2 px = (UV - 0.5) * u_size;
		float R = mix(7.0 * u_px, length(u_size) * 0.6, u_grow * u_grow);
		float disk = 1.0 - smoothstep(R - 1.2, R + 1.2, length(px));
		float ring = (1.0 - smoothstep(0.0, 1.4, abs(length(px) - R - 5.0 * u_px))) * (1.0 - u_grow);
		float beat = 1.0 + 0.06 * sin(u_time * 0.8 * 6.2832) * u_grow;
		vec3 dc = hue_rot(mix(bg_col, pc, pink), u_hue * 6.2832) * beat;
		float on = smoothstep(0.5, 0.9, u_squeeze);
		c = mix(c, dc, disk * on);
		c = mix(c, ink_col, ring * 0.14 * on);
		alpha = mix(alpha, 1.0, max(disk, ring * 0.14) * on);
	}
	COLOR = vec4(c, alpha * u_alpha);
}
