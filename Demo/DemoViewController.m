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
#import "Masonry.h"
#import "ReactiveCocoa.h"

@interface DemoViewController () <UICollectionViewDelegateFlowLayout, JCCircularCollectionViewProxyDataSource>
@property (nonatomic, strong) JCCircularCollectionViewProxy *proxy;
@property (nonatomic, weak) UIPageControl *pageControl;
@property (nonatomic, strong) NSArray *imageNames;
- (IBAction)randomPagePressed:(id)sender;
- (IBAction)jumpPressed:(id)sender;
- (NSUInteger) randomPage;
@end

@implementation DemoViewController

- (void)awakeFromNib {
  [super awakeFromNib];
  self.imageNames = @[@"flower1", @"flower2", @"flower3", @"flower4"];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.collectionView.contentInset = UIEdgeInsetsMake(50, 0, 50, 0);
  self.proxy = [self.collectionView circularProxyWithDataSource:self delegate:self];

  UIPageControl *pageControl = [[UIPageControl alloc] init];
  pageControl.translatesAutoresizingMaskIntoConstraints = NO;
  pageControl.numberOfPages = self.imageNames.count;
  [self.view addSubview:pageControl];
  [pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.view.mas_left);
    make.right.equalTo(self.view.mas_right);
    make.bottom.equalTo(self.view.mas_bottom);
    make.height.equalTo(@42);
  }];
  self.pageControl = pageControl;
  RAC(self.pageControl, currentPage) = RACObserve(self.proxy, currentPage);
  [[self.pageControl rac_signalForControlEvents:UIControlEventValueChanged]
   subscribeNext:^(UIPageControl *pageControl)
  {
    self.proxy.currentPage = pageControl.currentPage;
  }];
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

- (NSUInteger) randomPage {
  NSUInteger newPage = self.proxy.currentPage;
  while (newPage == self.proxy.currentPage) {
    newPage = arc4random() % self.imageNames.count;
  }
  return newPage;
}

- (IBAction)randomPagePressed:(id)sender {
  self.proxy.currentPage = self.randomPage;
//  [self.proxy setCurrentPage:self.randomPage animated:YES];
}

- (IBAction)jumpPressed:(id)sender {
  [self.proxy setCurrentPage:self.randomPage animated:NO];
}

@end
