//
//  Created by Matt Greenfield on 24/05/12
//  http://bigpaua.com/
//

#import "MGTableBoxStyled.h"
#import "MGLineStyled.h"

#define WIDTH       304.0
#define TOP_MARGIN    8.0
#define BOTTOM_MARGIN 0.0
#define LEFT_MARGIN   8.0
#define CORNER_RADIUS 4.0

@implementation MGTableBoxStyled

- (void)setup {
  [super setup];

  // shape, size, and position
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

  // performance
  self.rasterize = YES;
}

- (void)layout {
  [super layout];

  // row separators
  NSArray *allLines = self.allLines.array;
  for (MGLine *line in self.allLines) {

    // old style MGLine underlineType
    if (line == allLines.lastObject && [line isKindOfClass:MGLine.class]
        && line.underlineType != MGUnderlineTop) {
      line.underlineType = MGUnderlineNone;
    }

    // new style MGBox borderStyle
    if (line == allLines[0]) {
      line.borderStyle &= ~MGBorderEtchedTop;
    }
    if (line == allLines.lastObject) {
      line.borderStyle &= ~MGBorderEtchedBottom;
    }
  }

  // make shadow faster
  self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
      cornerRadius:self.layer.cornerRadius].CGPath;

  // if there's no lines, no need to do corner masking
  if (!allLines.count) {
    return;
  }

  // plain old layer radius for the only line
  if (allLines.count == 1) {
    MGLine *line = allLines.lastObject;
    line.layer.cornerRadius = self.layer.cornerRadius;
    return;
  }

  // corner mask top line
  MGLine *topLine = allLines[0];
  CAShapeLayer *topMask = CAShapeLayer.layer;
  topMask.frame = topLine.bounds;
  CGSize radius = (CGSize){self.layer.cornerRadius, self.layer.cornerRadius};
  topMask.path = [UIBezierPath bezierPathWithRoundedRect:topMask.bounds
      byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
      cornerRadii:radius].CGPath;
  topLine.layer.mask = topMask;

  // corner mask bottom line
  MGLine *bottomLine = allLines.lastObject;
  CAShapeLayer *bottomMask = CAShapeLayer.layer;
  bottomMask.frame = bottomLine.bounds;
  bottomMask.path = [UIBezierPath bezierPathWithRoundedRect:bottomMask.bounds
      byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight
      cornerRadii:radius].CGPath;
  bottomLine.layer.mask = bottomMask;
}

@end
