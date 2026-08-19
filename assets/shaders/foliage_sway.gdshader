shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec4 leaf_color_base : source_color = vec4(0.08, 0.35, 0.12, 1.0);
uniform vec4 leaf_color_tip : source_color = vec4(0.18, 0.65, 0.22, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.4;
uniform float sss_translucency : hint_range(0.0, 1.0) = 0.35;
uniform float sway_speed : hint_range(0.0, 10.0) = 2.0;
uniform float sway_strength : hint_range(0.0, 0.5) = 0.05;

void vertex() {
    float height_factor = clamp(VERTEX.y, 0.0, 1.0);
    float sway_x = sin(TIME * sway_speed + VERTEX.x * 3.0 + VERTEX.z * 2.0) * sway_strength * height_factor;
    float sway_z = cos(TIME * sway_speed * 1.3 + VERTEX.x * 2.0 + VERTEX.y * 4.0) * sway_strength * height_factor;
    VERTEX.x += sway_x;
    VERTEX.z += sway_z;
}

void fragment() {
    vec3 col = mix(leaf_color_base.rgb, leaf_color_tip.rgb, UV.y);
    ALBEDO = col;
    ROUGHNESS = roughness;
    SPECULAR = 0.25;
    BACKLIGHT = leaf_color_tip.rgb * sss_translucency;
}
