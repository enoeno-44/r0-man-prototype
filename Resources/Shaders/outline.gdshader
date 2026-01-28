shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;

    // ตรวจสอบ 8 ทิศทางรอบ ๆ pixel
    float outline = 0.0;
    outline += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;

    outline = min(outline, 1.0);

    vec4 color = texture(TEXTURE, UV);

    // ถ้าตรงกลางโปร่งใส แต่รอบ ๆ มีสี = วาดขอบ
    if (color.a < 0.1 && outline > 0.0) {
        COLOR = outline_color;
    } else {
        COLOR = color;
    }
}