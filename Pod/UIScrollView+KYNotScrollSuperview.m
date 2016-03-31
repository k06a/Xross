//
//  UIScrollView+KYNotScrollSuperview.m
//  Pods
//
//  Created by Anton Bukov on 26.01.16.
//
//

#import <libextobjc/extobjc.h>
#import <JRSwizzle/JRSwizzle.h>
#import <UAObfuscatedString/UAObfuscatedString.h>

#import "UIScrollView+KYNotScrollSuperview.h"

static NSString *selectorOfInterest() {
    return NSMutableString.string._.a.t.t.e.m.p.t.T.o.D.r.a.g.P.a.r.e.n.t.colon.f.o.r.N.e.w.B.o.u.n.d.s.colon.o.l.d.B.o.u.n.d.s.colon;
}

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
    [self jr_swizzleMethod:NSSelectorFromString(selectorOfInterest())
                withMethod:@selector(xxx_selectorOfInterest:newBounds:oldBounds:)
                     error:NULL];
}

- (void)xxx_selectorOfInterest:(UIScrollView *)arg1 newBounds:(CGRect)arg2 oldBounds:(CGRect)arg3 {
    if (!self.ky_notScrollSuperview && !arg1.ky_notScrollableBySubviews) {
        [self xxx_selectorOfInterest:arg1 newBounds:arg2 oldBounds:arg3];
    }
}

@end
