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
in vec2 vUv;
out vec4 outColor;

const float FIX_ERROR = 0.05;

float getTexturePixels1x1(vec2 truncUv, vec2 texSize) {
  vec2 uvNorm = (truncUv + FIX_ERROR) / texSize;
  return textureOffset(uImage, uvNorm, ivec2(0, 0)).r;
}

mat2 getTexturePixels2x2(vec2 truncUv, vec2 texSize) {
  vec2 uvNorm = (truncUv + FIX_ERROR) / texSize;
  return mat2(
    textureOffset(uImage, uvNorm, ivec2(0, 0)).r,
    textureOffset(uImage, uvNorm, ivec2(1, 0)).r,
    textureOffset(uImage, uvNorm, ivec2(0, 1)).r,
    textureOffset(uImage, uvNorm, ivec2(1, 1)).r
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

/* Расчет функции sampling для случая alpha = -0.5 */
float calcSamplingOneItem(float x) {
  x = abs(x);
  if (x <= 1.0) {
    x = 1.0 - 2.5 * pow(x, 2.0) + 1.5 * pow(x, 3.0);
  } else if (x < 2.0) {
    x = 2.0 - 4.0 * x + 2.5 * pow(x, 2.0) - 0.5 * pow(x, 3.0);
  } else {
    x = 0.0;
  }

  return x;
}

vec4 calcSamplingFourItems(float dx, float coord, float size) {
  float s0 = coord >= 0.0 ? calcSamplingOneItem(-dx - 1.0) : 0.0;
  float s1 = calcSamplingOneItem(-dx);
  float s2 = coord + 1.0 < size ? calcSamplingOneItem(-dx + 1.0) : 0.0;
  float s3 = coord + 2.0 < size ? calcSamplingOneItem(-dx + 2.0) : 0.0;

  return vec4(s0, s1, s2, s3);
}

mat4 getTexturePixels4x4(vec2 truncUv, vec2 texSize){
  vec2 uv = vec2((truncUv.xy + FIX_ERROR) / texSize);

  return mat4(
    textureOffset(uImage, uv, ivec2(-1, -1)).r,
    textureOffset(uImage, uv, ivec2( 0, -1)).r,
    textureOffset(uImage, uv, ivec2( 1, -1)).r,
    textureOffset(uImage, uv, ivec2( 2, -1)).r,

    textureOffset(uImage, uv, ivec2(-1,  0)).r,
    textureOffset(uImage, uv, ivec2( 0,  0)).r,
    textureOffset(uImage, uv, ivec2( 1,  0)).r,
    textureOffset(uImage, uv, ivec2( 2,  0)).r,

    textureOffset(uImage, uv, ivec2(-1,  1)).r,
    textureOffset(uImage, uv, ivec2( 0,  1)).r,
    textureOffset(uImage, uv, ivec2( 1,  1)).r,
    textureOffset(uImage, uv, ivec2( 2,  1)).r,

    textureOffset(uImage, uv, ivec2(-1,  2)).r,
    textureOffset(uImage, uv, ivec2( 0,  2)).r,
    textureOffset(uImage, uv, ivec2( 1,  2)).r,
    textureOffset(uImage, uv, ivec2( 2,  2)).r
  );
}


void main() {
  vec2 texSize = vec2(textureSize(uImage, 0));
  vec2 truncUv = trunc(vUv);
  vec2 dxy = vUv - truncUv;
  float val;
  float valLinear;
  float valBicubic;
  // Интерполяция
  // 1 - без интерполяции
  // 2 - билинейная интерполяция
  // 3 - бикубическая интерполяция
  int uMapInterpolation = 0;
  int uIsolineInterpolation = 1;
  bool isDiscard = false;
  bool bilinear = false;

  val = getTexturePixels1x1(truncUv, texSize);

  mat2 A = getTexturePixels2x2(truncUv, texSize);

  if (isEmpty(A[0][0]) || isEmpty(A[0][1]) || isEmpty(A[1][0]) || isEmpty(A[1][1])) {
    isDiscard = true;
  } else {
    valLinear = dot(vec2(1.0 - dxy.x, dxy.x) * A, vec2(1.0 - dxy.y, dxy.y));
  }

  mat4 B = getTexturePixels4x4(truncUv, texSize);
  if (isEmpty(B[0][0]) || isEmpty(B[0][3]) || isEmpty(B[3][0]) || isEmpty(B[3][3]))
  {
    isDiscard = true;
  } else {
    vec4 A = calcSamplingFourItems(dxy.x, truncUv.x, texSize.x + 3.0);
    vec4 C = calcSamplingFourItems(dxy.y, truncUv.y, texSize.y + 3.0);
    valBicubic = dot(A * B, C);
  }

  if (isDiscard) {
    outColor = vec4(0.8, 0.8, 0.8, 1);
  } else {
    float valForMap = uMapInterpolation == 2 ? valBicubic :
                      uMapInterpolation == 1 ? valLinear : val;
    vec4 depthColor = getPalleteColor(valForMap);

    float valForIsoline = uIsolineInterpolation == 2 ? valBicubic :
                          uIsolineInterpolation == 1 ? valLinear : val;
    float f = length(vec2(dFdx(valForIsoline), dFdy(valForIsoline)));
    float p = valForIsoline - uBaseline;
    float r = round(p / uIsolineStep) * uIsolineStep;
    float d = r < p ? p - r : r - p;

    float r5 = round(p / uIsolineStep / uMajorIsoline) * uIsolineStep * uIsolineStep;
    float d5 = r5 < p ? p - r5 : r5 - p;

    // outColor = d < 0.5 * f || d5 < 1.5 * f ? vec4(0, 0, 0, 1) : vec4(1, 1, 1, 1);

    //outColor = mix(depthColor, isolineColor, smoothstep(edge0, edge1, deltaPosition));
    outColor = mix(depthColor, isolineColor, d < 1.0 * f || d5 < 2.0 * f ? 1.0 : 0.0);
  }
}