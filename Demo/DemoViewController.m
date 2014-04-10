//
//  JCViewController.m
//  JCCircularCollectionViewProxy
//
//  Created by Jonathan Crooke on 10/04/2014.
//  Copyright (c) 2014 Jonathan Crooke. All rights reserved.
//

#import "DemoViewController.h"
#import "JCCircularCollectionViewProxy.h"
#import "DemoCell.h"

@interface DemoViewController () <UICollectionViewDelegateFlowLayout, JCCircularCollectionViewProxyDataSource>
@property (nonatomic, strong) JCCircularCollectionViewProxy *proxy;
@property (nonatomic, strong) NSArray *imageNames;
@end

@implementation DemoViewController

- (void)awakeFromNib {
  [super awakeFromNib];
  self.imageNames = @[@"flower1.jpg", @"flower2.jpg", @"flower3.jpg", @"flower4.jpg"];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.collectionView.contentInset = UIEdgeInsetsMake(50, 0, 50, 0);
  self.proxy = [self.collectionView circularProxyWithDataSource:self delegate:self];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.imageNames.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  /**
   *  The regular data source is still responsible for dequeueing a cell.
   *  Use the appropriate identifier here, but *don't configure*! Use the method below
   *  where the index path is correct for your *actual* data source.
   */
  return [collectionView dequeueReusableCellWithReuseIdentifier:@"DemoCell"
                                                   forIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView
         configureCell:(DemoCell*)cell
          forIndexPath:(NSIndexPath *)indexPath
{
  cell.imageView.image = [UIImage imageNamed:self.imageNames[indexPath.row]];
}

@end
