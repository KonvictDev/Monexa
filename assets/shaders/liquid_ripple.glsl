// Liquid ripple transition shader
// Save as assets/shaders/liquid_ripple.glsl

precision highp float;

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iTexture;

void main() {
  vec2 uv = gl_FragCoord.xy / iResolution.xy;

  // Bottom-right origin (0,0 is top-left)
  uv.y = 1.0 - uv.y;

  // Create a circular ripple expanding outwards
  vec2 center = vec2(1.0, 0.0);
  float dist = distance(uv, center);

  // Wave distortion
  float wave = sin((dist - iTime * 1.5) * 25.0) * 0.02;
  uv += normalize(uv - center) * wave;

  // Fade in as ripple expands
  float fade = smoothstep(iTime * 1.2 - 0.3, iTime * 1.2, dist);

  vec4 color = texture2D(iTexture, uv);
  color.rgb *= fade;
  gl_FragColor = color;
}
