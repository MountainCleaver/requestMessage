shader_type canvas_item;

uniform sampler2D noise_texture;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float time = 0.0;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Sample noise texture with moving UVs
    float n = texture(noise_texture, uv * 3.0 + vec2(time * 0.3, time * 0.5)).r;

    // Distort UVs using noise + time for irregular movement
    vec2 distortedUV = uv + vec2(
        sin(time * 8.0 + n * 25.0),
        cos(time * 5.0 + n * 15.0)
    ) * (0.02 + 0.01 * sin(time * 3.0));

    // Apply the distorted UVs directly without RGB offsets
    vec4 screenColor = texture(SCREEN_TEXTURE, distortedUV);
    screenColor.a = 1.0;

    COLOR = screenColor;
}
