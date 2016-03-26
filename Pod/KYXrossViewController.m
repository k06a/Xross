//
//  XrossViewController.m
//  XrossScreens
//
//  Created by Anton Bukov on 24.11.15.
//  Copyright © 2015 Searchie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KYXrossScrollView.h"
#import "KYXrossViewController.h"

KYXrossDirection KYXrossDirectionNone   = (KYXrossDirection){0,0};
KYXrossDirection KYXrossDirectionTop    = (KYXrossDirection){0,-1};
KYXrossDirection KYXrossDirectionBottom = (KYXrossDirection){0,1};
KYXrossDirection KYXrossDirectionLeft   = (KYXrossDirection){-1,0};
KYXrossDirection KYXrossDirectionRight  = (KYXrossDirection){1,0};


KYXrossDirection KYXrossDirectionMake(NSInteger x, NSInteger y) {
    return (KYXrossDirection){x ? x/ABS(x) : 0, y ? y/ABS(y) : 0};
}

KYXrossDirection KYXrossDirectionFromOffset(CGPoint offset) {
    return KYXrossDirectionMake(offset.x, offset.y);
}

BOOL KYXrossDirectionIsNone(KYXrossDirection direction) {
    return direction.x == 0 && direction.y == 0;
}

BOOL KYXrossDirectionIsHorizontal(KYXrossDirection direction) {
    return direction.x != 0 && direction.y == 0;
}

BOOL KYXrossDirectionIsVertical(KYXrossDirection direction) {
    return direction.x == 0 && direction.y != 0;
}

BOOL KYXrossDirectionEquals(KYXrossDirection direction, KYXrossDirection direction2) {
    return direction.x == direction2.x && direction.y == direction2.y;
}


@interface KYXrossViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) UIViewController *nextViewController;
@property (strong, nonatomic) UIViewController *nextViewControllerToBe;
@property (assign, nonatomic) KYXrossDirection nextViewControllerDirection;
@property (readonly, nonatomic) KYXrossScrollView *kyScrollView;
@property (assign, nonatomic) BOOL scrollViewDidScrollInCall;
@property (strong, nonatomic) NSDate *allowMoveToNextAfter;
@property (assign, nonatomic) UIEdgeInsets needEdgeInsets;

@end


@implementation KYXrossViewController

// KVO Dependent Keys
+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    return [[super keyPathsForValuesAffectingValueForKey:key] setByAddingObjectsFromArray:@{
        NSStringFromSelector(@selector(isMoving)) : @[ NSStringFromSelector(@selector(nextViewController)) ],
        NSStringFromSelector(@selector(isMovingDisabled)) : @[ @"scrollView.scrollEnabled" ],
    }[key] ?: @[]];
}

- (BOOL)isMoving {
    return (self.nextViewController != nil);
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
        self.denyTopMovement    ? 0 : self.needEdgeInsets.top,
        self.denyLeftMovement   ? 0 : self.needEdgeInsets.left,
        self.denyBottomMovement ? 0 : self.needEdgeInsets.bottom,
        self.denyRightMovement  ? 0 : self.needEdgeInsets.right
    );
}

- (UIScrollView *)scrollView {
    return (UIScrollView *)self.view;
}

- (KYXrossScrollView *)kyScrollView {
    return (KYXrossScrollView *)self.view;
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
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.scrollView.contentOffset = CGPointZero;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.scrollView.contentOffset = CGPointZero;
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.viewController.view.frame = (CGRect){CGPointZero, self.scrollView.frame.size};
    self.nextViewController.view.frame = CGRectOffset(
        self.viewController.view.frame,
        self.nextViewControllerDirection.x * self.scrollView.frame.size.width,
        self.nextViewControllerDirection.y * self.scrollView.frame.size.height);

    self.scrollView.contentSize = self.scrollView.frame.size;
    self.needEdgeInsets = UIEdgeInsetsMake(
        (self.nextViewControllerDirection.y < 0) ? self.scrollView.frame.size.height : 1,
        (self.nextViewControllerDirection.x < 0)  ? self.scrollView.frame.size.width  : 1,
        (self.nextViewControllerDirection.y > 0) ? self.scrollView.frame.size.height : 1,
        (self.nextViewControllerDirection.x > 0)  ? self.scrollView.frame.size.width  : 1);
    [self updateInsets];
}

- (void)loadView {
    self.view = [[KYXrossScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
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

- (void)setDataSource:(id<KYXrossViewControllerDataSource>)dataSource {
    _dataSource = dataSource;
    [self reloadData];
}

- (void)reloadData {
    if (self.viewController) {
        [self.viewController willMoveToParentViewController:nil];
        [self.viewController.view removeFromSuperview];
        [self.viewController removeFromParentViewController];
        self.viewController = nil;
    }

    self.viewController = [self.dataSource xross:self viewControllerForDirection:KYXrossDirectionNone];
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
            [self.delegate xross:self didMoveToDirection:KYXrossDirectionNone];
        }
    }
}

- (void)moveToDirection:(KYXrossDirection)direction {
    [self moveToDirection:direction controller:nil];
}

- (void)moveToDirection:(KYXrossDirection)direction controller:(UIViewController *)controller {
    self.nextViewControllerToBe = controller;
    self.scrollView.contentOffset = CGPointMake(direction.x, direction.y);
    [self.kyScrollView setContentOffsetTo:CGPointMake(direction.x * self.scrollView.frame.size.width, direction.y * self.scrollView.frame.size.height) animated:YES];
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
    KYXrossDirection direction = KYXrossDirectionMake(
        (ABS(scrollView.contentOffset.x) < FLT_EPSILON) ? 0 : scrollView.contentOffset.x / ABS(scrollView.contentOffset.x),
        (ABS(scrollView.contentOffset.y) < FLT_EPSILON) ? 0 : scrollView.contentOffset.y / ABS(scrollView.contentOffset.y));
    
    if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)] &&
        (self.nextViewController || self.nextViewControllerToBe))
    {
        CGFloat progress = KYXrossDirectionIsHorizontal(direction) ? ABS(self.scrollView.contentOffset.x)/self.scrollView.frame.size.width : ABS(self.scrollView.contentOffset.y)/self.scrollView.frame.size.height;
        progress = MIN(MAX(0, progress), 1);
        [self.delegate xross:self didScrollToDirection:direction progress:progress];
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
            direction = KYXrossDirectionNone;
        }

        // Remove VC
        [self.nextViewController willMoveToParentViewController:nil];
        [self.nextViewController.view removeFromSuperview];
        [self.nextViewController removeFromParentViewController];
        [self.nextViewController resignFirstResponder];

        // Center VC
        self.scrollView.contentOffset = CGPointZero;
        self.needEdgeInsets = UIEdgeInsetsMake(1, 1, 1, 1);
        [self updateInsets];
        self.viewController.view.frame = self.scrollView.bounds;
        [self.viewController becomeFirstResponder];

        if ([self.delegate respondsToSelector:@selector(xross:didMoveToDirection:)]) {
            [self.delegate xross:self didMoveToDirection:direction];
        }
        if ([self.delegate respondsToSelector:@selector(xross:removedViewController:)]) {
            [self.delegate xross:self removedViewController:self.nextViewController];
        }

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

        self.nextViewController = nil;
        self.nextViewControllerDirection = KYXrossDirectionNone;
        return;
    }

    // Add nextViewController if possible for known direction
    if (self.nextViewController == nil && !KYXrossDirectionEquals(direction, KYXrossDirectionNone)) {
        if ([[NSDate date] compare:self.allowMoveToNextAfter] == NSOrderedDescending) {
            self.nextViewController = self.nextViewControllerToBe ?: [self.dataSource xross:self viewControllerForDirection:direction];
            self.nextViewControllerToBe = nil;
            if (self.nextViewController) {
                self.nextViewControllerDirection = direction;
            }
        }
        if (self.nextViewController == nil) {
            BOOL bounces = self.bounces;
            if ([self.delegate respondsToSelector:@selector(xross:allowBounceToDirection:)]) {
                bounces = [self.delegate xross:self allowBounceToDirection:direction];
            }
            if (!bounces) {
                self.allowMoveToNextAfter = [NSDate dateWithTimeIntervalSinceNow:0.2];
                [self.kyScrollView setContentOffsetTo:CGPointZero animated:NO];
            }
            return;
        }
        [self addChildViewController:self.nextViewController];
        if (self.nextViewController.view.backgroundColor == nil) { // Fixed bug with broken scrolling
            self.nextViewController.view.backgroundColor = [UIColor whiteColor];
        }
        [self.scrollView addSubview:self.nextViewController.view];
        self.nextViewController.view.clipsToBounds = YES;
        [self.nextViewController didMoveToParentViewController:self];

        if (self.viewController == nil && KYXrossDirectionIsNone(direction)) {
            if ([self.delegate respondsToSelector:@selector(xross:didMoveToDirection:)]) {
                [self.delegate xross:self didMoveToDirection:direction];
            }
        }
        
        [self.scrollView layoutIfNeeded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.kyScrollView.contentOffset = CGPointZero;
}

@end
