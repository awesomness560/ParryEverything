shader_type canvas_item;

uniform sampler2D gradient_texture : source_color, filter_linear, repeat_enable;
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.5;
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform bool pulse_mode = false;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform float pulse_aspect : hint_range(0.1, 5.0) = 3.0; // Controls how oblong/stretched

void fragment() {
    vec4 final_color;
    
    if (pulse_mode) {
        // Pulsing gradient expanding from center
        vec2 center = vec2(0.5, 0.5);
        vec2 pos = UV - center;
        
        // Make it oblong by stretching horizontally
        pos.x /= pulse_aspect;
        
        // Calculate radial distance from center
        float dist = length(pos);
        
        // Add pulse animation
        float pulse_offset = TIME * pulse_speed;
        float sample_pos = dist + pulse_offset;
        
        final_color = texture(gradient_texture, vec2(sample_pos, 0.5));
    } else {
        // Scrolling gradient effect
        float scroll_offset = TIME * scroll_speed;
        float sample_pos = UV.x + scroll_offset;
        final_color = texture(gradient_texture, vec2(sample_pos, 0.5));
    }
    
    // Only show where progress allows
    if (UV.x <= progress) {
        COLOR = final_color * COLOR; // Multiply by modulate
    } else {
        COLOR = vec4(0.0);
    }
}