#version 300 es
in vec2 aPosition;
in vec2 aUv;

uniform mat3 uProjection;
out vec2 vUv;
void main() {
  gl_Position = vec4((uProjection * vec3(aPosition, 1)).xy, 0, 1);

  vUv = aUv;
}