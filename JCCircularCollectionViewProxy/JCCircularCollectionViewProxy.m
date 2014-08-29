//
//  JCCircularCollectionViewProxy.m
//
//  Created by Jonathan Crooke on 10/04/2014.
//  Copyright (c) 2014 Jonathan Crooke. All rights reserved.
//

#import "JCCircularCollectionViewProxy.h"

static const CGFloat kPagingRatio = 0.5;
static const CGFloat kPagingConstant = 1.0;
static const NSInteger kEndlessMultiplier = 7000;
static const NSUInteger kFixedSection = 0;

@interface JCCircularCollectionViewProxy ()
@property (nonatomic, weak) id <JCCircularCollectionViewProxyDataSource> dataSource;
@property (nonatomic, weak) id <UICollectionViewDelegateFlowLayout> delegate;
@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, assign) CGPoint lastOffset;
- (void) setCurrentPage:(NSUInteger)currentPage animated:(BOOL) animated;
- (UICollectionViewFlowLayout*) flowLayout;
- (NSUInteger) trueItemCount;
- (NSUInteger) currentItemInExpandedSpace;
- (NSUInteger) expandedSpaceIndexForTrueDataSourceIndex:(NSUInteger) index;
- (NSUInteger) numberOfPaddingCells;
- (CGFloat) itemWidth;
- (CGFloat) itemWidthPlusSpacing;
- (NSUInteger) numberOfVisibleWholeCells;
- (CGSize) trueContentSize;
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

- (void) configureForCollectionView:(UICollectionView*) collectionView
{
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
  self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
}

- (void) reloadDataWithCompletion:(dispatch_block_t) completion
{
  if (!CGSizeEqualToSize(self.collectionView.frame.size, CGSizeZero)) {
    [self.collectionView reloadData];

    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.trueItemCount) {
        // layout config
        CGFloat sidePadding = (CGRectGetWidth(self.collectionView.frame) -
                               (self.numberOfVisibleWholeCells * self.itemWidth)) / 2;
        self.flowLayout.sectionInset = UIEdgeInsetsMake(0, sidePadding, 0, sidePadding);
        // scroll to middle
        NSUInteger index = self.trueItemCount * kEndlessMultiplier / 2 + self.currentPage;
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:kFixedSection]
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                            animated:NO];
        completion ? completion() : nil;
      } else {
        completion ? completion() : nil;
      }
    });
  }
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  NSUInteger item = self.currentItemInExpandedSpace;

  if (scrollView.isDragging) {
    NSUInteger page = item % self.trueItemCount;
    if (page != self.currentPage) {
      [self willChangeValueForKey:@"currentPage"];
      _currentPage = page;
      [self didChangeValueForKey:@"currentPage"];
    }
  }

  NSComparisonResult direction = [@(self.lastOffset.x) compare:@(scrollView.contentOffset.x)];

  if (item == self.trueItemCount - self.numberOfPaddingCells && direction == NSOrderedAscending) {
    // reset to beginning
    self.lastOffset = CGPointMake(self.itemWidthPlusSpacing *
                                  self.numberOfPaddingCells,
                                  scrollView.contentOffset.y);
    dispatch_async(dispatch_get_main_queue(), ^{
      scrollView.contentOffset = self.lastOffset;
    });
  }
  else if (item == self.numberOfPaddingCells - 1 && direction == NSOrderedDescending) {
    // reset to end
    self.lastOffset = CGPointMake(self.itemWidthPlusSpacing *
                                  (self.trueItemCount - self.numberOfPaddingCells),
                                  scrollView.contentOffset.y);
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
  NSUInteger newItem = item + (velocity.x * kPagingRatio) + kPagingConstant;
  UICollectionViewLayoutAttributes *attrs = [self.collectionView
                                             layoutAttributesForItemAtIndexPath:
                                             [NSIndexPath indexPathForRow:newItem
                                                                inSection:kFixedSection]];
  CGPoint point = attrs.frame.origin;
  point.x -= self.flowLayout.sectionInset.left;
  *targetContentOffset = point;
}

#pragma mark Wrapped properties

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point {
  // normalize the point into the bounds of the "true" data source
  point.x = fmodf(point.x, self.trueContentSize.width);
  return [self.collectionView indexPathForItemAtPoint:point];
}

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath
               atScrollPosition:(UICollectionViewScrollPosition)scrollPosition
                       animated:(BOOL)animated
{
  [self.collectionView scrollToItemAtIndexPath:
   [NSIndexPath indexPathForRow:[self expandedSpaceIndexForTrueDataSourceIndex:indexPath.row]
                      inSection:kFixedSection]
                              atScrollPosition:scrollPosition
                                      animated:animated];
}

- (void)setCurrentPage:(NSUInteger)currentPage {
  [self setCurrentPage:currentPage animated:YES];
}

- (void) setCurrentPage:(NSUInteger)currentPage
               animated:(BOOL) animated
{
  NSParameterAssert(currentPage < self.trueItemCount);

  [self willChangeValueForKey:@"currentPage"];
  _currentPage = currentPage;
  [self didChangeValueForKey:@"currentPage"];

  [self scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentPage inSection:kFixedSection]
               atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                       animated:animated];
}

#pragma mark Calculated

- (NSUInteger) expandedSpaceIndexForTrueDataSourceIndex:(NSUInteger) index {
  NSUInteger currentZone = self.currentItemInExpandedSpace / kEndlessMultiplier;
  return (currentZone * kEndlessMultiplier) + index;
}

- (NSUInteger) currentItemInExpandedSpace {
  return ((self.collectionView.contentOffset.x + (self.itemWidthPlusSpacing / 2)) /
          self.itemWidthPlusSpacing);
}

- (NSUInteger) numberOfPaddingCells { return self.numberOfVisibleWholeCells + 2; }

- (NSUInteger) numberOfVisibleWholeCells {
  return CGRectGetWidth(self.collectionView.frame) / self.itemWidthPlusSpacing;
}

- (CGSize) trueContentSize {
  CGSize contentSize = self.collectionView.contentSize;
  contentSize.width = self.trueItemCount * self.itemWidthPlusSpacing;
  return contentSize;
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
  return [self.dataSource collectionView:self.collectionView numberOfItemsInSection:kFixedSection];
}

- (NSIndexPath*) indexPathInTrueDataSourceForIndexPath:(NSIndexPath*) indexPath {
  NSInteger itemIndex = indexPath.row % self.trueItemCount;
  return [NSIndexPath indexPathForRow:itemIndex inSection:kFixedSection];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
    return [self.dataSource numberOfSectionsInCollectionView:collectionView];
  }
  return kFixedSection + 1;
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
  [self.dataSource collectionView:self.collectionView
                    configureCell:cell
                     forIndexPath:[self indexPathInTrueDataSourceForIndexPath:indexPath]];
  return cell;
}

#pragma mark UICollectionViewDelegate

- (void)    collectionView:(UICollectionView *)collectionView
  didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self.delegate respondsToSelector:_cmd]) {
    [self.delegate collectionView:collectionView
         didSelectItemAtIndexPath:[self indexPathInTrueDataSourceForIndexPath:indexPath]];
  }
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
