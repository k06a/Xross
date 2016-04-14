//
//  XrossViewController.h
//  XrossScreens
//
//  Created by Anton Bukov on 24.11.15.
//  Copyright © 2015 Searchie. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class KYXrossViewController;

typedef struct {
    NSInteger x;
    NSInteger y;
} KYXrossDirection;

typedef KYXrossDirection KYXrossPosition;

extern KYXrossDirection KYXrossDirectionNone;
extern KYXrossDirection KYXrossDirectionTop;
extern KYXrossDirection KYXrossDirectionBottom;
extern KYXrossDirection KYXrossDirectionLeft;
extern KYXrossDirection KYXrossDirectionRight;

KYXrossDirection KYXrossDirectionMake(NSInteger x, NSInteger y);
KYXrossDirection KYXrossDirectionFromOffset(CGPoint offset);
BOOL KYXrossDirectionIsNone(KYXrossDirection direction);
BOOL KYXrossDirectionIsHorizontal(KYXrossDirection direction);
BOOL KYXrossDirectionIsVertical(KYXrossDirection direction);
BOOL KYXrossDirectionEquals(KYXrossDirection direction, KYXrossDirection direction2);

// Data Source

@protocol KYXrossViewControllerDataSource <NSObject>

- (nullable UIViewController *)xross:(KYXrossViewController *)xrossViewController viewControllerForDirection:(KYXrossDirection)direction;

@end

// Delegate

@protocol KYXrossViewControllerDelegate <NSObject>

@optional
- (void)xross:(KYXrossViewController *)xrossViewController didMoveToDirection:(KYXrossDirection)direction;
- (BOOL)xross:(KYXrossViewController *)xrossViewController allowBounceToDirection:(KYXrossDirection)direction;
- (void)xross:(KYXrossViewController *)xrossViewController removedViewController:(UIViewController *)viewController;
- (void)xross:(KYXrossViewController *)xrossViewController didScrollToDirection:(KYXrossDirection)direction progress:(CGFloat)progress;

@end

// Xross

@interface KYXrossViewController : UIViewController

@property (nullable, weak, nonatomic) id<KYXrossViewControllerDataSource> dataSource;
@property (nullable, weak, nonatomic) id<KYXrossViewControllerDelegate> delegate;
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
- (void)moveToDirection:(KYXrossDirection)direction;

@end

NS_ASSUME_NONNULL_END
