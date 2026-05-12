#extension GL_OES_EGL_image_external : require
precision mediump float;

uniform samplerExternalOES s_texture;
varying vec2 v_texCoord;

void main()
{
    vec3 c = texture2D(s_texture, v_texCoord).rgb;
    float y = dot(c, vec3(0.299, 0.587, 0.114));
    gl_FragColor = vec4(y, y, y, 1.0);
}