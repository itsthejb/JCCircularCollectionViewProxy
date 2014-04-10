//
//  Specs.m
//  JCCircularCollectionViewProxy
//
//  Created by Jonathan Crooke on 10/04/2014.
//  Copyright (c) 2014 Jonathan Crooke. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCCircularCollectionViewProxy.h"
#define EXP_SHORTHAND
#import "Expecta.h"
#import "Specta.h"
#import "OCMock.h"

SpecBegin(JCCircularCollectionViewProxy)

__block UICollectionView *collectionView = nil;
__block id mockDataSource = nil;
__block id mockDelegate = nil;
__block JCCircularCollectionViewProxy *proxy = nil;

before(^{
  mockDataSource = [OCMockObject mockForProtocol:@protocol(JCCircularCollectionViewProxyDataSource)];
  mockDelegate = [OCMockObject mockForProtocol:@protocol(UICollectionViewDelegateFlowLayout)];
  collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 100, 200)
                                      collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
  [[[mockDataSource stub] andReturnValue:@1] numberOfSectionsInCollectionView:collectionView];
  [[[mockDelegate stub] andReturnValue:[NSValue valueWithCGSize:CGSizeMake(50, 50)]]
   collectionView:collectionView
   layout:collectionView.collectionViewLayout
   sizeForItemAtIndexPath:[OCMArg any]];
  proxy = [collectionView circularProxyWithDataSource:mockDataSource
                                             delegate:mockDelegate];
});

describe(@"data source", ^{
  before(^{
    [[[mockDataSource stub] andReturnValue:@99] collectionView:collectionView numberOfItemsInSection:0];
  });

  it(@"should return proxied count", ^{
    expect([proxy collectionView:collectionView numberOfItemsInSection:0]).to.equal(99 * 7000);
  });

  it(@"should dequeue cell from true data source and pass on cell for configuration", ^{
    id obj = @"";
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:3000 inSection:0];
    [[[mockDataSource stub] andReturn:obj] collectionView:collectionView cellForItemAtIndexPath:indexPath];
    [[mockDataSource expect] collectionView:collectionView configureCell:obj
                               forIndexPath:[OCMArg checkWithBlock:^BOOL(NSIndexPath *indexPath)
    {
      return [indexPath isEqual:[NSIndexPath indexPathForRow:30 inSection:0]];
    }]];
    [proxy collectionView:collectionView cellForItemAtIndexPath:indexPath];
  });

  it(@"should forward data source method", ^{
    [[mockDataSource expect] collectionView:nil viewForSupplementaryElementOfKind:nil atIndexPath:nil];
    [proxy collectionView:nil viewForSupplementaryElementOfKind:nil atIndexPath:nil];
  });
});

describe(@"delegate", ^{
  it(@"should forward delegate method", ^{
    [[mockDelegate expect] collectionView:nil layout:nil referenceSizeForHeaderInSection:0];
    [proxy collectionView:nil layout:nil referenceSizeForHeaderInSection:0];
  });
});

SpecEnd
