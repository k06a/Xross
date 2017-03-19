//
//  MLWXrossTransitionCube.m
//  Pods
//
//  Created by Anton Bukov on 20.03.17.
//
//

#import "MLWXrossTransitionCube.h"

//

static void ApplyTransition3DCubeFromTo(BOOL from, BOOL to, CGFloat maxAngle, CGFloat minShadowAlpha, CALayer *currLayer, CALayer *nextLayer, CALayer *shadowLayer, MLWXrossDirection direction, CGFloat progress) {
    CGFloat orientedProgress = progress * ((MLWXrossDirectionEquals(direction, MLWXrossDirectionLeft) || MLWXrossDirectionEquals(direction, MLWXrossDirectionTop)) ? -1 : 1);
    BOOL rotationToNext = MLWXrossDirectionEquals(direction, MLWXrossDirectionRight) || MLWXrossDirectionEquals(direction, MLWXrossDirectionBottom);
    BOOL isVertical = MLWXrossDirectionIsVertical(direction);
    BOOL isHorizontal = MLWXrossDirectionIsHorizontal(direction);
    CGFloat size = isHorizontal ? CGRectGetWidth(currLayer.bounds) : CGRectGetHeight(currLayer.bounds);
    
    CALayer *shadowLayerParent = rotationToNext ? nextLayer : currLayer;
    if (shadowLayer.superlayer != shadowLayerParent) {
        [shadowLayer removeFromSuperlayer];
        shadowLayer.frame = (CGRect){CGPointZero, shadowLayerParent.frame.size};
        [shadowLayerParent addSublayer:shadowLayer];
    }
    
    CATransform3D currTransform = CATransform3DIdentity;
    if (from) {
        currTransform.m34 = -0.001;
        currTransform = CATransform3DTranslate(currTransform, (rotationToNext ? 1 : -1) * size / 2 * isHorizontal, (rotationToNext ? 1 : -1) * size / 2 * isVertical, 0);
        currTransform = CATransform3DRotate(currTransform, -orientedProgress * maxAngle * (isHorizontal ? 1 : -1), isVertical, isHorizontal, 0);
        currTransform = CATransform3DTranslate(currTransform, (rotationToNext ? -1 : 1) * size / 2 * isHorizontal, (rotationToNext ? -1 : 1) * size / 2 * isVertical, 0);
    }
    
    CATransform3D nextTransform = CATransform3DIdentity;
    if (to) {
        nextTransform.m34 = -0.001;
        nextTransform = CATransform3DTranslate(nextTransform, (rotationToNext ? -1 : 1) * size / 2 * isHorizontal, (rotationToNext ? -1 : 1) * size / 2 * isVertical, 0);
        nextTransform = CATransform3DRotate(nextTransform, (isHorizontal ? 1 : -1) * maxAngle + (rotationToNext ? 0 : maxAngle*2) - orientedProgress * maxAngle * (isHorizontal ? 1 : -1), isVertical, isHorizontal, 0);
        nextTransform = CATransform3DTranslate(nextTransform, (rotationToNext ? 1 : -1) * size / 2 * isHorizontal, (rotationToNext ? 1 : -1) * size / 2 * isVertical, 0);
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    shadowLayer.opacity = (rotationToNext ? (1 - progress) : progress) * minShadowAlpha;
    currLayer.transform = currTransform;
    nextLayer.transform = nextTransform;
    [CATransaction commit];
}

//

@interface MLWXrossTransitionCube ()

@property (nullable, strong, nonatomic) CALayer *shadowLayer;

@end

@implementation MLWXrossTransitionCube

- (instancetype)initWithCurrentView:(UIView *)currentView
                           nextView:(UIView *)nextView
                          direction:(MLWXrossDirection)direction {
    self = [super initWithCurrentView:currentView nextView:nextView direction:direction];
    if (self) {
        _shadowLayer = [[CALayer alloc] init];
        _shadowLayer.backgroundColor = [UIColor blackColor].CGColor;
        
        _minShadowAlpha = 0.85;
        _applyToCurrent = YES;
        _applyToNext = YES;
        _maxAngle = M_PI_2;
    }
    return self;
}

- (void)finishTransition {
    [super finishTransition];
    
    [self.shadowLayer removeFromSuperlayer];
    self.currentView.layer.transform = CATransform3DIdentity;
    self.nextView.layer.transform = CATransform3DIdentity;
}

- (void)updateForProgress:(CGFloat)progress {
    ApplyTransition3DCubeFromTo(self.applyToCurrent, self.applyToNext, self.maxAngle, self.minShadowAlpha, self.currentView.layer, self.nextView.layer, self.shadowLayer, self.direction, progress);
}

@end
