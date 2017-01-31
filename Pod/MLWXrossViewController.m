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

//

static CGFloat const kAllowedInsetAnimationMaxDuration = 0.4;
static CGFloat const kAllowedInsetAnimationMaxDurationDistance = 100;
static UIEdgeInsets const kDefaultEdgeInsets = (UIEdgeInsets){1, 1, 1, 1};

MLWXrossDirection MLWXrossDirectionNone = (MLWXrossDirection){0, 0};
MLWXrossDirection MLWXrossDirectionTop = (MLWXrossDirection){0, -1};
MLWXrossDirection MLWXrossDirectionBottom = (MLWXrossDirection){0, 1};
MLWXrossDirection MLWXrossDirectionLeft = (MLWXrossDirection){-1, 0};
MLWXrossDirection MLWXrossDirectionRight = (MLWXrossDirection){1, 0};

MLWXrossDirection MLWXrossDirectionMake(NSInteger x, NSInteger y) {
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

static void ViewSetFrameWithoutRelayoutIfPossible(UIView *view, CGRect frame) {
    CGRect bounds = (CGRect){view.bounds.origin, frame.size};
    if (!CGRectEqualToRect(view.bounds, bounds)) {
        view.bounds = bounds;
        [view layoutIfNeeded];
    }
    view.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
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

@interface MLWXrossViewController () <UIScrollViewDelegate>

@property (assign, nonatomic) BOOL skipScrollViewWillScroll;
@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) UIViewController *nextViewController;
@property (assign, nonatomic) MLWXrossDirection nextViewControllerDirection;
@property (assign, nonatomic) MLWXrossTransitionType transitionType;
@property (assign, nonatomic) BOOL scrollViewWillSkipCalls;
@property (assign, nonatomic) MLWXrossDirection prevDirection;
@property (readonly, nonatomic) MLWXrossScrollView *mlwScrollView;
@property (strong, nonatomic) NSDate *denyMovementUntilDate;
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

- (void)updateInsets {
    if (!self.prevAllowedToApplyInset && self.allowedToApplyInset) {
        CGPoint offset = [self.scrollView convertPoint:CGPointZero fromView:self.viewController.view];
        self.scrollView.contentInset = self.needEdgeInsets;
        CGPoint newOffset = [self.scrollView convertPoint:CGPointZero fromView:self.viewController.view];
        
        CGFloat duration = MIN(kAllowedInsetAnimationMaxDurationDistance, ABS(offset.x - newOffset.x) + ABS(offset.y - newOffset.y))/kAllowedInsetAnimationMaxDurationDistance * kAllowedInsetAnimationMaxDuration;
        
        self.viewController.view.center = CGPointMake(
            self.viewController.view.center.x - (newOffset.x - offset.x),
            self.viewController.view.center.y - (newOffset.y - offset.y));
        self.nextViewController.view.center = CGPointMake(
            self.nextViewController.view.center.x - (newOffset.x - offset.x),
            self.nextViewController.view.center.y - (newOffset.y - offset.y));
        
        [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.viewController.view.center = CGPointMake(
                self.viewController.view.center.x + (newOffset.x - offset.x),
                self.viewController.view.center.y + (newOffset.y - offset.y));
            self.nextViewController.view.center = CGPointMake(
                self.nextViewController.view.center.x + (newOffset.x - offset.x),
                self.nextViewController.view.center.y + (newOffset.y - offset.y));
        } completion:nil];
    }
    else {
        self.scrollView.contentInset = self.needEdgeInsets;
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
    self.scrollView.contentOffset = CGPointZero;
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    MLWXrossDirection direction = MLWXrossDirectionMake(scrollView.contentOffset.x, scrollView.contentOffset.y);
    
    CGFloat horizontalProgress = ABS(scrollView.contentOffset.x) / CGRectGetWidth(self.scrollView.frame);
    CGFloat verticalProgress = ABS(scrollView.contentOffset.y) / CGRectGetHeight(self.scrollView.frame);
    CGFloat unlimitedProgrees = MLWXrossDirectionIsHorizontal(direction) ? horizontalProgress : verticalProgress;
    CGFloat progress = MAX(0.0, MIN(unlimitedProgrees, 1.0));
    
    MLWCustomTransitionTypeFunctor transitionFunctor = [self transitionFunctorForTransitionType:self.transitionType];
    NSAssert(transitionFunctor, @"transitionFunctor must not be nil");
    if (transitionFunctor) {
        transitionFunctor(self.viewController.view.layer, self.nextViewController.view.layer, direction, progress);
    }
}

// Avoid diagonal scrolling
- (CGPoint)scrollView:(MLWXrossScrollView *)scrollView willScrollToContentOffset:(CGPoint)contentOffset {
    if (self.view.window == nil) {
        return self.scrollView.contentOffset;
    }
    
    if (self.denyMovementUntilDate && [[NSDate date] compare:self.denyMovementUntilDate] == NSOrderedAscending) {
        return self.scrollView.contentOffset;
    }
    
    MLWXrossDirection direction = MLWXrossDirectionMake(contentOffset.x, contentOffset.y);
    
    // Update content offset with direction respect
    contentOffset = CGPointMake(contentOffset.x * ABS(direction.x),
                                contentOffset.y * ABS(direction.y));
    
    // Update pan gesture recognizer with direction respect
    if (self.scrollView.isDragging) {
        CGPoint translation = [self.scrollView.panGestureRecognizer translationInView:self.scrollView];
        translation = CGPointMake(translation.x * ABS(direction.x),
                                  translation.y * ABS(direction.y));
        [self.scrollView.panGestureRecognizer setTranslation:translation inView:self.scrollView];
    }

    return [self notDiagonalScrollView:scrollView allowBounceToContentOffset:contentOffset];
}

- (CGPoint)notDiagonalScrollView:(MLWXrossScrollView *)scrollView allowBounceToContentOffset:(CGPoint)contentOffset {
    MLWXrossDirection direction = MLWXrossDirectionMake(contentOffset.x, contentOffset.y);
    
    BOOL returnedBack = self.nextViewController && !MLWXrossDirectionEquals(direction, self.prevDirection);
    
    // Remove viewController or nextViewController
    if (returnedBack ||
        ABS(contentOffset.x) >= CGRectGetWidth(self.scrollView.bounds) ||
        ABS(contentOffset.y) >= CGRectGetHeight(self.scrollView.bounds)) {
        
        contentOffset = [self removeNextViewControllerFromDirection:direction returnedBack:returnedBack contentOffset:contentOffset];
        direction = MLWXrossDirectionMake(contentOffset.x, contentOffset.y);
    }
    
    // Add nextViewController
    if (!self.nextViewController &&
        !MLWXrossDirectionIsNone(direction) &&
        !MLWXrossDirectionEquals(direction, self.prevDirection)) {
        
        [self addNextViewControllerToDirection:direction];
    }
    
    CGFloat horizontalProgress = ABS(contentOffset.x) / CGRectGetWidth(self.scrollView.frame);
    CGFloat verticalProgress = ABS(contentOffset.y) / CGRectGetHeight(self.scrollView.frame);
    CGFloat unlimitedProgrees = MLWXrossDirectionIsHorizontal(direction) ? horizontalProgress : verticalProgress;
    CGFloat progress = MAX(0.0, MIN(unlimitedProgrees, 1.0));
    
    CGPoint result = [self updateTransitionProgress:progress toDirection:direction contentOffset:contentOffset];
    self.prevDirection = MLWXrossDirectionMake(result.x, result.y);
    return result;
}

- (CGPoint)removeNextViewControllerFromDirection:(MLWXrossDirection)direction returnedBack:(BOOL)returnedBack contentOffset:(CGPoint)contentOffset {
    if (!returnedBack) {
        CGPoint contentOffset = CGPointMake(direction.x * CGRectGetWidth(self.scrollView.bounds),
                                            direction.y * CGRectGetHeight(self.scrollView.bounds));
        [self updateTransitionProgress:1.0 toDirection:direction contentOffset:contentOffset];
        
        // Swap VCs
        UIViewController *tmpViewController = self.viewController;
        self.viewController = self.nextViewController;
        self.nextViewController = tmpViewController;
        [UIView animateWithDuration:0.25 animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    }
    else {
        [self updateTransitionProgress:0.0 toDirection:direction contentOffset:CGPointZero];
        
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
    
    // Center VC
    if (contentOffset.x >= CGRectGetWidth(self.scrollView.bounds)) {
        contentOffset.x -= CGRectGetWidth(self.scrollView.bounds);
    }
    if (contentOffset.x <= -CGRectGetWidth(self.scrollView.bounds)) {
        contentOffset.x += CGRectGetWidth(self.scrollView.bounds);
    }
    if (contentOffset.y >= CGRectGetHeight(self.scrollView.bounds)) {
        contentOffset.y -= CGRectGetHeight(self.scrollView.bounds);
    }
    if (contentOffset.y <= -CGRectGetHeight(self.scrollView.bounds)) {
        contentOffset.y += CGRectGetHeight(self.scrollView.bounds);
    }
    if (ABS(contentOffset.x) < 0.1 && ABS(contentOffset.y) < 0.1) {
        contentOffset = CGPointZero;
    }
    [UIView performWithoutAnimation:^{
        //FIXME: Avoid gesture interruption in future versions
        self.scrollView.panGestureRecognizer.state = UIGestureRecognizerStateEnded;
        
        self.prevDirection = MLWXrossDirectionNone;
        self.scrollView.contentOffset = contentOffset;
        self.needEdgeInsets = kDefaultEdgeInsets;
        [self updateInsets];
        ViewSetFrameWithoutRelayoutIfPossible(self.viewController.view, (CGRect){CGPointZero,self.scrollView.bounds.size});
    }];
    [self.viewController becomeFirstResponder];
    if (!returnedBack) {
        [self.viewController endAppearanceTransition];
    }
    
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
    if (self.completionBlock) {
        self.completionBlock();
        self.completionBlock = nil;
    }
    
    self.mlwScrollView.skipLayoutSubviewCalls = NO;
    
    if (self.scrollView.isDecelerating) {
        self.skipScrollViewWillScroll = YES;
    }
    
    [self fixStatusBarOrientationIfNeeded];
    return contentOffset;
}

- (void)addNextViewControllerToDirection:(MLWXrossDirection)direction {
    self.nextViewController = [self.dataSource xross:self viewControllerForDirection:direction];
    if (self.nextViewController) {
        self.nextViewControllerDirection = direction;
    }
    
    if (!self.nextViewController) {
        return;
    }
    
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
    
    self.mlwScrollView.skipLayoutSubviewCalls = YES;
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

- (CGPoint)updateTransitionProgress:(CGFloat)progress toDirection:(MLWXrossDirection)direction contentOffset:(CGPoint)contentOffset {
    
    if (self.nextViewController) {
        if (UIEdgeInsetsEqualToEdgeInsets(self.scrollView.contentInset, kDefaultEdgeInsets)) {
            if (!self.allowedToApplyInset && self.scrollView.isDragging) {
                if ([self.delegate respondsToSelector:@selector(xross:shouldApplyInsetToDirection:progress:)]) {
                    self.allowedToApplyInset = [self.delegate xross:self shouldApplyInsetToDirection:direction progress:progress];
                }
                else {
                    self.allowedToApplyInset = YES;
                }
                if (self.allowedToApplyInset) {
                    [self updateInsets];
                }
            }
            self.scrollView.bounces = !self.allowedToApplyInset;
        }
        else {
            self.scrollView.bounces = NO;
        }
    }
    else {
        if(!self.scrollView.bounces &&
           !MLWXrossDirectionEquals(direction, self.prevDirection)) {
        
            BOOL bounces = self.bounces;
            if ([self.delegate respondsToSelector:@selector(xross:shouldBounceToDirection:)]) {
                bounces = [self.delegate xross:self shouldBounceToDirection:direction];
            }
            
            if (!bounces) {
                contentOffset = CGPointZero;
                progress = 0.0;
            }
            else {
                if ([self.delegate respondsToSelector:@selector(xross:transitionTypeToDirection:)]) {
                    self.transitionType = [self.delegate xross:self transitionTypeToDirection:direction];
                }
                else {
                    self.transitionType = MLWXrossTransitionTypeDefault;
                }
                self.scrollView.bounces = YES;
            }
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(xross:didScrollToDirection:progress:)]) {
        [self.delegate xross:self didScrollToDirection:direction progress:progress];
    }
    
    return contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self finishScrolling:scrollView animated:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self finishScrolling:scrollView animated:NO];
}

- (void)finishScrolling:(UIScrollView *)scrollView animated:(BOOL)animated {
    self.skipScrollViewWillScroll = NO;
    
    CGFloat width = CGRectGetWidth(self.scrollView.bounds);
    CGFloat height = CGRectGetHeight(self.scrollView.bounds);
    CGPoint point = CGPointMake(
        round(self.mlwScrollView.contentOffset.x / width) * width,
        round(self.mlwScrollView.contentOffset.y / height) * height);
    if (!self.scrollView.isDragging &&
        !CGPointEqualToPoint(point, self.scrollView.contentOffset)) {
        [self.mlwScrollView setContentOffsetTo:point animated:animated];
    }
    self.scrollView.bounces = NO;
}

@end
