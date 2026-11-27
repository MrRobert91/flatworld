// Patrones de dibujo técnico para cada tono (C4-07): el color nunca va solo, siempre con su rayado.
// Los ocho tonos del juego (ChB.HUES): rojo, naranja, amarillo, verde, celeste, violeta, malva, rosa.
float pat_hue(vec3 c) {
	float mx = max(c.r, max(c.g, c.b)); float mn = min(c.r, min(c.g, c.b)); float d = mx - mn;
	if (d < 1.0e-4) return 0.0;
	float h;
	if (mx == c.r) h = mod((c.g - c.b) / d, 6.0);
	else if (mx == c.g) h = (c.b - c.r) / d + 2.0;
	else h = (c.r - c.g) / d + 4.0;
	return h / 6.0;
}
float pat_sat(vec3 c) {
	float mx = max(c.r, max(c.g, c.b)); float mn = min(c.r, min(c.g, c.b));
	return mx > 1.0e-4 ? (mx - mn) / mx : 0.0;
}
int pat_index(float h) {
	float H[8] = float[8](0.005, 0.09, 0.145, 0.40, 0.55, 0.67, 0.80, 0.95);
	int best = 0; float bd = 9.0;
	for (int i = 0; i < 8; i++) { float d = abs(h - H[i]); d = min(d, 1.0 - d); if (d < bd) { bd = d; best = i; } }
	return best;
}
// máscara 0..1 del patrón k en coordenadas p (una celda por unidad)
float pat_mask(vec2 p, int k) {
	if (k == 0) return step(0.55, fract(p.x + p.y));                       // rayado a 45°
	if (k == 1) return step(0.55, fract(p.x - p.y));                       // rayado a −45°
	if (k == 2) return step(0.55, fract(p.y));                             // horizontal
	if (k == 3) return 1.0 - step(0.3, length(fract(p) - 0.5));            // punteado
	if (k == 4) return step(0.55, fract(p.x));                             // vertical
	if (k == 5) return max(step(0.8, fract(p.x + p.y)), step(0.8, fract(p.x - p.y)));   // cuadriculado en aspa
	if (k == 6) return step(0.7, fract((p.x + p.y) * 2.0));                // rayado fino
	return step(0.55, fract(p.y + 0.3 * sin(p.x * 3.14159)));              // ondulado
}
