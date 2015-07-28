
static const char* Trival_vert = STRINGIFY (

attribute vec3 aPosition;
attribute vec2 aTexCoords;
varying vec2 vST;
void main() {
    gl_Position = vec4(aPosition, 1.0);
    vST = aTexCoords;
}
                                
);

