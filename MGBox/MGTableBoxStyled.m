//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGTableBoxStyled.h"
#import "MGLine.h"

#define WIDTH       304.0
#define TOP_MARGIN    8.0
#define BOTTOM_MARGIN 0.0
#define LEFT_MARGIN   8.0
#define CORNER_RADIUS 4.0

@implementation MGTableBoxStyled

- (void)setup {
  [super setup];

  // size and position
  self.width = self.width ? self.width : WIDTH;
  self.topMargin = TOP_MARGIN;
  self.bottomMargin = BOTTOM_MARGIN;
  self.leftMargin = LEFT_MARGIN;

  // shape and colour
  self.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1];
  self.layer.cornerRadius = CORNER_RADIUS;

  // shadow
  self.layer.shadowColor = [UIColor colorWithWhite:0.12 alpha:1].CGColor;
  self.layer.shadowOffset = CGSizeMake(0, 0.5);
  self.layer.shadowRadius = 1;
  self.layer.shadowOpacity = 1;
}

- (void)layout {
  [super layout];

  // underlines
  for (MGLine *line in self.boxes) {
    if ([line isKindOfClass:MGLine.class] && line == self.boxes.lastObject
        && line.underlineType != MGUnderlineTop) {
      line.underlineType = MGUnderlineNone;
    }
  }

  // make shadow faster
  self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
      cornerRadius:self.layer.cornerRadius].CGPath;
}

@end
