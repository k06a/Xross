//
//  KYXrossScrollView.m
//  South
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright © 2015 KupitYandex. All rights reserved.
//

#import "KYXrossScrollView.h"

@interface UIScrollView () <UIGestureRecognizerDelegate>

@end


@interface KYXrossScrollView ()

@end


@implementation KYXrossScrollView

// Allows inner UITableView swipe-to-delete gesture
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view.superview isKindOfClass:[UITableView class]]) {
        return YES;
    }
    if ([[[self class] superclass] instancesRespondToSelector:@selector(gestureRecognizer:shouldRequireFailureOfGestureRecognizer:)]) {
        return [super gestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
    }
    return NO;
}

@end
