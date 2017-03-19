//
//  MLWXrossTransition.h
//  Pods
//
//  Created by Anton Bukov on 20.03.17.
//
//

#import "MLWXrossViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLWXrossTransition : NSObject

@property (weak, nonatomic) UIView *currentView;
@property (weak, nonatomic) UIView *nextView;
@property (assign, nonatomic) MLWXrossDirection direction;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCurrentView:(UIView *)currentView
                           nextView:(UIView *)nextView
                          direction:(MLWXrossDirection)direction;

- (void)updateForProgress:(CGFloat)progress;
- (void)finishTransition NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
