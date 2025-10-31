shader_type canvas_item;
render_mode unshaded;

uniform float curvature : hint_range(0.0, 10.0, 0.1) = 2.0;
uniform float vignette_softness : hint_range(0.0, 5.0, 0.1) = 1.5;
uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.05; // vignette darkness
uniform float blur_strength : hint_range(0.0, 3.0, 0.1) = 0.5;
uniform float scanline_speed : hint_range(0.0, 10.0, 0.1) = 1.2;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Normalize UV to [-1,1]
    vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;

    // Barrel distortion
    vec2 uv_offset = centered_uv.yx / curvature;
    vec2 warped_uv = centered_uv + centered_uv * uv_offset * uv_offset * 0.3;

    // Expanded UV to avoid black borders
    vec2 final_uv = clamp((warped_uv + 1.0) * 0.5, vec2(-0.1), vec2(1.1));

    // Moving scanlines (animated upward)
    float scanline_pattern = sin((warped_uv.y + TIME * scanline_speed * 0.1) * 180.0);
    vec3 scanlines = vec3(scanline_pattern * 0.05 + 0.98);

    // Soft vignette using smoothstep
    float dist = length(centered_uv);
    float vignette = smoothstep(vignette_softness * 0.5, 1.6, dist);

    // Sample screen (no RGB split)
    vec3 screen_color = textureLod(screen_texture, final_uv, blur_strength).rgb * scanlines;

    // Apply vignette
    screen_color *= mix(1.0, 1.0 - vignette_strength, vignette);

    COLOR = vec4(screen_color, 1.0);
}
