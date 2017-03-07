//
//  OpenGLView.m
//  OpenGLStudy
//
//  Created by 名策 on 2017/3/1.
//  Copyright © 2017年 名策. All rights reserved.
//

#import "OpenGLView.h"
#ifdef __OBJC__ // GL_ES_VERSION_2_0
#import <OpenGLES/gltypes.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "CC3GLMatrix.h"//定义了各种矩阵
#endif


typedef struct {
    float Position[3];
    float Color[4];
}Vertex;


const Vertex vertices[] = {
    {{1,-1,0},{1,0,0,1}},//第一个点,包括位置和颜色两个信息
    {{1,1,0},{1,0,0,1}},//第二个点
    {{-1,1,0},{1,0,0,1}},//第三个点
    {{-1,-1,0},{1,0,0,1}} //第四个点
          };
const GLubyte Indices[] = {0,1,2,2,3,0};//两个三角形画点的顺序

//以上的数据为画一个正方形的数据

@implementation OpenGLView


//旋转刷新
- (void)setupDisplayLink
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    displayLink.preferredFramesPerSecond = 0.5;
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

}
- (void)render:(CADisplayLink*)displayLink {
    
    [self compileShaders];
    [self setupVBOs];
    [self renderRect];

}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        [self setupLayer];//设置layer的透明度
        [self setupContext];
        [self setRenderBuffer];
        [self setupFrameBuffer];
        [self render];
        [self compileShaders];
        [self setupVBOs];
        [self renderRect];
        [self setupDisplayLink];


    }
    return self;
}




/*
 如你所见，其实很简单的。这其实是一种之前也用过的模式（pattern）。
 glGenBuffers - 创建一个Vertex Buffer 对象
 glBindBuffer – 告诉OpenGL我们的vertexBuffer 是指GL_ARRAY_BUFFER
 glBufferData – 把数据传到OpenGL-land
 想起哪里用过这个模式吗？要不再回去看看frame buffer那一段？ 万事俱备，我们可以通过新的shader，用新的渲染方法来把顶点数据画到屏幕上。
 


 */
- (void)setupVBOs
{
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    
}

- (void)renderRect{
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //1.调用glViewport设置UIView中用于渲染的部分，这个例子指定了整个屏幕，如果希望更小的部分，可以变更这些参数；
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    //2.调用glVertexAttribPointer来为vertex shader的两个输入参数配两个合适的值
    /*
      第一个参数，声明这个属性的名称，之前我们称之为glGetAttribLocation
      第二个参数，定义这个属性有多少个值组成，譬如position是有3个float(x,y,z)组成，而颜色是有4个float组成(r,g,b,a);
      第三个参数，声明每个值是什么类型(这例子中无论是位置还是颜色，都用了GL_FLOAT类型)
      第四个参数,....他总是flase就好了
      第五个参数,指stride的大小，这是一个种描述每个Vetex数据大小的方式，所以我们可以简单传入sizeOf(Vetext),让编译器计算出来就好。
      第六个参数，这个是数据结构的偏移量，表示在这个结构中，从哪里开始获取我们的值。Position的值在前面，所以传0就可以了，而颜色的值是紧接着位置的数据，二Position的大小是3个float的大小，所以就是3*sizeOf(flaot)开始的
     */

    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) *3));
    
    /*
     调用GLDrawElements,他最后会在每个vertex上调用我们的vertex shader，以及每个像素调用fragmen Shader 最终画出我们的图像
     第一个参数:声明用哪种特性来渲染图形，有GL_LINE_STRIP 和 GL_TRIANGLE_FAN.然而GL_TRIANGLE是最常用的，特别是与VBO关联的时候
     第二个参数，告诉渲染器有多少个图形要渲染，我们用到c的代码计算出有多少个。这里是通过array的byte大小除以一个indice类型的大小得到
     第三个参数，指每个Indices中的类型
     第四个参数，在官方文档中说，它是一个指向index的指针，但这里我们用的是VBO,所以通过index的array就可以访问到了，(在GL_ELEMENT_ARRAY_BUFFER传过了)，所以这里不需要
     */
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    /*
    你可能会疑惑，为什么这个长方形刚好占满整个屏幕。在缺省状态下，OpenGL的“camera”位于（0,0,0）位置，朝z轴的正方向。当然，后面我们会讲到projection（投影）以及如何控制camera。
    
    增加一个投影
    
    为了在2D屏幕上显示3D画面，我们需要在图形上做一些投影变换，所谓投影就是下图这个意思：
    
    
    
    基本上，为了模仿人类的眼球原理。我们设置一个远平面和一个近平面，在两个平面之前，离近平面近的图像，会因为被缩小了而显得变小；而离远平面近的图像，也会因此而变大。打开SimpleVertex.glsl，做一下修改：
    
    
    // Add right before the main
    uniform mat4 Projection;
    
    // Modify gl_Position line as follows
    gl_Position = Projection * Position;
    注意：矩阵运算顺序会影响结果。
     
     
     这里我们增加了一个叫做projection的传入变量。uniform 关键字表示，这会是一个应用于所有顶点的常量，而不是会因为顶点不同而不同的值。
     
     mat4 是 4X4矩阵的意思。然而，Matrix math是一个很大的课题，我们不可能在这里解析。所以在这里，你只要认为它是用于放大缩小、旋转、变形就好了。
     
     Position位置乘以Projection矩阵，我们就得到最终的位置数值。
     
     没错，这就是一种被称之“线性代数”的东西。其实数学也只是一种工具，而这种工具已经由前面的才子解决了，我们知道怎么用就好。
     
     Bill Hollings，cocos3d的作者。他编写了一个完整的3D特性框架，并整合到cocos2d中。无论如何，Cocos3d包含了Objective-C的向量和矩阵库，所以我们可以很好地应用到这个项目中。
     
     下载 Cocos3DMathLib 并copy到你的项目中。记得选上：“Copy items into destination group’s folder (if needed)” 点击Finish。
     */
    
}


//设置View的class为CAEAGLLayer
//想要显示OpenGL的内容，要把它缺省的layer设置成一个特殊的layer CAEAGLLayer 这里通过直接重写layerClass方法
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//设置layer的不透明度(Opaque)
//缺省layer是透明的，而透明层性能负荷很大，特别是OpenGL的层

- (void)setupLayer
{
    self.eaglLayer = (CAEAGLLayer*)self.layer;
    _eaglLayer.opaque = YES;
}

//创建OpenGL context
//无论需要OpenGL帮你实现什么总需要这个EAGLContext  EAGLContext管理所有通过OpenGL进行的draw信息。这个与CoreGraphics context 类似 当创建一个context需要声明要用哪个version的API,这里我们选择的是OpenGL 2.0
- (void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {

        NSLog(@"create Context succeed");
        exit(1);

    }
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"feiled to set current OpenGL context");
        exit(1);

    }
}

//创建Render buffer (渲染缓冲区)
//Render buffer是OpenGL 的一个对象，用于存放渲染过的图像，有时候renderBuffer会作为
//一个color buffer被引用，因为本质上他就是存放用于显示的颜色
/*
 1.调用glGenRenderBuffers来创建一个新的render buffer object，这里返回唯一的integer来标记renderbuffer (这里把这个唯一值赋值到_colorRenderBuffer).有时候你会发现这个唯一值被用来作为程序内的一个OpenGL 名称(因为它是唯一的)
 2.调用glBindRenderbuffer,告诉这个OpenGL:我在后面引用GL_RENDERBUFFER 的地方，其实是想用_colorRenderBuffer.其实就是OpenGL,我们定义的buffer对象是属于哪一种OenGL对象
 3.最后，为render buffer分配空间，renderbufferStorege
 */


-(void)setRenderBuffer{
    
    glGenRenderbuffers(1,&_colorRenderBuffer);//创建OpenGL
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
}

//创建一个frame buffer(帧缓冲区域)
/*
 frame buffer也是OpenG的对象，它包含了前面所提到的render buffer，以及后面会讲到的depth buffer stebcil buffer 和 accumulatoin buffer.
 前两步创建frame buffer的动作跟创建render buffer的动作很类似。
 而最后一步glFramebufferRenderbuffer 这个才有新意，他会把前面创建的buffer render 依附在frame buffer的GL_COLOR_ATTACHMENT0位置上。
 */
- (void)setupFrameBuffer
{
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}
//- (void)setupFrameBuffer {
//    GLuint framebuffer;
//    glGenFramebuffers(1, &framebuffer);
//    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
//                              GL_RENDERBUFFER, _colorRenderBuffer);
//}

/*
 为了在屏幕上尽快显示什么，在我们，和那些vertexes，shaders打交道之前，把屏幕清理一下，显示另一种颜色 黑色，下面解析每一个动作
 1.调用glClearColor,设置一个RGB颜色和透明度，接下来会用这个颜色涂满全屏
 2.调用glClear来进行这个"填色"的动作这里我们要用到GL_COlOR_BUFFER_BIT 来声明要清理哪一个缓冲区
 3.调用OpenGL context的prensentbuffer方法，把缓冲区(render buffer 和 color buffer)的颜色呈现在UIView上
 */
- (void)render{
    glClearColor(0, 104/255.0, 55/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}


/*注意这个会在glsl文件的注释中出现*/
//添加shaders(顶点着色器和片段着色器)，在场景渲染任何一种几何图形，都要创建两个称之为"着色器"的小程序。
//着色器由一个类似c的语言编写GLSL.
//这个世界有两种着色器(Shader):
/*
 1.Vertex shaders - 在你的场景中，每个顶点都要调用的程序称之为顶点着色器，假设渲染一个简单地场景，一个长方形，每个角只有一个顶点。于是vertext shader会被调用四次，他负责执行诸如灯光，几何变换等等的计算，得出最终的顶点位置后，为下面的片段着色器提供必需的数据；
 2.Fragment shaders,片段着色器的责任是计算灯光，以及更重要的是计算出每个像素的最终颜色 - 在你的场景中，大概每个像素都会调用的程序，成为"片段着色器，在一个简单的场景，也是刚刚说到的长方形。这个长方形所覆盖到的每一个像素，都会调用一次fragment shader"
 */

/*
 1.attribute 声明了这个shader会接受一个传入变量，这个变量名为“Position”;
 在后面你会用它来传入顶点的位置数据，这个变量的类型是vec4，表示这是一个有四部分组成的矢量；
 2.SourceColor 与上面同理，这是传入的颜色
 3.DestinationColor 这个变量没有attribute关键字，表明他是一个传出变量，他就是会传入片段着色器的参数。“varying”关键字表示，依据顶点的颜色，平滑计算出顶点之间每个像素的颜色。
 图中的一个像素，它位于红色和绿色的顶点之间，准确地说，这是一个距离上面顶点55/100，距离下面顶点45/100的点。所以通过过渡，能确定这个像素的颜色。
 4 每个shader都从main开始跟C一样。
 5 设置目标颜色 = 传入变量：SourceColor
 6 gl_Position 是一个内建的传出变量。这是一个在 vertex shader中必须设置的变量。这里我们直接把gl_Position = Position; 没有做任何逻辑运算。
 
 
 一个简单的vertex shader 就是这样了，接下来我们再创建一个简单的fragment shader。
 

 
//FragmentShader
1.DestinationColor 这是从vertex shader中传入的变量，这里和vertex shader定义的一致。而额外加了一个关键字：lowp。在fragment shader中，必须给出一个计算的精度。出于性能考虑，总使用最低精度是一个好习惯。这里就是设置成最低的精度。如果你需要，也可以设置成medp或者highp.
 
2.也是从main开始
3.正如你在vertex shader中必须设置位置一样gl_Position，在fragment shader中必须设置颜色gl_FragColor；
 
这里也是直接从 vertex shader中取值，先不做任何改变。接下来我们开始运用这些shader来创建我们的app。
 */


//编译 Vertex shader 和 Fragment shader
/*
  到目前为止，Xcode仅仅会把这两个文件copy到application bundle中，我们还需要在运行时编译和运行这些shader
 ?问什么要在运行时编译代码?这样做的好处就是，我们着色器不依赖于某种图形芯片。(这样才可以跨平台)
 
 下面开始加载编译shader的代码

 */

- (GLuint)compileShader:(NSString *)shaderName withType:(GLuint)shaderType
{
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error = nil;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    GLuint shaderHandle = glCreateShader(shaderType);
    const char*shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLenth = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLenth);
    glCompileShader(shaderHandle);
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if(compileSuccess == GL_FALSE){
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    return shaderHandle;
}
/*
 解析：
 1 这是一个UIKit编程的标准用法，就是在NSBundle中查找某个文件。
 
 2 调用 glCreateShader来创建一个代表shader 的OpenGL对象。这时你必须告诉OpenGL，你想创建 fragment shader还是vertex shader。所以便有了这个参数：shaderType
 3 调用glShaderSource ，让OpenGL获取到这个shader的源代码。（就是我们写的那个）这里我们还把NSString转换成C-string
 4 最后，调用glCompileShader 在运行时编译shader
 5 debug，如果编译失败了，我们必须一些信息来找出问题原因。 glGetShaderiv 和 glGetShaderInfoLog 会把error信息输出到屏幕, 然后退出。
 我们还需要一些步骤来编译vertex shader 和frament shader。
 
 把它们俩关联起来
 
 告诉OpenGL来调用这个程序，还需要一些指针什么的。
 在compileShader: 方法下方，加入这些代码：
 
 */

- (void)compileShaders
{
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShaders = [self compileShader:@"" withType:GL_FRAGMENT_SHADER];
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShaders);
    glLinkProgram(programHandle);
    
    GLint linkSucceess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSucceess);
    if (linkSucceess == GL_FALSE) {
        GLchar message[256];
        glGetProgramInfoLog(programHandle, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"%@", messageString);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    //通过调用glGetUniformLocation来获取在vertex shader中的projection输入变量
    
    _projectionUniform = glGetUniformLocation(programHandle,"Projection");
    
    //用math libray来创建投影矩阵。通过这个让你制定坐标，以及远近屏位置方式，来创建矩阵，会让事情比较简单
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h = 4.0f * self.frame.size.height/self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
    //用来把数据传入到vertex shader的方式，叫做glUniformMatrix4fv。这个CC3GLMatrix类有一个很方便的方法，hlMaxtrix，来吧矩阵转换成OpenGL的array的格式
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    [modelView populateFromTranslation:CC3VectorMake(sin(CACurrentMediaTime()), 0, - 7)];
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    

    
}


/*
 1 用来调用你刚刚写的动态编译方法，分别编译了vertex shader 和 fragment shader
 2 调用了glCreateProgram glAttachShader glLinkProgram 连接 vertex 和 fragment shader成一个完整的program。
 3 调用 glGetProgramiv lglGetProgramInfoLog 来检查是否有error，并输出信息。
 4 调用 glUseProgram 让OpenGL真正执行你的program
 
 5 最后，调用 glGetAttribLocation 来获取指向 vertex shader传入变量的指针。以后就可以通过这写指针来使用了。还有调用 glEnableVertexAttribArray来启用这些数据。（因为默认是 disabled的。）
 */



@end
