shader_type spatial;
render_mode blend_mix, cull_back, unshaded;

uniform vec4 background_color : source_color = vec4(0.02, 0.05, 0.08, 1.0);
uniform vec4 screen_color : source_color = vec4(0.0, 0.85, 1.0, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.0, 0.45, 0.7, 1.0);
uniform vec4 alert_color : source_color = vec4(1.0, 0.55, 0.1, 1.0);
uniform float emission_energy : hint_range(0.0, 10.0) = 2.5;
uniform float scanline_count : hint_range(50.0, 600.0) = 240.0;
uniform float scanline_speed : hint_range(0.0, 10.0) = 1.5;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.05;
uniform float is_active : hint_range(0.0, 1.0) = 0.0;

// Simple pseudo-random hash
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = UV;
    
    // Subtle curvature / bezel vignette
    vec2 centered = uv - 0.5;
    float dist = dot(centered, centered);
    float vignette = clamp(1.0 - dist * 1.2, 0.0, 1.0);
    
    // Glitch horizontal offset
    float glitch_time = floor(TIME * 8.0);
    float glitch_rnd = hash(vec2(glitch_time, floor(uv.y * 15.0)));
    if (glitch_rnd > 0.94) {
        uv.x += (hash(vec2(TIME, uv.y)) - 0.5) * glitch_intensity;
    }
    
    // Base colors based on active state
    vec4 current_primary = mix(screen_color, alert_color, is_active * 0.5 + 0.5 * sin(TIME * 2.0) * is_active);
    if (is_active < 0.5) {
        current_primary = screen_color;
    }
    
    // Animated Grid
    vec2 grid_uv = fract(uv * vec2(30.0, 20.0));
    float grid_line = step(0.92, grid_uv.x) + step(0.92, grid_uv.y);
    float grid = clamp(grid_line, 0.0, 1.0) * 0.15;
    
    // Waveform / Telemetry graph (lower section)
    float wave_y = 0.35 + 0.08 * sin(uv.x * 25.0 + TIME * 6.0) * cos(uv.x * 12.0 - TIME * 3.0);
    float wave_thickness = 0.008;
    float wave = smoothstep(wave_thickness, 0.0, abs(uv.y - wave_y)) * 0.9;
    
    // Secondary telemetry wave
    float wave2_y = 0.22 + 0.05 * sin(uv.x * 40.0 - TIME * 8.0);
    float wave2 = smoothstep(0.006, 0.0, abs(uv.y - wave2_y)) * 0.6;
    
    // Data stream bars (upper section)
    float bar_x = floor(uv.x * 24.0) / 24.0;
    float bar_height = 0.5 + 0.35 * sin(bar_x * 18.0 + TIME * 4.0);
    float in_bar = step(0.55, uv.y) * step(uv.y, 0.55 + bar_height * 0.35);
    float bar_gap = step(0.15, fract(uv.x * 24.0));
    float bars = in_bar * bar_gap * 0.7;
    
    // Protocol / System text readout simulation (hex blocks)
    float block_row = floor((uv.y - 0.75) * 16.0);
    float in_text_area = step(0.72, uv.y) * step(uv.y, 0.95) * step(0.08, uv.x) * step(uv.x, 0.92);
    float text_pattern = step(0.4, hash(vec2(floor(uv.x * 32.0), block_row + floor(TIME * 2.0))));
    float text_blocks = in_text_area * text_pattern * 0.8;
    
    // Target Lock / Circular Radar in center-right
    vec2 radar_center = vec2(0.75, 0.4);
    float radar_dist = length(uv - radar_center);
    float radar_ring1 = smoothstep(0.006, 0.0, abs(radar_dist - 0.12));
    float radar_ring2 = smoothstep(0.004, 0.0, abs(radar_dist - 0.06));
    float radar_sweep = fract((atan(uv.y - radar_center.y, uv.x - radar_center.x) + 3.14159) / 6.28318 - TIME * 0.8);
    float radar_blip = (radar_ring1 + radar_ring2 + radar_sweep * 0.3) * step(radar_dist, 0.14);
    
    // Scanlines
    float scanline = sin(uv.y * scanline_count + TIME * scanline_speed);
    float scanline_factor = 1.0 - (scanline * 0.5 + 0.5) * scanline_intensity;
    
    // Moving horizontal scan beam
    float beam = smoothstep(0.04, 0.0, abs(fract(uv.y - TIME * 0.2) - 0.5));
    
    // Combine all graphic layers
    vec3 graphics = current_primary.rgb * (wave + bars + text_blocks + radar_blip + beam * 0.4);
    graphics += secondary_color.rgb * (wave2 + grid);
    
    // Status text / header banner
    float header_bar = step(0.93, uv.y) * step(uv.y, 0.96) * step(0.05, uv.x) * step(uv.x, 0.95);
    graphics += current_primary.rgb * header_bar * 0.9;
    
    // Final composite
    vec3 final_color = mix(background_color.rgb, graphics, clamp(wave + wave2 + bars + text_blocks + radar_blip + grid + header_bar + beam * 0.3, 0.0, 1.0));
    final_color *= scanline_factor * vignette;
    
    // Chromatic aberration at edges
    float ca_offset = dist * 0.008;
    final_color.r += hash(uv + vec2(ca_offset, 0.0)) * 0.03;
    final_color.b += hash(uv - vec2(ca_offset, 0.0)) * 0.03;
    
    ALBEDO = final_color;
    EMISSION = final_color * emission_energy;
}
