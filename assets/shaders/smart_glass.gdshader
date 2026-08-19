shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

uniform vec4 glass_tint : source_color = vec4(0.05, 0.12, 0.18, 0.25);
uniform vec4 edge_color : source_color = vec4(0.2, 0.7, 0.9, 0.6);
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.9;
uniform float fresnel_power : hint_range(1.0, 10.0) = 3.5;
uniform float hex_scale : hint_range(5.0, 200.0) = 60.0;
uniform float hex_intensity : hint_range(0.0, 1.0) = 0.15;

// Procedural 2D hex grid distance calculation
vec4 get_hex(vec2 p) {
    vec2 s = vec2(1.0, 1.7320508);
    vec2 h = 0.5 * s;
    vec2 a = mod(p, s) - h;
    vec2 b = mod(p - h, s) - h;
    vec2 gv = dot(a, a) < dot(b, b) ? a : b;
    float x = abs(gv.x);
    float y = abs(gv.y);
    float d = max(x * 1.5 + y * 0.866025, y * 1.73205);
    return vec4(gv, d, 0.0);
}

void fragment() {
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
    
    // Hex pattern
    vec4 hex = get_hex(UV * hex_scale);
    float hex_edge = smoothstep(0.45, 0.5, hex.z);
    
    vec3 col = mix(glass_tint.rgb, edge_color.rgb, fresnel * 0.8 + hex_edge * hex_intensity);
    float alpha = mix(glass_tint.a, 0.85, fresnel * 0.6 + hex_edge * hex_intensity * 0.4);
    
    ALBEDO = col;
    ROUGHNESS = mix(roughness, 0.4, hex_edge * hex_intensity);
    METALLIC = metallic;
    SPECULAR = 0.8;
    ALPHA = clamp(alpha, 0.0, 1.0);
    EMISSION = edge_color.rgb * fresnel * 0.4;
}
