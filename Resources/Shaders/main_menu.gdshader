shader_type canvas_item;

uniform float heartbeat_speed : hint_range(0.5, 3.0) = 1.0;
uniform float glow_radius : hint_range(0.1, 1.0) = 0.4;
uniform float edge_softness : hint_range(0.1, 1.0) = 0.3;
uniform float min_brightness : hint_range(0.0, 0.5) = 0.1;
uniform float max_brightness : hint_range(0.5, 1.2) = 0.9;

void fragment() {
    vec2 uv = UV;
    
    // คำนวณระยะห่างจากจุดกลาง
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    
    // สร้างจังหวะเต้นแบบหัวใจ (เต้น 2 ครั้งแล้วพัก)
    float time = TIME * heartbeat_speed;
    float beat1 = exp(-mod(time, 2.0) * 8.0); // เต้นครั้งแรก
    float beat2 = exp(-mod(time - 0.2, 2.0) * 8.0); // เต้นครั้งที่สอง (เว้นระยะเล็กน้อย)
    float heartbeat = max(beat1, beat2) * 0.3 + 0.7; // ผสมทั้งสองจังหวะ
    
    // สร้าง gradient จากกลางไปขอบ
    float radial_gradient = 1.0 - smoothstep(glow_radius - edge_softness, glow_radius + edge_softness, dist);
    
    // ผสมกับจังหวะเต้น
    float brightness = mix(min_brightness, max_brightness, radial_gradient * heartbeat);
    
    // สีขาว
    vec3 color = vec3(brightness);
    
    COLOR = vec4(color, 1.0);
}