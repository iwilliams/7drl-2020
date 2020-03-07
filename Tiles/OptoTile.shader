shader_type canvas_item;

const vec4 default_color = vec4(62./255., 53./255., 70./255., 1.);

uniform sampler2D tex;
uniform vec2 tile = vec2(0, 0);
uniform vec4 fg_color = vec4(1, 1, 1, 1);
uniform vec4 bg_color = vec4(0, 0, 0, 1);
uniform float brightness = 1.0;

void fragment(){
  vec2 UV2 = UV * (vec2(32, 32) / vec2(textureSize(tex, 0))) - ((tile * vec2(-32, -32)) / vec2(textureSize(tex, 0)));
  vec4 newColor = texture(tex, UV2);
  COLOR = newColor;
  if (COLOR.a <= 0.0) {
    COLOR = mix(default_color, bg_color, brightness);
  } else {
    COLOR = mix(default_color, fg_color, brightness);
   }
}
