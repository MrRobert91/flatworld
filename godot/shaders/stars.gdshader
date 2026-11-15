shader_type spatial;
render_mode unshaded, depth_draw_never;
void vertex() { POINT_SIZE = 2.0; }
uniform vec4 col : source_color = vec4(1.0, 0.9, 0.68, 0.8);
void fragment() { ALBEDO = col.rgb; ALPHA = col.a; }
