// ==============================================================================
// PLAYDEAD PALETTE LOOKUP TABLE (LUT) SHADER FOR GODOT 4.x
// Reconstructs the 8-bit Indexed Grayscale to 1D Palette Gradient Mapping
// ==============================================================================
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_index_texture : source_color, filter_nearest;
uniform sampler2D palette_texture : source_color, filter_linear;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float specular : hint_range(0.0, 1.0) = 0.15;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.3;
uniform vec4 rim_color : source_color = vec4(0.65, 0.72, 0.80, 1.0);

void fragment() {
	// Sample raw 8-bit grayscale intensity
	vec4 index_sample = texture(albedo_index_texture, UV);
	float gray_index = index_sample.r;
	
	// Map grayscale coordinate through the 1D color palette
	vec4 palette_color = texture(palette_texture, vec2(gray_index, 0.5));
	
	ALBEDO = palette_color.rgb;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	
	// Playdead characteristic subtle silhouette rim light
	float rim = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	rim = smoothstep(0.6, 1.0, rim);
	EMISSION = rim_color.rgb * rim * rim_intensity;
}
