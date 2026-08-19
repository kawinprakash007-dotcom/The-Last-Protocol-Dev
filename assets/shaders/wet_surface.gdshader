shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color;
uniform sampler2D texture_normal : hint_normal;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

uniform float wetness : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D puddle_map;
uniform float puddle_scale : hint_range(0.1, 10.0) = 1.0;

void fragment() {
    vec2 base_uv = UV;
    vec4 albedo_tex = texture(texture_albedo, base_uv);
    vec3 normal_tex = texture(texture_normal, base_uv).rgb;
    
    // Read puddle mask
    float puddle = texture(puddle_map, base_uv * puddle_scale).r;
    puddle = smoothstep(1.0 - wetness, 1.05 - wetness, puddle);
    
    // Calculate wet properties
    float current_roughness = mix(roughness, 0.02, puddle); // Very smooth where wet
    vec3 current_normal = mix(normal_tex, vec3(0.5, 0.5, 1.0), puddle * 0.8); // Flatten normal where deep puddle
    vec3 current_albedo = mix(albedo.rgb * albedo_tex.rgb, albedo.rgb * albedo_tex.rgb * 0.5, puddle * 0.5); // Darken where wet
    
    ALBEDO = current_albedo;
    METALLIC = mix(metallic, 0.1, puddle);
    ROUGHNESS = current_roughness;
    NORMAL_MAP = current_normal;
}
