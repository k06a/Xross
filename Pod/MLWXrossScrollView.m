//
//  MLWXrossScrollView.m
//  Xross
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <JRSwizzle/JRSwizzle.h>
#import <libextobjc/extobjc.h>

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

static void ViewSetFrameWithoutRelayoutIfPossible(UIView *view, CGRect frame) {
    CGRect bounds = (CGRect){view.bounds.origin, frame.size};
    if (!CGSizeEqualToSize(view.bounds.size, bounds.size)) {
        view.bounds = bounds;
        [view layoutIfNeeded];
    }
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    if (!CGPointEqualToPoint(view.center, center)) {
        view.center = center;
    }
}

//

@interface UIScrollView () <UIGestureRecognizerDelegate>

@end

//

@interface MLWXrossScrollView ()

@property (assign, nonatomic) BOOL delegateRespondsToScrollViewWillScrollToContentOffset;
@property (assign, nonatomic) BOOL avoidInnerScrollViewRecursiveCall;
@property (assign, nonatomic) BOOL skipSetContentOffsetCalls;

@end

@implementation MLWXrossScrollView

@dynamic delegate;

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    MLWXrossScrollView *this;
    return @{
        @keypath(this.originOffset):[NSSet setWithArray:@[
            @keypath(this.originOffsetInSteps),
            @keypath(this.bounds.size),
        ]],
        @keypath(this.relativeContentOffset):[NSSet setWithArray:@[
            @keypath(this.contentOffset),
            @keypath(this.originOffset),
        ]],
    }[key] ?: [super keyPathsForValuesAffectingValueForKey:key];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.mlw_stickyKeyboard = YES;
        //self.mlw_notScrollableBySubviews = YES;
        
        [self updateInsets];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateInsets];
    if (self.nextView == nil) {
        [super setContentOffset:self.originOffset];
        if (self.centerView) {
            CGRect frame = (CGRect){self.originOffset, self.bounds.size};
            ViewSetFrameWithoutRelayoutIfPossible(self.centerView, frame);
        }
    }
}

- (void)layoutSubviews {
    if (self.nextView == nil) {
        [super layoutSubviews];
    }
}

- (CGPoint)originOffset {
    return CGPointMake(self.originOffsetInSteps.x * CGRectGetWidth(self.bounds),
                       self.originOffsetInSteps.y * CGRectGetHeight(self.bounds));
}

- (CGPoint)relativeContentOffset {
    return CGPointMake(self.contentOffset.x - self.originOffset.x,
                       self.contentOffset.y - self.originOffset.y);
}

- (void)setOriginOffsetInSteps:(CGPoint)originOffsetInSteps {
    _originOffsetInSteps = originOffsetInSteps;
    [self updateInsets];
}

- (void)setNextDirection:(CGPoint)nextDirection {
    _nextDirection = nextDirection;
    [self updateInsets];
}

- (void)updateInsets {
    CGPoint savedContentOffset = self.contentOffset;
    
    self.skipSetContentOffsetCalls = YES;
    self.contentSize = self.bounds.size;
    self.contentInset = UIEdgeInsetsMake(
        ((self.nextDirection.y < 0) - self.originOffsetInSteps.y) * CGRectGetHeight(self.bounds) + 1,
        ((self.nextDirection.x < 0) - self.originOffsetInSteps.x) * CGRectGetWidth(self.bounds) + 1,
        ((self.nextDirection.y > 0) + self.originOffsetInSteps.y) * CGRectGetHeight(self.bounds) + 1,
        ((self.nextDirection.x > 0) + self.originOffsetInSteps.x) * CGRectGetWidth(self.bounds) + 1);
    self.skipSetContentOffsetCalls = NO;
    
    [super setContentOffset:savedContentOffset];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self updateInsets];
    self.contentOffset = self.originOffset;
}

- (void)setCenterView:(UIView *)centerView {
    if (centerView) {
        if (centerView.superview != self) {
            [centerView removeFromSuperview];
            [self addSubview:centerView];
        }
        CGRect frame = (CGRect){self.originOffset, self.bounds.size};
        ViewSetFrameWithoutRelayoutIfPossible(centerView, frame);
    }
    else {
        [_centerView removeFromSuperview];
    }
    
    _centerView = centerView;
}

- (void)setNextView:(UIView *)nextView {
    NSAssert(NO, @"Do not call this method directly, use -setNextView:toDirection:");
}

- (void)setNextView:(UIView *)nextView toDirection:(CGPoint)direction {
    if (nextView) {
        if (nextView.superview != self) {
            [nextView removeFromSuperview];
            [self addSubview:nextView];
        }
        NSAssert(self.centerView, @"centerView should exist when setting nextView");
        CGRect frame = (CGRect){self.originOffset, self.bounds.size};
        frame.origin.x += direction.x * CGRectGetWidth(self.bounds);
        frame.origin.y += direction.y * CGRectGetHeight(self.bounds);
        ViewSetFrameWithoutRelayoutIfPossible(nextView, frame);
    }
    else {
        [_nextView removeFromSuperview];
    }
    
    _nextView = nextView;
}

- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
    
    if (_centerView == subview) {
        _centerView = _nextView;
        _nextView = nil;
    }
    
    if (_nextView == subview) {
        _nextView = nil;
    }
}

- (void)setDelegate:(id<MLWXrossScrollViewDelegate>)delegate {
    self.delegateRespondsToScrollViewWillScrollToContentOffset = [delegate respondsToSelector:@selector(scrollView:willScrollToContentOffset:)];
    [super setDelegate:delegate];
}

- (void)setContentOffset:(CGPoint)contentOffset {
    //NSLog(@"contentOffset = %@", NSStringFromCGPoint(contentOffset));
    if (self.skipSetContentOffsetCalls) {
        return;
    }
    
    if (self.avoidInnerScrollViewRecursiveCall) {
        [super setContentOffset:contentOffset];
        return;
    }
    
    // Fix inner bounce deceleration starts to scrolls xross
    if (CGPointEqualToPoint(self.relativeContentOffset, CGPointZero) &&
        self.mlw_isInsideAttemptToDragParent &&
        self.mlw_isInsideAttemptToDragParent.isDecelerating) {
        return;
    }
    
    CGPoint selfBounceDirection = MLWScrollViewBouncingDirectionForContentOffset(self, contentOffset);
    CGPoint innerBounceDirection = self.mlw_isInsideAttemptToDragParent ? MLWScrollViewBouncingDirection(self.mlw_isInsideAttemptToDragParent) : CGPointZero;
    if (CGPointEqualToPoint(self.relativeContentOffset, CGPointZero) &&
        !CGPointEqualToPoint(innerBounceDirection, CGPointZero) &&
        !CGPointEqualToPoint(selfBounceDirection, innerBounceDirection)) {
        return;
    }

    self.avoidInnerScrollViewRecursiveCall = YES;
    {
        if (self.delegateRespondsToScrollViewWillScrollToContentOffset &&
            !CGPointEqualToPoint(contentOffset, self.contentOffset)) {
            contentOffset = [self.delegate scrollView:self willScrollToContentOffset:contentOffset];
        }
        [super setContentOffset:contentOffset];
    }
    self.avoidInnerScrollViewRecursiveCall = NO;
}

// Avoid UITextField to scroll superview to become visible on becoming first responder
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    // Do nothing
}

- (void)setContentOffsetTo:(CGPoint)contentOffset animated:(BOOL)animated {
    [super setContentOffset:contentOffset animated:animated];
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
