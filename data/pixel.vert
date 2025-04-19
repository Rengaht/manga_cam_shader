// vertex.glsl (GLSL 1.20 style)

uniform mat4 modelview;
uniform mat4 projection;


attribute vec4 vertex;
attribute vec2 texcoord;

varying vec2 vertTexCoord;

void main() {
    vertTexCoord = texcoord;
    gl_Position = projection * modelview * vertex;
}
