shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never;

uniform vec4 holo_color : source_color = vec4(0.0, 0.9, 1.0, 1.0);
uniform float fresnel_power : hint_range(0.5, 8.0) = 2.5;
uniform float scanline_speed : hint_range(0.0, 10.0) = 2.0;
uniform float scanline_density : hint_range(10.0, 300.0) = 120.0;
uniform float glow_intensity : hint_range(0.1, 10.0) = 3.0;
uniform float flicker_speed : hint_range(0.0, 30.0) = 12.0;
uniform float alpha_base : hint_range(0.0, 1.0) = 0.4;

void fragment() {
    // Fresnel rim
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
    
    // Scanlines
    float scanline = sin(UV.y * scanline_density - TIME * scanline_speed);
    float scan_mod = 0.6 + 0.4 * scanline;
    
    // Vertical beam sweep
    float beam = smoothstep(0.15, 0.0, abs(fract(UV.y * 0.5 - TIME * 0.4) - 0.5));
    
    // Subtle flicker
    float flicker = 0.9 + 0.1 * sin(TIME * flicker_speed) * cos(TIME * flicker_speed * 1.7);
    
    // Combined alpha
    float alpha = (alpha_base + fresnel * 0.8 + beam * 0.5) * scan_mod * flicker;
    alpha = clamp(alpha, 0.0, 1.0);
    
    vec3 col = holo_color.rgb * (1.0 + fresnel * 1.5 + beam * 0.8);
    
    ALBEDO = col;
    EMISSION = col * glow_intensity * alpha;
    ALPHA = alpha * holo_color.a;
}
