shader_type canvas_item;
render_mode unshaded;

uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.3; // darkness
uniform float vignette_softness : hint_range(0.0, 2.0, 0.01) = 0.8; // feathered edge

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Normalize UV to [-1, 1]
    vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;

    // Distance from center (controls how far the corners darken)
    float dist = length(centered_uv);

    // Vignette calculation using smoothstep for smooth fading
    float vignette = smoothstep(0.8, vignette_softness + 0.8, dist);

    // Sample the screen normally
    vec3 color = texture(screen_texture, SCREEN_UV).rgb;

    // Apply vignette (subtle dark corners)
    color *= mix(1.0, 1.0 - vignette_strength, vignette);

    COLOR = vec4(color, 1.0);
}
