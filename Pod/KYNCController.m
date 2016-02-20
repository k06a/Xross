//
//  KYNCController.m
//  Pods
//
//  Created by Anton Bukov on 26.01.16.
//
//

#import <libextobjc/extobjc.h>
#import "KYNCController.h"

@interface KYNCController ()

@property (strong, nonatomic) NSMutableArray *observers;

@end

@implementation KYNCController

- (NSMutableArray *)observers {
    if (_observers == nil) {
        _observers = [NSMutableArray array];
    }
    return _observers;
}

- (void)dealloc {
    [self removeAllObservers];
}

- (void)addObserverForName:(nullable NSString *)name object:(nullable id)object queue:(NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block {
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:name object:object queue:queue usingBlock:block];
    [self.observers addObject:observer];
}

- (void)removeAllObservers {
    for (id observer in self.observers) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
    self.observers = nil;
}

@end

//

@implementation NSObject (KYNCController)

@synthesizeAssociation(NSObject, NCController)

@end
