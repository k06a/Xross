//
//  MLWXrossViewController.h
//  Xross
//
//  Created by Anton Bukov on 24.11.15.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MLWXrossViewController;

typedef struct {
    NSInteger x;
    NSInteger y;
} MLWXrossDirection;

typedef enum : NSUInteger {
    MLWXrossTransitionTypeDefault,
    MLWXrossTransitionType3DCube,
    MLWXrossTransitionType3DCubeTo,
    MLWXrossTransitionType3DCubeFrom,
    MLWXrossTransitionTypeStackNext,
    MLWXrossTransitionTypeStackPrev,
    MLWXrossTransitionTypeStackNextWithSwing,
    MLWXrossTransitionTypeStackPrevWithSwing,
    MLWXrossTransitionTypeCustom = 0x10000,
} MLWXrossTransitionType;

typedef MLWXrossDirection MLWXrossPosition;

extern MLWXrossDirection MLWXrossDirectionNone;
extern MLWXrossDirection MLWXrossDirectionTop;
extern MLWXrossDirection MLWXrossDirectionBottom;
extern MLWXrossDirection MLWXrossDirectionLeft;
extern MLWXrossDirection MLWXrossDirectionRight;

MLWXrossDirection MLWXrossDirectionMake(CGFloat x, CGFloat y);
MLWXrossDirection MLWXrossDirectionFromOffset(CGPoint offset);
BOOL MLWXrossDirectionIsNone(MLWXrossDirection direction);
BOOL MLWXrossDirectionIsHorizontal(MLWXrossDirection direction);
BOOL MLWXrossDirectionIsVertical(MLWXrossDirection direction);
BOOL MLWXrossDirectionEquals(MLWXrossDirection direction, MLWXrossDirection direction2);

typedef void (*MLWCustomTransitionTypeFunctor)(CALayer *currLayer, CALayer *nextLayer, MLWXrossDirection direction, CGFloat progress);

// Data Source

@protocol MLWXrossViewControllerDataSource <NSObject>

- (nullable UIViewController *)xross:(MLWXrossViewController *)xrossViewController viewControllerForDirection:(MLWXrossDirection)direction;

@end

// Delegate

@protocol MLWXrossViewControllerDelegate <NSObject>

@optional
- (void)xross:(MLWXrossViewController *)xrossViewController didMoveToDirection:(MLWXrossDirection)direction;
- (BOOL)xross:(MLWXrossViewController *)xrossViewController shouldBounceToDirection:(MLWXrossDirection)direction;
- (void)xross:(MLWXrossViewController *)xrossViewController removedViewController:(UIViewController *)viewController;
- (void)xross:(MLWXrossViewController *)xrossViewController didScrollToDirection:(MLWXrossDirection)direction progress:(CGFloat)progress;
- (BOOL)xross:(MLWXrossViewController *)xrossViewController shouldApplyInsetToDirection:(MLWXrossDirection)direction progress:(CGFloat)progress;
- (MLWXrossTransitionType)xross:(MLWXrossViewController *)xrossViewController transitionTypeToDirection:(MLWXrossDirection)direction;

@end

// Xross

@interface MLWXrossViewController<__covariant ChildViewControllerType : UIViewController *> : UIViewController

@property (nullable, weak, nonatomic) id<MLWXrossViewControllerDataSource> dataSource;
@property (nullable, weak, nonatomic) id<MLWXrossViewControllerDelegate> delegate;
@property (nullable, readonly, nonatomic) ChildViewControllerType viewController;
@property (nullable, readonly, nonatomic) ChildViewControllerType nextViewController;
@property (readonly, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) BOOL bounces;
@property (assign, nonatomic, getter=isMovingDisabled) BOOL movingDisabled;
@property (readonly, nonatomic, getter=isMoving) BOOL moving;
@property (assign, nonatomic) MLWCustomTransitionTypeFunctor customTransitionTypeFunctor;

+ (Class)xrossViewClass;
- (void)reloadData;
- (void)moveToDirection:(MLWXrossDirection)direction;
- (void)moveToDirection:(MLWXrossDirection)direction completion:(void (^_Nullable)())completion;

@end

NS_ASSUME_NONNULL_END
