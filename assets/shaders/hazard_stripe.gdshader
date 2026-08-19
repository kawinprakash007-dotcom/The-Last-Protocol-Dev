shader_type spatial;
render_mode blend_mix, cull_back;

uniform vec4 stripe_color1 : source_color = vec4(0.95, 0.75, 0.05, 1.0); // Safety amber
uniform vec4 stripe_color2 : source_color = vec4(0.08, 0.08, 0.09, 1.0); // Matte black
uniform float stripe_scale : hint_range(1.0, 50.0) = 10.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.3;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float emission_energy : hint_range(0.0, 5.0) = 0.2;

void fragment() {
    float stripe = fract((UV.x + UV.y) * stripe_scale);
    float mask = step(0.5, stripe);
    
    vec3 col = mix(stripe_color1.rgb, stripe_color2.rgb, mask);
    ALBEDO = col;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    EMISSION = stripe_color1.rgb * (1.0 - mask) * emission_energy;
}
