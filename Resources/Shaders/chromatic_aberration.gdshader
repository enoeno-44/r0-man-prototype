shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float aberration_strength : hint_range(0.0, 10.0) = 5.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 direction = uv - vec2(0.5);
    float distance_from_center = length(direction);
    
    vec2 offset = normalize(direction) * aberration_strength * 0.001 * distance_from_center;
    
    float r = texture(SCREEN_TEXTURE, uv + offset).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv - offset).b;
    
    COLOR = vec4(r, g, b, 1.0);
}