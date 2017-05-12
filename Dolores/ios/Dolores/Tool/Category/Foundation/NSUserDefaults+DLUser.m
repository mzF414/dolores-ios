//
//  NSUserDefaults+DLUser.m
//  Dolores
//
//  Created by Heath on 19/04/2017.
//  Copyright © 2017 Dolores. All rights reserved.
//

#import "NSUserDefaults+DLUser.h"

static NSString *const kIsLogin = @"isLoginKey";
static NSString *const kLastLoginUser = @"lastLoginUserKey";


@implementation NSUserDefaults (DLUser)

#pragma mark - public method

+ (void)setLoginStatus:(BOOL)isLogin {
    [self saveObject:@(isLogin) key:kIsLogin];
}

+ (BOOL)getLoginStatus {
    NSNumber *status = [self getObjectWithKey:kIsLogin];
    return [status boolValue];
}

+ (void)saveLastUser:(NSString *)user {
    [self saveObject:user ? : @"" key:kLastLoginUser];
}

+ (NSString *)getLastUser {
    return [self getObjectWithKey:kLastLoginUser];
}

#pragma mark - private method

+ (void)saveObject:(id)obj key:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:obj forKey:key];
    [defaults synchronize];
}

+ (id)getObjectWithKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:key];
}

@end