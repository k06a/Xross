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

@interface MLWXrossScrollView : UIScrollView <UIGestureRecognizerDelegate>

@property (nullable, weak, nonatomic) id<MLWXrossScrollViewDelegate> delegate;

@property (assign, nonatomic) BOOL skipLayoutSubviewCalls;
@property (assign, nonatomic) CGPoint originOffset;

- (void)setContentOffsetTo:(CGPoint)contentOffset animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
