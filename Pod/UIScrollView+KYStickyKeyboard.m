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
@property (strong, nonatomic) NSNumber *ky_keyboardVisibleObj;
@property (assign, nonatomic) BOOL ky_keyboardVisible;

@end

@implementation UIScrollView (KYStickyKeyboard_Private)

@synthesizeAssociation(UIScrollView, ky_ncController);
@synthesizeAssociation(UIScrollView, ky_kvoController);
@synthesizeAssociation(UIScrollView, ky_keyboardVisibleObj);

- (BOOL)ky_keyboardVisible {
    return self.ky_keyboardVisibleObj.boolValue;
}

- (void)setKy_keyboardVisible:(BOOL)ky_keyboardVisible {
    self.ky_keyboardVisibleObj = @(ky_keyboardVisible);
}

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

    @weakify(self);
    self.ky_ncController = [[MLWNCController alloc] init];
    [self.ky_ncController addObserverForName:UIKeyboardDidHideNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *_Nonnull note) {
        @strongify(self);
        if (!self) {
            return;
        }

        self.ky_keyboardVisible = NO;
        [self applyTransformToKeyboardWindows:CGAffineTransformIdentity];
    }];
    
    [self.ky_ncController addObserverForName:UIKeyboardDidShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *_Nonnull note) {
        @strongify(self);
        if (!self) {
            return;
        }
        
        self.ky_keyboardVisible = YES;
    }];

    self.ky_kvoController = [FBKVOController controllerWithObserver:self];
    [self.ky_kvoController observe:self keyPath:@keypath(self.contentOffset) options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        @strongify(self);
        if (!self) {
            return;
        }

        UIView *viewResponder = nil;
        UIResponder *responder = [UIResponder ky_currentFirstResponder];
        if (responder == nil) {
            if (!self.ky_keyboardVisible) {
                [self applyTransformToKeyboardWindows:CGAffineTransformIdentity];
            }
            return;
        }
        while (responder) {
            if ([responder isKindOfClass:[UIView class]] && [(UIView *)responder window] == self.window) {
                viewResponder = responder;
                break;
            }
            responder = [responder nextResponder];
        }

        if (viewResponder) {
            CGPoint p = [self convertPoint:CGPointZero fromView:viewResponder];
            CGFloat k = CGPointEqualToPoint(self.contentOffset, CGPointZero) ? 0.0 : 1.0;
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-self.contentOffset.x * k + floor(p.x / self.frame.size.width) * self.frame.size.width, -self.contentOffset.y * k + floor(p.y / self.frame.size.height) * self.frame.size.height);

            [self applyTransformToKeyboardWindows:transform];
        }
    }];
}

- (void)applyTransformToKeyboardWindows:(CGAffineTransform)transform {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if ([NSStringFromClass(window.class) isEqualToString:@"UIRemoteKeyboardWindow"] ||
            [NSStringFromClass(window.class) isEqualToString:@"UITextEffectsWindow"]) {
            window.clipsToBounds = YES;
            window.transform = transform;
        }
    }
}

@end
