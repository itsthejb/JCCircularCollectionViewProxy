//
//  DemoCell.m
//  JCCircularCollectionViewProxy
//
//  Created by Jonathan Crooke on 10/04/2014.
//  Copyright (c) 2014 Jonathan Crooke. All rights reserved.
//

#import "DemoCell.h"

@interface DemoCell ()
@property (weak, nonatomic, readwrite) IBOutlet UIImageView *imageView;
@end

@implementation DemoCell
- (void)prepareForReuse {
  [super prepareForReuse];
  self.imageView.image = nil;
}
@end
