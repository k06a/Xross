//
//  MLWXrossTransitionStack.h
//  Pods
//
//  Created by Anton Bukov on 20.03.17.
//
//

#import "MLWXrossTransition.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MLWXrossTransitionTypeStack) {
    MLWXrossTransitionTypeStackPush,
    MLWXrossTransitionTypeStackPop,
};

@interface MLWXrossTransitionStack : MLWXrossTransition

@property (assign, nonatomic) MLWXrossTransitionTypeStack stackType;
@property (assign, nonatomic) CGFloat minShadowAlpha; // Default 0.85
@property (assign, nonatomic) CGFloat minScaleAchievedByDistance; // Default 0.9
@property (assign, nonatomic) CGFloat maxSwingAngle; // Default M_PI_2/6

- (instancetype)initWithCurrentView:(UIView *)currentView
                           nextView:(UIView *)nextView
                          direction:(MLWXrossDirection)direction NS_UNAVAILABLE;

- (instancetype)initWithCurrentView:(UIView *)currentView
                           nextView:(UIView *)nextView
                          direction:(MLWXrossDirection)direction
                          stackType:(MLWXrossTransitionTypeStack)stackType;

+ (instancetype)stackPushTransitionWithCurrentView:(UIView *)currentView
                                          nextView:(UIView *)nextView
                                         direction:(MLWXrossDirection)direction;

+ (instancetype)stackPopTransitionWithCurrentView:(UIView *)currentView
                                         nextView:(UIView *)nextView
                                        direction:(MLWXrossDirection)direction;

@end

NS_ASSUME_NONNULL_END
