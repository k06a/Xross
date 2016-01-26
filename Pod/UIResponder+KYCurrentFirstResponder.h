//
//  UIResponder+KYCurrentFirstResponder.h
//  Pods
//
//  Created by Anton Bukov on 26.01.16.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIResponder (KYCurrentFirstResponder)

+ (__kindof UIResponder * _Nullable)ky_currentFirstResponder;

@end

NS_ASSUME_NONNULL_END
