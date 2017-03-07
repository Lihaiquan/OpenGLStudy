//
//  OpenGLView.h
//  OpenGLStudy
//
//  Created by 名策 on 2017/3/1.
//  Copyright © 2017年 名策. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenGLView : UIView{
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;


}
@property (nonatomic ,strong)CAEAGLLayer *eaglLayer;
@property (nonatomic ,strong)EAGLContext *context;
@property (nonatomic ,assign)GLuint colorRenderBuffer;

@end
