//
//  UIScrollView+KYNotScrollSuperview.h
//  Pods
//
//  Created by Anton Bukov on 26.01.16.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (KYNotScrollSuperview)

@property (assign, nonatomic) BOOL ky_notScrollSuperview;
@property (assign, nonatomic) BOOL ky_notScrollableBySubviews;

@end

NS_ASSUME_NONNULL_END
