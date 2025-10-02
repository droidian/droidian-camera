#extension GL_OES_EGL_image_external : require
attribute vec4 aPosition;
attribute vec2 aTexCoord;
varying vec2 vTexCoord;
void main()
{
    gl_Position = aPosition;
    vTexCoord = vec2(aTexCoord.x, 1.0 - aTexCoord.y);
}