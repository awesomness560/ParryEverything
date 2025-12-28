shader_type canvas_item;

uniform sampler2D gradient_texture : source_color, filter_linear, repeat_enable;
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.5;
uniform float progress : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    // Create scrolling effect
    float scroll_offset = TIME * scroll_speed;
    float sample_pos = UV.x + scroll_offset;
    
    // Sample the gradient
    vec4 gradient_color = texture(gradient_texture, vec2(sample_pos, 0.5));
    
    // Only show where progress allows
    if (UV.x <= progress) {
        COLOR = gradient_color * COLOR; // Multiply by modulate
    } else {
        COLOR = vec4(0.0);
    }
}