//
//  MLWXrossScrollView.h
//  Xross
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLWXrossScrollView : UIScrollView

@property (assign, nonatomic) BOOL skipLayoutSubviewCalls;

- (void)setContentOffsetTo:(CGPoint)contentOffset animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
