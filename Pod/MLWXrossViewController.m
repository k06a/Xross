//
//  XrossViewController.m
//  XrossScreens
//
//  Created by Anton Bukov on 24.11.15.
//  Copyright © 2015 Searchie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libextobjc/extobjc.h>

#import "MLWXrossScrollView.h"
#import "MLWXrossViewController.h"

//

static CGFloat const kScrollDampling = 0.4;
static UIEdgeInsets const kDefaultEdgeInsets = (UIEdgeInsets){1, 1, 1, 1};

MLWXrossDirection MLWXrossDirectionNone = (MLWXrossDirection){0, 0};
MLWXrossDirection MLWXrossDirectionTop = (MLWXrossDirection){0, -1};
MLWXrossDirection MLWXrossDirectionBottom = (MLWXrossDirection){0, 1};
MLWXrossDirection MLWXrossDirectionLeft = (MLWXrossDirection){-1, 0};
MLWXrossDirection MLWXrossDirectionRight = (MLWXrossDirection){1, 0};

MLWXrossDirection MLWXrossDirectionMake(NSInteger x, NSInteger y) {
    return (MLWXrossDirection){x ? x / ABS(x) : 0, y ? y / ABS(y) : 0};
}

MLWXrossDirection MLWXrossDirectionFromOffset(CGPoint offset) {
    return MLWXrossDirectionMake(offset.x, offset.y);
}

BOOL MLWXrossDirectionIsNone(MLWXrossDirection direction) {
    return direction.x == 0 && direction.y == 0;
}

BOOL MLWXrossDirectionIsHorizontal(MLWXrossDirection direction) {
    return direction.x != 0 && direction.y == 0;
}

BOOL MLWXrossDirectionIsVertical(MLWXrossDirection direction) {
    return direction.x == 0 && direction.y != 0;
}

BOOL MLWXrossDirectionEquals(MLWXrossDirection direction, MLWXrossDirection direction2) {
    return direction.x == direction2.x && direction.y == direction2.y;
}

static void ViewSetFrameWithoutRelayoutIfPossible(UIView *view, CGRect frame) {
    CGRect bounds = (CGRect){view.bounds.origin, frame.size};
    if (!CGRectEqualToRect(view.bounds, bounds)) {
        view.bounds = bounds;
    }
    view.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
}

//

@interface MLWXrossViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) UIViewController *nextViewController;
@property (assign, nonatomic) MLWXrossDirection nextViewControllerDirection;
@property (readonly, nonatomic) MLWXrossScrollView *mlwScrollView;
@property (assign, nonatomic) BOOL scrollViewDidScrollInCall;
@property (strong, nonatomic) NSDate *denyMovementUntilDate;
@property (assign, nonatomic) UIEdgeInsets needEdgeInsets;
@property (assign, nonatomic) BOOL allowedToApplyInset;
@property (assign, nonatomic) BOOL prevAllowedToApplyInset;
@property (assign, nonatomic) MLWXrossDirection prevDirection;
@property (copy, nonatomic) void (^completionBlock)();

@end

@implementation MLWXrossViewController

// KVO Dependent Keys
+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    MLWXrossViewController *this = nil;
    return @{
        @keypath(this.isMoving) : [NSSet setWithArray:@[ @keypath(this.nextViewController) ]],
        @keypath(this.isMovingDisabled) : [NSSet setWithArray:@[ @keypath(this.scrollView.scrollEnabled) ]],
    }[key]
               ?: [super keyPathsForValuesAffectingValueForKey:key];
}

- (BOOL)isMoving {
    return self.nextViewController ||
           self.scrollView.isDragging ||
           self.scrollView.isDecelerating;
}

- (BOOL)isMovingDisabled {
    return !self.scrollView.scrollEnabled;
}

- (void)setMovingDisabled:(BOOL)movingDisabled {
    self.scrollView.scrollEnabled = !movingDisabled;
}

- (BOOL)denyHorizontalMovement {
    return self.denyLeftMovement && self.denyRightMovement;
}

- (void)setDenyHorizontalMovement:(BOOL)denyHorizontalMovement {
    self.denyLeftMovement = denyHorizontalMovement;
    self.denyRightMovement = denyHorizontalMovement;
}

- (BOOL)denyVerticalMovement {
    return self.denyTopMovement && self.denyBottomMovement;
}

- (void)setDenyVerticalMovement:(BOOL)denyVerticalMovement {
    self.denyTopMovement = denyVerticalMovement;
    self.denyBottomMovement = denyVerticalMovement;
}

- (void)setDenyTopMovement:(BOOL)denyTopMovement {
    _denyTopMovement = denyTopMovement;
    [self updateInsets];
}

- (void)setDenyBottomMovement:(BOOL)denyBottomMovement {
    _denyBottomMovement = denyBottomMovement;
    [self updateInsets];
}

- (void)setDenyLeftMovement:(BOOL)denyLeftMovement {
    _denyLeftMovement = denyLeftMovement;
    [self updateInsets];
}

- (void)setDenyRightMovement:(BOOL)denyRightMovement {
    _denyRightMovement = denyRightMovement;
    [self updateInsets];
}

- (void)updateInsets {
    self.scrollView.contentInset = UIEdgeInsetsMake(
        self.denyTopMovement ? 0 : self.needEdgeInsets.top,
        self.denyLeftMovement ? 0 : self.needEdgeInsets.left,
        self.denyBottomMovement ? 0 : self.needEdgeInsets.bottom,
        self.denyRightMovement ? 0 : self.needEdgeInsets.right);

    if (!self.prevAllowedToApplyInset && self.allowedToApplyInset) {
        CGFloat sign = (self.nextViewControllerDirection.x < 0 || self.nextViewControllerDirection.y < 0) ? -1 : 1;
        self.viewController.view.center = CGPointMake(
            self.viewController.view.center.x + self.scrollView.contentOffset.x * (1 - kScrollDampling) * sign,
            self.viewController.view.center.y + self.scrollView.contentOffset.y * (1 - kScrollDampling) * sign);
        self.nextViewController.view.center = CGPointMake(
            self.nextViewController.view.center.x + self.scrollView.contentOffset.x * (1 - kScrollDampling) * sign,
            self.nextViewController.view.center.y + self.scrollView.contentOffset.y * (1 - kScrollDampling) * sign);
        [UIView animateWithDuration:0.4 delay:0.0 options:(UIViewAnimationOptionCurveEaseInOut) animations:^{
            self.viewController.view.center = CGPointMake(
                self.viewController.view.center.x - self.scrollView.contentOffset.x * (1 - kScrollDampling) * sign,
                self.viewController.view.center.y - self.scrollView.contentOffset.y * (1 - kScrollDampling) * sign);
            self.nextViewController.view.center = CGPointMake(
                self.nextViewController.view.center.x - self.scrollView.contentOffset.x * (1 - kScrollDampling) * sign,
                self.nextViewController.view.center.y - self.scrollView.contentOffset.y * (1 - kScrollDampling) * sign);
        }
                         completion:nil];
    }
    self.prevAllowedToApplyInset = self.allowedToApplyInset;
}

- (UIScrollView *)scrollView {
    return (UIScrollView *)self.view;
}

- (MLWXrossScrollView *)mlwScrollView {
    return (MLWXrossScrollView *)self.view;
}

- (BOOL)prefersStatusBarHidden {
    return self.viewController
               ? [self.viewController prefersStatusBarHidden]
               : [super prefersStatusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.viewController
               ? [self.viewController preferredStatusBarStyle]
               : [super preferredStatusBarStyle];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.viewController
               ? [self.viewController supportedInterfaceOrientations]
               : [super supportedInterfaceOrientations];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];

    self.denyMovementUntilDate = [NSDate dateWithTimeIntervalSinceNow:0.3];
    self.scrollView.contentOffset = CGPointZero;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        self.scrollView.contentOffset = CGPointZero;
    }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            self.scrollView.contentOffset = CGPointZero;
        }];
}

+ (Class)xrossViewClass {
    return [MLWXrossScrollView class];
}

- (void)loadView {
    self.view = [[[self.class xrossViewClass] alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.directionalLockEnabled = YES;
    self.scrollView.bounces = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.delegate = self;
    self.scrollView.scrollEnabled = YES;
    self.scrollView.scrollsToTop = NO;
    self.needEdgeInsets = kDefaultEdgeInsets;
    [self updateInsets];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self reloadData];
}

- (void)setDataSource:(id<MLWXrossViewControllerDataSource>)dataSource {
    _dataSource = dataSource;
    [self reloadData];
}

- (void)reloadData {
    if (self.viewController) {
        UIViewController *removedViewController = self.viewController;
        [self.viewController willMoveToParentViewController:nil];
        [self.viewController.view removeFromSuperview];
        [self.viewController removeFromParentViewController];
        self.viewController = nil;

        if (removedViewController) {
            if ([self.delegate respondsToSelector:@selector(xross:removedViewController:)]) {
                [self.delegate xross:self removedViewController:removedViewController];
            }
        }
    }

    self.viewController = [self.dataSource xross:self viewControllerForDirection:MLWXrossDirectionNone];
    if (self.viewController) {
        [self addChildViewController:self.viewController];
        if (self.viewController.view.backgroundColor == nil) { // Fixed bug with broken scrolling
            self.viewController.view.backgroundColor = [UIColor whiteColor];
        }
        [self.scrollView addSubview:self.viewController.view];
        self.viewController.view.clipsToBounds = YES;
        ViewSetFrameWithoutRelayoutIfPossible(self.viewController.view, (CGRect){CGPointZero, self.scrollView.bounds.size});
        [self.viewController didMoveToParentViewController:self];
        if ([self.delegate respondsToSelector:@selector(xross:didMoveToDirection:)]) {
            [self.delegate xross:self didMoveToDirection:MLWXrossDirectionNone];
        }
    }
}

- (void)moveToDirection:(MLWXrossDirection)direction {
    [self moveToDirection:direction completion:nil];
}

- (void)moveToDirection:(MLWXrossDirection)direction completion:(void (^)())completion {
    self.scrollView.contentOffset = CGPointMake(direction.x, direction.y);
    NSAssert(self.nextViewController, @"self.nextViewController should not be nil, check your xross:viewControllerForDirection: implementation");
    if (!self.nextViewController) {
        if (completion) {
            completion();
        }
        return;
    }
    
    self.completionBlock = completion;
    self.view.userInteractionEnabled = NO;
    [self.mlwScrollView setContentOffsetTo:CGPointMake(direction.x * self.scrollView.frame.size.width, direction.y * self.scrollView.frame.size.height) animated:YES];
}

#pragma mark - View

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.viewController beginAppearanceTransition:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.viewController endAppearanceTransition];
    [self fixStatusBarOrientationIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.viewController beginAppearanceTransition:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.viewController endAppearanceTransition];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (!CGSizeEqualToSize(self.scrollView.contentSize, self.scrollView.bounds.size)) {
        [UIView performWithoutAnimation:^{
            self.scrollView.contentSize = self.scrollView.bounds.size;
        }];
    }

    if (!self.mlwScrollView.skipLayoutSubviewCalls) {
        [UIView performWithoutAnimation:^{
            CGRect viewControllerFrame = (CGRect){CGPointZero, self.scrollView.frame.size};
            ViewSetFrameWithoutRelayoutIfPossible(self.viewController.view, viewControllerFrame);
            CGRect frame = CGRectOffset(
                viewControllerFrame,
                self.nextViewControllerDirection.x * CGRectGetWidth(self.scrollView.bounds),
                self.nextViewControllerDirection.y * CGRectGetHeight(self.scrollView.bounds));
            ViewSetFrameWithoutRelayoutIfPossible(self.nextViewController.view, frame);
        }];
    }

    if (self.allowedToApplyInset &&
        self.scrollView.contentInset.left <= kDefaultEdgeInsets.left &&
        self.scrollView.contentInset.right <= kDefaultEdgeInsets.right &&
        self.scrollView.contentInset.top <= kDefaultEdgeInsets.top &&
        self.scrollView.contentInset.bottom <= kDefaultEdgeInsets.bottom) {
        [UIView performWithoutAnimation:^{
            self.needEdgeInsets = UIEdgeInsetsMake(
                (self.nextViewControllerDirection.y < 0) ? CGRectGetHeight(self.scrollView.bounds) : kDefaultEdgeInsets.top,
                (self.nextViewControllerDirection.x < 0) ? CGRectGetWidth(self.scrollView.bounds) : kDefaultEdgeInsets.left,
                (self.nextViewControllerDirection.y > 0) ? CGRectGetHeight(self.scrollView.bounds) : kDefaultEdgeInsets.bottom,
                (self.nextViewControllerDirection.x > 0) ? CGRectGetWidth(self.scrollView.bounds) : kDefaultEdgeInsets.right);
            [self updateInsets];
        }];
    }
}

- (void)fixStatusBarOrientationIfNeeded {
    if (!(self.supportedInterfaceOrientations & (1 << [UIApplication sharedApplication].statusBarOrientation))) {
        NSArray<NSNumber *> *orientations = @[
            @(UIInterfaceOrientationMaskPortrait),
            @(UIInterfaceOrientationMaskLandscapeLeft),
            @(UIInterfaceOrientationMaskLandscapeRight),
            @(UIInterfaceOrientationMaskPortraitUpsideDown)
        ];
        for (NSNumber *orientation in orientations) {
            if (orientation.unsignedIntegerValue & self.supportedInterfaceOrientations) {
                [[UIDevice currentDevice] setValue:orientation forKey:@keypath([UIDevice currentDevice], orientation)];
                break;
            }
        }
    }
}

#pragma mark - Scroll View

// Avoid recursive calls of scrollViewDidScroll
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.scrollViewDidScrollInCall) {
        self.scrollViewDidScrollInCall = YES;
        [self scrollViewDidScrollNotRecursive:scrollView];
        self.scrollViewDidScrollInCall = NO;
    }
}

// Avoid diagonal scrolling
- (void)scrollViewDidScrollNotRecursive:(UIScrollView *)scrollView {
    scrollView.contentOffset = CGPointMake(
        (ABS(scrollView.contentOffset.y) > ABS(scrollView.contentOffset.x)) ? 0 : scrollView.contentOffset.x,
        (ABS(scrollView.contentOffset.x) > ABS(scrollView.contentOffset.y)) ? 0 : scrollView.contentOffset.y);

    [self scrollViewDidScrollNotRecursiveNotDiagonal:scrollView];
}

- (void)scrollViewDidScrollNotRecursiveNotDiagonal:(UIScrollView *)scrollView {
    MLWXrossDirection direction = MLWXrossDirectionMake(
        (ABS(scrollView.contentOffset.x) < FLT_EPSILON) ? 0 : scrollView.contentOffset.x / ABS(scrollView.contentOffset.x),
        (ABS(scrollView.contentOffset.y) < FLT_EPSILON) ? 0 : scrollView.contentOffset.y / ABS(scrollView.contentOffset.y));

    CGFloat progress = MIN(1, MAX(0, MLWXrossDirectionIsHorizontal(direction) ? ABS(self.scrollView.contentOffset.x) / self.scrollView.frame.size.width : ABS(self.scrollView.contentOffset.y) / self.scrollView.frame.size.height));

    if (self.scrollView.isDragging && [self.delegate respondsToSelector:@selector(xross:shouldApplyInsetToDirection:progress:)]) {
        if (!self.nextViewController) {
            self.allowedToApplyInset = NO;
        }
        if (!self.allowedToApplyInset) {
            self.allowedToApplyInset = [self.delegate xross:self shouldApplyInsetToDirection:direction progress:progress];
        }
    }
    else {
        self.allowedToApplyInset = YES;
    }
    self.scrollView.bounces = !self.allowedToApplyInset;

    BOOL returnedBack = (self.nextViewController &&
                         ((self.scrollView.contentInset.left > 1 && self.scrollView.contentOffset.x >= 0) ||
                          (self.scrollView.contentInset.right > 1 && self.scrollView.contentOffset.x <= 0) ||
                          (self.scrollView.contentInset.top > 1 && self.scrollView.contentOffset.y >= 0) ||
                          (self.scrollView.contentInset.bottom > 1 && self.scrollView.contentOffset.y <= 0)));

    BOOL willRemoveVC = ABS(self.scrollView.contentOffset.x) >= CGRectGetWidth(self.scrollView.bounds) ||
    ABS(self.scrollView.contentOffset.y) >= CGRectGetHeight(self.scrollView.bounds) ||
    returnedBack;
    
    BOOL willAddVC = self.nextViewController == nil && !MLWXrossDirectionEquals(direction, MLWXrossDirectionNone);
    
    // Remove viewController or nextViewController not visible by current scrolling
    if (willRemoveVC) {
        if (!returnedBack) {
            if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)]) {
                [self.delegate xross:self didScrollToDirection:self.prevDirection progress:1.0];
            }

            if (self.nextViewController == nil) {
                return;
            }
            
            // Swap VCs
            UIViewController *tmpView = self.viewController;
            self.viewController = self.nextViewController;
            self.nextViewController = tmpView;
            [UIView animateWithDuration:0.25 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
        }
        else {
            if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)]) {
                [self.delegate xross:self didScrollToDirection:self.prevDirection progress:0.0];
            }

            direction = MLWXrossDirectionNone;
            [self.viewController beginAppearanceTransition:YES animated:NO];
            [self.viewController endAppearanceTransition];
            [self.nextViewController beginAppearanceTransition:NO animated:NO];
            [self.nextViewController endAppearanceTransition];
        }

        // Remove VC
        [self.nextViewController willMoveToParentViewController:nil];
        [self.nextViewController.view removeFromSuperview];
        [self.nextViewController removeFromParentViewController];
        [self.nextViewController resignFirstResponder];
        if (!MLWXrossDirectionIsNone(direction)) {
            [self.nextViewController endAppearanceTransition];
        }

        // Center VC
        [UIView performWithoutAnimation:^{
            self.scrollView.contentOffset = CGPointZero;
            self.needEdgeInsets = kDefaultEdgeInsets;
            [self updateInsets];
            ViewSetFrameWithoutRelayoutIfPossible(self.viewController.view, self.scrollView.bounds);
        }];
        [self.viewController becomeFirstResponder];
        if (!MLWXrossDirectionIsNone(direction)) {
            [self.viewController endAppearanceTransition];
        }

        UIViewController *prevNextViewController = self.nextViewController;
        self.nextViewController = nil;
        self.nextViewControllerDirection = MLWXrossDirectionNone;

        if (!self.view.userInteractionEnabled) {
            self.view.userInteractionEnabled = YES;
        }
        if ([self.delegate respondsToSelector:@selector(xross:didMoveToDirection:)]) {
            [self.delegate xross:self didMoveToDirection:direction];
        }
        if ([self.delegate respondsToSelector:@selector(xross:removedViewController:)]) {
            [self.delegate xross:self removedViewController:prevNextViewController];
        }
        if (self.completionBlock) {
            self.completionBlock();
            self.completionBlock = nil;
        }

        self.mlwScrollView.skipLayoutSubviewCalls = NO;

        [self fixStatusBarOrientationIfNeeded];
    }
    else if (willAddVC) { // Add nextViewController if possible for known direction
        if (self.denyMovementUntilDate == nil ||
            [[NSDate date] compare:self.denyMovementUntilDate] == NSOrderedDescending) {
            self.nextViewController = [self.dataSource xross:self viewControllerForDirection:direction];
            if (self.nextViewController) {
                self.nextViewControllerDirection = direction;
            }
        }
        if (self.nextViewController == nil) {
            BOOL bounces = self.bounces;
            if ([self.delegate respondsToSelector:@selector(xross:shouldBounceToDirection:)]) {
                bounces = [self.delegate xross:self shouldBounceToDirection:direction];
            }
            if (!bounces) {
                [self.scrollView setContentOffset:CGPointZero animated:NO];
                self.scrollView.scrollEnabled = NO;
                self.scrollView.scrollEnabled = YES;
                if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)]) {
                    [self.delegate xross:self didScrollToDirection:direction progress:0.0];
                }
            }
            else {
                self.scrollView.bounces = YES;
                if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)]) {
                    [self.delegate xross:self didScrollToDirection:direction progress:progress];
                }
            }
            return;
        }
        [self.viewController beginAppearanceTransition:NO animated:YES];
        [self.nextViewController beginAppearanceTransition:YES animated:YES];
        [self addChildViewController:self.nextViewController];
        if (self.nextViewController.view.backgroundColor == nil) { // Fixed bug with broken scrolling
            self.nextViewController.view.backgroundColor = [UIColor whiteColor];
        }
        [self.scrollView addSubview:self.nextViewController.view];
        self.nextViewController.view.clipsToBounds = YES;
        [self.nextViewController didMoveToParentViewController:self];
        [UIView performWithoutAnimation:^{
            CGRect nextFrame = CGRectOffset(
                (CGRect){CGPointZero, self.scrollView.bounds.size},
                self.nextViewControllerDirection.x * CGRectGetWidth(self.scrollView.bounds),
                self.nextViewControllerDirection.y * CGRectGetHeight(self.scrollView.bounds));
            ViewSetFrameWithoutRelayoutIfPossible(self.nextViewController.view, nextFrame);
        }];

        if (self.viewController == nil && MLWXrossDirectionIsNone(direction)) {
            if ([self.delegate respondsToSelector:@selector(xross:didMoveToDirection:)]) {
                [self.delegate xross:self didMoveToDirection:direction];
            }
        }

        [self.scrollView layoutIfNeeded];
        self.mlwScrollView.skipLayoutSubviewCalls = YES;
        if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)]) {
            [self.delegate xross:self didScrollToDirection:direction progress:progress];
        }
    }
    else {
        if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)]) {
            [self.delegate xross:self didScrollToDirection:direction progress:progress];
        }
    }
    
    self.prevDirection = direction;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.scrollView.bounces = NO;
    CGFloat width = CGRectGetWidth(self.scrollView.bounds);
    CGFloat height = CGRectGetHeight(self.scrollView.bounds);
    self.mlwScrollView.contentOffset = CGPointMake(
        round(self.mlwScrollView.contentOffset.x / width) * width,
        round(self.mlwScrollView.contentOffset.y / height) * height);
}

@end
