shader_type canvas_item;

uniform float fade_offset : hint_range(0.0, 1.0, 0.01) = 0.0; // shift the fade horizontally
uniform float fade_strength : hint_range(0.1, 5.0, 0.1) = 1.0; // control how steep the fade is

void fragment() {
    vec4 base_color = COLOR;

    // Shift and compress the gradient
    float alpha = clamp((UV.x - fade_offset) * fade_strength, 0.0, 1.0);

    COLOR = vec4(base_color.rgb, base_color.a * alpha);
}
