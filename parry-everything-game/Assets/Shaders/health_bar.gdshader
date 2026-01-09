shader_type spatial;
render_mode unshaded;

uniform bool use_billboard;
uniform vec4 health_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 damage_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 background_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;
uniform float health : hint_range(0.0, 1.0) = 0.7;
uniform float damage : hint_range(0.0, 1.0) = 0.9;

varying float aspect_ratio;

void vertex() {
	// Extract scale from the model matrix
	vec3 scale = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	);
	
	// Calculate aspect ratio from actual mesh scale
	aspect_ratio = scale.x / scale.y;
	
	if (use_billboard) {
		// Create billboard rotation (facing camera) while preserving scale
		mat4 billboard = VIEW_MATRIX * mat4(
			vec4(normalize(INV_VIEW_MATRIX[0].xyz) * scale.x, 0.0),
			vec4(normalize(INV_VIEW_MATRIX[1].xyz) * scale.y, 0.0),
			vec4(normalize(INV_VIEW_MATRIX[2].xyz) * scale.z, 0.0),
			MODEL_MATRIX[3]
		);
		
		MODELVIEW_MATRIX = billboard;
	}
}

void fragment() {
	// Center coordinates from -0.5 to 0.5
	vec2 p = UV - 0.5;
	
	// Correct for aspect ratio
	p.x *= aspect_ratio;
	
	// Capsule parameters (in corrected space)
	float cap_radius = 0.5;
	float half_length = (aspect_ratio * 0.5) - cap_radius;
	
	// Distance from center line, accounting for the straight section
	float dx = abs(p.x) - half_length;
	dx = max(dx, 0.0);
	
	// Distance to capsule surface
	float dist = sqrt(dx * dx + p.y * p.y) - cap_radius;
	
	// Discard if outside capsule
	if (dist > 0.0) {
		discard;
	}
	
	// Check if we're in the outline region (inward from edge)
	bool is_outline = dist > -outline_width;
	
	// Determine color based on outline and layers
	if (is_outline) {
		ALBEDO = outline_color.rgb;
		ALPHA = outline_color.a;
	} else {
		// Layer the bars: health on top, damage below, background at bottom
		if (UV.x < health) {
			// Health bar (top layer)
			ALBEDO = health_color.rgb;
			ALPHA = health_color.a;
		} else if (UV.x < damage) {
			// Damage bar (middle layer, shows where health was lost)
			ALBEDO = damage_color.rgb;
			ALPHA = damage_color.a;
		} else {
			// Background (bottom layer)
			ALBEDO = background_color.rgb;
			ALPHA = background_color.a;
		}
	}
}