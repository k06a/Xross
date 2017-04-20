//
//  XrossViewController.m
//  XrossScreens
//
//  Created by Anton Bukov on 24.11.15.
//  Copyright © 2015 Searchie. All rights reserved.
//

#import <UIKit/UIGestureRecognizerSubclass.h>

#import <libextobjc/extobjc.h>

#import "MLWXrossScrollView.h"
#import "MLWXrossViewController.h"
#import "MLWXrossTransition.h"
#import "MLWXrossTransitionCube.h"
#import "MLWXrossTransitionStack.h"
#import "MLWXrossTransitionFade.h"
#import "UIScrollView+MLWNotScrollSuperview.h"

//

MLWXrossDirection MLWXrossDirectionNone = (MLWXrossDirection){0, 0};
MLWXrossDirection MLWXrossDirectionTop = (MLWXrossDirection){0, -1};
MLWXrossDirection MLWXrossDirectionBottom = (MLWXrossDirection){0, 1};
MLWXrossDirection MLWXrossDirectionLeft = (MLWXrossDirection){-1, 0};
MLWXrossDirection MLWXrossDirectionRight = (MLWXrossDirection){1, 0};

MLWXrossDirection MLWXrossDirectionMake(CGFloat x, CGFloat y) {
    return (!x && !y) ? MLWXrossDirectionNone : (MLWXrossDirection){
        ABS(y) <  ABS(x) ? (x > 0 ? 1 : -1) : 0,
        ABS(y) >= ABS(x) ? (y > 0 ? 1 : -1) : 0
    };
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

//

static MLWXrossTransition *TransitionForTransitionType(MLWTransitionType transitionType, UIView *currentView, UIView *nextView, MLWXrossDirection direction) {
    switch (transitionType) {
        case MLWTransitionTypeDefault: {
            return nil;
        }
        case MLWTransitionTypeCube: {
            return [[MLWXrossTransitionCube alloc] initWithCurrentView:currentView nextView:nextView direction:direction];
        }
        case MLWTransitionTypeCubeFrom: {
            MLWXrossTransitionCube *transition = [[MLWXrossTransitionCube alloc] initWithCurrentView:currentView nextView:nextView direction:direction];
            transition.applyToNext = NO;
            return transition;
        }
        case MLWTransitionTypeCubeTo: {
            MLWXrossTransitionCube *transition = [[MLWXrossTransitionCube alloc] initWithCurrentView:currentView nextView:nextView direction:direction];
            transition.applyToCurrent = NO;
            return transition;
        }
        case MLWTransitionTypeStackPop: {
            MLWXrossTransitionStack *transition = [MLWXrossTransitionStack stackPopTransitionWithCurrentView:currentView nextView:nextView direction:direction];
            transition.maxSwingAngle = 0;
            return transition;
        }
        case MLWTransitionTypeStackPush: {
            MLWXrossTransitionStack *transition = [MLWXrossTransitionStack stackPushTransitionWithCurrentView:currentView nextView:nextView direction:direction];
            transition.maxSwingAngle = 0;
            return transition;
        }
        case MLWTransitionTypeStackPopWithSwing: {
            return [MLWXrossTransitionStack stackPopTransitionWithCurrentView:currentView nextView:nextView direction:direction];
        }
        case MLWTransitionTypeStackPushWithSwing: {
            return [MLWXrossTransitionStack stackPushTransitionWithCurrentView:currentView nextView:nextView direction:direction];
        }
        case MLWTransitionTypeStackPopFlat: {
            MLWXrossTransitionStack *transition = [MLWXrossTransitionStack stackPopTransitionWithCurrentView:currentView nextView:nextView direction:direction];
            transition.maxSwingAngle = 0;
            transition.minScaleAchievedByDistance = 1.0;
            return transition;
        }
        case MLWTransitionTypeStackPushFlat: {
            MLWXrossTransitionStack *transition = [MLWXrossTransitionStack stackPushTransitionWithCurrentView:currentView nextView:nextView direction:direction];
            transition.maxSwingAngle = 0;
            transition.minScaleAchievedByDistance = 1.0;
            return transition;
        }
        case MLWTransitionTypeFadeIn: {
            return [MLWXrossTransitionFade fadeInTransitionWithCurrentView:currentView nextView:nextView direction:direction];
        }
        case MLWTransitionTypeFadeOut: {
            return [MLWXrossTransitionFade fadeInTransitionWithCurrentView:currentView nextView:nextView direction:direction];
        }
    }
}

//

@interface MLWXrossViewController () <MLWXrossScrollViewDelegate>

@property (strong, nonatomic) MLWXrossScrollView *view;

@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) UIViewController *nextViewController;
@property (assign, nonatomic) MLWXrossDirection nextViewControllerDirection;
@property (strong, nonatomic) MLWXrossTransition *transition;
@property (assign, nonatomic) BOOL scrollViewWillSkipCalls;
@property (assign, nonatomic) MLWXrossDirection prevDirection;
@property (assign, nonatomic) MLWXrossDirection prevWantedDirection;
@property (assign, nonatomic) MLWXrossDirection skipAddDirection;
@property (assign, nonatomic) BOOL inMoveToDirection;
@property (assign, nonatomic) BOOL denyMovementWhileRotation;
@property (copy, nonatomic) void (^moveToDirectionCompletionBlock)();

@end

@implementation MLWXrossViewController

@dynamic view;

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    MLWXrossViewController *this = nil;
    return @{
        @keypath(this.isMoving) : [NSSet setWithArray:@[ @keypath(this.nextViewController) ]],
        @keypath(this.isMovingDisabled) : [NSSet setWithArray:@[ @keypath(this.view.scrollEnabled) ]],
    }[key] ?: [super keyPathsForValuesAffectingValueForKey:key];
}

- (BOOL)isMoving {
    return self.nextViewController ||
           self.view.isDragging ||
           self.view.isDecelerating;
}

- (BOOL)isMovingDisabled {
    return !self.view.scrollEnabled;
}

- (void)setMovingDisabled:(BOOL)movingDisabled {
    self.view.scrollEnabled = !movingDisabled;
}

- (MLWXrossScrollView *)scrollView {
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
    if (self.nextViewController) {
        return (1 << [UIApplication sharedApplication].statusBarOrientation);
    }
    return self.viewController
               ? [self.viewController supportedInterfaceOrientations]
               : [super supportedInterfaceOrientations];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];

    @weakify(self);
    self.denyMovementWhileRotation = YES;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            @strongify(self);
            self.denyMovementWhileRotation = NO;
        }];
}

+ (Class)xrossViewClass {
    return [MLWXrossScrollView class];
}

- (void)loadView {
    self.view = [[[self.class xrossViewClass] alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.delegate = self;
    self.view.bounces = NO;
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
        self.view.centerView = self.viewController.view;
        [self.viewController didMoveToParentViewController:self];
        self.viewController.view.clipsToBounds = YES;
        [self.view.centerView layoutIfNeeded];
        
        if ([self.delegate respondsToSelector:@selector(xross:didMoveToDirection:)]) {
            [self.delegate xross:self didMoveToDirection:MLWXrossDirectionNone];
        }
    }
}

- (void)moveToDirection:(MLWXrossDirection)direction {
    [self moveToDirection:direction completion:nil];
}

- (void)moveToDirection:(MLWXrossDirection)direction completion:(void (^)())completion {
    self.inMoveToDirection = YES;
    self.view.contentOffset = CGPointMake(self.view.originOffset.x + direction.x,
                                          self.view.originOffset.y + direction.y);
    NSAssert(self.nextViewController, @"self.nextViewController should not be nil, check your xross:viewControllerForDirection: implementation");
    if (!self.nextViewController) {
        self.inMoveToDirection = NO;
        if (completion) {
            completion();
        }
        return;
    }
    
    self.moveToDirectionCompletionBlock = completion;
    self.view.userInteractionEnabled = NO;
    CGPoint prePoint = CGPointMake(
        self.view.originOffset.x + direction.x * (CGRectGetWidth(self.view.bounds) - 1),
        self.view.originOffset.y + direction.y * (CGRectGetHeight(self.view.bounds) - 1));
    [self.view setContentOffsetTo:prePoint animated:YES];
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
    [self fixStatusBarOrientationIfNeededForCurrentSupported:self.supportedInterfaceOrientations];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.viewController beginAppearanceTransition:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.viewController endAppearanceTransition];
}

- (void)fixStatusBarOrientationIfNeededForCurrentSupported:(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIInterfaceOrientation statusBarInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    UIInterfaceOrientation realInterfaceOrientation = ^{
        switch ([UIDevice currentDevice].orientation) {
            case UIDeviceOrientationPortrait:
                return UIInterfaceOrientationPortrait;
            case UIDeviceOrientationPortraitUpsideDown:
                return UIInterfaceOrientationPortraitUpsideDown;
            case UIDeviceOrientationLandscapeLeft:
                return UIInterfaceOrientationLandscapeRight;
            case UIDeviceOrientationLandscapeRight:
                return UIInterfaceOrientationLandscapeLeft;
            case UIDeviceOrientationUnknown:
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationFaceDown:
                return UIInterfaceOrientationUnknown;
        }
    }();
    
    if (!(self.supportedInterfaceOrientations & (1 << statusBarInterfaceOrientation)) ||
        (realInterfaceOrientation != UIInterfaceOrientationUnknown &&
        !(supportedInterfaceOrientations & (1 << realInterfaceOrientation)))) {
        NSArray<NSNumber *> *orientations = @[
            @(UIInterfaceOrientationPortrait),
            @(UIInterfaceOrientationLandscapeLeft),
            @(UIInterfaceOrientationLandscapeRight),
            @(UIInterfaceOrientationPortraitUpsideDown)
        ];
        for (NSNumber *orientation in orientations) {
            if (self.supportedInterfaceOrientations & (1 << orientation.unsignedIntegerValue)) {
                if (realInterfaceOrientation != UIInterfaceOrientationUnknown &&realInterfaceOrientation == orientation.unsignedIntegerValue) {
                    //
                    // Rotate UI to real device orientation
                    //
                    //UIViewController *aDummyController = [[UIViewController alloc] init];
                    //aDummyController.view.backgroundColor = [UIColor clearColor];
                    //aDummyController.view.hidden = YES;
                    
                    //self.view.userInteractionEnabled = NO;
                    //[self presentViewController:aDummyController animated:YES completion:^{
                    //    [aDummyController dismissViewControllerAnimated:YES completion:^{
                    //        self.view.userInteractionEnabled = YES;
                    //    }];
                    //}];
                }
                else {
                    //
                    // Rotate UI to new VC supported orientation
                    //
                    [[UIDevice currentDevice] setValue:orientation forKey:@keypath([UIDevice currentDevice], orientation)];
                }
                break;
            }
        }
    }
}

#pragma mark - Scroll View

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint directionVector = CGPointMake(
        scrollView.contentOffset.x - self.view.originOffset.x,
        scrollView.contentOffset.y - self.view.originOffset.y);
    MLWXrossDirection direction = MLWXrossDirectionMake(directionVector.x, directionVector.y);
    
    CGFloat horizontalProgress = ABS(scrollView.contentOffset.x - self.view.originOffset.x) / CGRectGetWidth(self.view.bounds);
    CGFloat verticalProgress = ABS(scrollView.contentOffset.y - self.view.originOffset.y) / CGRectGetHeight(self.view.bounds);
    CGFloat unlimitedProgrees = MLWXrossDirectionIsHorizontal(direction) ? horizontalProgress : verticalProgress;
    CGFloat progress = MAX(0.0, MIN(unlimitedProgrees, 1.0));
    
    [self.transition updateForProgress:progress];
}

- (CGPoint)scrollView:(MLWXrossScrollView *)scrollView willScrollToContentOffset:(CGPoint)contentOffset {
    if (self.denyMovementWhileRotation) {
        return self.view.contentOffset;
    }
    
    CGPoint directionVector = CGPointMake(
        contentOffset.x - scrollView.originOffset.x,
        contentOffset.y - scrollView.originOffset.y);
    MLWXrossDirection direction = MLWXrossDirectionMake(directionVector.x, directionVector.y);
    MLWXrossDirection originalDirection = direction;
    
    // Update content offset with direction respect
    contentOffset = CGPointMake(
        scrollView.originOffset.x + directionVector.x * ABS(direction.x),
        scrollView.originOffset.y + directionVector.y * ABS(direction.y));
    
    // Update pan gesture recognizer with direction respect
    if (self.view.isDragging) {
        CGPoint translation = [self.view.panGestureRecognizer translationInView:self.view];
        if (direction.x == 0) {
            translation.x = round(translation.x / CGRectGetWidth(self.view.bounds)) * CGRectGetWidth(self.view.bounds);
        }
        if (direction.y == 0) {
            translation.y = round(translation.y / CGRectGetHeight(self.view.bounds)) * CGRectGetHeight(self.view.bounds);
        }
        [self.view.panGestureRecognizer setTranslation:translation inView:self.view];
    }
    
    BOOL returnedBack = self.nextViewController &&
                        !MLWXrossDirectionIsNone(self.prevDirection) &&
                        !MLWXrossDirectionEquals(direction, self.prevDirection);
    
    // Remove viewController or nextViewController
    BOOL skipUpdateTransitionCall = NO;
    if (returnedBack ||
        ABS(contentOffset.x - scrollView.originOffset.x) >= CGRectGetWidth(self.view.bounds) ||
        ABS(contentOffset.y - scrollView.originOffset.y) >= CGRectGetHeight(self.view.bounds)) {
        
        [self removeNextViewControllerFromDirection:direction returnedBack:returnedBack contentOffset:contentOffset];
        directionVector = CGPointMake(contentOffset.x - scrollView.originOffset.x,
                                      contentOffset.y - scrollView.originOffset.y);
        direction = MLWXrossDirectionMake(directionVector.x, directionVector.y);
        self.prevWantedDirection = MLWXrossDirectionNone;
        self.inMoveToDirection = NO;
        
        skipUpdateTransitionCall = MLWXrossDirectionIsNone(direction);
    }
    
    if (self.denyMovementWhileRotation) {
        return self.view.contentOffset;
    }
    
    // Add nextViewController
    if (!self.nextViewController &&
        !MLWXrossDirectionIsNone(direction) &&
        !MLWXrossDirectionEquals(direction, self.skipAddDirection)) {
        
        if (!self.inMoveToDirection && self.view.isDecelerating &&
            self.view.panGestureRecognizer.state != UIGestureRecognizerStateBegan &&
            self.view.panGestureRecognizer.state != UIGestureRecognizerStateChanged) {
            // Avoid overdeceleration
            return self.view.originOffset;
        }
        
        [self addNextViewControllerToDirection:direction];
    }
    
    CGFloat horizontalProgress = ABS(contentOffset.x - scrollView.originOffset.x) / CGRectGetWidth(self.view.bounds);
    CGFloat verticalProgress = ABS(contentOffset.y - scrollView.originOffset.y) / CGRectGetHeight(self.view.bounds);
    CGFloat unlimitedProgrees = MLWXrossDirectionIsHorizontal(direction) ? horizontalProgress : verticalProgress;
    CGFloat progress = MAX(0.0, MIN(unlimitedProgrees, 1.0));
    
    CGPoint result = contentOffset;
    if (!skipUpdateTransitionCall) {
        result = [self updateTransitionProgress:progress toDirection:direction contentOffset:contentOffset];
        self.prevDirection = MLWXrossDirectionMake(result.x - scrollView.originOffset.x, result.y - scrollView.originOffset.y);
    }
    
    self.prevWantedDirection = originalDirection;
    return result;
}

- (void)removeNextViewControllerFromDirection:(MLWXrossDirection)direction returnedBack:(BOOL)returnedBack contentOffset:(CGPoint)contentOffset {
    if (!returnedBack) {
        CGPoint point = CGPointMake(self.view.originOffset.x + direction.x*CGRectGetWidth(self.view.bounds),
                                    self.view.originOffset.y + direction.y*CGRectGetWidth(self.view.bounds));
        [self updateTransitionProgress:1.0 toDirection:direction contentOffset:point];
        
        // Swap VCs
        UIViewController *tmpViewController = self.viewController;
        self.viewController = self.nextViewController;
        self.nextViewController = tmpViewController;
        [UIView animateWithDuration:0.25 animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    }
    else {
        [self updateTransitionProgress:0.0 toDirection:direction contentOffset:self.view.originOffset];
        
        [self.nextViewController beginAppearanceTransition:NO animated:NO];
        [self.nextViewController endAppearanceTransition];
        [self.viewController beginAppearanceTransition:YES animated:NO];
        [self.viewController endAppearanceTransition];
    }
    
    // Remove VC
    [self.nextViewController willMoveToParentViewController:nil];
    [self.nextViewController.view removeFromSuperview];
    [self.nextViewController removeFromParentViewController];
    [self.nextViewController resignFirstResponder];
    if (!returnedBack) {
        [self.nextViewController endAppearanceTransition];
    }
    
    self.prevDirection = MLWXrossDirectionNone;
    self.view.nextDirection = CGPointZero;
    if (!returnedBack) {
        self.view.originOffsetInSteps = CGPointMake(
            self.view.originOffsetInSteps.x + direction.x,
            self.view.originOffsetInSteps.y + direction.y);
    }
    
    [self.viewController becomeFirstResponder];
    if (!returnedBack) {
        [self.viewController endAppearanceTransition];
    }
    
    UIInterfaceOrientationMask prevSupportedInterfaceOrientations = self.supportedInterfaceOrientations; // Before nextViewControlled get nilled
    
    UIViewController *prevNextViewController = self.nextViewController;
    self.nextViewController = nil;
    self.nextViewControllerDirection = MLWXrossDirectionNone;
    self.view.bounces = NO;
    
    [self.transition finishTransition];
    self.transition = nil;
    
    if (!self.view.userInteractionEnabled) {
        self.view.userInteractionEnabled = YES;
    }
    if ([self.delegate respondsToSelector:@selector(xross:didMoveToDirection:)]) {
        [self.delegate xross:self didMoveToDirection:returnedBack ? MLWXrossDirectionNone : direction];
    }
    if ([self.delegate respondsToSelector:@selector(xross:removedViewController:)]) {
        [self.delegate xross:self removedViewController:prevNextViewController];
    }
    if (self.moveToDirectionCompletionBlock) {
        self.moveToDirectionCompletionBlock();
        self.moveToDirectionCompletionBlock = nil;
    }
    
    [self fixStatusBarOrientationIfNeededForCurrentSupported:prevSupportedInterfaceOrientations];
}

- (void)addNextViewControllerToDirection:(MLWXrossDirection)direction {
    self.nextViewController = [self.dataSource xross:self viewControllerForDirection:direction];
    if (self.nextViewController) {
        self.nextViewControllerDirection = direction;
    }
    
    if (!self.nextViewController) {
        self.skipAddDirection = direction;
        return;
    }
    self.skipAddDirection = MLWXrossDirectionNone;
    
    self.transition = nil;
    if ([self.delegate respondsToSelector:@selector(xross:transitionToDirection:)]) {
        self.transition = [self.delegate xross:self transitionToDirection:direction];
    }
    else if ([self.delegate respondsToSelector:@selector(xross:transitionTypeToDirection:)]) {
        self.transition = TransitionForTransitionType([self.delegate xross:self transitionTypeToDirection:direction], self.viewController.view, self.nextViewController.view, direction);
    }
    
    [self.viewController beginAppearanceTransition:NO animated:YES];
    [self.nextViewController beginAppearanceTransition:YES animated:YES];
    [self addChildViewController:self.nextViewController];
    if (self.nextViewController.view.backgroundColor == nil) { // Fixed bug with broken scrolling
        self.nextViewController.view.backgroundColor = [UIColor whiteColor];
    }
    [self.view setNextView:self.nextViewController.view toDirection:CGPointMake(direction.x, direction.y)];
    [self.nextViewController didMoveToParentViewController:self];
    self.nextViewController.view.clipsToBounds = YES;
    [self.nextViewController.view layoutIfNeeded];
}

- (CGPoint)updateTransitionProgress:(CGFloat)progress
                        toDirection:(MLWXrossDirection)direction
                      contentOffset:(CGPoint)contentOffset {
    
    if (self.nextViewController) {
        if (CGPointEqualToPoint(self.view.nextDirection, CGPointZero)) {
            BOOL isAllowedToApplyInset = NO;
            if (self.view.isDragging || self.view.mlw_isInsideAttemptToDragParent.isDragging) {
                if ([self.delegate respondsToSelector:@selector(xross:shouldApplyInsetToDirection:progress:)]) {
                    isAllowedToApplyInset = [self.delegate xross:self shouldApplyInsetToDirection:direction progress:progress];
                }
                else {
                    isAllowedToApplyInset = YES;
                }
                
                if (isAllowedToApplyInset) {
                    CGPoint needOffset = CGPointMake(
                        progress * CGRectGetWidth(self.view.bounds) * direction.x,
                        progress * CGRectGetHeight(self.view.bounds) * direction.y);
                    
                    CGPoint translation = [self.view.panGestureRecognizer translationInView:self.view];
                    translation.x = round(translation.x / CGRectGetWidth(self.view.bounds)) * CGRectGetWidth(self.view.bounds);
                    translation.y = round(translation.y / CGRectGetHeight(self.view.bounds)) * CGRectGetHeight(self.view.bounds);
                    translation.x -= needOffset.x;
                    translation.y -= needOffset.y;
                    [self.view.panGestureRecognizer setTranslation:translation inView:self.view];
                    self.view.nextDirection = CGPointMake(direction.x, direction.y);
                }
            }
            self.view.bounces = !isAllowedToApplyInset;
        }
        else {
            self.view.bounces = NO;
        }
    }
    else {
        if (!self.view.bounces &&
            !MLWXrossDirectionEquals(direction, self.prevWantedDirection)) {
        
            BOOL bounces = self.bounces;
            if ([self.delegate respondsToSelector:@selector(xross:shouldBounceToDirection:)]) {
                bounces = [self.delegate xross:self shouldBounceToDirection:direction];
            }
            
            if (bounces) {
                self.transition = nil;
                if ([self.delegate respondsToSelector:@selector(xross:transitionToDirection:)]) {
                    self.transition = [self.delegate xross:self transitionToDirection:direction];
                }
                else if ([self.delegate respondsToSelector:@selector(xross:transitionTypeToDirection:)]) {
                    self.transition = TransitionForTransitionType([self.delegate xross:self transitionTypeToDirection:direction], self.viewController.view, self.nextViewController.view, direction);
                }
                self.view.bounces = YES;
            }
        }
        
        if (!self.view.bounces &&
            MLWXrossDirectionEquals(direction, self.skipAddDirection)) {
            progress = 0.0;
            contentOffset = self.view.originOffset;
            CGPoint translation = [self.view.panGestureRecognizer translationInView:self.view];
            translation.x = round(translation.x / CGRectGetWidth(self.view.bounds)) * CGRectGetWidth(self.view.bounds);
            translation.y = round(translation.y / CGRectGetHeight(self.view.bounds)) * CGRectGetHeight(self.view.bounds);
            [self.view.panGestureRecognizer setTranslation:translation inView:self.view];
        }
    }
    
    if (((direction.x || direction.y) && progress) ||
        !CGPointEqualToPoint(self.view.contentOffset, self.view.originOffset)) {
        if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)]) {
            MLWXrossDirection notNoneDirection = (MLWXrossDirectionIsNone(direction) ? self.prevWantedDirection : direction);
            [self.delegate xross:self didScrollToDirection:notNoneDirection progress:progress];
        }
    }
    
    return contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self finishScrolling:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self finishScrolling:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self finishScrolling:scrollView];
}

- (void)finishScrolling:(UIScrollView *)scrollView {
    CGPoint point = CGPointMake(
        round(self.view.contentOffset.x / CGRectGetWidth(self.view.bounds)) * CGRectGetWidth(self.view.bounds),
        round(self.view.contentOffset.y / CGRectGetHeight(self.view.bounds)) * CGRectGetHeight(self.view.bounds));
    if (!self.view.isDragging &&
        !CGPointEqualToPoint(point, self.view.contentOffset)) {
        [self.view setContentOffsetTo:point animated:NO];
    }
    self.view.bounces = NO;
    self.prevWantedDirection = MLWXrossDirectionNone;
    self.skipAddDirection = MLWXrossDirectionNone;
}

@end
