
static const char* Gaussian_frag = STRINGIFY
(
 
precision mediump float;

uniform highp sampler2D uImageUnit;
varying vec2 vST;
uniform vec2 uDimension;
uniform int uHorizontal;
 
 uniform vec2 uOrigin;
 uniform vec4 uSize;
 uniform highp float uFactor;
 uniform highp vec2 uTopLeft;
 uniform highp vec2 uBottomRight;

void main() {
    if (uHorizontal == 0) {
        gl_FragColor = texture2D(uImageUnit, vST);
    } else {
        highp float l = uHorizontal == 1 ? uDimension.s : uDimension.t;
        highp float offset[3];
        offset[0] = 0.0;
        offset[1] = 1.3846153846 / l;
        offset[2] = 3.2307692308 / l;
        float weight[3];
        weight[0]=1.0 + (0.2270270270 - 1.0) * uFactor;
        weight[1]=0.3162162162 * uFactor;
        weight[2]=0.0702702703 * uFactor;
        gl_FragColor = texture2D( uImageUnit, vST) * weight[0];
        if  (uHorizontal == 1) {
            for (int i=1; i<3; i++) {
                vec2 vDown = (vST.t + offset[i] > uBottomRight.t) ? vST : (vST+vec2(0.0, offset[i]));
                gl_FragColor += texture2D(uImageUnit, vDown)* weight[i];
                vec2 vUp = (vST.t - offset[i] < uTopLeft.t) ? vST : (vST-vec2(0.0, offset[i]));
                gl_FragColor += texture2D(uImageUnit, vUp)* weight[i];
            }
        } else {
            for (int i=1; i<3; i++) {
                vec2 vRight = (vST.s + offset[i] > uBottomRight.s) ? vST : (vST+vec2(offset[i], 0.0));
                gl_FragColor += texture2D(uImageUnit, (vST+vec2(offset[i], 0.0)))* weight[i];
                vec2 vLeft = (vST.s - offset[i] < uTopLeft.s) ? vST : (vST-vec2(offset[i], 0.0));
                gl_FragColor += texture2D(uImageUnit, vLeft)* weight[i];
            }
        }
    }
}
);