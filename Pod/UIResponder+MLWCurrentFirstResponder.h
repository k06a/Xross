//
//  UIResponder+MLWCurrentFirstResponder.h
//  Xross
//
//  Created by Anton Bukov on 26.01.16.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIResponder (MLWCurrentFirstResponder)

+ (__kindof UIResponder * _Nullable)mlw_currentFirstResponder;

@end

NS_ASSUME_NONNULL_END
