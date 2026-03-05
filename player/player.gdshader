shader_type canvas_item;

uniform float white_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec3 white = vec3(1.0);

    tex.rgb = mix(tex.rgb, white, white_amount);

    COLOR = tex;
}