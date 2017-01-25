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

//

static BOOL MLWScrollViewIsBouncing(UIScrollView *scrollView) {
    CGFloat topOffset = scrollView.contentOffset.y + scrollView.contentInset.top;
    CGFloat bottomOffset = scrollView.contentOffset.y + CGRectGetHeight(scrollView.bounds) - scrollView.contentInset.bottom - scrollView.contentSize.height;
    return (topOffset < 0) || (bottomOffset > 0);
}

static CGPoint MLWPointDirectionMake(NSInteger x, NSInteger y) {
    return (!x && !y) ? CGPointZero : CGPointMake(
        ABS(y) <  ABS(x) ? (x > 0 ? 1 : -1) : 0,
        ABS(y) >= ABS(x) ? (y > 0 ? 1 : -1) : 0);
}

//

@interface UIScrollView () <UIGestureRecognizerDelegate>

@end

//

@interface MLWXrossScrollView ()

@property (weak, nonatomic) UIScrollView *innerScrollView;

@end

@implementation MLWXrossScrollView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.mlw_stickyKeyboard = YES;
        self.mlw_notScrollableBySubviews = YES;
    }
    return self;
}

- (void)handleOtherPanGesture:(UIPanGestureRecognizer *)otherGestureRecognizer {
    if (otherGestureRecognizer.state == UIGestureRecognizerStateBegan ||
        otherGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        if (self.innerScrollView == nil) {
            self.innerScrollView = (id)otherGestureRecognizer.view;
        }
    }
    
    if (otherGestureRecognizer.state == UIGestureRecognizerStateEnded ||
        otherGestureRecognizer.state == UIGestureRecognizerStateCancelled ||
        otherGestureRecognizer.state == UIGestureRecognizerStateFailed) {
        if (self.innerScrollView == otherGestureRecognizer.view) {
            self.innerScrollView = nil;
        }
        [otherGestureRecognizer removeTarget:self action:@selector(handleOtherPanGesture:)];
    }
}

- (BOOL)isAllowedToStartScrollingWithContentOffset:(CGPoint)contentOffset {
    CGPoint direction = MLWPointDirectionMake(contentOffset.x, contentOffset.y);
    CGPoint otherTranslation = [self.innerScrollView.panGestureRecognizer translationInView:self.innerScrollView];
    otherTranslation = CGPointApplyAffineTransform(otherTranslation, self.innerScrollView.transform);
    CGPoint otherDirection = MLWPointDirectionMake(-otherTranslation.x, -otherTranslation.y);
    CGPoint velocity = [self.innerScrollView.panGestureRecognizer velocityInView:self.innerScrollView];
    CGFloat speed = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2));
    CGFloat verticalSpeed = ABS(velocity.y);
    CGFloat horizontalSpeed = ABS(velocity.x);

    if (self.innerScrollView.window == nil) {
        return YES;
    }
    
    if (self.innerScrollView.panGestureRecognizer.state != UIGestureRecognizerStateBegan &&
        self.innerScrollView.panGestureRecognizer.state != UIGestureRecognizerStateChanged &&
        !self.innerScrollView.isDragging &&
        !self.innerScrollView.isDecelerating) {
        return YES;
    }
    
    if (!self.innerScrollView.isZooming &&
        CGPointEqualToPoint(direction, otherDirection) &&
        MLWScrollViewIsBouncing(self.innerScrollView) &&
        ((self.innerScrollView.isDragging && speed < 1000) ||
         self.innerScrollView.isDecelerating)) {
        return YES;
    }
    
    if (!self.innerScrollView.isZooming &&
        ABS(direction.x) != ABS(otherDirection.x) &&
        !CGPointEqualToPoint(self.contentOffset, CGPointZero)) {
        return YES;
    }
    
    //
    // Allow horizontal movement while inner vertical scrolling
    // Formula: |y| < |x| / 2
    //
    //      y^
    //  *\   |   /*
    //  **\  |  /**
    //  ***\ | /***
    //  ****\|/**** x
    // ------+------>
    //  ****/|\****
    //  ***/ | \***
    //  **/  |  \**
    //  */   |   \*
    //
    if (self.innerScrollView.contentSize.width == CGRectGetWidth(self.bounds) &&
        !self.innerScrollView.alwaysBounceHorizontal && verticalSpeed > 50) {
        
        if (verticalSpeed && horizontalSpeed) {
            return verticalSpeed < horizontalSpeed / 2;
        }

        // While vertical scrolling started trying to swipe horizontal gives zeros
        if (!verticalSpeed && !horizontalSpeed) {
            return YES;
        }
    }
    
    //
    // Allow vertical movement while inner horizaontal scrolling
    // Formula: |y| > |x| / 2
    //
    //      y^
    //   \***|***/
    //    \**|**/
    //     \*|*/
    //      \|/     x
    // ------+------>
    //      /|\
    //     /*|*\
    //    /**|**\
    //   /***|***\
    //
    if (self.innerScrollView.contentSize.height == CGRectGetHeight(self.bounds) &&
        !self.innerScrollView.alwaysBounceVertical && horizontalSpeed > 50) {
        
        if (verticalSpeed && horizontalSpeed) {
            return verticalSpeed > horizontalSpeed / 2;
        }
        
        // While vertical scrolling started trying to swipe horizontal gives zeros
        if (!verticalSpeed && !horizontalSpeed) {
            return YES;
        }
    }
    
    return NO;
}

- (void)setContentOffset:(CGPoint)contentOffset {
    if (CGPointEqualToPoint(contentOffset, self.contentOffset) ||
        !CGPointEqualToPoint(self.contentOffset, CGPointZero) ||
        [self isAllowedToStartScrollingWithContentOffset:contentOffset]) {
        [super setContentOffset:contentOffset];
    } else {
        if (self.panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
            [self.panGestureRecognizer setTranslation:CGPointZero inView:self];
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

- (void)layoutSubviews {
    if (!self.skipLayoutSubviewCalls) {
        [super layoutSubviews];
    }
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    
    // Allows inner UITableView swipe-to-delete gesture
    if ([otherGestureRecognizer.view.superview isKindOfClass:[UITableView class]]) {
        return YES;
    }
    
    if ([[MLWXrossScrollView superclass] instancesRespondToSelector:_cmd]) {
        return [super gestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
    }
    
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    UIView *gestureRecognizerView = [gestureRecognizer.view hitTest:[gestureRecognizer locationInView:gestureRecognizer.view] withEvent:nil];

    // Avoid xross movement by UISlider
    if ([gestureRecognizerView isKindOfClass:[UISlider class]]) {
        return NO;
    }
    
//    if ([[MLWXrossScrollView superclass] instancesRespondToSelector:_cmd]) {
//        return [super gestureRecognizerShouldBegin:gestureRecognizer];
//    }

    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]] &&
            [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            [otherGestureRecognizer addTarget:self action:@selector(handleOtherPanGesture:)];
        }
    
        return YES;
    }
    
    return NO;
}

@end
