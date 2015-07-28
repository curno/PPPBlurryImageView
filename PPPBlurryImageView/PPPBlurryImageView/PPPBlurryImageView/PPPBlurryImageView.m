//
//  PPPBlurryImageView.m
//  PPPBlurryImageView
//
//  Created by Yunfeng Liang on 15/7/22.
//
//

#import "PPPBlurryImageView.h"

#define STRINGIFY(A) #A
#import "Trival.vert"
#import "Gaussian.frag"

@interface PPPBlurryImageView () {
    GLuint _program;
    GLuint _fbos[2]; // frame buffer objects.
    GLuint _tos[2]; // texture objects.
    GLuint _texture;
}

@property (nonatomic, readonly) GLuint currentProgram;
@property (nonatomic, readwrite) GLsizei currentTextureSize;
@end

@implementation PPPBlurryImageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createComponents];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self createComponents];
    }
    return self;
}

- (void)createComponents {
    
    // load shader.
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    _program = 0;
    
    memset(_fbos, 0, sizeof(_fbos));
    memset(_tos, 0, sizeof(_tos));
    
    
    [EAGLContext setCurrentContext:self.context];
    [self createShader];
    [self createFrameBuffers];
    [EAGLContext setCurrentContext:nil];
    self.beginTextureLevel = 7;
    
    self.enableSetNeedsDisplay = YES;
}

- (GLuint)loadShader:(GLenum)shaderType shaderSource:(const char *)shaderSource {
    GLuint shader = glCreateShader(shaderType);
    if(shader == 0)
        return 0;
    glShaderSource(shader, 1, &shaderSource, NULL);
    glCompileShader(shader);
    
    GLint success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if(!success) {
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
        if(infoLen > 1) {
            char * infoLog = malloc(sizeof(char) * infoLen);
            glGetShaderInfoLog(shader, infoLen, NULL, infoLog); NSLog(@"Error compiling shader:\n%s\n", infoLog);
            free(infoLog);
        }
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

- (void)createShader {
    GLuint vertexShader = [self loadShader:GL_VERTEX_SHADER shaderSource:Trival_vert];
    
    GLuint fragmentShader = [self loadShader:GL_FRAGMENT_SHADER shaderSource:Gaussian_frag];
    
    GLuint program = glCreateProgram();
    
    if (program == 0 || vertexShader == 0 || fragmentShader == 0) {
        return;
    }
    
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    glLinkProgram(program);
    
    GLint linked;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (!linked) {
        return;
    }
    
    _program = program;
}


- (void)createFrameBuffers {
    glGenTextures(2, _tos);
    glGenBuffers(2, _fbos);
}

- (void)recreateTextureObjects {
    for (int i = 0; i < 2; ++i) {
        glBindTexture(GL_TEXTURE_2D, _tos[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.currentTextureSize, self.currentTextureSize, 0, GL_RGBA,
                     GL_UNSIGNED_BYTE, NULL);
        
        glBindFramebuffer(GL_FRAMEBUFFER, _fbos[i]);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _tos[i], 0);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"fail to initialize frame buffer's texture.");
        }
    }
}


- (void)setImage:(UIImage *)image {
    if (self.image == image) {
        return;
    }
    
    _image = image;
    
    [EAGLContext setCurrentContext:self.context];
    
    //_texture = [self loadTexture:image];
    [self createImageTexure];
    
    [EAGLContext setCurrentContext:nil];
    
    [self setNeedsDisplay];
}

- (void)setBeginTextureLevel:(NSUInteger)beginTextureLevel {
    if (beginTextureLevel == self.beginTextureLevel) {
        return;
    }
    
    _beginTextureLevel = beginTextureLevel;
    self.currentTextureSize = pow(2, _beginTextureLevel);
    [self setNeedsDisplay];
}

- (GLuint)loadTexture:(UIImage *)image
{
    NSDictionary* options = @{ GLKTextureLoaderOriginBottomLeft:[NSNumber numberWithBool:YES], GLKTextureLoaderSRGB : @(YES)};
    GLKTextureInfo* texture = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:nil];
    glBindTexture(GL_TEXTURE_2D, texture.name);
    return texture.name;
}

- (void)createImageTexure {
    if (_texture != 0) {
        glDeleteTextures(1, &_texture);
        _texture = 0;
    }
    
    CGImageRef cgImage = self.image.CGImage;
    
    GLsizei width = (GLsizei)CGImageGetWidth(cgImage);
    GLsizei height = (GLsizei)CGImageGetHeight(cgImage);
    
    GLsizei w = [self textureSize:width];
    GLsizei h = [self textureSize:height];
    
    
    GLubyte * data = (GLubyte *)calloc(w * h * 4, sizeof(GLubyte));
    
    CGContextRef cgContext = CGBitmapContextCreate(data, w, h, 8, w * 4,
                                                       CGImageGetColorSpace(cgImage), (CGImageAlphaInfo)kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(cgContext, CGRectMake(0, 0, w, h), cgImage);
    
    CGContextRelease(cgContext);
    
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glGenerateMipmap(GL_TEXTURE_2D);
    
    free(data);
}

- (GLsizei)textureSize:(GLsizei)size {
    CGFloat logOf2 = ceil(log2(size));
    return pow(2, logOf2);
}

- (void)setBlur:(CGFloat)blur {
    if (self.blur == blur) {
        return;
    }
    _blur = blur;
    [self setNeedsDisplay];
}

- (void)setTextureLevelDecrease:(CGFloat)textureLevelDecrease {
    if (self.textureLevelDecrease == textureLevelDecrease) {
        return;
    }
    
    _textureLevelDecrease = textureLevelDecrease;
    [self setNeedsDisplay];
}

- (GLuint)currentProgram {
    return _program;
}

- (void)setCurrentTextureSize:(GLsizei)currentTextureSize {
    if (_currentTextureSize == currentTextureSize) {
        return;
    }
    _currentTextureSize = currentTextureSize;
    [EAGLContext setCurrentContext:self.context];
    [self recreateTextureObjects];
    [EAGLContext setCurrentContext:nil];
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    GLsizei viewPort[4];
    glGetIntegerv(GL_VIEWPORT, viewPort);
    glUseProgram(self.currentProgram);
    
    GLfloat vVertices[] = {-1.0f, -1.0f, 0.0f,
        -1.0f, 1.0f, 0.0f,
        1.0f, 1.0f, 0.0f,
        1.0f, -1.0f, 0.0f};
    
    GLfloat vTextureCoords[] = {0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f, 1.0f};

    if (self.blur == 0) {
        [self bindDrawable];
        glBindTexture(GL_TEXTURE_2D, _texture);
        [self drawImageWithGaussienBlurType:0
                                      flipY:NO
                                       size:self.frame.size
                                     factor:0.0f
                                   vertices:vVertices
                              textureCoords:vTextureCoords];
        return;
    }
    
    glViewport(0, 0, self.currentTextureSize, self.currentTextureSize);
    glBindFramebuffer(GL_FRAMEBUFFER, _fbos[0]);
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    [self drawImageWithGaussienBlurType:0
                                  flipY:NO
                                   size:CGSizeMake(self.currentTextureSize, self.currentTextureSize)
                                 factor:0.0f
                               vertices:vVertices
                          textureCoords:vTextureCoords];
    
    int pingPongCount = (int)self.blur;
    CGFloat factor = self.blur - pingPongCount;
    
    if (factor > 0) {
        ++pingPongCount;
    }
    
    for (int i = 0; i < pingPongCount; ++i) {
        CGFloat currentFactor = (factor > 0 && i == pingPongCount - 1 ? factor : 1.0);
        glBindFramebuffer(GL_FRAMEBUFFER, _fbos[1]);
        glBindTexture(GL_TEXTURE_2D, _tos[0]);
        glViewport(0, 0, self.currentTextureSize, self.currentTextureSize);
        [self drawImageWithGaussienBlurType:1
                                      flipY:NO
                                       size:CGSizeMake(self.currentTextureSize, self.currentTextureSize)
                                     factor:currentFactor
                                   vertices:vVertices
                              textureCoords:vTextureCoords];
        
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, _fbos[0]);
        glBindTexture(GL_TEXTURE_2D, _tos[1]);
        glViewport(0, 0, self.currentTextureSize, self.currentTextureSize);
        
        [self drawImageWithGaussienBlurType:2
                                      flipY:NO
                                       size:CGSizeMake(self.currentTextureSize, self.currentTextureSize)
                                     factor:currentFactor
                                   vertices:vVertices
                              textureCoords:vTextureCoords];
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
    
    [self bindDrawable];
    
    glViewport(viewPort[0], viewPort[1], viewPort[2], viewPort[3]);
    glUseProgram(self.currentProgram);
    glBindTexture(GL_TEXTURE_2D, _tos[0]);
    [self drawImageWithGaussienBlurType:0
                                  flipY:YES
                                   size:CGSizeMake(self.currentTextureSize, self.currentTextureSize)
                                 factor:0.0f
                               vertices:vVertices
                          textureCoords:vTextureCoords];
    
}

- (void)drawImageWithGaussienBlurType:(GLint)type
                                flipY:(BOOL)flipY
                                 size:(CGSize)size
                               factor:(CGFloat)factor
                             vertices:(GLfloat *)vVertices
                        textureCoords:(GLfloat *)vTextureCoords{
    GLuint uTexture = glGetUniformLocation(self.currentProgram, "uImageUnit");
    glUniform1i(uTexture, 0);
    GLuint uDimension = glGetUniformLocation(self.currentProgram, "uDimension");
    glUniform2f(uDimension, (GLfloat)size.width, (GLfloat)size.height);
    GLuint uHorizontal = glGetUniformLocation(self.currentProgram, "uHorizontal");
    glUniform1i(uHorizontal, type);
    GLuint uGlassColor = glGetUniformLocation(self.currentProgram, "uGlassColor");
    glUniform4f(uGlassColor, 0.1f, 0.1f, 0.1f, 0.3f);
    GLuint uFactor = glGetUniformLocation(self.currentProgram, "uFactor");
    glUniform1f(uFactor, factor);
    GLuint uTopLeft = glGetUniformLocation(self.currentProgram, "uTopLeft");
    glUniform2f(uTopLeft, 0.0f, 0.0f);
    GLuint uBottomRight = glGetUniformLocation(self.currentProgram, "uBottomRight");
    glUniform2f(uBottomRight, 1.0f, 1.0f);
    
    
    GLuint aTexCoords = glGetAttribLocation(self.currentProgram, "aTexCoords");
    GLuint aPosition = glGetAttribLocation(self.currentProgram, "aPosition");
    
    
    
    if (flipY) {
        vVertices[1] *= -1.0f;
        vVertices[4] *= -1.0f;
        vVertices[7] *= -1.0f;
        vVertices[10] *= -1.0f;
    }
    
    glEnableVertexAttribArray(aPosition);
    glVertexAttribPointer(aPosition, 3, GL_FLOAT, GL_FALSE, 0, vVertices);
    glEnableVertexAttribArray(aTexCoords);
    glVertexAttribPointer(aTexCoords, 2, GL_FLOAT, GL_FALSE, 0, vTextureCoords);
    glClearColor(1.0f, 0.3f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glDisableVertexAttribArray(aPosition);
    glDisableVertexAttribArray(aTexCoords);
}




@end
