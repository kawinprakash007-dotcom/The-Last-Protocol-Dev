shader_type spatial;
render_mode blend_mix, cull_back;

uniform vec4 base_color : source_color = vec4(0.08, 0.09, 0.11, 1.0);
uniform vec4 pulse_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform vec4 pulse_color2 : source_color = vec4(0.2, 0.9, 0.6, 1.0);
uniform float speed : hint_range(0.0, 10.0) = 2.0;
uniform float frequency : hint_range(1.0, 40.0) = 8.0;
uniform float pulse_width : hint_range(0.01, 0.5) = 0.15;
uniform float emission_energy : hint_range(0.0, 15.0) = 4.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.3;
uniform float metallic : hint_range(0.0, 1.0) = 0.8;

void fragment() {
    float coord = UV.x * frequency - TIME * speed;
    float pulse = smoothstep(pulse_width, 0.0, abs(fract(coord) - 0.5));
    
    // Segmented line pattern (stripes along Y)
    float stripe = step(0.3, fract(UV.y * 3.0));
    
    // Color gradient along the packet
    vec3 emissive_col = mix(pulse_color.rgb, pulse_color2.rgb, sin(coord * 0.5) * 0.5 + 0.5);
    vec3 final_emission = emissive_col * pulse * stripe * emission_energy;
    
    ALBEDO = mix(base_color.rgb, emissive_col, pulse * 0.5);
    ROUGHNESS = roughness;
    METALLIC = metallic;
    EMISSION = final_emission;
}
