shader_type canvas_item;

// พารามิเตอร์ที่ปรับได้
uniform float glitch_strength : hint_range(0.0, 1.0) = 0.3;
uniform float color_shift_amount : hint_range(0.0, 1.0) = 0.2;
uniform float scan_line_speed : hint_range(0.0, 5.0) = 1.0;
uniform float distortion_speed : hint_range(0.0, 3.0) = 0.5;

// Pixelation
uniform float pixel_size : hint_range(1.0, 32.0) = 4.0;
uniform float color_corruption : hint_range(0.0, 1.0) = 0.3;

// สุ่ม noise
float random(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// สุ่มสีแบบ glitch
vec3 corrupt_color(vec3 original, vec2 pos, float time) {
    float r = random(vec2(pos.x, time));

    if (r < color_corruption * 0.3) {
        // สีสุ่มสนิท
        return vec3(
            random(vec2(pos.x, time)),
            random(vec2(pos.y, time + 1.0)),
            random(vec2(pos.x + pos.y, time + 2.0))
        );
    } else if (r < color_corruption * 0.6) {
        // Invert สี
        return vec3(1.0) - original;
    } else if (r < color_corruption) {
        // เปลี่ยนช่อง RGB
        return original.gbr;
    }

    return original;
}

void fragment() {
    vec2 uv = UV;

    // === 1. Pixelation Effect ===
    vec2 pixel_uv = uv;
    if (pixel_size > 1.0) {
        vec2 texture_size = vec2(textureSize(TEXTURE, 0));
        vec2 pixel_count = texture_size / pixel_size;
        pixel_uv = floor(uv * pixel_count) / pixel_count;
    }

    // === 2. Horizontal Glitch (เลื่อนแนวนอนแบบสุ่ม) ===
    float glitch_line = floor(pixel_uv.y * 50.0);
    float glitch_random = random(vec2(glitch_line, floor(TIME * 2.0)));

    if (glitch_random > 0.95) {
        float offset = (random(vec2(glitch_line, TIME)) - 0.5) * glitch_strength * 0.1;
        pixel_uv.x += offset;
    }

    // === 3. Color Channel Shift (RGB แยกกัน) ===
    float shift = color_shift_amount * 0.01;
    vec4 color_r = texture(TEXTURE, pixel_uv + vec2(shift, 0.0));
    vec4 color_g = texture(TEXTURE, pixel_uv);
    vec4 color_b = texture(TEXTURE, pixel_uv - vec2(shift, 0.0));

    vec4 color = vec4(color_r.r, color_g.g, color_b.b, color_g.a);

    // === 4. Pixel Color Corruption (สีเพี้ยนแบบสุ่มตาม pixel) ===
    vec2 pixel_pos = floor(pixel_uv * 100.0);
    float corrupt_chance = random(vec2(pixel_pos.x, floor(TIME * distortion_speed)));

    if (corrupt_chance > 0.96) {
        color.rgb = corrupt_color(color.rgb, pixel_pos, TIME);
    }

    // === 5. Scan Lines (เส้นสแกนแบบ TV เก่า) ===
    float scan = sin((uv.y + TIME * scan_line_speed) * 200.0) * 0.05 + 0.95;
    color.rgb *= scan;

    // === 6. Random Color Blocks (บล็อกสีเพี้ยนแบบสุ่ม) ===
    vec2 block_pos = floor(uv * 20.0);
    float block_random = random(vec2(block_pos.x, floor(TIME * 1.5)));

    if (block_random > 0.985) {
        // เปลี่ยนสีทั้งบล็อก
        color.rgb = vec3(
            random(vec2(block_pos.x, TIME)),
            random(vec2(block_pos.y, TIME + 0.5)),
            random(vec2(block_pos.x + block_pos.y, TIME + 1.0))
        );
    }

    // === 7. Vertical Distortion (บิดเบือนแนวตั้งเล็กน้อย) ===
    float wave = sin(uv.x * 10.0 + TIME * distortion_speed) * glitch_strength * 0.005;

    // === 8. Chromatic Aberration แบบสุ่ม ===
    if (random(vec2(floor(TIME * 3.0), uv.y)) > 0.97) {
        color.rgb = vec3(
            texture(TEXTURE, pixel_uv + vec2(0.01, 0.0)).r,
            texture(TEXTURE, pixel_uv).g,
            texture(TEXTURE, pixel_uv - vec2(0.01, 0.0)).b
        );
    }

    COLOR = color;
}