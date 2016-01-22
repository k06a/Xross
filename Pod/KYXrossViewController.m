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

KYXrossViewControllerDirection KYXrossViewControllerDirectionNone   = (CGSize){0,0};
KYXrossViewControllerDirection KYXrossViewControllerDirectionTop    = (CGSize){0,-1};
KYXrossViewControllerDirection KYXrossViewControllerDirectionBottom = (CGSize){0,1};
KYXrossViewControllerDirection KYXrossViewControllerDirectionLeft   = (CGSize){-1,0};
KYXrossViewControllerDirection KYXrossViewControllerDirectionRight  = (CGSize){1,0};


KYXrossViewControllerDirection KYXrossViewControllerDirectionMake(NSInteger dx, NSInteger dy) {
    return CGSizeMake(dx ? dx/ABS(dx) : 0, dy ? dy/ABS(dy) : 0);
}

KYXrossViewControllerDirection KYXrossViewControllerDirectionFromOffset(CGPoint offset) {
    return KYXrossViewControllerDirectionMake(offset.x, offset.y);
}

BOOL KYXrossViewControllerDirectionIsNone(KYXrossViewControllerDirection direction) {
    return direction.width == 0 && direction.height == 0;
}

BOOL KYXrossViewControllerDirectionIsHorizontal(KYXrossViewControllerDirection direction) {
    return direction.width != 0 && direction.height == 0;
}

BOOL KYXrossViewControllerDirectionIsVertical(KYXrossViewControllerDirection direction) {
    return direction.width == 0 && direction.height != 0;
}

BOOL KYXrossViewControllerDirectionEquals(KYXrossViewControllerDirection direction, KYXrossViewControllerDirection direction2) {
    return CGSizeEqualToSize(direction, direction2);
}


@interface KYXrossViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) UIViewController *nextViewController;
@property (strong, nonatomic) UIViewController *nextViewControllerToBe;
@property (assign, nonatomic) KYXrossViewControllerDirection nextViewControllerDirection;
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
    
    self.kyScrollView.contentOffsetTo = CGPointZero;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.kyScrollView.contentOffsetTo = CGPointZero;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.kyScrollView.contentOffsetTo = CGPointZero;
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.viewController.view.frame = (CGRect){CGPointZero, self.scrollView.frame.size};
    self.nextViewController.view.frame = CGRectOffset(
        self.viewController.view.frame,
        self.nextViewControllerDirection.width * self.scrollView.frame.size.width,
        self.nextViewControllerDirection.height * self.scrollView.frame.size.height);

    self.scrollView.contentSize = self.scrollView.frame.size;
    self.needEdgeInsets = UIEdgeInsetsMake(
        (self.nextViewControllerDirection.height < 0) ? self.scrollView.frame.size.height : 1,
        (self.nextViewControllerDirection.width < 0)  ? self.scrollView.frame.size.width  : 1,
        (self.nextViewControllerDirection.height > 0) ? self.scrollView.frame.size.height : 1,
        (self.nextViewControllerDirection.width > 0)  ? self.scrollView.frame.size.width  : 1);
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
        [self.viewController.view removeFromSuperview];
        [self.viewController removeFromParentViewController];
        [self.viewController didMoveToParentViewController:nil];
        self.viewController = nil;
    }

    self.viewController = [self.dataSource xross:self viewControllerForDirection:KYXrossViewControllerDirectionNone];
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
    }
}

- (void)moveToDirection:(KYXrossViewControllerDirection)direction {
    [self moveToDirection:direction controller:nil];
}

- (void)moveToDirection:(KYXrossViewControllerDirection)direction controller:(UIViewController *)controller {
    self.nextViewControllerToBe = controller;
    self.kyScrollView.contentOffsetTo = CGPointMake(direction.width, direction.height);
    [self.kyScrollView setContentOffsetTo:CGPointMake(direction.width * self.scrollView.frame.size.width, direction.height * self.scrollView.frame.size.height) animated:YES];
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
    self.kyScrollView.contentOffsetTo = CGPointMake(
        (ABS(scrollView.contentOffset.y) > ABS(scrollView.contentOffset.x)) ? 0 : scrollView.contentOffset.x,
        (ABS(scrollView.contentOffset.x) > ABS(scrollView.contentOffset.y)) ? 0 : scrollView.contentOffset.y);

    [self scrollViewDidScrollNotRecursiveNotDiagonal:scrollView];
}

- (void)scrollViewDidScrollNotRecursiveNotDiagonal:(UIScrollView *)scrollView {
    KYXrossViewControllerDirection direction = KYXrossViewControllerDirectionMake(
        (ABS(scrollView.contentOffset.x) < FLT_EPSILON) ? 0 : scrollView.contentOffset.x / ABS(scrollView.contentOffset.x),
        (ABS(scrollView.contentOffset.y) < FLT_EPSILON) ? 0 : scrollView.contentOffset.y / ABS(scrollView.contentOffset.y));
    
    if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)]) {
        CGFloat progress = KYXrossViewControllerDirectionIsHorizontal(direction) ? ABS(self.scrollView.contentOffset.x)/self.scrollView.frame.size.width : ABS(self.scrollView.contentOffset.y)/self.scrollView.frame.size.height;
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
            direction = KYXrossViewControllerDirectionNone;
        }

        // Remove VC
        [self.nextViewController.view removeFromSuperview];
        [self.nextViewController removeFromParentViewController];
        [self.nextViewController didMoveToParentViewController:nil];
        [self.nextViewController resignFirstResponder];

        // Center VC
        self.kyScrollView.contentOffsetTo = CGPointZero;
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
        self.nextViewControllerDirection = KYXrossViewControllerDirectionNone;
        return;
    }

    // Add nextViewController if possible for known direction
    if (self.nextViewController == nil && !KYXrossViewControllerDirectionEquals(direction, KYXrossViewControllerDirectionNone)) {
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

        [self.scrollView layoutIfNeeded];
    }
}

@end
