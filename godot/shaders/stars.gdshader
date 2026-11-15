shader_type spatial;
render_mode unshaded, depth_draw_never;
void vertex() { POINT_SIZE = 2.0; }
void fragment() { ALBEDO = vec3(1.0, 0.9, 0.68); ALPHA = 0.8; }
