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

@interface MLWXrossShadowLayer : CALayer

@end

@implementation MLWXrossShadowLayer

@end

//

static MLWXrossShadowLayer *ShadowLayerForTransition(CALayer *currLayer, CALayer *nextLayer) {
    for (MLWXrossShadowLayer *layer in currLayer.sublayers.reverseObjectEnumerator) {
        if ([layer isKindOfClass:[MLWXrossShadowLayer class]]) {
            return layer;
        }
    }
    for (MLWXrossShadowLayer *layer in nextLayer.sublayers.reverseObjectEnumerator) {
        if ([layer isKindOfClass:[MLWXrossShadowLayer class]]) {
            return layer;
        }
    }
    return nil;
}

static void ApplyTransitionDefault(CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    MLWXrossShadowLayer *shadowLayer = ShadowLayerForTransition(currLayer, nextLayer);
    
    currLayer.transform = CATransform3DIdentity;
    nextLayer.transform = CATransform3DIdentity;
    currLayer.shouldRasterize = NO;
    nextLayer.shouldRasterize = NO;
    [shadowLayer removeFromSuperlayer];
}

static void ApplyTransition3DCubeFromTo(BOOL from, BOOL to, CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    MLWXrossShadowLayer *shadowLayer = ShadowLayerForTransition(currLayer, nextLayer);
    CGFloat orientedProgress = progress * ((MLWXrossDirectionEquals(direction, MLWXrossDirectionLeft) || MLWXrossDirectionEquals(direction, MLWXrossDirectionTop)) ? -1 : 1);
    BOOL rotationToNext = MLWXrossDirectionEquals(direction, MLWXrossDirectionRight) || MLWXrossDirectionEquals(direction, MLWXrossDirectionBottom);
    BOOL isVertical = MLWXrossDirectionIsVertical(direction);
    BOOL isHorizontal = MLWXrossDirectionIsHorizontal(direction);
    CGFloat size = isHorizontal ? CGRectGetWidth(currLayer.bounds) : CGRectGetHeight(currLayer.bounds);
    
    if (ABS(progress) > DBL_EPSILON && ABS(1.0 - progress) > DBL_EPSILON) {
        CALayer *shadowLayerParent = rotationToNext ? nextLayer : currLayer;
        if (shadowLayer == nil) {
            shadowLayer = [MLWXrossShadowLayer new];
            shadowLayer.backgroundColor = [UIColor blackColor].CGColor;
        }
        if (shadowLayer.superlayer != shadowLayerParent) {
            [shadowLayer removeFromSuperlayer];
            shadowLayer.frame = (CGRect){CGPointZero, shadowLayerParent.frame.size};
            [shadowLayerParent addSublayer:shadowLayer];
        }
        
        CATransform3D currTransform = CATransform3DIdentity;
        if (from) {
            currTransform.m34 = -0.001;
            currTransform = CATransform3DTranslate(currTransform, (rotationToNext ? 1 : -1) * size / 2 * isHorizontal, (rotationToNext ? 1 : -1) * size / 2 * isVertical, 0);
            currTransform = CATransform3DRotate(currTransform, -orientedProgress * M_PI_2 * (isHorizontal ? 1 : -1), isVertical, isHorizontal, 0);
            currTransform = CATransform3DTranslate(currTransform, (rotationToNext ? -1 : 1) * size / 2 * isHorizontal, (rotationToNext ? -1 : 1) * size / 2 * isVertical, 0);
        }
        
        CATransform3D nextTransform = CATransform3DIdentity;
        if (to) {
            nextTransform.m34 = -0.001;
            nextTransform = CATransform3DTranslate(nextTransform, (rotationToNext ? -1 : 1) * size / 2 * isHorizontal, (rotationToNext ? -1 : 1) * size / 2 * isVertical, 0);
            nextTransform = CATransform3DRotate(nextTransform, (isHorizontal ? 1 : -1) * M_PI_2 + (rotationToNext ? 0 : M_PI) - orientedProgress * M_PI_2 * (isHorizontal ? 1 : -1), isVertical, isHorizontal, 0);
            nextTransform = CATransform3DTranslate(nextTransform, (rotationToNext ? 1 : -1) * size / 2 * isHorizontal, (rotationToNext ? 1 : -1) * size / 2 * isVertical, 0);
        }
        
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        shadowLayer.opacity = (rotationToNext ? (1 - progress) : progress) * 0.85;
        currLayer.transform = currTransform;
        nextLayer.transform = nextTransform;
        [CATransaction commit];
        
        currLayer.rasterizationScale = [UIScreen mainScreen].scale;
        nextLayer.rasterizationScale = [UIScreen mainScreen].scale;
        currLayer.shouldRasterize = YES;
        nextLayer.shouldRasterize = YES;
    }
    else {
        currLayer.transform = CATransform3DIdentity;
        nextLayer.transform = CATransform3DIdentity;
        currLayer.shouldRasterize = NO;
        nextLayer.shouldRasterize = NO;
        [shadowLayer removeFromSuperlayer];
    }
}

static void ApplyTransition3DCube(CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    ApplyTransition3DCubeFromTo(YES, YES, currLayer, nextLayer, direction, progress);
}

static void ApplyTransition3DCubeFrom(CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    ApplyTransition3DCubeFromTo(YES, NO, currLayer, nextLayer, direction, progress);
}

static void ApplyTransition3DCubeTo(CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    ApplyTransition3DCubeFromTo(NO, YES, currLayer, nextLayer, direction, progress);
}

static void ApplyTransitionStack(BOOL rotationToNext, CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    MLWXrossShadowLayer *shadowLayer = ShadowLayerForTransition(currLayer, nextLayer);
    CGFloat orientedProgress = progress * ((MLWXrossDirectionEquals(direction, MLWXrossDirectionLeft) || MLWXrossDirectionEquals(direction, MLWXrossDirectionTop)) ? -1 : 1);
    CGFloat maxOrientedProgress = orientedProgress < 0 ? -1 : 1.0;
    BOOL isVertical = MLWXrossDirectionIsVertical(direction);
    BOOL isHorizontal = MLWXrossDirectionIsHorizontal(direction);
    CGFloat size = isHorizontal ? CGRectGetWidth(currLayer.bounds) : CGRectGetHeight(currLayer.bounds);
    CGFloat scale = rotationToNext ? (0.85 + progress * 0.15) : (1.0 - progress * 0.15);
    CGFloat eyeDistance = size;
    CGFloat distance = -eyeDistance*(1/scale - scale);
    
    NSUInteger currLayerIndex = [currLayer.superlayer.sublayers indexOfObject:currLayer];
    NSUInteger nextLayerIndex = [nextLayer.superlayer.sublayers indexOfObject:nextLayer];
    if (rotationToNext && currLayerIndex < nextLayerIndex) {
        [currLayer.superlayer addSublayer:currLayer];
    }
    if (!rotationToNext && currLayerIndex > nextLayerIndex) {
        [currLayer.superlayer addSublayer:nextLayer];
    }
    
    if (ABS(progress) > DBL_EPSILON && ABS(1.0 - progress) > DBL_EPSILON) {
        CALayer *shadowLayerParent = rotationToNext ? nextLayer : currLayer;
        if (shadowLayer == nil) {
            shadowLayer = [MLWXrossShadowLayer new];
            shadowLayer.backgroundColor = [UIColor blackColor].CGColor;
        }
        if (shadowLayer.superlayer != shadowLayerParent) {
            [shadowLayer removeFromSuperlayer];
            shadowLayer.frame = (CGRect){CGPointZero, shadowLayerParent.frame.size};
            [shadowLayerParent addSublayer:shadowLayer];
        }
        
        CATransform3D currTransform = CATransform3DIdentity;
        CATransform3D nextTransform = CATransform3DIdentity;
        
        // The amendment to the wind
        size += (size - size*scale)/2;
        
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = -1/eyeDistance;
        if (rotationToNext) {
            transform = CATransform3DTranslate(transform, -size * maxOrientedProgress * isHorizontal / scale, -size * maxOrientedProgress * isVertical / scale, 0);
        }
        transform = CATransform3DTranslate(transform, size * orientedProgress * isHorizontal / scale, size * orientedProgress * isVertical / scale, distance);
        
        if (rotationToNext) {
            nextTransform = transform;
        }
        else {
            currTransform = transform;
        }
        
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        shadowLayer.opacity = (rotationToNext ? (1 - progress) : progress) * 0.85;
        currLayer.transform = currTransform;
        nextLayer.transform = nextTransform;
        [CATransaction commit];
        
        currLayer.rasterizationScale = [UIScreen mainScreen].scale;
        nextLayer.rasterizationScale = [UIScreen mainScreen].scale;
        currLayer.shouldRasterize = YES;
        nextLayer.shouldRasterize = YES;
    }
    else {
        currLayer.transform = CATransform3DIdentity;
        nextLayer.transform = CATransform3DIdentity;
        currLayer.shouldRasterize = NO;
        nextLayer.shouldRasterize = NO;
        [shadowLayer removeFromSuperlayer];
    }
}

static void ApplyTransitionStackNext(CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    ApplyTransitionStack(YES, currLayer, nextLayer, direction, progress);
}

static void ApplyTransitionStackPrev(CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    ApplyTransitionStack(NO, currLayer, nextLayer, direction, progress);
}

static void ApplyTransitionStackWithSwing(BOOL rotationToNext, CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    CGFloat orientation = ((MLWXrossDirectionEquals(direction, MLWXrossDirectionLeft) || MLWXrossDirectionEquals(direction, MLWXrossDirectionTop)) ? -1 : 1) * (rotationToNext ? 1 : -1);
    BOOL isVertical = MLWXrossDirectionIsVertical(direction);
    BOOL isHorizontal = MLWXrossDirectionIsHorizontal(direction);
    
    ApplyTransitionStack(rotationToNext, currLayer, nextLayer, direction, progress);
    
    CGFloat maxAngle = 15.0 / 180.0 * M_PI;
    CGFloat angle = maxAngle * (1.0 - 2*ABS(0.5 - progress)) * (isHorizontal ? -1 : 1);
    CATransform3D transform = (rotationToNext ? nextLayer : currLayer).transform;
    transform = CATransform3DRotate(transform, angle*orientation, isVertical, isHorizontal, 0.0);
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    if (rotationToNext) {
        nextLayer.transform = transform;
    }
    else {
        currLayer.transform = transform;
    }
    [CATransaction commit];
}

static void ApplyTransitionStackNextWithSwing(CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    ApplyTransitionStackWithSwing(YES, currLayer, nextLayer, direction, progress);
}

static void ApplyTransitionStackPrevWithSwing(CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    ApplyTransitionStackWithSwing(NO, currLayer, nextLayer, direction, progress);
}


//

@interface MLWXrossViewController () <MLWXrossScrollViewDelegate>

@property (strong, nonatomic) MLWXrossScrollView *view;

@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) UIViewController *nextViewController;
@property (assign, nonatomic) MLWXrossDirection nextViewControllerDirection;
@property (assign, nonatomic) MLWXrossTransitionType transitionType;
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
    self.view.showsHorizontalScrollIndicator = NO;
    self.view.showsVerticalScrollIndicator = NO;
    self.view.directionalLockEnabled = YES;
    self.view.bounces = NO;
    self.view.pagingEnabled = YES;
    self.view.delegate = self;
    self.view.scrollEnabled = YES;
    self.view.scrollsToTop = NO;
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
    CGPoint point = CGPointMake(
        self.view.originOffset.x + direction.x * CGRectGetWidth(self.view.bounds),
        self.view.originOffset.y + direction.y * CGRectGetHeight(self.view.bounds));
    [self.view setContentOffsetTo:point animated:YES];
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
    
    MLWCustomTransitionTypeFunctor transitionFunctor = [self transitionFunctorForTransitionType:self.transitionType];
    NSAssert(transitionFunctor, @"transitionFunctor must not be nil");
    if (transitionFunctor) {
        transitionFunctor(self.viewController.view.layer, self.nextViewController.view.layer, direction, progress);
    }
}

- (CGPoint)scrollView:(MLWXrossScrollView *)scrollView willScrollToContentOffset:(CGPoint)contentOffset {
    if (self.view.window == nil) {
        return self.view.contentOffset;
    }
    
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
        
        if (!self.inMoveToDirection && self.view.isDecelerating) {
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
    
    if ([self.delegate respondsToSelector:@selector(xross:transitionTypeToDirection:)]) {
        self.transitionType = [self.delegate xross:self transitionTypeToDirection:direction];
    }
    else {
        self.transitionType = MLWXrossTransitionTypeDefault;
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
}

- (MLWCustomTransitionTypeFunctor)transitionFunctorForTransitionType:(MLWXrossTransitionType)transitionType {
    switch (self.transitionType) {
        case MLWXrossTransitionTypeDefault:            return ApplyTransitionDefault;
        case MLWXrossTransitionType3DCube:             return ApplyTransition3DCube;
        case MLWXrossTransitionType3DCubeFrom:         return ApplyTransition3DCubeFrom;
        case MLWXrossTransitionType3DCubeTo:           return ApplyTransition3DCubeTo;
        case MLWXrossTransitionTypeStackNext:          return ApplyTransitionStackNext;
        case MLWXrossTransitionTypeStackPrev:          return ApplyTransitionStackPrev;
        case MLWXrossTransitionTypeStackNextWithSwing: return ApplyTransitionStackNextWithSwing;
        case MLWXrossTransitionTypeStackPrevWithSwing: return ApplyTransitionStackPrevWithSwing;
        case MLWXrossTransitionTypeCustom:             return self.customTransitionTypeFunctor;
        default:                                       return nil;
    }
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
                if ([self.delegate respondsToSelector:@selector(xross:transitionTypeToDirection:)]) {
                    self.transitionType = [self.delegate xross:self transitionTypeToDirection:direction];
                }
                else {
                    self.transitionType = MLWXrossTransitionTypeDefault;
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
