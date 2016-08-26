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

static CGFloat kScrollDampling = 0.4;

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

@interface MLWXrossViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) UIViewController *nextViewController;
@property (assign, nonatomic) MLWXrossDirection nextViewControllerDirection;
@property (readonly, nonatomic) MLWXrossScrollView *mlwScrollView;
@property (assign, nonatomic) BOOL scrollViewDidScrollInCall;
@property (strong, nonatomic) NSDate *allowMoveToNextAfter;
@property (assign, nonatomic) UIEdgeInsets needEdgeInsets;
@property (assign, nonatomic) BOOL allowedToApplyInset;
@property (assign, nonatomic) BOOL prevAllowedToApplyInset;
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

    self.allowMoveToNextAfter = [NSDate dateWithTimeIntervalSinceNow:0.3];
    self.scrollView.contentOffset = CGPointZero;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        self.scrollView.contentOffset = CGPointZero;
    }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            self.scrollView.contentOffset = CGPointZero;
        }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [UIView performWithoutAnimation:^{
        self.viewController.view.frame = (CGRect){CGPointZero, self.scrollView.frame.size};
        self.nextViewController.view.frame = CGRectOffset(
            self.viewController.view.frame,
            self.nextViewControllerDirection.x * self.scrollView.frame.size.width,
            self.nextViewControllerDirection.y * self.scrollView.frame.size.height);
        self.scrollView.contentSize = self.scrollView.frame.size;
        self.needEdgeInsets = UIEdgeInsetsMake(
            (self.nextViewControllerDirection.y < 0 && self.allowedToApplyInset) ? self.scrollView.frame.size.height : 1,
            (self.nextViewControllerDirection.x < 0 && self.allowedToApplyInset) ? self.scrollView.frame.size.width : 1,
            (self.nextViewControllerDirection.y > 0 && self.allowedToApplyInset) ? self.scrollView.frame.size.height : 1,
            (self.nextViewControllerDirection.x > 0 && self.allowedToApplyInset) ? self.scrollView.frame.size.width : 1);
        [self updateInsets];
    }];
}

- (void)loadView {
    self.view = [[MLWXrossScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.directionalLockEnabled = YES;
    self.scrollView.bounces = YES;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.delegate = self;
    self.scrollView.scrollEnabled = YES;
    self.scrollView.scrollsToTop = NO;
    self.needEdgeInsets = UIEdgeInsetsMake(1, 1, 1, 1);
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
        self.viewController.view.frame = self.scrollView.bounds;
        [self.viewController didMoveToParentViewController:self];
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width,
                                                 self.scrollView.frame.size.height);
        if ([self.delegate respondsToSelector:@selector(xross:didMoveToDirection:)]) {
            [self.delegate xross:self didMoveToDirection:MLWXrossDirectionNone];
        }
    }
}

- (void)moveToDirection:(MLWXrossDirection)direction {
    [self moveToDirection:direction completion:nil];
}

- (void)moveToDirection:(MLWXrossDirection)direction completion:(void (^)())completion {
    self.completionBlock = completion;
    self.view.userInteractionEnabled = NO;
    self.scrollView.contentOffset = CGPointMake(direction.x, direction.y);
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.viewController beginAppearanceTransition:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.viewController endAppearanceTransition];
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

    if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)] && self.nextViewController) {
        [self.delegate xross:self didScrollToDirection:direction progress:progress];
    }

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

    // Remove viewController or nextViewController not visible by current scrolling
    if (!CGRectIntersectsRect(self.viewController.view.frame, self.scrollView.bounds) ||
        (self.nextViewController && !CGRectIntersectsRect(self.nextViewController.view.frame, self.scrollView.bounds))) {
        if (!CGRectIntersectsRect(self.viewController.view.frame, self.scrollView.bounds)) {
            // Swap VCs
            UIViewController *tmpView = self.viewController;
            self.viewController = self.nextViewController;
            self.nextViewController = tmpView;
            [UIView animateWithDuration:0.25 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
        }
        else {
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
            self.needEdgeInsets = UIEdgeInsetsMake(1, 1, 1, 1);
            [self updateInsets];
            self.viewController.view.frame = self.scrollView.bounds;
        }];
        [self.viewController becomeFirstResponder];
        if (!MLWXrossDirectionIsNone(direction)) {
            [self.viewController endAppearanceTransition];
        }

        self.nextViewController = nil;
        self.nextViewControllerDirection = MLWXrossDirectionNone;

        if (!self.view.userInteractionEnabled) {
            self.view.userInteractionEnabled = YES;
        }
        if ([self.delegate respondsToSelector:@selector(xross:didMoveToDirection:)]) {
            [self.delegate xross:self didMoveToDirection:direction];
        }
        if ([self.delegate respondsToSelector:@selector(xross:removedViewController:)]) {
            [self.delegate xross:self removedViewController:self.nextViewController];
        }
        if (self.completionBlock) {
            self.completionBlock();
            self.completionBlock = nil;
        }

        self.mlwScrollView.skipLayoutSubviewCalls = NO;

        if (!(self.supportedInterfaceOrientations & (1 << [UIApplication sharedApplication].statusBarOrientation))) {
            NSArray<NSNumber *> *orientations = @[
                @(UIInterfaceOrientationMaskPortrait),
                @(UIInterfaceOrientationMaskLandscapeLeft),
                @(UIInterfaceOrientationMaskLandscapeRight),
                @(UIInterfaceOrientationMaskPortraitUpsideDown)
            ];
            for (NSNumber *orientation in orientations) {
                if (orientation.unsignedIntegerValue & self.supportedInterfaceOrientations) {
                    [[UIDevice currentDevice] setValue:orientation forKey:@"orientation"];
                    break;
                }
            }
        }
        return;
    }

    // Add nextViewController if possible for known direction
    if (self.nextViewController == nil && !MLWXrossDirectionEquals(direction, MLWXrossDirectionNone)) {
        if ([[NSDate date] compare:self.allowMoveToNextAfter] == NSOrderedDescending) {
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
                self.allowMoveToNextAfter = [NSDate dateWithTimeIntervalSinceNow:0.2];
                [self.mlwScrollView setContentOffsetTo:CGPointZero animated:NO];
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
            self.nextViewController.view.frame = self.scrollView.bounds;
            [self.nextViewController.view layoutIfNeeded];
        }];

        if (self.viewController == nil && MLWXrossDirectionIsNone(direction)) {
            if ([self.delegate respondsToSelector:@selector(xross:didMoveToDirection:)]) {
                [self.delegate xross:self didMoveToDirection:direction];
            }
        }

        [self.scrollView layoutIfNeeded];
        self.mlwScrollView.skipLayoutSubviewCalls = YES;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.mlwScrollView.contentOffset = CGPointZero;
}

@end
