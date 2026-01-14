shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Maximum distortion amount
uniform float strength : hint_range(-0.5, 0.5) = -0.05;

// Controls the sharpness of the ring
uniform float ring_width : hint_range(1.0, 10.0) = 4.0;

// Chromatic aberration amount
uniform float aberration : hint_range(0.0, 0.1) = 0.02;

// MASTER FADE CONTROL (0.0 = Invisible, 1.0 = Visible)
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// 1. Calculate the Ring Mask
	// We use the view angle (fresnel) to make the center clear and edges thick
	float fresnel = 1.0 - dot(NORMAL, VIEW);
	float ring_mask = pow(fresnel, ring_width);
	
	// 2. Apply the "Fade"
	// As 'fade' goes to 0, the distortion strength drops to 0.
	// We also multiply the mask so the ring gets thinner/weaker.
	float current_strength = strength * fade;
	float current_mask = ring_mask * fade;

	// 3. Distortion Vector
	vec2 offset_dir = normalize(NORMAL.xy);
	vec2 final_offset = offset_dir * current_strength * current_mask;

	// 4. Sample Screen (The Distortion)
	// We offset the Read coordinates by our vector
	float r = texture(screen_texture, SCREEN_UV + final_offset * (1.0 + aberration)).r;
	float g = texture(screen_texture, SCREEN_UV + final_offset).g;
	float b = texture(screen_texture, SCREEN_UV + final_offset * (1.0 - aberration)).b;

	ALBEDO = vec3(r, g, b);
	
	// 5. Alpha Handling (Crucial for the Fade)
	// We manually set Alpha. When fade is 0, alpha is 0.
	// We keep alpha somewhat high usually so we can see the distortion, 
	// but dropping it to 0 ensures the mesh fully disappears at the end.
	ALPHA = clamp(current_mask + 0.1, 0.0, 1.0) * fade; 
}