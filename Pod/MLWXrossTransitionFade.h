//
//  MLWXrossTransitionFade.h
//  Pods
//
//  Created by Anton Bukov on 22.03.17.
//
//

#import <Xross/Xross.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MLWXrossTransitionTypeFade) {
    MLWXrossTransitionTypeFadeIn,
    MLWXrossTransitionTypeFadeOut,
};

@interface MLWXrossTransitionFade : MLWXrossTransition

@property (assign, nonatomic) MLWXrossTransitionTypeFade fadeType;

- (instancetype)initWithCurrentView:(UIView *)currentView
                           nextView:(UIView *)nextView
                          direction:(MLWXrossDirection)direction NS_UNAVAILABLE;

- (instancetype)initWithCurrentView:(UIView *)currentView
                           nextView:(UIView *)nextView
                          direction:(MLWXrossDirection)direction
                           fadeType:(MLWXrossTransitionTypeFade)fadeType;

+ (instancetype)fadeInTransitionWithCurrentView:(UIView *)currentView
                                       nextView:(UIView *)nextView
                                      direction:(MLWXrossDirection)direction;

+ (instancetype)fadeOutTransitionWithCurrentView:(UIView *)currentView
                                        nextView:(UIView *)nextView
                                       direction:(MLWXrossDirection)direction;

@end

NS_ASSUME_NONNULL_END
