//
//  UIResponder+KYCurrentFirstResponder.m
//  Pods
//
//  Created by Anton Bukov on 26.01.16.
//
//

#import "UIResponder+KYCurrentFirstResponder.h"

static __weak id currentFirstResponder_private;

@implementation UIResponder (KYCurrentFirstResponder)

+ (__kindof UIResponder *)ky_currentFirstResponder {
    currentFirstResponder_private = nil;
    [[UIApplication sharedApplication] sendAction:@selector(ky_findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder_private;
}

- (void)ky_findFirstResponder:(id)sender {
    currentFirstResponder_private = self;
}

@end
