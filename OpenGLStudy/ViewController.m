//
//  ViewController.m
//  OpenGLStudy
//
//  Created by 名策 on 2017/3/1.
//  Copyright © 2017年 名策. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLView.h"

@interface ViewController ()

@property(nonatomic,strong)OpenGLView *openGlView;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.openGlView = [[OpenGLView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:self.openGlView];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
