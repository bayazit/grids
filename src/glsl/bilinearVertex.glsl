#version 300 es
in vec2 aPosition;
in vec2 aTextureCoord;

uniform mat3 uProjection;
out vec2 vTexCoord;
void main() {
  gl_Position = vec4((uProjection * vec3(aPosition, 1)).xy, 0, 1);

  vTexCoord = aTextureCoord;
}