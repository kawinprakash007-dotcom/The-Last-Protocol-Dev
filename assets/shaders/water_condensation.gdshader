shader_type spatial;
render_mode blend_mix, cull_back;

uniform vec4 surface_color : source_color = vec4(0.12, 0.14, 0.16, 1.0);
uniform float base_roughness : hint_range(0.0, 1.0) = 0.6;
uniform float wetness_roughness : hint_range(0.0, 1.0) = 0.05;
uniform float metallic : hint_range(0.0, 1.0) = 0.8;
uniform float droplet_scale : hint_range(5.0, 100.0) = 30.0;

// Pseudo-random noise for droplet positioning
float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 p = UV * droplet_scale;
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    
    // Droplet mask
    float rnd = hash21(ip);
    vec2 drop_center = vec2(rnd, hash21(ip + vec2(1.0, 5.0))) * 0.6 + 0.2;
    float dist = length(fp - drop_center);
    float droplet = smoothstep(0.2, 0.05, dist) * step(0.4, rnd);
    
    // Trickle drip lines
    float drip = smoothstep(0.05, 0.0, abs(fp.x - drop_center.x)) * step(drop_center.y, fp.y) * step(0.7, rnd);
    float wet_mask = clamp(droplet + drip, 0.0, 1.0);
    
    vec3 col = surface_color.rgb * (1.0 - wet_mask * 0.2);
    
    ALBEDO = col;
    ROUGHNESS = mix(base_roughness, wetness_roughness, wet_mask);
    METALLIC = metallic;
    SPECULAR = mix(0.5, 0.9, wet_mask);
}
