//
//  MLWXrossScrollView.m
//  Xross
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <JRSwizzle/JRSwizzle.h>
#import "UIResponder+MLWCurrentFirstResponder.h"
#import "UIScrollView+MLWNotScrollSuperview.h"
#import "UIScrollView+MLWStickyKeyboard.h"
#import "MLWXrossScrollView.h"

@interface UIScrollView () <UIGestureRecognizerDelegate>

@end

//

@interface MLWXrossScrollView ()

@end

@implementation MLWXrossScrollView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.mlw_stickyKeyboard = YES;
        self.mlw_notScrollableBySubviews = YES;
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
    
    if ([[MLWXrossScrollView superclass] instancesRespondToSelector:@selector(gestureRecognizer:shouldRequireFailureOfGestureRecognizer:)]) {
        return [super gestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
    }
    return NO;
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    UIView *gestureRecognizerView = [gestureRecognizer.view hitTest:[gestureRecognizer locationInView:gestureRecognizer.view] withEvent:nil];
    NSUInteger panGestureIndex = [gestureRecognizerView.gestureRecognizers indexOfObjectPassingTest:^BOOL(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj isKindOfClass:[UIPanGestureRecognizer class]];
    }];
    
    if ([gestureRecognizerView isKindOfClass:[UIControl class]] && panGestureIndex != NSNotFound) {
        return NO;
    }
    
    return YES;
}

- (void)layoutSubviews {
    if (!self.skipLayoutSubviewCalls) {
        [super layoutSubviews];
    }
}

@end
