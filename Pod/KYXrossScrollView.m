//
//  KYXrossScrollView.m
//  South
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright © 2015 KupitYandex. All rights reserved.
//

#import <JRSwizzle/JRSwizzle.h>
#import "UIScrollView+KYStickyKeyboard.h"
#import "UIScrollView+KYNotScrollSuperview.h"
#import "UIResponder+KYCurrentFirstResponder.h"
#import "KYXrossScrollView.h"

@interface UIScrollView () <UIGestureRecognizerDelegate>

- (void)_attemptToDragParent:(id)arg1 forNewBounds:(CGRect)arg2 oldBounds:(CGRect)arg3;

@end

//

@interface KYXrossScrollView ()

@end

@implementation KYXrossScrollView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.ky_stickyKeyboard = YES;
        self.ky_notScrollableBySubviews = YES;
    }
    return self;
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
    if ([[KYXrossScrollView superclass] instancesRespondToSelector:@selector(gestureRecognizer:shouldRequireFailureOfGestureRecognizer:)]) {
        return [super gestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
    }
    return NO;
}

@end
