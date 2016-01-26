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

@interface UIScrollView (KYNotScrollSuperview_Private)

@property (strong, nonatomic) NSNumber *ky_notScrollSuperview_obj;
@property (strong, nonatomic) NSNumber *ky_notScrollableBySubviews_obj;

@end

@implementation UIScrollView (KYNotScrollSuperview_Private)

@synthesizeAssociation(UIScrollView, ky_notScrollSuperview_obj);
@synthesizeAssociation(UIScrollView, ky_notScrollableBySubviews_obj);

@end

//

@implementation UIScrollView (KYNotScrollSuperview)

- (BOOL)ky_notScrollSuperview {
    return self.ky_notScrollSuperview_obj.boolValue;
}

- (void)setKy_notScrollSuperview:(BOOL)ky_notScrollSuperview {
    self.ky_notScrollSuperview_obj = @(ky_notScrollSuperview);
}

- (BOOL)ky_notScrollableBySubviews {
    return self.ky_notScrollableBySubviews_obj.boolValue;
}

- (void)setKy_notScrollableBySubviews:(BOOL)ky_notScrollableBySubviews {
    self.ky_notScrollableBySubviews_obj = @(ky_notScrollableBySubviews);
}

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
