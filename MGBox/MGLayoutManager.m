//
//  Created by matt on 14/06/12.
//

#import "MGLayoutManager.h"
#import "MGScrollView.h"
#import "MGLayoutBox.h"

@interface MGLayoutManager ()

+ (void)stackTableStyle:(UIView <MGLayoutBox> *)container
               onlyMove:(NSSet *)only;
+ (void)stackGridStyle:(UIView <MGLayoutBox> *)container
              onlyMove:(NSSet *)only;

@end

@implementation MGLayoutManager

+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container {

  // layout locked?
  if (container.layingOut) {
    return;
  }
  container.layingOut = YES;

  // goners
  NSArray *gone = [MGLayoutManager findBoxesInView:container
      notInSet:container.boxes];
  [gone makeObjectsPerformSelector:@selector(removeFromSuperview)];

  // everyone in now please
  for (UIView <MGLayoutBox> *box in container.boxes) {
    NSAssert([box conformsToProtocol:@protocol(MGLayoutBox)], @"Items in the boxes set must conform to MGLayoutBox");
    [container addSubview:box];
    box.parentBox = (id)container;
  }

  // children layout first
  for (id <MGLayoutBox> box in container.boxes) {
    [box layout];
  }

  // layout the boxes
  switch (container.contentLayoutMode) {
    case MGLayoutTableStyle:
      [MGLayoutManager stackTableStyle:container onlyMove:nil];
      break;
    case MGLayoutGridStyle:
      [MGLayoutManager stackGridStyle:container onlyMove:nil];
      break;
  }

  // position attached and replacement boxes
  [MGLayoutManager positionAttachedBoxesIn:container];

  // zindex time
  [self stackByZIndexIn:container];

  // release the lock
  container.layingOut = NO;
}

+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container
            withSpeed:(NSTimeInterval)speed completion:(Block)completion {

  // layout locked?
  if (container.layingOut) {
    return;
  }
  container.layingOut = YES;

  // find new top boxes
  NSMutableOrderedSet *newTopBoxes = NSMutableOrderedSet.orderedSet;
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

  // find gone boxes
  NSArray *gone = [MGLayoutManager findBoxesInView:container
      notInSet:container.boxes];

  // every box is new and haven't asked for slide-in-from-empty animation?
  if (newTopBoxes.count == container.boxes.count
      && !container.slideBoxesInFromEmpty) {
    [newTopBoxes removeAllObjects];
  }

  // parent box relationship
  for (UIView <MGLayoutBox> *box in container.boxes) {
    box.parentBox = (id)container;
  }

  // children layout first
  for (id <MGLayoutBox> box in container.boxes) {
    [box layout];
  }

  // set origin for new top boxes
  CGFloat offsetY = 0;
  for (UIView <MGLayoutBox> *box in newTopBoxes) {
    box.x = container.leftPadding + box.leftMargin;
    offsetY += box.topMargin;
    box.y = offsetY;
    offsetY += box.height + box.bottomMargin;
  }

  // move top new boxes above the top
  for (UIView <MGLayoutBox> *box in newTopBoxes) {
    box.y -= offsetY;
  }

  // new boxes start faded out
  NSMutableSet *newNotTopBoxes = NSMutableSet.set;
  for (UIView <MGLayoutBox> *box in container.boxes) {
    if (![container.subviews containsObject:box] && !box.replacementFor) {
      box.alpha = 0;

      // collect new boxes that aren't top boxes
      if (![newTopBoxes containsObject:box]) {
        [newNotTopBoxes addObject:box];
      }
    }
  }

  // set start positions for remaining new boxes
  switch (container.contentLayoutMode) {
    case MGLayoutTableStyle:
      [MGLayoutManager stackTableStyle:container onlyMove:newNotTopBoxes];
      break;
    case MGLayoutGridStyle:
      [MGLayoutManager stackGridStyle:container onlyMove:newNotTopBoxes];
      break;
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
      if (![gone containsObject:box] && !box.alpha) {
        box.alpha = 1;
      }
    }

    // set final positions
    switch (container.contentLayoutMode) {
      case MGLayoutTableStyle:
        [MGLayoutManager stackTableStyle:container onlyMove:nil];
        break;
      case MGLayoutGridStyle:
        [MGLayoutManager stackGridStyle:container onlyMove:nil];
        break;
    }

    // final positions for attached and replacement boxes
    [MGLayoutManager positionAttachedBoxesIn:container];

    // release the layout lock
    container.layingOut = NO;

  } completion:^(BOOL done) {

    // clean up
    [gone makeObjectsPerformSelector:@selector(removeFromSuperview)];

    // completion handler
    if (completion) {
      completion();
    }
  }];
}

+ (void)stackTableStyle:(UIView <MGLayoutBox> *)container
               onlyMove:(NSSet *)only {
  CGFloat y = container.topPadding, maxWidth = 0;

  // lay out automatic boxes
  for (UIView <MGLayoutBox> *box in container.boxes) {
    if (box.boxLayoutMode != MGBoxLayoutAutomatic) {
      continue;
    }
    maxWidth = MAX(maxWidth, box.leftMargin + box.width + box.rightMargin);
    y += box.topMargin;
    if (!only || [only containsObject:box]) {
      box.origin = CGPointMake(container.leftPadding + box.leftMargin, roundf(y));
    }
    y += box.height + box.bottomMargin;
  }

  // don't update height if we weren't positioning everyone
  if (only) {
    return;
  }

  // update size to fit the children (and possible shrink wrap)
  CGSize size;
  if (container.sizingMode == MGResizingShrinkWrap) {
    size.width = container.leftPadding + maxWidth + container.rightPadding;
    size.height = y + container.bottomPadding;
  } else {
    size.width = MAX(container.width, container.leftPadding + maxWidth
        + container.rightPadding);
    size.height = MAX(container.height, y + container.bottomPadding);
  }
  if ([container isKindOfClass:MGScrollView.class]) {
    [(id)container setContentSize:size];
  } else {
    container.size = size;
  }
}

+ (void)stackGridStyle:(UIView <MGLayoutBox> *)container
              onlyMove:(NSSet *)only {
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
    if (!only || [only containsObject:box]) {
      box.origin = CGPointMake(roundf(x), roundf(y + box.topMargin));
    }

    x += box.width + box.rightMargin;
    maxHeight = MAX(maxHeight, y + box.topMargin + box.height + box.bottomMargin);
  }

  // don't update height if we weren't positioning everyone
  if (only) {
    return;
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

    // ignore views tagged -2 and below
    if (item.tag < -1) {
      continue;
    }

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
