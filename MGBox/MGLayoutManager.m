//
//  Created by matt on 14/06/12.
//

#import "MGLayoutManager.h"
#import "MGScrollView.h"

@interface MGLayoutManager ()

+ (void)stackVertical:(UIView <MGLayoutBox> *)container;
+ (void)stackHorizontal:(UIView <MGLayoutBox> *)container;
+ (void)stackVerticalWithWrap:(UIView <MGLayoutBox> *)container;
+ (void)stackHorizontalWithWrap:(UIView <MGLayoutBox> *)container;

@end

@implementation MGLayoutManager

+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container {

  // goners
  NSArray *gone = [MGLayoutManager findBoxesInView:container
      notInSet:container.boxes];
  [gone makeObjectsPerformSelector:@selector(removeFromSuperview)];

  // everyone in now please
  for (UIView <MGLayoutBox> *box in container.boxes) {
    [container addSubview:box];
    if ([container conformsToProtocol:@protocol(MGLayoutBox)]
        || [container conformsToProtocol:@protocol(MGLayoutBox)]) {
      box.parentBox = (id)container;
    }
  }

  // children layout first
  for (id box in container.boxes) {
    [box layout];
  }

  // layout the boxes
  switch (container.contentLayoutMode) {
  case MGLayoutStackVertical:
    [MGLayoutManager stackVertical:container];
    break;
  case MGLayoutStackHorizontal:
    [MGLayoutManager stackHorizontal:container];
    break;
  case MGLayoutStackVerticalWithWrap:
    [MGLayoutManager stackVerticalWithWrap:container];
    break;
  case MGLayoutStackHorizontalWithWrap:
    [MGLayoutManager stackHorizontalWithWrap:container];
    break;
  }

  // position attached and replacement boxes
  [MGLayoutManager positionAttachedBoxesIn:container];

  // zindex time
  [self stackByZIndexIn:container];
}

+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container
            withSpeed:(NSTimeInterval)speed completion:(Block)completion {

  // find new top boxes
  NSMutableArray *newTopBoxes = @[].mutableCopy;
  for (UIView <MGLayoutBox> *box in container.boxes) {
    if (box.replacementFor || box.boxLayoutMode != MGBoxLayoutAutomatic) {
      continue;
    }

    // found the first existing box
    if ([container.subviews containsObject:box]) {
      break;
    }

    [newTopBoxes addObject:box];
  }

  // parent box relationship
  for (UIView <MGLayoutBox> *box in container.boxes) {
    if ([container conformsToProtocol:@protocol(MGLayoutBox)]) {
      box.parentBox = (id)container;
    }
  }

  // children layout first
  for (id box in container.boxes) {
    [box layout];
  }

  // find gone boxes
  NSArray *gone = [MGLayoutManager findBoxesInView:container
      notInSet:container.boxes];

  // new boxes start at zero alpha
  for (UIView <MGLayoutBox> *box in container.boxes) {
    if ([container.subviews indexOfObject:box] == NSNotFound) {
      box.alpha = 0;
    }
  }

  // set y for new top boxes
  CGFloat offsetY = 0;
  for (UIView <MGLayoutBox> *box in newTopBoxes) {
    offsetY += box.topMargin;
    box.y = offsetY;
    offsetY += box.height + box.bottomMargin;
  }

  // move top new boxes above the top
  for (UIView <MGLayoutBox> *box in newTopBoxes) {
    box.y -= offsetY;
  }

  // pre animation positions for remaining new boxes
  CGFloat preAnimY = container.topPadding;
  for (UIView <MGLayoutBox> *box in container.boxes) {
    if (box.boxLayoutMode != MGBoxLayoutAutomatic) {
      continue;
    }
    if ([newTopBoxes containsObject:box]) {
      continue; // new top boxes are already positioned
    }
    preAnimY += box.topMargin;
    CGPoint pos = box.frame.origin;
    if (![container.subviews containsObject:box]) {
      box.alpha = 0;
      box.frame = CGRectMake(pos.x, preAnimY, box.width, box.height);
    }
    preAnimY += box.height + box.bottomMargin;
  }

  // everyone in now please
  for (UIView <MGLayoutBox> *box in container.boxes) {
    [container addSubview:box];
  }

  // pre animation positions for attached and replacement boxes
  [MGLayoutManager positionAttachedBoxesIn:container];

  // stack by zindex
  [MGLayoutManager stackByZIndexIn:container];

  // animate all to final pos and alpha
  [UIView animateWithDuration:speed animations:^{

    // gone boxes fade out
    for (UIView <MGLayoutBox> *box in gone) {
      box.alpha = 0;
    }

    // new boxes fade in
    for (UIView <MGLayoutBox> *box in container.boxes) {
      if ([gone indexOfObject:box] == NSNotFound && !box.alpha) {
        box.alpha = 1;
      }
    }

    // set final positions
    switch (container.contentLayoutMode) {
    case MGLayoutStackVertical:
      [MGLayoutManager stackVertical:container];
      break;
    case MGLayoutStackHorizontal:
      [MGLayoutManager stackHorizontal:container];
      break;
    case MGLayoutStackVerticalWithWrap:
      [MGLayoutManager stackVerticalWithWrap:container];
      break;
    case MGLayoutStackHorizontalWithWrap:
      [MGLayoutManager stackHorizontalWithWrap:container];
      break;
    }

    // final positions for attached and replacement boxes
    [MGLayoutManager positionAttachedBoxesIn:container];

  } completion:^(BOOL done) {

    // clean up
    [gone makeObjectsPerformSelector:@selector(removeFromSuperview)];

    // completion handler
    if (completion) {
      completion();
    }
  }];
}

+ (void)stackVertical:(UIView <MGLayoutBox> *)container {
  CGFloat y = container.topPadding, maxWidth = 0;

  // lay out automatic boxes
  for (UIView <MGLayoutBox> *box in container.boxes) {
    if (box.boxLayoutMode != MGBoxLayoutAutomatic) {
      continue;
    }
    maxWidth = MAX(maxWidth, box.leftMargin + box.width + box.rightMargin);
    y += box.topMargin;
    box.origin = CGPointMake(container.leftPadding + box.leftMargin, y);
    y += box.height + box.bottomMargin;
  }

  // update size to fit the children
  CGSize size;
  size.width = MAX(container.width, container.leftPadding + maxWidth
      + container.rightPadding);
  size.height = MAX(container.height, y + container.bottomPadding);
  if ([container isKindOfClass:MGScrollView.class]) {
    size.width += container.leftMargin + container.rightMargin;
    size.height += container.topMargin + container.bottomMargin;
    [(MGScrollView *)container setContentSize:size];
  } else {
    container.size = size;
  }
}

+ (void)stackHorizontal:(UIView <MGLayoutBox> *)container {
  // implement plz
}

+ (void)stackVerticalWithWrap:(UIView <MGLayoutBox> *)container {
  // implement plz
}

+ (void)stackHorizontalWithWrap:(UIView <MGLayoutBox> *)container {
  CGFloat x = container.leftPadding, y = container.topPadding, maxHeight = 0;

  // lay out automatic boxes
  for (UIView <MGLayoutBox> *box in container.boxes) {
    if (box.boxLayoutMode != MGBoxLayoutAutomatic) {
      continue;
    }

    // next row?
    if (x + box.leftMargin + box.width + box.rightMargin > container.width) {
      x = container.leftPadding;
      y = maxHeight;
    }

    // position
    x += box.leftMargin;
    box.origin = CGPointMake(x, y + box.topMargin);

    x += box.width + box.rightMargin;
    maxHeight = MAX(maxHeight, y + box.topMargin + box.height + box.bottomMargin);
  }

  // update height to fit the children
  if ([container isKindOfClass:MGScrollView.class]) {
    CGSize size = container.size;

    // content size shouldn't be smaller than scroll view size
    size.height = maxHeight + container.bottomPadding > container.height
        ? maxHeight + container.bottomPadding
        : container.height;
    size.width = size.width > container.width ? size.width : container.width;

    [(id)container setContentSize:size];
  } else {
    container.height = maxHeight + container.bottomPadding;
  }
}

+ (void)positionAttachedBoxesIn:(UIView <MGLayoutBox> *)container {
  for (UIView <MGLayoutBox> *box in container.boxes) {
    if (box.boxLayoutMode == MGBoxLayoutAttached) {
      box.origin = CGPointMake(box.attachedTo.frame.origin.x + box.leftMargin,
          box.attachedTo.frame.origin.y + box.topMargin);
    } else if (box.replacementFor) {
      box.origin = box.replacementFor.frame.origin;
      box.replacementFor = nil;
    }
  }
}

+ (NSArray *)findBoxesInView:(UIView *)view notInSet:(id)boxes {
  NSMutableArray *gone = @[].mutableCopy;

  // find gone boxes
  for (UIView <MGLayoutBox> *box in view.subviews) {

    // only manage MGLayoutBoxes
    if (![box conformsToProtocol:@protocol(MGLayoutBox)]) {
      continue;
    }

    if ([boxes indexOfObject:box] == NSNotFound) {
      [gone addObject:box];
    }
  }

  // find attached boxes that lost their buddy
  for (UIView <MGLayoutBox> *box in view.subviews) {

    // only looking for attached boxes
    if (![box conformsToProtocol:@protocol(MGLayoutBox)] || box.boxLayoutMode
        != MGBoxLayoutAttached) {
      continue;
    }

    // buddy is gone. *sob*
    if (!box.attachedTo || ![boxes containsObject:box.attachedTo]
        || [gone containsObject:box.attachedTo]) {
      [boxes removeObject:box];
      [gone addObject:box];
    }
  }

  return gone;
}

+ (NSSet *)findViewsInView:(UIView *)view notInSet:(id)boxes {
  NSMutableSet *gone = NSMutableSet.set;

  // find gone views
  for (UIView *item in view.subviews) {
    if (![boxes containsObject:item]) {
      [gone addObject:item];
    }
  }

  // find attached boxes that lost their buddy
  for (UIView <MGLayoutBox> *box in view.subviews) {

    // only looking for attached boxes
    if (![box conformsToProtocol:@protocol(MGLayoutBox)] || box.boxLayoutMode
        != MGBoxLayoutAttached) {
      continue;
    }

    // buddy is gone. *sob*
    if (!box.attachedTo || ![boxes containsObject:box.attachedTo]
        || [gone containsObject:box.attachedTo]) {
      [boxes removeObject:box];
      [gone addObject:box];
    }
  }

  return gone;
}

+ (void)stackByZIndexIn:(UIView *)container {
  NSSortDescriptor
      *sort = [NSSortDescriptor sortDescriptorWithKey:@"zIndex" ascending:YES];
  NSMutableArray *undies = @[].mutableCopy;
  NSMutableArray *middles = @[].mutableCopy;
  NSMutableArray *topsies = @[].mutableCopy;
  for (id <MGLayoutBox> view in container.subviews) {
    if ([view conformsToProtocol:@protocol(MGLayoutBox)]) {
      if (view.zIndex < 0) {
        [undies addObject:view];
      } else if (view.zIndex > 0) {
        [topsies addObject:view];
      } else {
        [middles addObject:view];
      }
    } else {
      [middles addObject:view];
    }
  }
  [undies sortUsingDescriptors:@[sort]];
  [topsies sortUsingDescriptors:@[sort]];
  for (id view in undies) {
    [container bringSubviewToFront:view];
  }
  for (id view in middles) {
    [container bringSubviewToFront:view];
  }
  for (id view in topsies) {
    [container bringSubviewToFront:view];
  }
}

@end
