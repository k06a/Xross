//
//  UIScrollView+KYNotScrollSuperview.m
//  Pods
//
//  Created by Anton Bukov on 26.01.16.
//
//

#import <libextobjc/extobjc.h>
#import <JRSwizzle/JRSwizzle.h>
#import "UIScrollView+KYNotScrollSuperview.h"

@interface UIScrollView ()

- (void)_attemptToDragParent:(id)arg1 forNewBounds:(CGRect)arg2 oldBounds:(CGRect)arg3;

@end

//

@implementation UIScrollView (KYNotScrollSuperview)

@synthesizeAssociation(UIScrollView, ky_notScrollSuperview);
@synthesizeAssociation(UIScrollView, ky_notScrollableBySubviews);

+ (void)load {
    [self jr_swizzleMethod:@selector(_attemptToDragParent:forNewBounds:oldBounds:)
                withMethod:@selector(xxx_attemptToDragParent:forNewBounds:oldBounds:)
                     error:NULL];
}

- (void)xxx_attemptToDragParent:(UIScrollView *)arg1 forNewBounds:(CGRect)arg2 oldBounds:(CGRect)arg3 {
    if (!self.ky_notScrollSuperview && !arg1.ky_notScrollableBySubviews) {
        [self xxx_attemptToDragParent:arg1 forNewBounds:arg2 oldBounds:arg3];
    }
}

@end
