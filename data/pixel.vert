// vertex.glsl (GLSL 1.20 style)

uniform mat4 modelview;
uniform mat4 projection;
uniform mat4 texMatrix;

attribute vec4 vertex;
attribute vec2 texCoord;

varying vec4 vertTexCoord;

void main() {
    
    vertTexCoord = texMatrix * vec4(texCoord, 1.0, 1.0);     
    gl_Position = projection * modelview * vertex;
}
