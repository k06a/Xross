//
//  MLWXrossScrollView.h
//  Xross
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MLWXrossScrollView;

@protocol MLWXrossScrollViewDelegate <UIScrollViewDelegate>

@optional
- (CGPoint)scrollView:(MLWXrossScrollView *)scrollView willScrollToContentOffset:(CGPoint)contentOffset;

@end

//

@protocol MLWXrossGestureRecognizerDelegate <UIGestureRecognizerDelegate>

@optional
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer allowXrossPanGestureRecognizerToWorkSimultaneously:(nonnull UIGestureRecognizer *)xrossGestureRecognizer; // Default is \c YES for non UIScrollView pan gesture recognizers and \c NO for UIScrollView gesture recognizers

@end

//

@interface MLWXrossScrollView : UIScrollView <UIGestureRecognizerDelegate>

@property (nullable, weak, nonatomic) id<MLWXrossScrollViewDelegate> delegate;

@property (assign, nonatomic) CGPoint originOffsetInSteps;
@property (readonly, nonatomic) CGPoint originOffset;
@property (readonly, nonatomic) CGPoint relativeContentOffset;
@property (assign, nonatomic) CGPoint nextDirection;

@property (nullable, strong, nonatomic) UIView *centerView;
@property (nullable, readonly, strong, nonatomic) UIView *nextView;
- (void)setNextView:(UIView *)nextView toDirection:(CGPoint)direction;

- (void)setContentOffsetTo:(CGPoint)contentOffset animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
