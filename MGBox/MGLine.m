//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGLine.h"
#import "MGLayoutManager.h"

@interface MGLine ()

@property (nonatomic, retain) NSMutableArray *dontFit;

- (void)wrapRawContents:(NSMutableArray *)contents
                  align:(UITextAlignment)align;
- (void)removeOldContents;
- (void)layoutLeftWithin:(CGFloat)limit;
- (void)layoutRightWithin:(CGFloat)limit;
- (void)layoutMiddleWithin:(CGFloat)limit;
- (CGFloat)size:(NSArray *)views within:(CGFloat)limit font:(UIFont *)font;

@end

@implementation MGLine {
  CGFloat leftUsed, middleUsed, rightUsed;
}

- (void)setup {
  [super setup];

  self.dontFit = @[].mutableCopy;

  // fonts
  self.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
  self.textColor = UIColor.blackColor;
  self.textShadowColor = UIColor.whiteColor;
  self.rightFont = self.font;
}

+ (id)line {
  return [self boxWithSize:CGSizeZero];
}

+ (id)lineWithSize:(CGSize)size {
  return [self boxWithSize:size];
}

+ (id)multilineWithText:(NSString *)text font:(UIFont *)font width:(CGFloat)width
                padding:(UIEdgeInsets)padding {

  // default font?
  font = font ? font : [UIFont fontWithName:@"HelveticaNeue-Light" size:14];

  // make the label
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
  label.backgroundColor = UIColor.clearColor;
  label.shadowColor = UIColor.whiteColor;
  label.shadowOffset = CGSizeMake(0, 1);
  label.numberOfLines = 0;
  label.font = font;
  label.text = text;

  // usable width
  CGFloat innerWidth = width - padding.left - padding.right;

  // size the label
  CGSize textSize = [label.text sizeWithFont:label.font
      constrainedToSize:CGSizeMake(innerWidth, FLT_MAX)];
  label.size = (CGSize){innerWidth, textSize.height};

  // make the line
  MGLine *line = [MGLine lineWithSize:(CGSize){width,
      label.height + padding.top + padding.bottom
  }];
  line.leftItems = @[label].mutableCopy;
  line.padding = padding;
  line.font = font;

  return line;
}

+ (id)lineWithLeft:(NSObject *)left right:(NSObject *)right {
  return [self lineWithLeft:left right:right size:CGSizeZero];
}

+ (id)lineWithLeft:(NSObject *)left right:(NSObject *)right
              size:(CGSize)size {
  MGLine *line = [self lineWithSize:size];
  if ([left isKindOfClass:NSArray.class]) {
    line.leftItems = left.mutableCopy;
  } else {
    line.leftItems = left ? @[left].mutableCopy : nil;
  }
  if ([right isKindOfClass:NSArray.class]) {
    line.rightItems = right.mutableCopy;
  } else {
    line.rightItems = right ? @[right].mutableCopy : nil;
  }
  return line;
}

#pragma mark - Layout

- (void)layout {

  // wrap NSStrings and UIImages
  [self wrapRawContents:self.leftItems align:NSTextAlignmentLeft];
  [self wrapRawContents:self.rightItems align:NSTextAlignmentRight];
  [self wrapRawContents:self.middleItems align:NSTextAlignmentCenter];

  [self removeOldContents];

  // max usable space
  CGFloat maxWidth = self.width - self.leftPadding - self.rightPadding;

  // lay things out
  switch (self.sidePrecedence) {
  case MGSidePrecedenceLeft:
    [self layoutLeftWithin:maxWidth];
    [self layoutRightWithin:maxWidth - leftUsed];
    [self layoutMiddleWithin:maxWidth - leftUsed - rightUsed];
    break;
  case MGSidePrecedenceRight:
    [self layoutRightWithin:maxWidth];
    [self layoutLeftWithin:maxWidth - rightUsed];
    [self layoutMiddleWithin:maxWidth - leftUsed - rightUsed];
    break;
  case MGSidePrecedenceMiddle:
    [self layoutMiddleWithin:maxWidth];
    [self layoutLeftWithin:maxWidth - middleUsed];
    [self layoutRightWithin:maxWidth - leftUsed - middleUsed];
    break;
  }

  // deal with attached boxes
  for (UIView <MGLayoutBox> *attachee in self.allItems) {
    if (![attachee conformsToProtocol:@protocol(MGLayoutBox)]
        || attachee.boxLayoutMode != MGBoxLayoutAttached) {
      continue;
    }
    CGRect frame = attachee.frame;
    frame.origin = attachee.attachedTo.frame.origin;
    frame.origin.x += attachee.leftMargin;
    frame.origin.y += attachee.topMargin;
    attachee.frame = frame;
  }

  // zIndex stack plz
  [MGLayoutManager stackByZIndexIn:self];
}

- (void)wrapRawContents:(NSMutableArray *)contents
                  align:(UITextAlignment)align {
  for (int i = 0; i < contents.count; i++) {
    id item = contents[i];
    if ([item isKindOfClass:NSString.class]) {
      UILabel *label = [self makeLabel:item align:align];
      contents[i] = label;
    } else if ([item isKindOfClass:UIImage.class]) {
      UIImageView *view = [[UIImageView alloc] initWithImage:item];
      contents[i] = view;
    }
  }
}

- (void)removeOldContents {

  // start with all views that aren't in boxes
  NSMutableSet *gone = [MGLayoutManager findViewsInView:self
      notInSet:self.boxes].mutableCopy;

  // intersect views not items arrays
  [gone intersectSet:[MGLayoutManager findViewsInView:self
      notInSet:self.allItems]];

  // now kick 'em out
  [gone makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)layoutLeftWithin:(CGFloat)limit {

  // size and discard
  leftUsed = [self size:self.leftItems within:limit font:self.font];

  // widen as needed
  if (self.widenAsNeeded) {
    CGFloat needed = self.leftPadding + leftUsed + middleUsed + rightUsed
        + self.rightPadding;
    self.width = needed > self.width ? needed : self.width;
  }

  // lay out
  CGFloat x = self.leftPadding;
  int i;
  for (i = 0; i < self.leftItems.count; i++) {
    UIView *view = self.leftItems[i];
    if ([self.dontFit indexOfObject:view] != NSNotFound) {
      continue;
    }
    if ([view conformsToProtocol:@protocol(MGLayoutBox)]
        && [(id <MGLayoutBox>)view boxLayoutMode] == MGBoxLayoutAttached) {
      continue;
    }

    x += self.itemPadding;
    CGFloat y = (self.height - view.height) / 2;

    // MGLayoutBoxes have margins to deal with
    if ([view conformsToProtocol:@protocol(MGLayoutBox)]) {
      UIView <MGLayoutBox> *box = (id)view;

      y += box.topMargin;
      x += box.leftMargin;
      box.frame = CGRectMake(x, roundf(y), box.width, box.height);
      x += box.rightMargin;

      // better be a UIView then
    } else {
      view.frame = CGRectMake(x, roundf(y), view.width, view.height);
    }
    x += view.width + self.itemPadding;

    view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  }
}

- (void)layoutRightWithin:(CGFloat)limit {

  // size and discard
  rightUsed = [self size:self.rightItems within:limit font:self.rightFont];

  // widen as needed
  if (self.widenAsNeeded) {
    CGFloat needed = self.leftPadding + leftUsed + middleUsed + rightUsed
        + self.rightPadding;
    self.width = needed > self.width ? needed : self.width;
  }

  // lay out
  CGFloat x = self.width - self.rightPadding;
  int i;
  for (i = 0; i < self.rightItems.count; i++) {
    UIView *view = self.rightItems[i];

    if ([self.dontFit indexOfObject:view] != NSNotFound) {
      continue;
    }

    if ([view conformsToProtocol:@protocol(MGLayoutBox)]
        && [(id <MGLayoutBox>)view boxLayoutMode] == MGBoxLayoutAttached) {
      continue;
    }

    x -= self.itemPadding;
    CGFloat y = (self.height - view.height) / 2;

    // MGLayoutBoxes have margins to deal with
    if ([view conformsToProtocol:@protocol(MGLayoutBox)]) {
      UIView <MGLayoutBox> *box = (id)view;

      y += box.topMargin;
      x -= box.width + box.rightMargin;
      box.frame = CGRectMake(x, roundf(y), box.width, box.height);
      x -= box.leftMargin;

      // hopefully is a UIView then
    } else {
      x -= view.width;
      view.frame = CGRectMake(x, roundf(y), view.width, view.height);
    }

    x -= self.itemPadding;

    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  }
}

- (void)layoutMiddleWithin:(CGFloat)limit {

  // size and discard
  middleUsed = [self size:self.middleItems within:limit font:self.font];

  // widen as needed
  if (self.widenAsNeeded) {
    CGFloat needed = self.leftPadding + leftUsed + middleUsed + rightUsed
        + self.rightPadding;
    self.width = needed > self.width ? needed : self.width;
  }

  // lay out
  CGFloat x;
  if (self.sidePrecedence == MGSidePrecedenceMiddle) {
    x = roundf((self.width - middleUsed) / 2);
  } else {
    x = self.leftPadding + leftUsed + roundf((limit - middleUsed) / 2);
  }

  int i;
  for (i = 0; i < self.middleItems.count; i++) {
    UIView *view = self.middleItems[i];

    if ([self.dontFit indexOfObject:view] != NSNotFound) {
      continue;
    }

    if ([view conformsToProtocol:@protocol(MGLayoutBox)]
        && [(id <MGLayoutBox>)view boxLayoutMode] == MGBoxLayoutAttached) {
      continue;
    }

    x += self.itemPadding;
    CGFloat y = (self.height - view.height) / 2;

    // MGLayoutBoxes have margins to deal with
    if ([view conformsToProtocol:@protocol(MGLayoutBox)]) {
      UIView <MGLayoutBox> *box = (id)view;
      y += box.topMargin;
      x += box.leftMargin;
      box.frame = CGRectMake(x, roundf(y), box.width, box.height);
      x += box.rightMargin;

      // better be a UIView then
    } else {
      view.frame = CGRectMake(x, roundf(y), view.width, view.height);
    }
    x += view.width + self.itemPadding;

    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin
        | UIViewAutoresizingFlexibleRightMargin;
  }
}

- (CGFloat)size:(NSArray *)views within:(CGFloat)limit font:(UIFont *)font {
  NSMutableArray *expandables = @[].mutableCopy;
  CGFloat used = 0;
  unsigned int i;
  for (i = 0; i < views.count; i++) {
    UIView *item = views[i];
    CGSize itemSize = item.frame.size;
    [self.dontFit removeObject:item];

    // add to subviews
    if (item.superview != self) {
      [self addSubview:item];
    }

    // lay out child MGBoxes first
    if ([item conformsToProtocol:@protocol(MGLayoutBox)]) {
      UIView <MGLayoutBox> *box = (id)item;
      box.parentBox = self;
      [box layout];

      // collect expandables
      if (box.sizingMode == MGResizingExpandWidthToFill) {
        [expandables addObject:box];
      }

      // don't layout attached boxes yet
      if (box.boxLayoutMode == MGBoxLayoutAttached) {
        continue;
      }
    }

    // everything gets left and right padding
    used += self.itemPadding * 2;

    // not even enough space for the padding alone?
    if (!self.widenAsNeeded && used > limit) {
      break; // yep, out of space
    }

    // single line UILabels can be shrunk
    if ([item isKindOfClass:UILabel.class] && [(UILabel *)item numberOfLines]
        == 1) {
      UILabel *label = (id)item;
      label.font = font;
      CGSize labelSize = [label.text sizeWithFont:label.font];
      if (used + labelSize.width > limit) { // needs slimming
        label.width = limit - used;
      }
      used += label.width;

      // MGLayoutBoxes have margins to deal with
    } else if ([item conformsToProtocol:@protocol(MGLayoutBox)]) {
      MGBox *box = (id)item;
      used += box.leftMargin + box.width + box.rightMargin;

      // hopefully is a UIView then
    } else {
      used += itemSize.width;
    }

    // ran out of space after counting the view size?
    if (!self.widenAsNeeded && used > limit) {
      break;
    }
  }

  // ditch leftovers if out of space
  if (i < views.count) {
    NSMutableArray *ditch = @[].mutableCopy;
    for (; i < views.count; i++) {
      [ditch addObject:views[i]];
    }
    [ditch makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.dontFit addObjectsFromArray:ditch];
    [expandables removeObjectsInArray:ditch];
  }

  // distribute leftover space to expandables
  if (limit - used > 0) {
    CGFloat remaining = limit - used;
    CGFloat perBox = floorf(remaining / expandables.count);
    CGFloat leftover = remaining - perBox * expandables.count;
    for (MGBox *expandable in expandables) {
      expandable.width += perBox;
      used += perBox;
      if (expandable == expandables.lastObject) {
        expandable.width += leftover;
        used += leftover;
      }
      [expandable layout];
    }
  }

  return used;
}

- (UILabel *)makeLabel:(NSString *)text
                 align:(UITextAlignment)align {
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
  label.backgroundColor = UIColor.clearColor;
  label.text = text;
  label.font = align == UITextAlignmentRight && self.rightFont
      ? self.rightFont
      : self.font;
  label.textColor = self.textColor;
  label.shadowColor = self.textShadowColor;
  label.shadowOffset = CGSizeMake(0, 1);
  label.lineBreakMode = align == NSTextAlignmentRight
      ? NSLineBreakByTruncatingHead
      : NSLineBreakByTruncatingTail;
  label.textAlignment = align;
  CGSize size = [label.text sizeWithFont:label.font];
  label.size = CGSizeMake(size.width, self.height);
  return label;
}

#pragma mark - Setters

- (void)setHeight:(CGFloat)height {
  super.height = height;
  self.underlineType = self.underlineType;
}

- (void)setUnderlineType:(MGUnderlineType)type {
  _underlineType = type;
  switch (_underlineType) {
  case MGUnderlineTop:
    self.solidUnderline.frame = CGRectMake(0, 0, self.width, 2);
    [self.layer addSublayer:self.solidUnderline];
    break;
  case MGUnderlineBottom:
    self.solidUnderline.frame = CGRectMake(0, self.height - 1, self.width, 2);
    [self.layer addSublayer:self.solidUnderline];
    break;
  case MGUnderlineNone:
  default:
    [self.solidUnderline removeFromSuperlayer];
    break;
  }
}

- (void)setTextColor:(UIColor *)textColor {
  _textColor = textColor;
  if (!textColor) {
    return;
  }
  for (UILabel *label in self.subviews) {
    if ([label isKindOfClass:UILabel.class]) {
      label.textColor = textColor;
    }
  }
  for (UILabel *label in self.allItems) {
    if ([label isKindOfClass:UILabel.class]) {
      label.textColor = textColor;
    }
  }
}

- (void)setTextShadowColor:(UIColor *)textShadowColor {
  _textShadowColor = textShadowColor;
  if (!textShadowColor) {
    return;
  }
  for (UILabel *label in self.subviews) {
    if ([label isKindOfClass:UILabel.class]) {
      label.shadowColor = textShadowColor;
    }
  }
  for (UILabel *label in self.allItems) {
    if ([label isKindOfClass:UILabel.class]) {
      label.shadowColor = textShadowColor;
    }
  }
}

#pragma mark - Getters

- (NSSet *)allItems {
  NSMutableSet *items = [NSMutableSet setWithArray:self.leftItems];
  [items addObjectsFromArray:self.middleItems];
  [items addObjectsFromArray:self.rightItems];
  return items;
}

- (CALayer *)solidUnderline {
  if (_solidUnderline) {
    return _solidUnderline;
  }
  _solidUnderline = CALayer.layer;
  _solidUnderline.frame = CGRectMake(0, 0, self.width, 2);
  _solidUnderline.backgroundColor = [UIColor colorWithWhite:0.87 alpha:1].CGColor;
  CALayer *bot = CALayer.layer;
  bot.frame = CGRectMake(0, 1, self.frame.size.width, 1);
  bot.backgroundColor = UIColor.whiteColor.CGColor;
  [_solidUnderline addSublayer:bot];
  return _solidUnderline;
}

- (NSMutableArray *)leftItems {
  if (!_leftItems) {
    _leftItems = @[].mutableCopy;
  }
  return _leftItems;
}

- (NSMutableArray *)middleItems {
  if (!_middleItems) {
    _middleItems = @[].mutableCopy;
  }
  return _middleItems;
}

- (NSMutableArray *)rightItems {
  if (!_rightItems) {
    _rightItems = @[].mutableCopy;
  }
  return _rightItems;
}

@end
