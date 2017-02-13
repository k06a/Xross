//
//  UIScrollView+MLWNotScrollSuperview.m
//  Xross
//
//  Created by Anton Bukov on 26.01.16.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <JRSwizzle/JRSwizzle.h>
#import <UAObfuscatedString/UAObfuscatedString.h>
#import <libextobjc/extobjc.h>

#import "UIScrollView+MLWNotScrollSuperview.h"

static NSString *selectorOfInterest() {
    return NSMutableString.string.underscore.a.t.t.e.m.p.t.T.o.D.r.a.g.P.a.r.e.n.t.colon.f.o.r.N.e.w.B.o.u.n.d.s.colon.o.l.d.B.o.u.n.d.s.colon;
}

//

@interface UIScrollView (MLWNotScrollSuperview_Private)

@property (strong, nonatomic) NSNumber *mlw_notScrollSuperview_obj;
@property (strong, nonatomic) NSNumber *mlw_notScrollableBySubviews_obj;
@property (strong, nonatomic) UIScrollView *mlw_isInsideAttemptToDragParent_obj;

@end

@implementation UIScrollView (MLWNotScrollSuperview_Private)

@synthesizeAssociation(UIScrollView, mlw_notScrollSuperview_obj);
@synthesizeAssociation(UIScrollView, mlw_notScrollableBySubviews_obj);
@synthesizeAssociation(UIScrollView, mlw_isInsideAttemptToDragParent_obj);

@end

//

@implementation UIScrollView (KYNotScrollSuperview)

- (BOOL)mlw_notScrollSuperview {
    return self.mlw_notScrollSuperview_obj.boolValue;
}

- (void)setMlw_notScrollSuperview:(BOOL)mlw_notScrollSuperview {
    self.mlw_notScrollSuperview_obj = @(mlw_notScrollSuperview);
}

- (BOOL)mlw_notScrollableBySubviews {
    return self.mlw_notScrollableBySubviews_obj.boolValue;
}

- (void)setMlw_notScrollableBySubviews:(BOOL)mlw_notScrollableBySubviews {
    self.mlw_notScrollableBySubviews_obj = @(mlw_notScrollableBySubviews);
}

- (UIScrollView *)mlw_isInsideAttemptToDragParent {
    return self.mlw_isInsideAttemptToDragParent_obj;
}

+ (void)load {
    assert([self jr_swizzleMethod:NSSelectorFromString(selectorOfInterest())
                       withMethod:@selector(xxx_selectorOfInterest:newBounds:oldBounds:)
                            error:NULL]);
}

- (void)xxx_selectorOfInterest:(UIScrollView *)arg1 newBounds:(CGRect)arg2 oldBounds:(CGRect)arg3 {
    if (!self.mlw_notScrollSuperview && !arg1.mlw_notScrollableBySubviews) {
        arg1.mlw_isInsideAttemptToDragParent_obj = self;
        [self xxx_selectorOfInterest:arg1 newBounds:arg2 oldBounds:arg3];
        arg1.mlw_isInsideAttemptToDragParent_obj = nil;
    }
}

@end
