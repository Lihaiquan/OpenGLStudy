//
//  AppDelegate.h
//  OpenGLStudy
//
//  Created by 名策 on 2017/3/1.
//  Copyright © 2017年 名策. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

