//
//  MLWXrossTransitionStack.m
//  Pods
//
//  Created by Anton Bukov on 20.03.17.
//
//

#import "MLWXrossTransitionStack.h"

//

static void ApplyTransitionStack(BOOL rotationToNext, CGFloat minScaleAchievedByDistance, CGFloat maxSwingAngle, CGFloat minShadowAlpha, CALayer *currLayer, CALayer *nextLayer, CALayer *shadowLayer, MLWXrossDirection direction, CGFloat progress) {
    CGFloat orientedProgress = progress * ((MLWXrossDirectionEquals(direction, MLWXrossDirectionLeft) || MLWXrossDirectionEquals(direction, MLWXrossDirectionTop)) ? -1 : 1);
    CGFloat maxOrientedProgress = orientedProgress < 0 ? -1 : 1.0;
    BOOL isVertical = MLWXrossDirectionIsVertical(direction);
    BOOL isHorizontal = MLWXrossDirectionIsHorizontal(direction);
    CGFloat size = isHorizontal ? CGRectGetWidth(currLayer.bounds) : CGRectGetHeight(currLayer.bounds);
    CGFloat scale = rotationToNext ? (minScaleAchievedByDistance + progress * (1.0 - minScaleAchievedByDistance)) : (1.0 - progress * (1.0 - minScaleAchievedByDistance));
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
    
    CALayer *shadowLayerParent = rotationToNext ? nextLayer : currLayer;
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
    
    // Swing
    {
        CGFloat orientation = ((MLWXrossDirectionEquals(direction, MLWXrossDirectionLeft) || MLWXrossDirectionEquals(direction, MLWXrossDirectionTop)) ? -1 : 1) * (rotationToNext ? 1 : -1);
        
        CGFloat angle = maxSwingAngle * (1.0 - 2*ABS(0.5 - progress)) * (isHorizontal ? -1 : 1);
        CATransform3D transform = (rotationToNext ? nextTransform : currTransform);
        transform = CATransform3DRotate(transform, angle*orientation, isVertical, isHorizontal, 0.0);
        
        if (rotationToNext) {
            nextTransform = transform;
        }
        else {
            currTransform = transform;
        }
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    shadowLayer.opacity = (rotationToNext ? (1 - progress) : progress) * minShadowAlpha;
    currLayer.transform = currTransform;
    nextLayer.transform = nextTransform;
    [CATransaction commit];
}

//

@interface MLWXrossTransitionStack ()

@property (nullable, strong, nonatomic) CALayer *shadowLayer;

@end

@implementation MLWXrossTransitionStack

+ (instancetype)pushStackTransitionWithCurrentView:(UIView *)currentView
                                          nextView:(UIView *)nextView
                                         direction:(MLWXrossDirection)direction {
    return [[[self class] alloc] initWithCurrentView:currentView nextView:nextView direction:direction stackType:MLWXrossTransitionStackTypePush];
}

+ (instancetype)popStackTransitionWithCurrentView:(UIView *)currentView
                                         nextView:(UIView *)nextView
                                        direction:(MLWXrossDirection)direction {
    return [[[self class] alloc] initWithCurrentView:currentView nextView:nextView direction:direction stackType:MLWXrossTransitionStackTypePop];
}

- (instancetype)initWithCurrentView:(UIView *)currentView
                           nextView:(UIView *)nextView
                          direction:(MLWXrossDirection)direction
                          stackType:(MLWXrossTransitionStackType)stackType {
    self = [super initWithCurrentView:currentView nextView:nextView direction:direction];
    if (self) {
        _shadowLayer = [[CALayer alloc] init];
        _shadowLayer.backgroundColor = [UIColor blackColor].CGColor;
        
        _stackType = stackType;
        _minShadowAlpha = 0.85;
        _minScaleAchievedByDistance = 0.9;
        _maxSwingAngle = M_PI_2 / 6.0;
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
    ApplyTransitionStack(self.stackType == MLWXrossTransitionStackTypePop, self.minScaleAchievedByDistance, self.maxSwingAngle, self.minShadowAlpha, self.currentView.layer, self.nextView.layer, self.shadowLayer, self.direction, progress);
}

@end
