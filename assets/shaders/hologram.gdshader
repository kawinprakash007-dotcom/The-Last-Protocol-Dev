shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 hologram_color : source_color = vec4(0.0, 0.8, 1.0, 0.8);
uniform float scanline_speed : hint_range(0.0, 10.0) = 2.0;
uniform float scanline_density : hint_range(1.0, 100.0) = 50.0;
uniform float flicker_speed : hint_range(0.0, 20.0) = 5.0;
uniform sampler2D noise_texture;
uniform float noise_amount : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    // Scanlines
    float scanline = sin(UV.y * scanline_density - TIME * scanline_speed) * 0.5 + 0.5;
    
    // Flicker
    float flicker = sin(TIME * flicker_speed) * 0.5 + 0.5;
    flicker = mix(0.8, 1.0, flicker);
    
    // Noise
    vec4 noise_val = texture(noise_texture, UV + vec2(TIME * 0.1, TIME * 0.2));
    float noise_effect = mix(1.0, noise_val.r, noise_amount);
    
    // Rim lighting effect
    float rim = 1.0 - dot(NORMAL, VIEW);
    rim = smoothstep(0.5, 1.0, rim);
    
    ALBEDO = hologram_color.rgb;
    ALPHA = hologram_color.a * scanline * flicker * noise_effect + rim * 0.5;
    
    // Ensure it's somewhat transparent in the center, opaque on edges
    ALPHA = clamp(ALPHA, 0.0, 1.0);
}
