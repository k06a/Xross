//
//  MLWXrossTransitionCube.h
//  Pods
//
//  Created by Anton Bukov on 20.03.17.
//
//

#import "MLWXrossTransition.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLWXrossTransitionCube : MLWXrossTransition

@property (assign, nonatomic) CGFloat minShadowAlpha; // Default 0.85
@property (assign, nonatomic) BOOL applyToCurrent; // Default YES
@property (assign, nonatomic) BOOL applyToNext; // Default YES
@property (assign, nonatomic) CGFloat maxAngle; // Default M_PI_2

@end

NS_ASSUME_NONNULL_END
