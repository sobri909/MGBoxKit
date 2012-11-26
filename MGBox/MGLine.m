//
//  Created by Matt Greenfield on 24/05/12
//  http://bigpaua.com/
//

#import "MGLine.h"
#import "MGLayoutManager.h"
#import "MGMushParser.h"
#import "NSAttributedString+MGTrim.h"

#define FALLBACK(potential, fallback) (potential ? potential : fallback)

@interface MGLine ()

@property (nonatomic, retain) NSMutableArray *dontFit;

@end

@implementation MGLine {
  CGFloat leftUsed, middleUsed, rightUsed;
  NSMutableArray *_leftItems, *_middleItems, *_rightItems;
  BOOL asyncDrawing, asyncDrawOnceing;
}

- (void)setup {
  [super setup];

  self.dontFit = @[].mutableCopy;

  // default font styles
  self.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
  self.textColor = UIColor.blackColor;
  self.textShadowColor = UIColor.whiteColor;
  self.leftTextShadowOffset = (CGSize){0, 1};
  self.middleTextShadowOffset = (CGSize){0, 1};
  self.rightTextShadowOffset = (CGSize){0, 1};

  // default text alignments
  self.leftItemsTextAlignment = NSTextAlignmentLeft;
  self.middleItemsTextAlignment = NSTextAlignmentCenter;
  self.rightItemsTextAlignment = NSTextAlignmentRight;

  // may be deprecated in future. use MGBox borders instead
  self.underlineType = MGUnderlineNone;
}

#pragma mark - Factories

+ (id)line {
  return [self boxWithSize:CGSizeZero];
}

+ (id)lineWithSize:(CGSize)size {
  return [self boxWithSize:size];
}

+ (id)lineWithMultilineLeft:(NSString *)left right:(id)right width:(CGFloat)width
                  minHeight:(CGFloat)height {
  MGLine *line = [self lineWithSize:(CGSize){width, height}];
  line.multilineLeft = left;
  line.rightItems = right;
  line.minHeight = height;
  line.maxHeight = 0;
  return line;
}

+ (id)lineWithLeft:(id)left multilineRight:(NSString *)right width:(CGFloat)width
         minHeight:(CGFloat)height {
  MGLine *line = [self lineWithSize:(CGSize){width, height}];
  line.leftItems = left;
  line.multilineRight = right;
  line.minHeight = height;
  line.maxHeight = 0;
  return line;
}

+ (id)multilineWithText:(NSString *)text font:(UIFont *)font width:(CGFloat)width
                padding:(UIEdgeInsets)padding {

  // compute min height
  CGSize minSize = [text sizeWithFont:font];
  CGFloat height = minSize.height + padding.top + padding.bottom;

  // make the line
  MGLine *line = [self lineWithSize:(CGSize){width, height}];
  line.minHeight = height;
  line.maxHeight = 0;

  line.font = font ? font : [line.font fontWithSize:14];
  line.padding = padding;
  line.multilineLeft = text;

  return line;
}

+ (id)lineWithLeft:(NSObject *)left right:(NSObject *)right {
  return [self lineWithLeft:left right:right size:CGSizeZero];
}

+ (id)lineWithLeft:(NSObject *)left right:(NSObject *)right size:(CGSize)size {
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

  // wrap NSStrings, NSAttributedStrings, and UIImages
  [self wrapRawContents:self.leftItems placement:MGLeft];
  [self wrapRawContents:self.rightItems placement:MGRight];
  [self wrapRawContents:self.middleItems placement:MGMiddle];

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
      [self layoutLeftWithin:(maxWidth - middleUsed) / 2];
      [self layoutRightWithin:(maxWidth - middleUsed) / 2];
      break;
  }

  // adjust height to fit contents
  [self adjustHeight];

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

  // async draws
  if (self.asyncLayout || self.asyncLayoutOnce) {
    dispatch_async(self.asyncQueue, ^{
      if (self.asyncLayout && !asyncDrawing) {
        asyncDrawing = YES;
        self.asyncLayout();
        asyncDrawing = NO;
      }
      if (self.asyncLayoutOnce && !asyncDrawOnceing) {
        asyncDrawOnceing = YES;
        self.asyncLayoutOnce();
        self.asyncLayoutOnce = nil;
        asyncDrawOnceing = NO;
      }
    });
  }
}

- (void)wrapRawContents:(NSMutableArray *)items
              placement:(MGItemPlacement)placement {
  for (int i = 0; i < items.count; i++) {
    id item = items[i];
    if ([item isKindOfClass:NSString.class]
        || [item isKindOfClass:NSAttributedString.class]) {
      items[i] = [self makeLabel:item placement:placement];
    } else if ([item isKindOfClass:UIImage.class]) {
      items[i] = [[UIImageView alloc] initWithImage:item];
    }
  }
}

- (void)removeOldContents {

  // start with all views that aren't in boxes
  NSMutableSet *gone = [MGLayoutManager findViewsInView:self
      notInSet:self.boxes].mutableCopy;

  // intersect views not in items arrays
  [gone intersectSet:[MGLayoutManager findViewsInView:self
      notInSet:self.allItems]];

  // now kick 'em out
  [gone makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)layoutLeftWithin:(CGFloat)limit {

  // size and discard
  leftUsed = [self size:self.leftItems within:limit];

  // widen as needed
  if (self.widenAsNeeded) {
    CGFloat needed = self.leftPadding + leftUsed + middleUsed + rightUsed
        + self.rightPadding;
    self.width = needed > self.width ? needed : self.width;
  }

  // lay out
  CGFloat x = self.leftPadding;
  for (int i = 0; i < self.leftItems.count; i++) {
    UIView *view = self.leftItems[i];

    if ([self.dontFit containsObject:view]) {
      continue;
    }

    if ([view conformsToProtocol:@protocol(MGLayoutBox)]
        && [(id)view boxLayoutMode] == MGBoxLayoutAttached) {
      continue;
    }

    x += self.itemPadding;
    CGFloat y = self.paddedVerticalCenter - view.height / 2;

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

    view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleRightMargin;
  }
}

- (void)layoutRightWithin:(CGFloat)limit {

  // size and discard
  rightUsed = [self size:self.rightItems within:limit];

  // widen as needed
  if (self.widenAsNeeded) {
    CGFloat needed = self.leftPadding + leftUsed + middleUsed + rightUsed
        + self.rightPadding;
    self.width = needed > self.width ? needed : self.width;
  }

  // lay out
  CGFloat x = self.width - self.rightPadding;
  for (int i = 0; i < self.rightItems.count; i++) {
    UIView *view = self.rightItems[i];

    if ([self.dontFit containsObject:view]) {
      continue;
    }

    if ([view conformsToProtocol:@protocol(MGLayoutBox)]
        && [(id <MGLayoutBox>)view boxLayoutMode] == MGBoxLayoutAttached) {
      continue;
    }

    x -= self.itemPadding;
    CGFloat y = self.paddedVerticalCenter - view.height / 2;

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

    view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleLeftMargin;
  }
}

- (void)layoutMiddleWithin:(CGFloat)limit {

  // size and discard
  middleUsed = [self size:self.middleItems within:limit];

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

  for (int i = 0; i < self.middleItems.count; i++) {
    UIView *view = self.middleItems[i];

    if ([self.dontFit containsObject:view]) {
      continue;
    }

    if ([view conformsToProtocol:@protocol(MGLayoutBox)]
        && [(id <MGLayoutBox>)view boxLayoutMode] == MGBoxLayoutAttached) {
      continue;
    }

    x += self.itemPadding;
    CGFloat y = self.paddedVerticalCenter - view.height / 2;

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

    view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleLeftMargin
        | UIViewAutoresizingFlexibleRightMargin;
  }
}

- (void)adjustHeight {

  // no room for adjustment?
  if (self.minHeight == self.maxHeight) {
    return;
  }

  // find the highest item
  CGFloat maxItemHeight = 0;
  for (UIView <MGLayoutBox> *item in self.allItems) {
    if ([item conformsToProtocol:@protocol(MGLayoutBox)] && item.boxLayoutMode
        == MGBoxLayoutAttached) {
      continue;
    }
    maxItemHeight = MAX(maxItemHeight, item.height);
  }

  // adjust box height while respecting minHeight/maxHeight properties
  CGFloat newHeight = MAX(maxItemHeight + self.topPadding
      + self.bottomPadding, self.minHeight);
  if (self.maxHeight) {
    newHeight = MIN(newHeight, self.maxHeight);
  }
  if (newHeight != self.height) {
    self.height = ceilf(newHeight);
  }
}

- (CGFloat)size:(NSArray *)views within:(CGFloat)limit {
  NSMutableArray *expandables = @[].mutableCopy;
  CGFloat used = 0;
  unsigned int i;
  for (i = 0; i < views.count; i++) {

    // little bit of thread safety
    if (![views[i] isKindOfClass:UIView.class]) {
      continue;
    }

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

    // UILabels made by MGLine can be resized
    if ([item isKindOfClass:UILabel.class] && item.tag == -1) {
      UILabel *label = (id)item;

      // multiline
      if (!label.numberOfLines) {
        CGFloat maxHeight = self.maxHeight ? self.maxHeight - self.topPadding
            - self.bottomPadding : FLT_MAX;

        // attributed string?
        if ([label respondsToSelector:@selector(attributedText)]) {
          CGSize maxSize = (CGSize){limit - used, maxHeight};
          CGSize size = [label.attributedText boundingRectWithSize:maxSize
              options:NSStringDrawingUsesLineFragmentOrigin
                  | NSStringDrawingUsesFontLeading context:nil].size;
          size.width = ceilf(size.width);
          size.height = ceilf(size.height);

          // for auto resizing margin sanity, make height odd/even match with self
          if ((int)size.height % 2 && !((int)self.height % 2)) {
            size.height += 1;
          }
          label.size = size;

          // plain old string
        } else {
          label.size = [label.text sizeWithFont:label.font
              constrainedToSize:(CGSize){limit - used, maxHeight}];
        }

        // single line
      } else {
        if (used + label.width > limit) { // needs slimming
          label.width = limit - used;
        }
      }

      used += label.width;

      // MGLayoutBoxes have margins to deal with
    } else if ([item conformsToProtocol:@protocol(MGLayoutBox)]) {
      UIView <MGLayoutBox> *box = (id)item;

      // undocumented optional 'maxWidth' property
      if ([box respondsToSelector:@selector(setMaxWidth:)]) {
        CGFloat totalWidth = box.leftMargin + box.width + box.rightMargin;
        if (used + totalWidth > limit) { // needs slimming
          box.maxWidth = limit - used - box.leftMargin - box.rightMargin;
        }
      }

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
        expandable.width += floorf(leftover);
        used += leftover;
      }
      [expandable layout];
    }
  }

  return used;
}

#pragma mark - Label factory

- (UILabel *)makeLabel:(id)text placement:(MGItemPlacement)placement {

  // base label
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
  label.backgroundColor = UIColor.clearColor;

  // styling
  switch (placement) {
    case MGLeft:
      label.font = self.font;
      label.textAlignment = self.leftItemsTextAlignment;
      label.shadowOffset = self.leftTextShadowOffset;
      label.shadowColor = self.textShadowColor;
      label.textColor = self.textColor;
      break;
    case MGMiddle:
      label.font = FALLBACK(self.middleFont, self.font);
      label.textAlignment = self.middleItemsTextAlignment;
      label.shadowOffset = self.middleTextShadowOffset;
      label.shadowColor
          = FALLBACK(self.middleTextShadowColor, self.textShadowColor);
      label.textColor = FALLBACK(self.middleTextColor, self.textColor);
      break;
    case MGRight:
      label.font = FALLBACK(self.rightFont, self.font);
      label.textAlignment = self.rightItemsTextAlignment;
      label.shadowOffset = self.rightTextShadowOffset;
      label.shadowColor
          = FALLBACK(self.rightTextShadowColor, self.textShadowColor);
      label.textColor = FALLBACK(self.rightTextColor, self.textColor);
      break;
  }

  // newline chars trigger a multiline label
  NSString *plain = [text isKindOfClass:NSAttributedString.class]
      ? [text string]
      : text;
  if ([plain rangeOfString:@"\n"].location != NSNotFound) {
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;

    // trim newlines off start and end
    id ws = NSCharacterSet.whitespaceAndNewlineCharacterSet;
    if ([text isKindOfClass:NSAttributedString.class]) {
      text = [text attributedStringByTrimming:ws];
    } else {
      text = [text stringByTrimmingCharactersInSet:ws];
    }

    // single line
  } else {
    label.lineBreakMode = NSLineBreakByTruncatingTail;
  }

  // turn mush strings into attributed strings
  if ([text isKindOfClass:NSString.class] && [text hasSuffix:@"|mush"]) {
    text = [text substringToIndex:[text length] - 5];
    text = [MGMushParser attributedStringFromMush:text font:label.font
        color:label.textColor];
  }

  // attributed string?
  if ([text isKindOfClass:NSAttributedString.class]) {
    if ([label respondsToSelector:@selector(attributedText)]) {
      label.attributedText = text;
    } else {
      label.text = [text string];
    }
  } else {
    label.text = text;
  }

  // final resizing will be done at layout time
  if ([label respondsToSelector:@selector(attributedText)]) {
    CGSize maxSize = (CGSize){self.width, 0};
    CGSize size = [label.attributedText boundingRectWithSize:maxSize
        options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    size.width = ceilf(size.width);
    size.height = ceilf(size.height);

    // for auto resizing margin sanity, make height odd/even match with self
    if ((int)size.height % 2 && !((int)self.height % 2)) {
      size.height += 1;
    }
    label.size = size;
  } else {
    label.size = [label.text sizeWithFont:label.font];
  }

  // tag as modifiable
  label.tag = -1;

  return label;
}

#pragma mark - Style setters

- (void)setFrame:(CGRect)frame {
  super.frame = frame;
  self.underlineType = self.underlineType;
}

// this may disappear in future. use MGBox borders instead
- (void)setUnderlineType:(MGUnderlineType)type {
  _underlineType = type;
  switch (_underlineType) {
    case MGUnderlineTop:
      self.solidUnderline.frame = CGRectMake(0, 0, self.width, 2);
      [self.layer addSublayer:self.solidUnderline];
      break;
    case MGUnderlineBottom:
      self.solidUnderline.frame = CGRectMake(0, self.height - 2, self.width, 2);
      [self.layer addSublayer:self.solidUnderline];
      break;
    case MGUnderlineNone:
    default:
      [self.solidUnderline removeFromSuperlayer];
      break;
  }
}

- (void)setTextColor:(UIColor *)color {
  _textColor = color;
  NSMutableArray *items = self.leftItems.mutableCopy;
  if (!self.middleTextColor) {
    [items addObjectsFromArray:self.middleItems];
  }
  if (!self.rightTextColor) {
    [items addObjectsFromArray:self.rightItems];
  }
  for (UILabel *label in items) {
    if ([label isKindOfClass:UILabel.class] && label.tag == -1) {
      label.textColor = color;
    }
  }
}

- (void)setMiddleTextColor:(UIColor *)color {
  _middleTextColor = color;
  for (UILabel *label in self.middleItems) {
    if ([label isKindOfClass:UILabel.class] && label.tag == -1) {
      label.textColor = color;
    }
  }
}

- (void)setRightTextColor:(UIColor *)color {
  _rightTextColor = color;
  for (UILabel *label in self.rightItems) {
    if ([label isKindOfClass:UILabel.class] && label.tag == -1) {
      label.textColor = color;
    }
  }
}

- (void)setTextShadowColor:(UIColor *)color {
  _textShadowColor = color;
  NSMutableArray *items = self.leftItems.mutableCopy;
  if (!self.middleTextShadowColor) {
    [items addObjectsFromArray:self.middleItems];
  }
  if (!self.rightTextShadowColor) {
    [items addObjectsFromArray:self.rightItems];
  }
  for (UILabel *label in items) {
    if ([label isKindOfClass:UILabel.class] && label.tag == -1) {
      label.shadowColor = color;
    }
  }
}

- (void)setMiddleTextShadowColor:(UIColor *)color {
  _middleTextShadowColor = color;
  for (UILabel *label in self.middleItems) {
    if ([label isKindOfClass:UILabel.class] && label.tag == -1) {
      label.shadowColor = color;
    }
  }
}

- (void)setRightTextShadowColor:(UIColor *)color {
  _rightTextShadowColor = color;
  for (UILabel *label in self.rightItems) {
    if ([label isKindOfClass:UILabel.class] && label.tag == -1) {
      label.shadowColor = color;
    }
  }
}

- (void)setLeftTextShadowOffset:(CGSize)offset {
  _leftTextShadowOffset = offset;
  for (UILabel *label in self.leftItems) {
    if ([label isKindOfClass:UILabel.class] && label.tag == -1) {
      label.shadowOffset = offset;
    }
  }
}

- (void)setMiddleTextShadowOffset:(CGSize)offset {
  _middleTextShadowOffset = offset;
  for (UILabel *label in self.middleItems) {
    if ([label isKindOfClass:UILabel.class] && label.tag == -1) {
      label.shadowOffset = offset;
    }
  }
}

- (void)setRightTextShadowOffset:(CGSize)offset {
  _rightTextShadowOffset = offset;
  for (UILabel *label in self.rightItems) {
    if ([label isKindOfClass:UILabel.class] && label.tag == -1) {
      label.shadowOffset = offset;
    }
  }
}

#pragma mark - Content setters

- (void)setLeftItems:(id)items {
  if (!items) {
    _leftItems = NSMutableArray.array;
  } else if ([items isKindOfClass:NSMutableArray.class]) {
    _leftItems = items;
  } else if ([items isKindOfClass:NSArray.class]) {
    _leftItems = [items mutableCopy];
  } else {
    _leftItems = @[items].mutableCopy;
  }
}

- (void)setMiddleItems:(id)items {
  if (!items) {
    _middleItems = NSMutableArray.array;
  } else if ([items isKindOfClass:NSMutableArray.class]) {
    _middleItems = items;
  } else if ([items isKindOfClass:NSArray.class]) {
    _middleItems = [items mutableCopy];
  } else {
    _middleItems = @[items].mutableCopy;
  }
}

- (void)setRightItems:(id)items {
  if (!items) {
    _rightItems = NSMutableArray.array;
  } else if ([items isKindOfClass:NSMutableArray.class]) {
    _rightItems = items;
  } else if ([items isKindOfClass:NSArray.class]) {
    _rightItems = [items mutableCopy];
  } else {
    _rightItems = @[items].mutableCopy;
  }
}

- (void)setMultilineLeft:(NSString *)text {
  if ([text rangeOfString:@"\n"].location == NSNotFound) {
    self.leftItems = (id)[@"\n" stringByAppendingString:text];
  } else {
    self.leftItems = (id)text;
  }
}

- (void)setMultilineMiddle:(NSString *)text {
  if ([text rangeOfString:@"\n"].location == NSNotFound) {
    self.middleItems = (id)[@"\n" stringByAppendingString:text];
  } else {
    self.middleItems = (id)text;
  }
}

- (void)setMultilineRight:(NSString *)text {
  if ([text rangeOfString:@"\n"].location == NSNotFound) {
    self.rightItems = (id)[@"\n" stringByAppendingString:text];
  } else {
    self.rightItems = (id)text;
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

- (CGFloat)paddedVerticalCenter {
  CGFloat innerHeight = self.height - self.topPadding - self.bottomPadding;
  return innerHeight / 2 + self.topPadding;
}

@end
