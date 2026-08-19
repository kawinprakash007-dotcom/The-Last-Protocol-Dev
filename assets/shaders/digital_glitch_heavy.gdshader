shader_type spatial;
render_mode blend_add, unshaded;

uniform sampler2D screen_texture : source_color;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float glitch_rate : hint_range(0.0, 20.0) = 5.0;
uniform vec4 error_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // Heavy slicing/offset
    float slice_y = floor(uv.y * 20.0);
    float noise = random(vec2(slice_y, floor(TIME * glitch_rate)));
    
    if (noise > (1.0 - glitch_intensity)) {
        uv.x += (random(vec2(slice_y, TIME)) - 0.5) * 0.2 * glitch_intensity;
    }
    
    // Color separation (Chromatic aberration)
    float r = texture(screen_texture, uv + vec2(0.01 * glitch_intensity, 0.0)).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - vec2(0.01 * glitch_intensity, 0.0)).b;
    
    vec3 col = vec3(r, g, b);
    
    // Error block overlay
    if (noise > 0.9 && glitch_intensity > 0.3) {
        col = mix(col, error_color.rgb, 0.5);
    }
    
    ALBEDO = col;
    EMISSION = col * 2.0;
}
