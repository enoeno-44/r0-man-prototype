shader_type canvas_item;

uniform float chaos_level : hint_range(0.5, 10.0) = 5.0;
uniform float glitch_frequency : hint_range(0.1, 1.0) = 0.4;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * chaos_level;

    // ตัดสินใจว่าจะ glitch หรือไม่
    float should_glitch = step(1.0 - glitch_frequency, random(vec2(floor(time * 5.0), 0.0)));

    // Vertical displacement แบบสุ่ม
    float line_y = floor(uv.y * 20.0);
    float h_shift = (random(vec2(line_y, floor(time * 10.0))) - 0.5) * 0.3 * should_glitch;

    // RGB ซอยไปคนละทาง
    float rgb_offset = random(vec2(floor(time), 0.0)) * 0.05 * should_glitch;

    vec2 uv_r = uv + vec2(h_shift + rgb_offset, 0.0);
    vec2 uv_g = uv + vec2(h_shift, 0.0);
    vec2 uv_b = uv + vec2(h_shift - rgb_offset, 0.0);

    float r = texture(TEXTURE, uv_r).r;
    float g = texture(TEXTURE, uv_g).g;
    float b = texture(TEXTURE, uv_b).b;
    float a = texture(TEXTURE, uv).a;

    // เพิ่มการกระพริบ (flash)
    float flash = step(0.97, random(vec2(floor(time * 20.0), 1.0))) * should_glitch;

    vec3 color = vec3(r, g, b) + vec3(flash * 0.5);
    COLOR = vec4(color, a);
}