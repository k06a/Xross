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

static CGPoint MLWPointDirectionMake(NSInteger x, NSInteger y) {
    return (!x && !y) ? CGPointZero : CGPointMake(
        ABS(y) <  ABS(x) ? (x > 0 ? 1 : -1) : 0,
        ABS(y) >= ABS(x) ? (y > 0 ? 1 : -1) : 0);
}

static CGPoint MLWScrollViewBouncingDirectionForContentOffset(UIScrollView *scrollView, CGPoint contentOffset) {
    CGFloat topOffset = contentOffset.y + scrollView.contentInset.top;
    CGFloat leftOffset = contentOffset.x + scrollView.contentInset.left;
    CGFloat bottomOffset = contentOffset.y + CGRectGetHeight(scrollView.bounds)
                         - scrollView.contentInset.bottom - scrollView.contentSize.height;
    CGFloat rightOffset = contentOffset.x + CGRectGetWidth(scrollView.bounds)
                        - scrollView.contentInset.right - scrollView.contentSize.width;
    return MLWPointDirectionMake((leftOffset < 0 ? -1 : 0) + (rightOffset  > 0 ? 1 : 0),
                                 (topOffset  < 0 ? -1 : 0) + (bottomOffset > 0 ? 1 : 0));
}

static CGPoint MLWScrollViewBouncingDirection(UIScrollView *scrollView) {
    return MLWScrollViewBouncingDirectionForContentOffset(scrollView, scrollView.contentOffset);
}

static BOOL MLWScrollViewIsBouncing(UIScrollView *scrollView) {
    return CGPointEqualToPoint(MLWScrollViewBouncingDirection(scrollView), CGPointZero);
}

//

@interface UIScrollView () <UIGestureRecognizerDelegate>

@end

//

@interface MLWXrossScrollView ()

@property (assign, nonatomic) BOOL delegateRespondsToScrollViewWillScrollToContentOffset;
@property (assign, nonatomic) BOOL avoidInnerScrollViewRecursiveCall;

@end

@implementation MLWXrossScrollView

@dynamic delegate;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.mlw_stickyKeyboard = YES;
        //self.mlw_notScrollableBySubviews = YES;
        
        _originOffset = CGPointZero;
    }
    return self;
}

- (void)setDelegate:(id<MLWXrossScrollViewDelegate>)delegate {
    self.delegateRespondsToScrollViewWillScrollToContentOffset = [delegate respondsToSelector:@selector(scrollView:willScrollToContentOffset:)];
    [super setDelegate:delegate];
}

- (void)setContentOffset:(CGPoint)contentOffset {
    if (self.avoidInnerScrollViewRecursiveCall) {
        [super setContentOffset:contentOffset];
        return;
    }
    
    // Fix inner bounce deceleration starts to scrolls xross
    if (CGPointEqualToPoint(self.contentOffset, CGPointZero) &&
        self.mlw_isInsideAttemptToDragParent &&
        self.mlw_isInsideAttemptToDragParent.isDecelerating) {
        return;
    }
    
    CGPoint selfBounceDirection = MLWScrollViewBouncingDirectionForContentOffset(self, contentOffset);
    CGPoint innerBounceDirection = self.mlw_isInsideAttemptToDragParent ? MLWScrollViewBouncingDirection(self.mlw_isInsideAttemptToDragParent) : CGPointZero;
    if (CGPointEqualToPoint(self.contentOffset, CGPointZero) &&
        !CGPointEqualToPoint(innerBounceDirection, CGPointZero) &&
        !CGPointEqualToPoint(selfBounceDirection, innerBounceDirection)) {
        return;
    }

    if (self.delegateRespondsToScrollViewWillScrollToContentOffset &&
        !CGPointEqualToPoint(contentOffset, self.contentOffset)) {
        self.avoidInnerScrollViewRecursiveCall = YES;
        contentOffset = [self.delegate scrollView:self willScrollToContentOffset:contentOffset];
        self.avoidInnerScrollViewRecursiveCall = NO;
    }

    [super setContentOffset:contentOffset];
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
    CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
    UIView *viewAtPoint = [gestureRecognizer.view hitTest:point withEvent:nil];

    // Avoid xross movement by UISlider
    if ([viewAtPoint isKindOfClass:[UISlider class]]) {
        return NO;
    }
    
    if ([[MLWXrossScrollView superclass] instancesRespondToSelector:_cmd]) {
        return [super gestureRecognizerShouldBegin:gestureRecognizer];
    }

    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Allow simultaneous non-scroll pan gesture recognizers
    return (self.panGestureRecognizer == otherGestureRecognizer) ||
           (self.panGestureRecognizer == gestureRecognizer &&
            [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
            ![otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]);
}

@end
