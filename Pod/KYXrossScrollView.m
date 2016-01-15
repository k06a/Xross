//
//  KYXrossScrollView.m
//  South
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright © 2015 KupitYandex. All rights reserved.
//

#import "KYXrossScrollView.h"

static __weak id currentFirstResponder_private;

@implementation UIResponder (FirstResponder)

+ (id)currentFirstResponder {
    currentFirstResponder_private = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder_private;
}

- (void)findFirstResponder:(id)sender {
    currentFirstResponder_private = self;
}

@end

//

@interface UIScrollView () <UIGestureRecognizerDelegate>

@end

//

@interface KYXrossScrollView ()

@end

@implementation KYXrossScrollView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addObserver:self forKeyPath:@"contentOffset" options:(NSKeyValueObservingOptionNew) context:NULL];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"contentOffset"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    UIView *responder = [UIResponder currentFirstResponder];
    while (responder && responder.window != self.window) {
        responder = [responder nextResponder];
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
}

- (void)keyboardDidHide:(NSNotification *)note {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if ([NSStringFromClass(window.class) isEqualToString:@"UIRemoteKeyboardWindow"] ||
            [NSStringFromClass(window.class) isEqualToString:@"UITextEffectsWindow"])
        {
            window.clipsToBounds = YES;
            window.transform = CGAffineTransformIdentity;
        }
    }
}

// Avoid UITextField to scroll superview to become visible on becoming first responder
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    // Do nothing
}

- (void)setContentOffsetTo:(CGPoint)contentOffset animated:(BOOL)animated {
    [super setContentOffset:contentOffset animated:animated];
}

// Allows inner UITableView swipe-to-delete gesture
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view.superview isKindOfClass:[UITableView class]]) {
        return YES;
    }
    if ([[[self class] superclass] instancesRespondToSelector:@selector(gestureRecognizer:shouldRequireFailureOfGestureRecognizer:)]) {
        return [super gestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
    }
    return NO;
}

@end
