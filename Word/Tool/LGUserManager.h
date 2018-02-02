//
//  LGUserManager.h
//  Word
//
//  Created by Charles Cao on 2018/1/27.
//  Copyright © 2018年 Charles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGUserModel.h"

#define UserDefaultKey @"userKey"

@interface LGUserManager : NSObject

@property (nonatomic, strong) LGUserModel *user;

+ (instancetype)shareManager;

//设置 cookie
+ (void)configCookie;

//清除 cookie
+ (void)cleanCookie;

- (BOOL)isLogin;

@end