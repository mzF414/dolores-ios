//
// Created by Heath on 23/06/2017.
// Copyright (c) 2017 Dolores. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLBaseViewController.h"


@interface DLChildOrganizationController : DLBaseViewController

@property (nonatomic, copy) NSString *departmentId;

- (instancetype)initWithDepartmentId:(NSString *)departmentId;

@end