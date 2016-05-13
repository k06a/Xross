//
//  UIScrollView+MLWSticMLWKeyboard.m
//  Pods
//
//  Created by Anton Bukov on 26.01.16.
//
//

#import <libextobjc/extobjc.h>

#import <KVOController/FBKVOController.h>
#import <NCController/MLWNCController.h>

#import "UIResponder+MLWCurrentFirstResponder.h"
#import "UIScrollView+MLWStickyKeyboard.h"

@interface UIScrollView (MLWSticMLWKeyboard_Private)

@property (strong, nonatomic) MLWNCController *mlw_ncController;
@property (strong, nonatomic) FBKVOController *mlw_kvoController;
@property (strong, nonatomic) NSNumber *mlw_keyboardVisibleObj;
@property (assign, nonatomic) BOOL mlw_keyboardVisible;

@end

@implementation UIScrollView (MLWSticMLWKeyboard_Private)

@synthesizeAssociation(UIScrollView, mlw_ncController);
@synthesizeAssociation(UIScrollView, mlw_kvoController);
@synthesizeAssociation(UIScrollView, mlw_keyboardVisibleObj);

- (BOOL)mlw_keyboardVisible {
    return self.mlw_keyboardVisibleObj.boolValue;
}

- (void)setMlw_keyboardVisible:(BOOL)mlw_keyboardVisible {
    self.mlw_keyboardVisibleObj = @(mlw_keyboardVisible);
}

@end

//

@implementation UIScrollView (MLWStickyKeyboard)

- (BOOL)mlw_stickyKeyboard {
    return (self.mlw_ncController || self.mlw_kvoController);
}

- (void)setMlw_stickyKeyboard:(BOOL)mlw_stickyKeyboard {
    if (!mlw_stickyKeyboard) {
        self.mlw_ncController = nil;
        self.mlw_kvoController = nil;
        return;
    }

    @weakify(self);
    self.mlw_ncController = [[MLWNCController alloc] init];
    [self.mlw_ncController addObserverForName:UIKeyboardDidHideNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *_Nonnull note) {
        @strongify(self);
        if (!self) {
            return;
        }

        self.mlw_keyboardVisible = NO;
        [self applyTransformToKeyboardWindows:CGAffineTransformIdentity];
    }];

    [self.mlw_ncController addObserverForName:UIKeyboardDidShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *_Nonnull note) {
        @strongify(self);
        if (!self) {
            return;
        }

        self.mlw_keyboardVisible = YES;
    }];

    self.mlw_kvoController = [FBKVOController controllerWithObserver:self];
    [self.mlw_kvoController observe:self keyPath:@keypath(self.contentOffset) options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        @strongify(self);
        if (!self) {
            return;
        }

        UIView *viewResponder = nil;
        UIResponder *responder = [UIResponder mlw_currentFirstResponder];
        if (responder == nil) {
            if (!self.mlw_keyboardVisible) {
                [self applyTransformToKeyboardWindows:CGAffineTransformIdentity];
            }
            return;
        }
        while (responder) {
            if ([responder isKindOfClass:[UIView class]] && [(UIView *)responder window] == self.window) {
                viewResponder = (UIView *)responder;
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
