//
//  UIScrollView+KYStickyKeyboard.m
//  Pods
//
//  Created by Anton Bukov on 26.01.16.
//
//

#import <libextobjc/extobjc.h>
#import <KVOController/FBKVOController.h>
#import <NCController/MLWNCController.h>
#import "UIResponder+KYCurrentFirstResponder.h"
#import "UIScrollView+KYStickyKeyboard.h"

@interface UIScrollView (KYStickyKeyboard_Private)

@property (strong, nonatomic) MLWNCController *ky_ncController;
@property (strong, nonatomic) FBKVOController *ky_kvoController;

@end

@implementation UIScrollView (KYStickyKeyboard_Private)

@synthesizeAssociation(UIScrollView, ky_ncController);
@synthesizeAssociation(UIScrollView, ky_kvoController);

@end

//

@implementation UIScrollView (KYStickyKeyboard)

- (BOOL)ky_stickyKeyboard {
    return (self.ky_ncController || self.ky_kvoController);
}

- (void)setKy_stickyKeyboard:(BOOL)ky_stickyKeyboard {
    if (!ky_stickyKeyboard) {
        self.ky_ncController = nil;
        self.ky_kvoController = nil;
        return;
    }
    
    self.ky_ncController = [[MLWNCController alloc] init];
    [self.ky_ncController addObserverForName:UIKeyboardDidHideNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if ([NSStringFromClass(window.class) isEqualToString:@"UIRemoteKeyboardWindow"] ||
                [NSStringFromClass(window.class) isEqualToString:@"UITextEffectsWindow"])
            {
                window.clipsToBounds = YES;
                window.transform = CGAffineTransformIdentity;
            }
        }
    }];
    
    @weakify(self);
    self.ky_kvoController = [FBKVOController controllerWithObserver:self];
    [self.ky_kvoController observe:self keyPath:@keypath(self.contentOffset) options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        @strongify(self);
        UIView *responder = [UIResponder ky_currentFirstResponder];
        while (responder && [responder isKindOfClass:[UIView class]] && responder.window != self.window) {
            responder = (id)[responder nextResponder];
        }
        
        if ([responder isKindOfClass:[UIView class]]) {
            CGPoint p = [self convertPoint:CGPointZero fromView:responder];
            CGFloat k = CGPointEqualToPoint(self.contentOffset, CGPointZero) ? 0.0 : 1.0;
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-self.contentOffset.x*k + floor(p.x/self.frame.size.width)*self.frame.size.width, -self.contentOffset.y*k + floor(p.y/self.frame.size.height)*self.frame.size.height);
            
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if ([NSStringFromClass(window.class) isEqualToString:@"UIRemoteKeyboardWindow"] ||
                    [NSStringFromClass(window.class) isEqualToString:@"UITextEffectsWindow"])
                {
                    window.clipsToBounds = YES;
                    window.transform = transform;
                }
            }
        }
    }];
}

@end
