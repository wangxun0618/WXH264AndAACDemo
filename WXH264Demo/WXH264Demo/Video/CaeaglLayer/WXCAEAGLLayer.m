//
//  WXCAEAGLLayer.m
//  WXH264Demo
//
//  Created by ABC on 17/3/9.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import "WXCAEAGLLayer.h"
#import <AVFoundation/AVUtilities.h>
#import <mach/mach_time.h>
#include <AVFoundation/AVFoundation.h>
#import <UIKit/UIScreen.h>
#include <OpenGLES/EAGL.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

// Uniform index.
enum
{
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_ROTATION_ANGLE,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    NUM_UNIFORMS
};

GLint LYCAEAGl_uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

// Color Conversion Constants (YUV to RGB) including adjustment from 16-235/16-240 (video range)

// BT.601, which is the standard for SDTV.
static const GLfloat kColorConversion601[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.709, which is the standard for HDTV.
static const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

@interface WXCAEAGLLayer() {
    GLint m_backingWidth;
    GLint m_backingHeight;
    
    EAGLContext *m_context;
    CVOpenGLESTextureRef m_lumaTexture;
    CVOpenGLESTextureRef m_chromaTexture;
    
    GLuint m_frameBufferHandle;
    GLuint m_colorBufferHandle;
    
    const GLfloat *m_preferredConversion;
}
@property GLuint program;

@end

@implementation WXCAEAGLLayer

@synthesize pixelBuffer = _pixelBuffer;


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        CGFloat scale = [[UIScreen mainScreen] scale];
        self.contentsScale = scale;
        
        self.opaque = TRUE;
        self.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking :[NSNumber numberWithBool:YES]};
        
        [self setFrame:frame];
        
        // Set the context into which the frames will be drawn.
        m_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!m_context) {
            return nil;
        }
        
        // Set the default conversion to BT.709, which is the standard for HDTV.
        m_preferredConversion = kColorConversion709;
        
        [self setupGL];
    }
    
    return self;
}


-(CVPixelBufferRef) pixelBuffer {
    return _pixelBuffer;
}

- (void)setPixelBuffer:(CVPixelBufferRef)pb {
    if(_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    _pixelBuffer = CVPixelBufferRetain(pb);
    
    int frameWidth = (int)CVPixelBufferGetWidth(_pixelBuffer);
    int frameHeight = (int)CVPixelBufferGetHeight(_pixelBuffer);
    [self displayPixelBuffer:_pixelBuffer width:frameWidth height:frameHeight];
}


- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer width:(uint32_t)frameWidth height:(uint32_t)frameHeight
{
//    NSLog(@"displayPixelBuffer frameWidth = %d, frameHeight = %d", frameWidth, frameHeight);
    if (!m_context || ![EAGLContext setCurrentContext:m_context]) {
        return;
    }
    
    if(pixelBuffer == NULL) {
        NSLog(@"Pixel buffer is null");
        return;
    }
    
    CVReturn err;
    
    size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
    
    /*
     Use the color attachment of the pixel buffer to determine the appropriate color conversion matrix.
     */
    CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
    
    if (colorAttachments == kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
        m_preferredConversion = kColorConversion601;
    }
    else {
        m_preferredConversion = kColorConversion709;
    }
    
    /*
     CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture optimally from CVPixelBufferRef.
     */
    
    /*
     Create Y and UV textures from the pixel buffer. These textures will be drawn on the frame buffer Y-plane.
     */
    
    CVOpenGLESTextureCacheRef _videoTextureCache;
    
    // Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
    err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, m_context, NULL, &_videoTextureCache);
    if (err != noErr) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }
    
    glActiveTexture(GL_TEXTURE0);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       frameWidth,
                                                       frameHeight,
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &m_lumaTexture);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(m_lumaTexture), CVOpenGLESTextureGetName(m_lumaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    if(planeCount == 2) {
        // UV-plane.
        glActiveTexture(GL_TEXTURE1);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RG_EXT,
                                                           frameWidth / 2,
                                                           frameHeight / 2,
                                                           GL_RG_EXT,
                                                           GL_UNSIGNED_BYTE,
                                                           1,
                                                           &m_chromaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(m_chromaTexture), CVOpenGLESTextureGetName(m_chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, m_frameBufferHandle);
    
    // Set the view port to the entire view.
    glViewport(0, 0, m_backingWidth, m_backingHeight);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Use shader program.
    glUseProgram(self.program);
    //    glUniform1f(LYCAEAGl_uniforms[UNIFORM_LUMA_THRESHOLD], 1);
    //    glUniform1f(LYCAEAGl_uniforms[UNIFORM_CHROMA_THRESHOLD], 1);
    glUniform1f(LYCAEAGl_uniforms[UNIFORM_ROTATION_ANGLE], 0);
    glUniformMatrix3fv(LYCAEAGl_uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, m_preferredConversion);
    
    // Set up the quad vertices with respect to the orientation and aspect ratio of the video.
    CGRect viewBounds = self.bounds;
    //quinn note 下面这一行暂时没用
//    CGSize contentSize = CGSizeMake(frameWidth, frameHeight);
    
    //    CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(contentSize, viewBounds);
    
    CGRect vertexSamplingRect = self.bounds;
    
    
    // Compute normalized quad coordinates to draw the frame into.
    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width/viewBounds.size.width,
                                        vertexSamplingRect.size.height/viewBounds.size.height);
    
    // Normalize the quad vertices.
    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
    }
    else {
        normalizedSamplingSize.width = cropScaleAmount.width/cropScaleAmount.height;
        normalizedSamplingSize.height = 1.0;;
    }
    
    /*
     The quad vertex data defines the region of 2D plane onto which we draw our pixel buffers.
     Vertex data formed using (-1,-1) and (1,1) as the bottom left and top right coordinates respectively, covers the entire screen.
     */
    GLfloat quadVertexData [] = {
        -1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        -1 * normalizedSamplingSize.width, normalizedSamplingSize.height,
        normalizedSamplingSize.width, normalizedSamplingSize.height,
    };
    
    // Update attribute values.
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    
    /*
     The texture vertices are set up such that we flip the texture vertically. This is so that our top left origin buffers match OpenGL's bottom left texture coordinate system.
     */
    CGRect textureSamplingRect = CGRectMake(0, 0, 1, 1);
    GLfloat quadTextureData[] =  {
        CGRectGetMinX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
        CGRectGetMaxX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
        CGRectGetMinX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
        CGRectGetMaxX(textureSamplingRect), CGRectGetMinY(textureSamplingRect)
    };
    
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindRenderbuffer(GL_RENDERBUFFER, m_colorBufferHandle);
    [m_context presentRenderbuffer:GL_RENDERBUFFER];
    
    [self cleanUpTextures];
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
    
//    NSLog(@"end display &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
}


# pragma mark - OpenGL setup

- (void)setupGL
{
    if (!m_context || ![EAGLContext setCurrentContext:m_context]) {
        return;
    }
    
    [self setupBuffers];
    [self loadShaders];
    
    glUseProgram(self.program);
    
    // 0 and 1 are the texture IDs of _lumaTexture and _chromaTexture respectively.
    glUniform1i(LYCAEAGl_uniforms[UNIFORM_Y], 0);
    glUniform1i(LYCAEAGl_uniforms[UNIFORM_UV], 1);
    glUniform1f(LYCAEAGl_uniforms[UNIFORM_ROTATION_ANGLE], 0);
    glUniformMatrix3fv(LYCAEAGl_uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, m_preferredConversion);
}

#pragma mark - Utilities

- (void)setupBuffers
{
    glDisable(GL_DEPTH_TEST);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    [self createBuffers];
}

- (void) createBuffers
{
    glGenFramebuffers(1, &m_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, m_frameBufferHandle);
    
    glGenRenderbuffers(1, &m_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, m_colorBufferHandle);
    
    [m_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &m_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &m_backingHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, m_colorBufferHandle);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void) releaseBuffers
{
    if(m_frameBufferHandle) {
        glDeleteFramebuffers(1, &m_frameBufferHandle);
        m_frameBufferHandle = 0;
    }
    
    if(m_colorBufferHandle) {
        glDeleteRenderbuffers(1, &m_colorBufferHandle);
        m_colorBufferHandle = 0;
    }
}

- (void) resetRenderBuffer
{
    if (!m_context || ![EAGLContext setCurrentContext:m_context]) {
        return;
    }
    
    [self releaseBuffers];
    [self createBuffers];
}

- (void) cleanUpTextures
{
    if (m_lumaTexture) {
        CFRelease(m_lumaTexture);
        m_lumaTexture = NULL;
    }
    
    if (m_chromaTexture) {
        CFRelease(m_chromaTexture);
        m_chromaTexture = NULL;
    }
}

#pragma mark -  OpenGL ES 2 shader compilation

const GLchar *LYCAEAGL_shader_fsh = (const GLchar*)"varying highp vec2 texCoordVarying;"
"precision mediump float;"
"uniform sampler2D SamplerY;"
"uniform sampler2D SamplerUV;"
"uniform mat3 colorConversionMatrix;"
"void main()"
"{"
"    mediump vec3 yuv;"
"    lowp vec3 rgb;"
//   Subtract constants to map the video range start at 0
"    yuv.x = (texture2D(SamplerY, texCoordVarying).r - (16.0/255.0));"
"    yuv.yz = (texture2D(SamplerUV, texCoordVarying).rg - vec2(0.5, 0.5));"
"    rgb = colorConversionMatrix * yuv;"
"    gl_FragColor = vec4(rgb, 1);"
"}";

const GLchar *LYCAEAGL_shader_vsh = (const GLchar*)"attribute vec4 position;"
"attribute vec2 texCoord;"
"uniform float preferredRotation;"
"varying vec2 texCoordVarying;"
"void main()"
"{"
"    mat4 rotationMatrix = mat4(cos(preferredRotation), -sin(preferredRotation), 0.0, 0.0,"
"                               sin(preferredRotation),  cos(preferredRotation), 0.0, 0.0,"
"                               0.0,					    0.0, 1.0, 0.0,"
"                               0.0,					    0.0, 0.0, 1.0);"
"    gl_Position = position * rotationMatrix;"
"    texCoordVarying = texCoord;"
"}";

- (BOOL)loadShaders
{
    GLuint vertShader = 0, fragShader = 0;
    
    // Create the shader program.
    self.program = glCreateProgram();
    
    if(![self compileShaderString:&vertShader type:GL_VERTEX_SHADER shaderString:LYCAEAGL_shader_vsh]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    if(![self compileShaderString:&fragShader type:GL_FRAGMENT_SHADER shaderString:LYCAEAGL_shader_fsh]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(self.program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(self.program, fragShader);
    
    // Bind attribute locations. This needs to be done prior to linking.
    glBindAttribLocation(self.program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(self.program, ATTRIB_TEXCOORD, "texCoord");
    
    // Link the program.
    if (![self linkProgram:self.program]) {
        NSLog(@"Failed to link program: %d", self.program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (self.program) {
            glDeleteProgram(self.program);
            self.program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    LYCAEAGl_uniforms[UNIFORM_Y] = glGetUniformLocation(self.program, "SamplerY");
    LYCAEAGl_uniforms[UNIFORM_UV] = glGetUniformLocation(self.program, "SamplerUV");
    //    LYCAEAGl_uniforms[UNIFORM_LUMA_THRESHOLD] = glGetUniformLocation(self.program, "lumaThreshold");
    //    LYCAEAGl_uniforms[UNIFORM_CHROMA_THRESHOLD] = glGetUniformLocation(self.program, "chromaThreshold");
    LYCAEAGl_uniforms[UNIFORM_ROTATION_ANGLE] = glGetUniformLocation(self.program, "preferredRotation");
    LYCAEAGl_uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = glGetUniformLocation(self.program, "colorConversionMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(self.program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(self.program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShaderString:(GLuint *)shader type:(GLenum)type shaderString:(const GLchar*)shaderString
{
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &shaderString, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    GLint status = 0;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type URL:(NSURL *)URL
{
    NSError *error;
    NSString *sourceString = [[NSString alloc] initWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
    if (sourceString == nil) {
        NSLog(@"Failed to load vertex shader: %@", [error localizedDescription]);
        return NO;
    }
    
    const GLchar *source = (GLchar *)[sourceString UTF8String];
    
    return [self compileShaderString:shader type:type shaderString:source];
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (void)dealloc
{
    if (!m_context || ![EAGLContext setCurrentContext:m_context]) {
        return;
    }
    
    [self cleanUpTextures];
    
    if(_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    
    if (self.program) {
        glDeleteProgram(self.program);
        self.program = 0;
    }
    if(m_context) {
        //[_context release];
        m_context = nil;
    }
    //[super dealloc];
}


@end
