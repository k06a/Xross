//
//  KYXrossScrollView.h
//  South
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright © 2015 KupitYandex. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KYXrossScrollView : UIScrollView

@property (assign, nonatomic) CGPoint contentOffsetTo;

- (void)setContentOffsetTo:(CGPoint)contentOffset animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
