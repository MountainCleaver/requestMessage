/*
	Consistent Glitch Effect Shader
	Based on Yui Kinomoto @arlez80
	MIT License
*/

shader_type canvas_item;

// === CONFIGURABLE PARAMETERS ===
uniform float shake_power = 0.03;         // Strength of glitch shift
uniform float shake_speed = 5.0;          // Speed of movement
uniform float shake_block_size = 30.5;    // Size of glitch strips
uniform float shake_color_rate = 0.01;    // RGB separation
uniform sampler2D screen_texture : hint_screen_texture;

// === UTILITY ===
float random(float seed) {
	return fract(543.2543 * sin(dot(vec2(seed, seed), vec2(3525.46, -54.3415))));
}

void fragment() {
	vec2 fixed_uv = SCREEN_UV;

	// 🔁 Instead of random timing, use a smooth sine wave for consistent flicker
	float enable_shift = abs(sin(TIME * shake_speed));

	// 🔄 Per-line horizontal distortion (blocky look retained)
	fixed_uv.x += (
		random(trunc(SCREEN_UV.y * shake_block_size) / shake_block_size + TIME)
		- 0.5
	) * shake_power * enable_shift;

	// 🎨 RGB channel offset (same style as original)
	vec4 pixel_color = textureLod(screen_texture, fixed_uv, 0.0);
	pixel_color.r = mix(
		pixel_color.r,
		textureLod(screen_texture, fixed_uv + vec2(shake_color_rate, 0.0), 0.0).r,
		enable_shift
	);
	pixel_color.b = mix(
		pixel_color.b,
		textureLod(screen_texture, fixed_uv + vec2(-shake_color_rate, 0.0), 0.0).b,
		enable_shift
	);

	COLOR = pixel_color;
}
