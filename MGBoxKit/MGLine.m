//
//  Created by Matt Greenfield on 24/05/12
//  http://bigpaua.com/
//

#import "MGLine.h"
#import "MGLayoutManager.h"
#import "MGMushParser.h"
#import "NSAttributedString+MGTrim.h"

// extra width allowance due to 'boundingRectWithSize' inaccuracy

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
  self.opaqueLabels = NO;

  // default horizontal and vertical alignments
  self.leftItemsAlignment = NSTextAlignmentLeft;
  self.middleItemsAlignment = NSTextAlignmentCenter;
  self.rightItemsAlignment = NSTextAlignmentRight;
  self.verticalAlignment = MGVerticalAlignmentCenter;

  // default item layout precedence
  self.sidePrecedence = MGSidePrecedenceLeft;

  // default column widths (0 = flexible)
  self.leftWidth = 0;
  self.middleWidth = 0;
  self.rightWidth = 0;

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

  // apply line spacing
  if ([UILabel instancesRespondToSelector:@selector(attributedText)]) {
    for (UILabel *label in self.leftItems) {
      if ([label isKindOfClass:UILabel.class]) {
        label.attributedText =
            [self applyLineSpacing:self.leftLineSpacing to:label.attributedText];
      }
    }
    for (UILabel *label in self.middleItems) {
      if ([label isKindOfClass:UILabel.class]) {
        label.attributedText =
            [self applyLineSpacing:self.middleLineSpacing to:label.attributedText];
      }
    }
    for (UILabel *label in self.rightItems) {
      if ([label isKindOfClass:UILabel.class]) {
        label.attributedText =
            [self applyLineSpacing:self.rightLineSpacing to:label.attributedText];
      }
    }
  }

  // max usable space
  CGFloat maxWidth = self.widenAsNeeded
          ? FLT_MAX
          :  self.width - self.leftPadding - self.rightPadding;

  // assign space for fixed width columns
  leftUsed = self.leftWidth ? self.leftWidth : 0;
  middleUsed = self.middleWidth ? self.middleWidth : 0;
  rightUsed = self.rightWidth ? self.rightWidth : 0;

  // lay things out
  CGFloat from, limit, used;
  switch (self.sidePrecedence) {
    case MGSidePrecedenceLeft:

      // left first
      limit = self.leftWidth ? self.leftWidth : maxWidth;
      used = [self layoutItems:self.leftItems from:self.leftPadding within:limit
          align:self.leftItemsAlignment];
      leftUsed = self.leftWidth ? self.leftWidth : used;

      // right second
      from = self.leftPadding + leftUsed + middleUsed;
      limit = self.rightWidth ? self.rightWidth : maxWidth - leftUsed;
      used = [self layoutItems:self.rightItems from:from within:limit
          align:self.rightItemsAlignment];
      rightUsed = self.rightWidth ? self.rightWidth : used;

      // middle last
      from = self.leftPadding + leftUsed;
      limit = self.middleWidth ? self.middleWidth : maxWidth - leftUsed
          - rightUsed;
      used = [self layoutItems:self.middleItems from:from within:limit
          align:self.middleItemsAlignment];
      middleUsed = self.middleWidth ? self.middleWidth : used;
      break;

    case MGSidePrecedenceRight:

      // right first
      limit = self.rightWidth ? self.rightWidth : maxWidth;
      used = [self layoutItems:self.rightItems from:self.leftPadding within:limit
          align:self.rightItemsAlignment];
      rightUsed = self.rightWidth ? self.rightWidth : used;

      // left second
      limit = self.leftWidth ? self.leftWidth : maxWidth - rightUsed;
      used = [self layoutItems:self.leftItems from:self.leftPadding within:limit
          align:self.leftItemsAlignment];
      leftUsed = self.leftWidth ? self.leftWidth : used;

      // middle last
      from = self.leftPadding + leftUsed;
      limit = self.middleWidth ? self.middleWidth : maxWidth - leftUsed
          - rightUsed;
      used = [self layoutItems:self.middleItems from:from within:limit
          align:self.middleItemsAlignment];
      middleUsed = self.middleWidth ? self.middleWidth : used;
      break;

    case MGSidePrecedenceMiddle:

      // middle first
      limit = self.middleWidth ? self.middleWidth : maxWidth;
      used = [self layoutItems:self.middleItems from:self.leftPadding within:limit
          align:self.middleItemsAlignment];
      middleUsed = self.middleWidth ? self.middleWidth : used;

      // left second
      limit = self.leftWidth ? self.leftWidth : maxWidth - middleUsed;
      used = [self layoutItems:self.leftItems from:self.leftPadding within:limit
          align:self.leftItemsAlignment];
      leftUsed = self.leftWidth ? self.leftWidth : used;

      // right last
      from = self.leftPadding + leftUsed + middleUsed;
      limit = self.rightWidth ? self.rightWidth : maxWidth - leftUsed
          - middleUsed;
      used = [self layoutItems:self.rightItems from:from within:limit
          align:self.rightItemsAlignment];
      rightUsed = self.rightWidth ? self.rightWidth : used;
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

- (NSAttributedString *)applyLineSpacing:(CGFloat)spacing
    to:(NSAttributedString *)string {
  if (!string.length) {
    return string;
  }
  NSMutableAttributedString *result = string.mutableCopy;
  NSMutableParagraphStyle *parastyle =
      [[string attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL]
          mutableCopy];
  if (!parastyle) {
    parastyle = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
  }
  parastyle.lineSpacing = spacing;
  [result addAttribute:NSParagraphStyleAttributeName value:parastyle
      range:NSMakeRange(0, string.length)];
  return result;
}

- (CGFloat)layoutItems:(NSArray *)items from:(CGFloat)x within:(CGFloat)limit
                 align:(NSTextAlignment)alignment {

  // size and discard
  CGFloat used = [self size:items within:limit];

  // deal with item alignment
  CGFloat nudge = 0;
  switch (alignment) {
    case NSTextAlignmentCenter:
      nudge = (limit - used) / 2;
      break;
    case NSTextAlignmentRight:
      nudge = limit - used;
      break;
    case NSTextAlignmentLeft:
    default:
      break;
  }

  // widen as needed
  if (self.widenAsNeeded) {
    CGFloat needed = self.leftPadding + leftUsed + middleUsed + rightUsed
        + self.rightPadding;
    self.width = needed > self.width ? needed : self.width;
  }

  // lay out
  for (int i = 0; i < items.count; i++) {
    UIView *view = items[i];

    if ([self.dontFit containsObject:view]) {
      continue;
    }

    if ([view conformsToProtocol:@protocol(MGLayoutBox)]
        && [(id)view boxLayoutMode] == MGBoxLayoutAttached) {
      continue;
    }

    x += self.itemPadding;

    CGFloat y = 0;
    switch (self.verticalAlignment) {
      case MGVerticalAlignmentTop:
        y = self.topPadding;
        view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        break;
      case MGVerticalAlignmentCenter:
        y = self.paddedVerticalCenter - view.height / 2;
        view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
            | UIViewAutoresizingFlexibleBottomMargin;
        break;
      case MGVerticalAlignmentBottom:
        y = self.height - self.bottomPadding - view.height;
        view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        break;
    }

    // MGLayoutBoxes have margins to deal with
    if ([view conformsToProtocol:@protocol(MGLayoutBox)]) {
      UIView <MGLayoutBox> *box = (id)view;

      y += box.topMargin;
      x += box.leftMargin;
      box.origin = (CGPoint){roundf(x + nudge), roundf(y)};
      x += box.rightMargin;

      // better be a UIView then
    } else {
      view.origin = (CGPoint){roundf(x + nudge), roundf(y)};
    }
    x += view.width + self.itemPadding;
  }

  return used;
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
          size.width = ceilf(size.width) < maxSize.width ? ceilf(size.width) : maxSize.width;
          size.height = ceilf(size.height);

          // for auto resizing margin sanity, make height odd/even match with self
          if ((int)size.height % 2 && !((int)self.height % 2)) {
            size.height += 1;
          }
          label.size = size;

          used += (label.width);

          // plain old string
        } else {
          label.size = [label.text sizeWithFont:label.font
              constrainedToSize:(CGSize){limit - used, maxHeight}];
          used += label.width;
        }

        // single line
      } else {
        if (used + label.width > limit) { // needs slimming
          label.width = limit - used;
        }
        used += label.width;
      }

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
  label.backgroundColor = self.opaqueLabels
      ? self.backgroundColor
      : UIColor.clearColor;

  // styling
  switch (placement) {
    case MGLeft:
      label.font = self.font;
      label.textAlignment = self.leftItemsAlignment;
      label.shadowOffset = self.leftTextShadowOffset;
      label.shadowColor = self.textShadowColor;
      label.textColor = self.textColor;
      break;
    case MGMiddle:
      label.font = self.middleFont ? : self.font;
      label.textAlignment = self.middleItemsAlignment;
      label.shadowOffset = self.middleTextShadowOffset;
      label.shadowColor = self.middleTextShadowColor ? : self.textShadowColor;
      label.textColor = self.middleTextColor ? : self.textColor;
      break;
    case MGRight:
      label.font = self.rightFont ? : self.font;
      label.textAlignment = self.rightItemsAlignment;
      label.shadowOffset = self.rightTextShadowOffset;
      label.shadowColor = self.rightTextShadowColor ? : self.textShadowColor;
      label.textColor = self.rightTextColor ? : self.textColor;
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

  // need to reset text alignment due to being overwritten in the attributed string attribs
  switch (placement) {
    case MGLeft:
      label.textAlignment = self.leftItemsAlignment;
      break;
    case MGMiddle:
      label.textAlignment = self.middleItemsAlignment;
      break;
    case MGRight:
      label.textAlignment = self.rightItemsAlignment;
      break;
  }

  // final resizing will be done at layout time
  if ([label respondsToSelector:@selector(attributedText)]) {
    CGSize maxSize = (CGSize){FLT_MAX, 0};
    CGSize size = [label.attributedText boundingRectWithSize:maxSize
        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
        context:nil].size;
    size.width = ceilf(size.width) < maxSize.width ? ceilf(size.width) : maxSize.width;
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

#pragma mark - Metrics getters

- (CGFloat)leftSpace {
  return self.innerWidth - middleUsed - rightUsed;
}

- (CGFloat)middleSpace {
  return self.innerWidth - leftUsed - rightUsed;
}

- (CGFloat)rightSpace {
  return self.innerWidth - leftUsed - middleUsed;
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
