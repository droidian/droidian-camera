#extension GL_OES_EGL_image_external : require
attribute vec4 a_position;
attribute vec2 a_texCoord;
uniform mat4 m_texMatrix;
varying vec2 v_texCoord;
varying float topDown;
void main()
{
    gl_Position = a_position;
    v_texCoord = vec2(a_texCoord.x, 1.0 - a_texCoord.y);
}