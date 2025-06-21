#extension GL_OES_EGL_image_external : require
precision mediump float;

uniform samplerExternalOES s_texture;
varying vec2 v_texCoord;
uniform float u_blurSize;

void main() {
    if(u_blurSize > 0.0) {
        vec2 texOffset = vec2(u_blurSize);
        vec4 color = vec4(0.0);
        float weightSum = 0.0;

        float weights[7];
        weights[0] = 0.204164;
        weights[1] = 0.180384;
        weights[2] = 0.123875;
        weights[3] = 0.066341;
        weights[4] = 0.027825;
        weights[5] = 0.009305;
        weights[6] = 0.002596;

        for (int i = -6; i <= 6; ++i) {
            int index = abs(i);
            vec2 offset = float(i) * texOffset;
            vec4 sampleX = texture2D(s_texture, v_texCoord + offset);
            vec4 sampleY = texture2D(s_texture, v_texCoord + vec2(0.0, offset.y));
            color += (sampleX + sampleY) * weights[index];
            weightSum += 2.0 * weights[index];
        }

        color /= weightSum;

        // Apply uniform fog overlay
        vec3 fogColor = vec3(0.0); // black fog
        float fogAlpha = 0.8;     // 0.0 = none, 1.0 = fully black
        color.rgb = mix(color.rgb, fogColor, fogAlpha);

        gl_FragColor = color;
    } else {
        gl_FragColor = texture2D(s_texture, v_texCoord);
    }
}