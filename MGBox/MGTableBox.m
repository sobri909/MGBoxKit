//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGTableBox.h"
#import "MGLine.h"

#define DEFAULT_WIDTH 320.0

@implementation MGTableBox

@synthesize topLines, middleLines, bottomLines, content;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.topLines = @[].mutableCopy;
    self.middleLines = @[].mutableCopy;
    self.bottomLines = @[].mutableCopy;
    [self setup];
  }
  return self;
}

+ (id)box {
  CGRect frame = CGRectMake(0, 0, DEFAULT_WIDTH, 0);
  MGBox *box = [[self alloc] initWithFrame:frame];
  return box;
}

- (void)layout {
  [super layout];

  // collapse the lines
  NSMutableArray *lines = @[].mutableCopy;
  [lines addObjectsFromArray:self.topLines];
  [lines addObjectsFromArray:self.middleLines];
  [lines addObjectsFromArray:self.bottomLines];

  // remove removed lines
  for (UIView *view in self.content.subviews) {
    if (view.tag != 1000 && [lines indexOfObject:view] == NSNotFound) {
      [view removeFromSuperview];
    }
  }

  // draw the remaining lines
  CGFloat y = 0;
  for (UIView *line in lines) {
    [self drawLine:line fromLines:lines at:y];
    y += line.frame.size.height;
  }

  // resize to fit
  UIView *superview = self.content.superview;
  CGPoint origin = superview.frame.origin;
  superview.frame = CGRectMake(origin.x, origin.y, self.size.width, y);
  self.content.frame = superview.bounds;
}

- (void)drawLine:(UIView *)line fromLines:(NSArray *)lines at:(CGFloat)y {
  if ([line isKindOfClass:[MGLine class]]) {
    MGLine *pline = (MGLine *)line;
    pline.parentBox = self;
    [pline layout];
    if (pline == [lines lastObject] && pline.underlineType != MGUnderlineTop) {
      pline.underlineType = MGUnderlineNone;
    }
  }
  CGFloat x = 0;
  CGSize lineSize = line.frame.size;
  if (lineSize.width != self.size.width) {
    x = (self.size.width - lineSize.width) / 2;
  }
  line.frame = CGRectMake(roundf(x), y, lineSize.width, lineSize.height);
  [self.content addSubview:line];
}

- (void)setup {
  if (!self.content) {
    self.content = [[UIView alloc] initWithFrame:self.bounds];
    self.content.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.content.layer.masksToBounds = YES;
  }
  [self.content removeFromSuperview];
  [self addSubview:self.content];
}

- (void)setSize:(CGSize)size {
  super.size = size;
  [self setup];
}

@end
