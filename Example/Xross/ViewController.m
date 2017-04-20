//
//  SecondViewController.m
//  XrossScreens
//
//  Created by Anton Bukov on 24.11.15.
//  Copyright © 2015 Searchie. All rights reserved.
//

#import <WebKit/WebKit.h>

#import <Xross/Xross.h>

#import "ViewController.h"

@interface ViewController () <MLWXrossViewControllerDataSource, MLWXrossViewControllerDelegate>

@property (assign, nonatomic) CGPoint position;
@property (strong, nonatomic) UISwitch *bounceSwitch;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;
@property (strong, nonatomic) UISegmentedControl *segmentedControlStack;
@property (strong, nonatomic) MLWXrossViewController *xross;
@property (strong, nonatomic) UIViewController *topViewController;
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) UIViewController *webViewController;
@property (strong, nonatomic) NSDictionary<NSValue *, UIColor *> *colors;

@end

@implementation ViewController

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
        
        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Default", @"Cube", @"Fade", @"Stack"]];
        [self.segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
        self.segmentedControl.selectedSegmentIndex = 0;
        [_topViewController.view addSubview:self.segmentedControl];
        self.segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
        [self.segmentedControl.centerXAnchor constraintEqualToAnchor:_topViewController.view.centerXAnchor].active = YES;
        [self.segmentedControl.topAnchor constraintEqualToAnchor:self.bounceSwitch.bottomAnchor constant:20.0].active = YES;
        [self.segmentedControl.widthAnchor constraintLessThanOrEqualToAnchor:self.segmentedControl.superview.widthAnchor multiplier:0.9].active = YES;
        
        self.segmentedControlStack = [[UISegmentedControl alloc] initWithItems:@[@"Default", @"Swing", @"Flat"]];
        self.segmentedControlStack.selectedSegmentIndex = 0;
        self.segmentedControlStack.hidden = YES;
        [_topViewController.view addSubview:self.segmentedControlStack];
        self.segmentedControlStack.translatesAutoresizingMaskIntoConstraints = NO;
        [self.segmentedControlStack.centerXAnchor constraintEqualToAnchor:_topViewController.view.centerXAnchor].active = YES;
        [self.segmentedControlStack.topAnchor constraintEqualToAnchor:self.segmentedControl.bottomAnchor constant:20.0].active = YES;
        [self.segmentedControlStack.widthAnchor constraintLessThanOrEqualToAnchor:self.segmentedControlStack.superview.widthAnchor multiplier:0.9].active = YES;
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
        self.webView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.webView.topAnchor constraintEqualToAnchor:self.webView.superview.topAnchor].active = YES;
        [self.webView.bottomAnchor constraintEqualToAnchor:self.webView.superview.bottomAnchor].active = YES;
        [self.webView.leadingAnchor constraintEqualToAnchor:self.webView.superview.leadingAnchor].active = YES;
        [self.webView.trailingAnchor constraintEqualToAnchor:self.webView.superview.trailingAnchor].active = YES;
    }
    return _webViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.xross = [[MLWXrossViewController alloc] init];
    self.xross.view.backgroundColor = [UIColor blackColor];
    self.xross.dataSource = self;
    self.xross.delegate = self;
    [self addChildViewController:self.xross];
    self.xross.view.frame = self.view.bounds;
    [self.view addSubview:self.xross.view];
    [self.xross didMoveToParentViewController:self];
    self.xross.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.xross.view.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.xross.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.xross.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.xross.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;

    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://apple.com"]]];
}

- (BOOL)shouldAutorotate {
    return self.xross.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.xross.supportedInterfaceOrientations;
}

- (void)segmentedControlChanged:(id)sender {
    self.segmentedControlStack.hidden = (self.segmentedControl.selectedSegmentIndex != self.segmentedControl.numberOfSegments - 1);
}

#pragma mark - Xross

- (nullable UIViewController *)xross:(MLWXrossViewController *)xrossViewController viewControllerForDirection:(MLWXrossDirection)direction {
    NSLog(@"%s (%@,%@)", __PRETTY_FUNCTION__, @(direction.x), @(direction.y));
    
    BOOL samePosition = MLWXrossDirectionIsNone(direction);
    CGPoint nextPosition = CGPointMake(self.position.x + direction.x,
                                       self.position.y + direction.y);

    if (samePosition || (self.position.x == 0 && self.position.y != 0 && nextPosition.y == 0)) {
        return self.topViewController;
    }

    if (samePosition || (self.position.y != 2 && nextPosition.y == 2)) {
        return self.webViewController;
    }

    UIColor *color = self.colors[[NSValue valueWithCGPoint:nextPosition]];
    if (color) {
        UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"vc-1"];
        controller.view.backgroundColor = color;
        return controller;
    }

    return nil;
}

- (MLWTransitionType)xross:(MLWXrossViewController *)xrossViewController transitionTypeToDirection:(MLWXrossDirection)direction {
    NSLog(@"%s (%@,%@)", __PRETTY_FUNCTION__, @(direction.x), @(direction.y));
    
    NSArray<NSNumber *> *dict = @[
        @(MLWTransitionTypeDefault),
        @(MLWTransitionTypeCube),
        @(MLWTransitionTypeFadeIn),
        @(MLWTransitionTypeStackPush),
    ];
    MLWTransitionType type = dict[self.segmentedControl.selectedSegmentIndex].unsignedIntegerValue;
    if (type == MLWTransitionTypeStackPush) {
        type += 2*self.segmentedControlStack.selectedSegmentIndex;
    }
    
    if (type == MLWTransitionTypeStackPush &&
        direction.x + direction.y < 0) {
        type = MLWTransitionTypeStackPop;
    }
    if (type == MLWTransitionTypeStackPushFlat &&
        direction.x + direction.y < 0) {
        type = MLWTransitionTypeStackPopFlat;
    }
    if (type == MLWTransitionTypeStackPushWithSwing &&
        direction.x + direction.y < 0) {
        type = MLWTransitionTypeStackPopWithSwing;
    }
    if (type == MLWTransitionTypeFadeIn &&
        direction.x + direction.y < 0) {
        type = MLWTransitionTypeFadeOut;
    }
    
    return type;
}

- (BOOL)xross:(MLWXrossViewController *)xrossViewController shouldBounceToDirection:(MLWXrossDirection)direction {
    NSLog(@"%s (%@,%@)", __PRETTY_FUNCTION__, @(direction.x), @(direction.y));
    return self.bounceSwitch.on;
}

- (void)xross:(MLWXrossViewController *)xrossViewController didMoveToDirection:(MLWXrossDirection)direction {
    NSLog(@"%s (%@,%@)", __PRETTY_FUNCTION__, @(direction.x), @(direction.y));
    self.position = CGPointMake(self.position.x + direction.x,
                                self.position.y + direction.y);
}

- (void)xross:(MLWXrossViewController *)xrossViewController removedViewController:(UIViewController *)viewController {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (BOOL)xross:(MLWXrossViewController *)xrossViewController shouldApplyInsetToDirection:(MLWXrossDirection)direction progress:(CGFloat)progress {
    NSLog(@"%s (%@,%@) %.4f%%", __PRETTY_FUNCTION__, @(direction.x), @(direction.y), progress*100);
    return YES;
}

- (void)xross:(MLWXrossViewController *)xrossViewController didScrollToDirection:(MLWXrossDirection)direction progress:(CGFloat)progress {
    NSLog(@"%s (%@,%@) %.4f%%", __PRETTY_FUNCTION__, @(direction.x), @(direction.y), progress*100);
}

@end
