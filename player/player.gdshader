shader_type canvas_item;

uniform float white_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV) * COLOR; // keep modulate + vertex color
    tex.rgb = mix(tex.rgb, vec3(1.0), white_amount); // fade to white
    COLOR = tex; // alpha preserved
}