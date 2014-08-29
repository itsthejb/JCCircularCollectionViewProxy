//
//  JCCircularCollectionViewProxy.h
//
//  Created by Jonathan Crooke on 10/04/2014.
//  Copyright (c) 2014 Jonathan Crooke. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Protocol wrapper.
 
 @note `-collectionView:cellForItemAtIndexPath:` must still be overridden in order to dequeue
 the appropriate cell. *Don't customise the cell here*; use
 `-collectionView:configureCell:forIndexPath:`

  - (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView
                     cellForItemAtIndexPath:(NSIndexPath *)indexPath
  {
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"MyIdentifier"
                                                     forIndexPath:indexPath];
  }

 */
@protocol JCCircularCollectionViewProxyDataSource <UICollectionViewDataSource>
@required
/**
 *  Required additional method for actually configuring the dequeud cell.
 *
 *  @param collectionView The collection view
 *  @param cell           A dequeued reusable cell for the collection view
 *  @note  #protip - cast the cell argument to the expected cell subclass.
 *  @param indexPath      "True" index path for the cell, based on the data source's
 *  real item count.
 */
- (void) collectionView:(UICollectionView*) collectionView
          configureCell:(id) cell
           forIndexPath:(NSIndexPath*) indexPath;
@end

/**
 *  Proxy object
 */
@interface JCCircularCollectionViewProxy : NSObject
  <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

/**
 *  The current *page* in the context of the true data source.
 */
@property (nonatomic, assign, readwrite) NSUInteger currentPage;

/**
 *  Change the current page
 *
 *  @param currentPage New current page
 *  @param animated    `YES` to scroll animated
 */
- (void) setCurrentPage:(NSUInteger)currentPage
               animated:(BOOL) animated;

/**
 *  Designated initialiser
 *
 *  @param dataSource Object that conforms to the proxy data source
 *  @param delegate   Collection view delegate - can be `nil`.
 *
 *  @return Proxy
 */
+ (instancetype) proxyWithDataSource:(id <JCCircularCollectionViewProxyDataSource>) dataSource
                            delegate:(id <UICollectionViewDelegateFlowLayout>)delegate;

/**
 *  Required additional set up, once the collection view itself has been created
 *  and laid-out.
 *
 *  @param collectionView The collection view to use.
 */
- (void) configureForCollectionView:(UICollectionView*) collectionView;

/**
 *  Reload the collection view's data only
 *
 *  @param completion     Completion, executed after all set up
 */
- (void) reloadDataWithCompletion:(dispatch_block_t) completion;

/**
 *  Convert the given "expanded space" index path to an index path valid
 *  for the real data source.
 *
 *  @param indexPath An "expanded space" collection view index path
 *
 *  @return Index path in the context of the true data source
 */
- (NSIndexPath*) indexPathInTrueDataSourceForIndexPath:(NSIndexPath*) indexPath;

/**
 *  Calculate index into the "true" data source using a point in our
 *  fake expanded collection view.
 *
 *  @param point Point in the coordinate system of the expanded collection view.
 *
 *  @return Index path into your "real" data source.
 */
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point;

/**
 *  Proxy's the normal `UICollectionView` method.
 *
 *  @param indexPath      An index path in the context of the "true" data source
 *  @param scrollPosition UICollectionViewScrollPosition
 *  @param animated       Animate option
 */
- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath
               atScrollPosition:(UICollectionViewScrollPosition)scrollPosition
                       animated:(BOOL)animated;

/** I'm useless. */
- (id)init __attribute__((deprecated("Use +proxyWithDataSource:delegate:")));

@end

/**
 *  Convenience initialiser category
 */
@interface UICollectionView (CircularProxy)
/**
 *  Instantiate a proxy object and configure the receiver for it in one fell swoop.
 *
 *  @param dataSource Data source
 *  @param delegate   Optional delegate
 *
 *  @return Instantiated proxy - store in a `strong` property!
 */
- (JCCircularCollectionViewProxy*) circularProxyWithDataSource:(id <JCCircularCollectionViewProxyDataSource>) dataSource
                                                      delegate:(id <UICollectionViewDelegateFlowLayout>)delegate;
@end
