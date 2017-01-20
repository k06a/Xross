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
@property (strong, nonatomic) UISegmentedControl *segmentedControl;
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
        
        UILabel *bounceLabel = [UILabel new];
        bounceLabel.text = @"Bounce Enabled:";
        [_topViewController.view addSubview:bounceLabel];
        bounceLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [bounceLabel.centerYAnchor constraintEqualToAnchor:self.bounceSwitch.centerYAnchor].active = YES;
        [bounceLabel.trailingAnchor constraintEqualToAnchor:self.bounceSwitch.leadingAnchor constant:-10.0].active = YES;
        
        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Default", @"3D Cube", @"Stack", @"Stack(swing)"]];
        self.segmentedControl.selectedSegmentIndex = 0;
        [_topViewController.view addSubview:self.segmentedControl];
        self.segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
        [self.segmentedControl.centerXAnchor constraintEqualToAnchor:_topViewController.view.centerXAnchor].active = YES;
        [self.segmentedControl.topAnchor constraintEqualToAnchor:self.bounceSwitch.bottomAnchor constant:20.0].active = YES;
        [self.segmentedControl.widthAnchor constraintLessThanOrEqualToAnchor:self.segmentedControl.superview.widthAnchor multiplier:0.9].active = YES;
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
    CGPoint nextPosition = CGPointMake(self.position.x + direction.x,
                                   self.position.y + direction.y);

    if (samePosition || (self.position.y != 0 && nextPosition.y == 0)) {
        return self.topViewController;
    }

    if (samePosition || (self.position.y != 2 && nextPosition.y == 2)) {
        return self.webViewController;
    }

    UIColor *color = self.colors[[NSValue valueWithCGPoint:nextPosition]];
    if (color) {
        UIViewController *controller = [[UIViewController alloc] init];
        controller.view.backgroundColor = color;
        return controller;
    }

    return nil;
}

- (MLWXrossTransitionType)xross:(MLWXrossViewController *)xrossViewController transitionTypeToDirection:(MLWXrossDirection)direction {
    NSArray<NSNumber *> *dict = @[
        @(MLWXrossTransitionTypeDefault),
        @(MLWXrossTransitionType3DCube),
        @(MLWXrossTransitionTypeStackNext),
        @(MLWXrossTransitionTypeStackNextWithSwing),
    ];
    MLWXrossTransitionType type = dict[self.segmentedControl.selectedSegmentIndex].unsignedIntegerValue;
    if (type == MLWXrossTransitionTypeStackNext &&
        direction.x + direction.y < 0) {
        type = MLWXrossTransitionTypeStackPrev;
    }
    if (type == MLWXrossTransitionTypeStackNextWithSwing &&
        direction.x + direction.y < 0) {
        type = MLWXrossTransitionTypeStackPrevWithSwing;
    }
    return type;
}

- (BOOL)xross:(MLWXrossViewController *)xrossViewController shouldBounceToDirection:(MLWXrossDirection)direction {
    return self.bounceSwitch.on;
}

- (void)xross:(MLWXrossViewController *)xrossViewController didMoveToDirection:(MLWXrossDirection)direction {
    self.position = CGPointMake(self.position.x + direction.x,
                                self.position.y + direction.y);
    NSLog(@"pos = (%@,%@)", @(self.position.x), @(self.position.y));
}

@end
