//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGTableBoxStyled.h"

#define DEFAULT_WIDTH       304.0
#define DEFAULT_TOP_MARGIN   10.0
#define DEFAULT_BOTTOM_MARGIN 0.0
#define CORNER_RADIUS         4.0

@implementation MGTableBoxStyled

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizesSubviews = YES;
    self.topMargin = DEFAULT_TOP_MARGIN;
    self.bottomMargin = DEFAULT_BOTTOM_MARGIN;
  }
  return self;
}

+ (id)box {
  CGRect frame = CGRectMake(0, 0, DEFAULT_WIDTH, 0);
  MGTableBoxStyled *box = [[self alloc] initWithFrame:frame];
  return box;
}

- (void)setup {
  [super setup];
  self.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1];
  self.layer.cornerRadius = CORNER_RADIUS;
  self.layer.shadowColor = [UIColor colorWithWhite:0.12 alpha:1].CGColor;
  self.layer.shadowOffset = CGSizeMake(0, 0.5);
  self.layer.shadowRadius = 0.7;
  self.layer.shadowOpacity = 1;
  self.layer.shouldRasterize = YES;
  self.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)layout {
  [super layout];

  // make shadow faster
  self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
      cornerRadius:self.layer.cornerRadius].CGPath;
}

@end
