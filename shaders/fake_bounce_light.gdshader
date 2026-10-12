// ==============================================================================
// PLAYDEAD FAKE DIRECTIONAL BOUNCE LIGHT SHADER FOR GODOT 4.x
// Recreates Ground Reflection / Ambient Bounce Lighting on Character Undersides
// ==============================================================================
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 albedo_base_color : source_color = vec4(0.22, 0.24, 0.26, 1.0);
uniform sampler2D main_texture : source_color;

// Ground bounce light parameters
uniform vec4 ground_bounce_color : source_color = vec4(0.18, 0.28, 0.22, 1.0); // Wet grass / floor reflection
uniform float bounce_intensity : hint_range(0.0, 2.0) = 0.65;
uniform float bounce_exponent : hint_range(0.5, 4.0) = 1.2;

// Sky / Top light parameters
uniform vec4 sky_top_color : source_color = vec4(0.45, 0.50, 0.55, 1.0);
uniform float top_light_intensity : hint_range(0.0, 2.0) = 0.8;

void fragment() {
	vec4 tex = texture(main_texture, UV);
	vec3 base = albedo_base_color.rgb * tex.rgb;
	
	// Normal in world space
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// Upward bounce factor: normals pointing downward (-Y) receive ground light
	float bounce_factor = max(-world_normal.y, 0.0);
	bounce_factor = pow(bounce_factor, bounce_exponent);
	vec3 bounce_contribution = ground_bounce_color.rgb * bounce_factor * bounce_intensity;
	
	// Downward top factor: normals pointing upward (+Y) receive diffuse sky light
	float top_factor = max(world_normal.y, 0.0);
	vec3 top_contribution = sky_top_color.rgb * top_factor * top_light_intensity;
	
	ALBEDO = base;
	EMISSION = bounce_contribution + top_contribution * 0.4;
	ROUGHNESS = 0.9;
	SPECULAR = 0.05;
}
