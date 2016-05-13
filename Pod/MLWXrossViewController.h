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

typedef MLWXrossDirection MLWXrossPosition;

extern MLWXrossDirection MLWXrossDirectionNone;
extern MLWXrossDirection MLWXrossDirectionTop;
extern MLWXrossDirection MLWXrossDirectionBottom;
extern MLWXrossDirection MLWXrossDirectionLeft;
extern MLWXrossDirection MLWXrossDirectionRight;

MLWXrossDirection MLWXrossDirectionMake(NSInteger x, NSInteger y);
MLWXrossDirection MLWXrossDirectionFromOffset(CGPoint offset);
BOOL MLWXrossDirectionIsNone(MLWXrossDirection direction);
BOOL MLWXrossDirectionIsHorizontal(MLWXrossDirection direction);
BOOL MLWXrossDirectionIsVertical(MLWXrossDirection direction);
BOOL MLWXrossDirectionEquals(MLWXrossDirection direction, MLWXrossDirection direction2);

// Data Source

@protocol MLWXrossViewControllerDataSource <NSObject>

- (nullable UIViewController *)xross:(MLWXrossViewController *)xrossViewController viewControllerForDirection:(MLWXrossDirection)direction;

@end

// Delegate

@protocol MLWXrossViewControllerDelegate <NSObject>

@optional
- (void)xross:(MLWXrossViewController *)xrossViewController didMoveToDirection:(MLWXrossDirection)direction;
- (BOOL)xross:(MLWXrossViewController *)xrossViewController allowBounceToDirection:(MLWXrossDirection)direction;
- (void)xross:(MLWXrossViewController *)xrossViewController removedViewController:(UIViewController *)viewController;
- (void)xross:(MLWXrossViewController *)xrossViewController didScrollToDirection:(MLWXrossDirection)direction progress:(CGFloat)progress;

@end

// Xross

@interface MLWXrossViewController : UIViewController

@property (nullable, weak, nonatomic) id<MLWXrossViewControllerDataSource> dataSource;
@property (nullable, weak, nonatomic) id<MLWXrossViewControllerDelegate> delegate;
@property (nullable, readonly, nonatomic) UIViewController *viewController;
@property (nullable, readonly, nonatomic) UIViewController *nextViewController;
@property (readonly, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) BOOL bounces;
@property (assign, nonatomic, getter=isMovingDisabled) BOOL movingDisabled;
@property (readonly, nonatomic, getter=isMoving) BOOL moving;

// Use to deny parent scrolling when inner VC contains __kindof UIScrollView
@property (assign, nonatomic) BOOL denyHorizontalMovement;
@property (assign, nonatomic) BOOL denyVerticalMovement;
@property (assign, nonatomic) BOOL denyTopMovement;
@property (assign, nonatomic) BOOL denyBottomMovement;
@property (assign, nonatomic) BOOL denyLeftMovement;
@property (assign, nonatomic) BOOL denyRightMovement;

- (void)reloadData;
- (void)moveToDirection:(MLWXrossDirection)direction;
- (void)moveToDirection:(MLWXrossDirection)direction completion:(void (^_Nullable)())completion;

@end

NS_ASSUME_NONNULL_END
