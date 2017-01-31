//
//  ItemViewController.m
//  Xross
//
//  Created by Anton Bukov on 27.01.17.
//  Copyright © 2017 Andrew Podkovyrin. All rights reserved.
//

#import "ItemViewController.h"

@interface ItemViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation ItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    for (UICollectionView *collectionView in self.view.subviews) {
        if ([collectionView isKindOfClass:[UICollectionView class]]) {
            collectionView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
            collectionView.backgroundColor = [UIColor clearColor];
        }
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 20;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"cell-1" forIndexPath:indexPath];
}

@end
