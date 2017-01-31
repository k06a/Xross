//
//  UIScrollView+MLWNotScrollSuperview.h
//  Xross
//
//  Created by Anton Bukov on 26.01.16.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (MLWNotScrollSuperview)

@property (assign, nonatomic) BOOL mlw_notScrollSuperview;
@property (assign, nonatomic) BOOL mlw_notScrollableBySubviews;
@property (readonly, strong, nonatomic) UIScrollView *mlw_isInsideAttemptToDragParent;

@end

NS_ASSUME_NONNULL_END
