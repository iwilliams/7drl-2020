shader_type canvas_item;

uniform sampler2D tex;
uniform vec2 tile = vec2(0, 0);
uniform vec4 fg_color = vec4(1, 1, 1, 1);
uniform vec4 bg_color = vec4(0, 0, 0, 1);

// 2668 * x = 32

// UV.x = % pos of x

// 32/2668

void fragment() {
  vec2 UV2 = UV * vec2(textureSize(TEXTURE, 0)) / vec2(textureSize(tex, 0)) * 6.2;
//  vec2 UV2 = UV * (vec2(96, 96) / vec2(textureSize(tex, 0)));
  float s = 32.0/vec2(textureSize(tex, 0)).x;
  COLOR = vec4(0, 0, 0, 1);
  vec4 texColor = texture(tex, vec2((UV2.x - floor(UV2.x / s) * s) + (s*tile.x), (UV2.y - floor(UV2.y / s) * s) + (s*tile.y)));
  COLOR.rgb = texColor.rgb * texColor.a;
}
