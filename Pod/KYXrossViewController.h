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

typedef CGSize KYXrossViewControllerDirection;

extern KYXrossViewControllerDirection KYXrossViewControllerDirectionNone;
extern KYXrossViewControllerDirection KYXrossViewControllerDirectionTop;
extern KYXrossViewControllerDirection KYXrossViewControllerDirectionBottom;
extern KYXrossViewControllerDirection KYXrossViewControllerDirectionLeft;
extern KYXrossViewControllerDirection KYXrossViewControllerDirectionRight;

KYXrossViewControllerDirection KYXrossViewControllerDirectionMake(NSInteger dx, NSInteger dy);
KYXrossViewControllerDirection KYXrossViewControllerDirectionFromOffset(CGPoint offset);
BOOL KYXrossViewControllerDirectionIsNone(KYXrossViewControllerDirection direction);
BOOL KYXrossViewControllerDirectionIsHorizontal(KYXrossViewControllerDirection direction);
BOOL KYXrossViewControllerDirectionIsVertical(KYXrossViewControllerDirection direction);
BOOL KYXrossViewControllerDirectionEquals(KYXrossViewControllerDirection direction, KYXrossViewControllerDirection direction2);

// Data Source

@protocol KYXrossViewControllerDataSource <NSObject>

- (nullable UIViewController *)xross:(KYXrossViewController *)xrossViewController viewControllerForDirection:(KYXrossViewControllerDirection)direction;

@end

// Delegate

@protocol KYXrossViewControllerDelegate <NSObject>

@optional
- (void)xross:(KYXrossViewController *)xrossViewController didMoveToDirection:(KYXrossViewControllerDirection)direction;
- (BOOL)xross:(KYXrossViewController *)xrossViewController allowBounceToDirection:(KYXrossViewControllerDirection)direction;
- (void)xross:(KYXrossViewController *)xrossViewController removedViewController:(UIViewController *)viewController;
- (void)xross:(KYXrossViewController *)xrossViewController didScrollToDirection:(KYXrossViewControllerDirection)direction progress:(CGFloat)progress;
- (BOOL)xross:(KYXrossViewController *)xrossViewController shouldOverScrollToDirection:(KYXrossViewControllerDirection)direction;

@end

// Xross

@interface KYXrossViewController : UIViewController

@property (nullable, weak, nonatomic) id<KYXrossViewControllerDataSource> dataSource;
@property (nullable, weak, nonatomic) id<KYXrossViewControllerDelegate> delegate;
@property (nullable, readonly, nonatomic) UIViewController *viewController;
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
- (void)moveToDirection:(KYXrossViewControllerDirection)direction;
- (void)moveToDirection:(KYXrossViewControllerDirection)direction controller:(nullable UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
