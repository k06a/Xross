//
//  ViewController.m
//  XrossScreens
//
//  Created by Anton Bukov on 23.11.15.
//  Copyright © 2015 Searchie. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "ViewController.h"

@interface ViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) WKWebView *webView;

@property (readonly, nonatomic) NSInteger currentPage;

@end

@implementation ViewController

- (NSInteger)currentPage {
    if (self.pageViewController.viewControllers.count == 0) {
        return -1;
    }
    return self.pageViewController.viewControllers.firstObject.view.tag;
}

- (void)tap:(UITapGestureRecognizer *)recognizer {
    UIViewController *nextController = [self pageViewController:self.pageViewController viewControllerAfterViewController:self.pageViewController.viewControllers.firstObject];
    if (nextController == nil) {
        return;
    }
    nextController.view.tag = self.currentPage + 1;
    [self.pageViewController.view addSubview:nextController.view];
    nextController.view.frame = self.pageViewController.view.bounds;

    nextController.view.alpha = 0.0;
    recognizer.view.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.5 delay:0.0 options:(UIViewAnimationOptionCurveEaseInOut) animations:^{
        nextController.view.alpha = 1.0;
    }
        completion:^(BOOL finished) {
            [self.pageViewController setViewControllers:@[ nextController ] direction:(UIPageViewControllerNavigationDirectionForward) animated:NO completion:nil];
            recognizer.view.userInteractionEnabled = YES;
        }];
}

- (void)buildViews {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.scrollsToTop = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;

    self.topView = [[UIView alloc] init];
    self.topView.backgroundColor = [UIColor greenColor];
    [self.scrollView addSubview:self.topView];
    [self.topView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor].active = YES;
    [self.topView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor].active = YES;
    [self.topView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor].active = YES;

    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:(UIPageViewControllerTransitionStyleScroll) navigationOrientation:(UIPageViewControllerNavigationOrientationHorizontal) options:nil];
    [self.pageViewController.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    self.pageViewController.view.backgroundColor = [UIColor blackColor];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    [self addChildViewController:self.pageViewController];
    [self.scrollView addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    self.pageViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pageViewController.view.topAnchor constraintEqualToAnchor:self.topView.bottomAnchor].active = YES;
    [self.pageViewController.view.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor].active = YES;
    [self.pageViewController.view.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor].active = YES;

    self.webView = [[WKWebView alloc] init];
    self.webView.scrollView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    self.webView.scrollView.contentOffset = CGPointMake(0, 20);
    self.webView.scrollView.backgroundColor = [UIColor lightGrayColor];
    [self.scrollView addSubview:self.webView];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webView.topAnchor constraintEqualToAnchor:self.pageViewController.view.bottomAnchor].active = YES;
    [self.webView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor].active = YES;
    [self.webView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor].active = YES;
    [self.webView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor].active = YES;

    for (UIView *view in @[ self.topView, self.pageViewController.view, self.webView ]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view.widthAnchor constraintEqualToConstant:[UIScreen mainScreen].bounds.size.width].active = YES;
        [view.heightAnchor constraintEqualToConstant:[UIScreen mainScreen].bounds.size.height].active = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self buildViews];

    [self.pageViewController setViewControllers:@[ [self pageViewController:self.pageViewController viewControllerAfterViewController:self.pageViewController] ] direction:(UIPageViewControllerNavigationDirectionForward) animated:NO completion:nil];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://apple.com"]]];
}

#pragma mark - Page View

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if (self.currentPage == 4) {
        return nil;
    }
    UIViewController *controller = [[UIViewController alloc] init];
    controller.view.tag = self.currentPage + 1;
    controller.view.backgroundColor = @[ [UIColor blueColor],
                                         [UIColor redColor],
                                         [UIColor grayColor],
                                         [UIColor yellowColor],
                                         [UIColor brownColor] ][self.currentPage + 1];
    return controller;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if (self.currentPage == 0) {
        return nil;
    }
    UIViewController *controller = [[UIViewController alloc] init];
    controller.view.tag = self.currentPage - 1;
    controller.view.backgroundColor = @[ [UIColor blueColor],
                                         [UIColor redColor],
                                         [UIColor grayColor],
                                         [UIColor yellowColor],
                                         [UIColor brownColor] ][self.currentPage - 1];
    return controller;
}

@end
