//
//  MLWXrossTransitionFade.m
//  Pods
//
//  Created by Anton Bukov on 22.03.17.
//
//

#import "MLWXrossTransitionFade.h"

//

static void ApplyTransitionFade(BOOL rotationToNext, CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress) {
    CGFloat orientedProgress = progress * ((MLWXrossDirectionEquals(direction, MLWXrossDirectionLeft) || MLWXrossDirectionEquals(direction, MLWXrossDirectionTop)) ? -1 : 1);
    CGFloat maxOrientedProgress = orientedProgress < 0 ? -1 : 1;
    BOOL isVertical = MLWXrossDirectionIsVertical(direction);
    BOOL isHorizontal = MLWXrossDirectionIsHorizontal(direction);
    CGFloat size = isHorizontal ? CGRectGetWidth(currLayer.bounds) : CGRectGetHeight(currLayer.bounds);
    
    NSUInteger currLayerIndex = [currLayer.superlayer.sublayers indexOfObject:currLayer];
    NSUInteger nextLayerIndex = [nextLayer.superlayer.sublayers indexOfObject:nextLayer];
    if (!rotationToNext && currLayerIndex < nextLayerIndex) {
        [currLayer.superlayer addSublayer:currLayer];
    }
    if (rotationToNext && currLayerIndex > nextLayerIndex) {
        [currLayer.superlayer addSublayer:nextLayer];
    }
    
    CATransform3D transform = CATransform3DMakeTranslation(
        size * (orientedProgress - rotationToNext*direction.x) * isHorizontal,
        size * (orientedProgress - rotationToNext*direction.y) * isVertical,
        0);
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (rotationToNext) {
        nextLayer.opacity = progress;
        currLayer.opacity = 1.0;
    }
    else {
        currLayer.opacity = (1.0 - progress);
        nextLayer.opacity = 1.0;
    }
    currLayer.transform = CATransform3DTranslate(
        transform,
        size * (rotationToNext?1:0)*direction.x * isHorizontal,
        size * (rotationToNext?1:0)*direction.y * isVertical,
        0);
    nextLayer.transform = CATransform3DTranslate(
        transform,
        size * (rotationToNext?0:1)*direction.x * isHorizontal,
        size * (rotationToNext?0:1)*direction.y * isVertical,
        0);
    [CATransaction commit];
}

//

@implementation MLWXrossTransitionFade

+ (instancetype)fadeInTransitionWithCurrentView:(UIView *)currentView
                                       nextView:(UIView *)nextView
                                      direction:(MLWXrossDirection)direction {
    return [[[self class] alloc] initWithCurrentView:currentView nextView:nextView direction:direction fadeType:MLWXrossTransitionTypeFadeIn];
}

+ (instancetype)popStackTransitionWithCurrentView:(UIView *)currentView
                                         nextView:(UIView *)nextView
                                        direction:(MLWXrossDirection)direction {
    return [[[self class] alloc] initWithCurrentView:currentView nextView:nextView direction:direction fadeType:MLWXrossTransitionTypeFadeOut];
}

- (instancetype)initWithCurrentView:(UIView *)currentView
                           nextView:(UIView *)nextView
                          direction:(MLWXrossDirection)direction
                           fadeType:(MLWXrossTransitionTypeFade)fadeType {
    self = [super initWithCurrentView:currentView nextView:nextView direction:direction];
    if (self) {
        _fadeType = fadeType;
    }
    return self;
}

- (void)finishTransition {
    [super finishTransition];
    self.currentView.layer.opacity = 1.0;
    self.nextView.layer.opacity = 1.0;
    self.currentView.layer.transform = CATransform3DIdentity;
    self.nextView.layer.transform = CATransform3DIdentity;
}

- (void)updateForProgress:(CGFloat)progress {
    ApplyTransitionFade(self.fadeType == MLWXrossTransitionTypeFadeIn, self.currentView.layer, self.nextView.layer, self.direction, progress);
}

@end
