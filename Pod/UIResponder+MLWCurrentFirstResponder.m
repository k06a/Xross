//
//  UIResponder+MLWCurrentFirstResponder.m
//  Xross
//
//  Created by Anton Bukov on 26.01.16.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import "UIResponder+MLWCurrentFirstResponder.h"

static __weak id currentFirstResponder_private;

@implementation UIResponder (MLWCurrentFirstResponder)

+ (__kindof UIResponder *)mlw_currentFirstResponder {
    currentFirstResponder_private = nil;
    [[UIApplication sharedApplication] sendAction:@selector(mlw_findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder_private;
}

- (void)mlw_findFirstResponder:(id)sender {
    currentFirstResponder_private = self;
}

@end
