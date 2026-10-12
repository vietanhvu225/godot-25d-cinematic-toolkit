// ==============================================================================
// PLAYDEAD VOLUMETRIC FOG & ORDERED BAYER DITHERING SHADER FOR GODOT 4.x
// Eliminates 8-bit Gradient Color Banding in Deep Dark Atmospheres
// ==============================================================================
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 fog_deep_color : source_color = vec4(0.04, 0.06, 0.08, 1.0);
uniform vec4 fog_light_color : source_color = vec4(0.18, 0.22, 0.26, 1.0);
uniform float fog_start_distance : float = 4.0;
uniform float fog_density : hint_range(0.01, 1.0) = 0.065;
uniform float dither_strength : hint_range(0.0, 0.1) = 0.025;

uniform sampler2D depth_texture : hint_depth_texture;

// Standard 4x4 Bayer Matrix for ordered dithering
const mat4 bayer_4x4 = mat4(
	vec4( 0.0,  8.0,  2.0, 10.0) / 16.0,
	vec4(12.0,  4.0, 14.0,  6.0) / 16.0,
	vec4( 3.0, 11.0,  1.0,  9.0) / 16.0,
	vec4(15.0,  7.0, 13.0,  5.0) / 16.0
);

void fragment() {
	// Reconstruct linear camera depth from depth buffer
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	float linear_depth = -view_pos.z;
	
	// Compute fog depth factor with exponential falloff
	float fog_factor = clamp((linear_depth - fog_start_distance) * fog_density, 0.0, 1.0);
	fog_factor = 1.0 - exp(-fog_factor * 2.5);
	
	// Evaluate Bayer ordered dither matrix based on screen pixel coords
	ivec2 pixel_coord = ivec2(FRAGCOORD.xy) % 4;
	float dither = bayer_4x4[pixel_coord.x][pixel_coord.y] - 0.5;
	
	// Apply dither noise directly to the fog factor before interpolation to prevent banding
	fog_factor = clamp(fog_factor + dither * dither_strength, 0.0, 1.0);
	
	vec3 final_fog_color = mix(fog_deep_color.rgb, fog_light_color.rgb, pow(fog_factor, 0.7));
	
	ALBEDO = final_fog_color;
	ALPHA = fog_factor;
}
