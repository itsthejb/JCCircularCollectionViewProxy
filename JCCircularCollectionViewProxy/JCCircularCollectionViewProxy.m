//
//  JCCircularCollectionViewProxy.m
//
//  Created by Jonathan Crooke on 10/04/2014.
//  Copyright (c) 2014 Jonathan Crooke. All rights reserved.
//

#import "JCCircularCollectionViewProxy.h"

static const NSInteger kEndlessMultiplier = 7000;

@interface JCCircularCollectionViewProxy ()
@property (nonatomic, weak) id <JCCircularCollectionViewProxyDataSource> dataSource;
@property (nonatomic, weak) id <UICollectionViewDelegateFlowLayout> delegate;
@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, assign) CGPoint lastOffset;
- (UICollectionViewFlowLayout*) flowLayout;
- (NSUInteger) trueItemCount;
- (NSUInteger) numberOfPaddingCells;
- (CGFloat) itemWidth;
- (CGFloat) itemWidthPlusSpacing;
- (NSUInteger) numberOfVisibleWholeCells;
@end

#pragma mark -

@implementation JCCircularCollectionViewProxy

- (id)init { return [super init]; }

+ (instancetype) proxyWithDataSource:(id <JCCircularCollectionViewProxyDataSource>) dataSource
                            delegate:(id <UICollectionViewDelegateFlowLayout>)delegate
{
  JCCircularCollectionViewProxy *proxy = [[self alloc] init];
  proxy.dataSource = dataSource;
  proxy.delegate = delegate;
  return proxy;
}

- (void) configureForCollectionView:(UICollectionView*) collectionView {
  NSAssert(self.dataSource, @"No data source provided");
  NSAssert(!CGSizeEqualToSize(collectionView.frame.size, CGSizeZero),
           @"Collection view must be laid-out already");
  NSAssert([self numberOfSectionsInCollectionView:collectionView] < 2,
           @"Only one section supported");

  // collection view config
  self.collectionView = collectionView;
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  self.collectionView.pagingEnabled = NO;
  self.collectionView.showsHorizontalScrollIndicator = NO;
  self.collectionView.showsVerticalScrollIndicator = NO;
  self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;

  // layout config
  CGFloat sidePadding = (CGRectGetWidth(self.collectionView.frame) -
                         (self.numberOfVisibleWholeCells * self.itemWidth)) / 2;
  self.flowLayout.sectionInset = UIEdgeInsetsMake(0, sidePadding, 0, sidePadding);
  self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

  // scroll to centre
  dispatch_async(dispatch_get_main_queue(), ^{
    NSUInteger index = self.trueItemCount * kEndlessMultiplier / 2;
    [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
                           atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                   animated:NO];
  });
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  NSUInteger item = scrollView.contentOffset.x / self.itemWidthPlusSpacing;
  NSComparisonResult direction = [@(self.lastOffset.x) compare:@(scrollView.contentOffset.x)];

  if (item == self.trueItemCount - self.numberOfPaddingCells && direction == NSOrderedAscending) {
    // reset to beginning
    self.lastOffset = CGPointMake(self.itemWidthPlusSpacing *
                                  self.numberOfPaddingCells,
                                  0);
    dispatch_async(dispatch_get_main_queue(), ^{
      scrollView.contentOffset = self.lastOffset;
    });
  }
  else if (item == self.numberOfPaddingCells - 1 && direction == NSOrderedDescending) {
    // reset to end
    self.lastOffset = CGPointMake(self.itemWidthPlusSpacing *
                                  (self.trueItemCount - self.numberOfPaddingCells),
                                  0);
    dispatch_async(dispatch_get_main_queue(), ^{
      scrollView.contentOffset = self.lastOffset;
    });
  }
  else {
    self.lastOffset = self.collectionView.contentOffset;
  }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
  NSUInteger item = scrollView.contentOffset.x / self.itemWidthPlusSpacing;
  NSUInteger newItem = item + (velocity.x * 1.5) + 1;
    UICollectionViewLayoutAttributes *attrs = [self.collectionView
                                             layoutAttributesForItemAtIndexPath:
                                             [NSIndexPath indexPathForRow:newItem
                                                                inSection:0]];
  CGPoint point = attrs.frame.origin;
  point.x -= self.flowLayout.sectionInset.left;
  *targetContentOffset = point;
}

#pragma mark Calculated

- (NSUInteger) numberOfPaddingCells { return self.numberOfVisibleWholeCells + 2; }

- (NSUInteger) numberOfVisibleWholeCells {
  return CGRectGetWidth(self.collectionView.frame) / self.itemWidthPlusSpacing;
}

- (CGFloat) itemWidth {
  CGSize itemSize = self.flowLayout.itemSize;
  if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
    itemSize = [self.delegate collectionView:self.collectionView
                                      layout:self.flowLayout
                      sizeForItemAtIndexPath:nil];
  }
  return itemSize.width;
}

- (CGFloat) itemWidthPlusSpacing { return self.itemWidth + self.flowLayout.minimumInteritemSpacing; }

- (UICollectionViewFlowLayout*) flowLayout {
  UICollectionViewFlowLayout *layout = (id) self.collectionView.collectionViewLayout;
  NSAssert([layout isKindOfClass:[UICollectionViewFlowLayout class]],
           @"Only compatible with %@", NSStringFromClass([UICollectionViewFlowLayout class]));
  return layout;
}

- (NSUInteger) trueItemCount {
  return [self.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
    return [self.dataSource numberOfSectionsInCollectionView:collectionView];
  }
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.trueItemCount * kEndlessMultiplier;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  UICollectionViewCell *cell = [self.dataSource collectionView:collectionView
                                        cellForItemAtIndexPath:indexPath];
  NSInteger itemIndex = indexPath.row % self.trueItemCount;
  [self.dataSource collectionView:self.collectionView
                    configureCell:cell
                     forIndexPath:[NSIndexPath indexPathForRow:itemIndex inSection:0]];
  return cell;
}

#pragma mark Delegate / data source message forwarding

- (BOOL)respondsToSelector:(SEL)aSelector {
  return ([super respondsToSelector:aSelector] ||
          [self.dataSource respondsToSelector:aSelector] ||
          [self.delegate respondsToSelector:aSelector]);
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  if ([self.delegate respondsToSelector:[invocation selector]]) {
    [invocation invokeWithTarget:self.delegate];
  }
  else if ([self.dataSource respondsToSelector:[invocation selector]]) {
    [invocation invokeWithTarget:self.dataSource];
  }
  else {
    [super forwardInvocation:invocation];
  }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
  NSMethodSignature *signature = [super methodSignatureForSelector:selector];
  if (!signature) {
    signature = [(id) self.delegate methodSignatureForSelector:selector];
  }
  if (!signature) {
    signature = [(id) self.dataSource methodSignatureForSelector:selector];
  }
  return signature;
}

@end

#pragma mark -

@implementation UICollectionView (CircularProxy)
- (JCCircularCollectionViewProxy*) circularProxyWithDataSource:(id <JCCircularCollectionViewProxyDataSource>) dataSource
                                                      delegate:(id <UICollectionViewDelegateFlowLayout>)delegate
{
  JCCircularCollectionViewProxy *proxy = [JCCircularCollectionViewProxy proxyWithDataSource:dataSource
                                                                                   delegate:delegate];
  [proxy configureForCollectionView:self];
  return proxy;
}
@end
