#version 300 es

precision highp float;

const vec4 isolineColor = vec4(0.0, 0.0, 0.0, 1.0);

uniform sampler2D uImage;
uniform float uNullValue;
uniform float uRangeMin;
uniform float uRangeMax;
uniform vec4 uPalette[256];
uniform float uIsolineStep;
uniform float uBaseline;
uniform float uMajorIsoline;
uniform float uMinorIsolineWidth;
uniform float uMajorIsolineWidth;
in vec2 vTexCoord;
out vec4 outColor;

mat2 getTexturePixels2x2(vec2 texCoord, vec2 onePixelSize) {
  return mat2(
    texture(uImage, onePixelSize * (texCoord + vec2(0, 0))).r,
    texture(uImage, onePixelSize * (texCoord + vec2(1, 0))).r,
    texture(uImage, onePixelSize * (texCoord + vec2(0, 1))).r,
    texture(uImage, onePixelSize * (texCoord + vec2(1, 1))).r
  );
}

bool isEmpty(float value) {
  return value == uNullValue;
}

vec4 getPalleteColor(float val) {
  float val255 = (uRangeMax - val) / (uRangeMax - uRangeMin) * 255.0;
  int pos1 = clamp(int(trunc(val255)), 0, 255);
  int pos2 = pos1 < 255 ? pos1 + 1 : pos1;
  float deltaValue = val255 - float(pos1);
  return mix(uPalette[pos1], uPalette[pos2], deltaValue) / 255.0;
}

void main() {
  ivec2 texSize = textureSize(uImage, 0);
  vec2 onePixelSize = 1.0 / vec2(texSize);

  vec2 textureCoord = vTexCoord / onePixelSize - vec2(0.5);
  vec2 truncTextureCoord = trunc(textureCoord);
  vec2 dxy = textureCoord - truncTextureCoord;

  mat2 A = getTexturePixels2x2(truncTextureCoord, onePixelSize);

  if (isEmpty(A[0][0]) || isEmpty(A[0][1]) || isEmpty(A[1][0]) || isEmpty(A[1][1])) {
    discard;
  }

  float val = dot(vec2(1.0 - dxy.x, dxy.x) * A, vec2(1.0 - dxy.y, dxy.y));
  float f = length(vec2(dFdx(val), dFdy(val)));
  vec4 depthColor = getPalleteColor(val);

  float p = val - uBaseline;
  float r = round(p / uIsolineStep) * uIsolineStep;
  float d = r < p ? p - r : r - p;

  float r5 = round(p / uIsolineStep / uMajorIsoline) * uIsolineStep * uIsolineStep;
  float d5 = r5 < p ? p - r5 : r5 - p;

  // outColor = d < 0.5 * f || d5 < 1.5 * f ? vec4(0, 0, 0, 1) : vec4(1, 1, 1, 1);

  // outColor = mix(depthColor, isolineColor, smoothstep(edge0, edge1, deltaPosition));
  outColor = mix(depthColor, isolineColor, d < 1.0 * f || d5 < 2.0 * f ? 1.0 : 0.0);
}