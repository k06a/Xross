//
//  SecondViewController.m
//  XrossScreens
//
//  Created by Anton Bukov on 24.11.15.
//  Copyright © 2015 Searchie. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <Xross/Xross.h>

#import "SecondViewController.h"

@interface SecondViewController () <MLWXrossViewControllerDataSource, MLWXrossViewControllerDelegate>

@property (assign, nonatomic) CGPoint position;
@property (strong, nonatomic) UISwitch *bounceSwitch;
@property (strong, nonatomic) MLWXrossViewController *xross;
@property (strong, nonatomic) UIViewController *topViewController;
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) UIViewController *webViewController;
@property (strong, nonatomic) NSDictionary<NSValue *, UIColor *> *colors;

@end

@implementation SecondViewController

- (NSDictionary<NSValue *, UIColor *> *)colors {
    if (_colors == nil) {
        _colors = @{
            [NSValue valueWithCGPoint:CGPointMake(0, 1)] : [UIColor blueColor],
            [NSValue valueWithCGPoint:CGPointMake(1, 1)] : [UIColor redColor],
            [NSValue valueWithCGPoint:CGPointMake(2, 1)] : [UIColor grayColor],
            [NSValue valueWithCGPoint:CGPointMake(3, 1)] : [UIColor yellowColor],
        };
    }
    return _colors;
}

- (UIViewController *)topViewController {
    if (_topViewController == nil) {
        _topViewController = [[UIViewController alloc] init];
        _topViewController.view.backgroundColor = [UIColor greenColor];

        self.bounceSwitch = [[UISwitch alloc] init];
        [_topViewController.view addSubview:self.bounceSwitch];
        self.bounceSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        [self.bounceSwitch.centerXAnchor constraintEqualToAnchor:_topViewController.view.centerXAnchor].active = YES;
        [self.bounceSwitch.centerYAnchor constraintEqualToAnchor:_topViewController.view.centerYAnchor].active = YES;
    }
    return _topViewController;
}

- (WKWebView *)webView {
    if (_webView == nil) {
        _webView = [[WKWebView alloc] init];
        _webView.scrollView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
        _webView.scrollView.backgroundColor = [UIColor lightGrayColor];
    }
    return _webView;
}

- (UIViewController *)webViewController {
    if (_webViewController == nil) {
        _webViewController = [[UIViewController alloc] init];
        self.webView.frame = [UIScreen mainScreen].bounds;
        [_webViewController.view addSubview:self.webView];
    }
    return _webViewController;
}

- (void)buildViews {
    self.xross = [[MLWXrossViewController alloc] init];
    self.xross.view.backgroundColor = [UIColor blackColor];
    self.xross.dataSource = self;
    self.xross.delegate = self;
    self.xross.bounces = YES;
    [self addChildViewController:self.xross];
    self.xross.view.frame = self.view.bounds;
    [self.view addSubview:self.xross.view];
    [self.xross didMoveToParentViewController:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildViews];

    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://apple.com"]]];
}

#pragma mark - Xross

- (nullable UIViewController *)xross:(MLWXrossViewController *)xrossViewController viewControllerForDirection:(MLWXrossDirection)direction {
    BOOL samePosition = MLWXrossDirectionIsNone(direction);
    CGPoint position = CGPointMake(self.position.x + direction.x,
                                   self.position.y + direction.y);

    if (samePosition || (self.position.y != 0 && position.y == 0)) {
        return self.topViewController;
    }

    if (samePosition || (self.position.y != 2 && position.y == 2)) {
        return self.webViewController;
    }

    UIColor *color = self.colors[[NSValue valueWithCGPoint:position]];
    if (color) {
        UIViewController *controller = [[UIViewController alloc] init];
        controller.view.backgroundColor = color;
        return controller;
    }

    return nil;
}

- (BOOL)xross:(MLWXrossViewController *)xrossViewController allowBounceToDirection:(MLWXrossDirection)direction {
    return self.bounceSwitch.on;
}

- (void)xross:(MLWXrossViewController *)xrossViewController didMoveToDirection:(MLWXrossDirection)direction {
    self.position = CGPointMake(self.position.x + direction.x,
                                self.position.y + direction.y);
    NSLog(@"pos = (%@,%@)", @(self.position.x), @(self.position.y));
}

@end
