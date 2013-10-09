//
//  Created by matt on 14/06/12.
//

#import "MGLayoutManager.h"
#import "MGScrollView.h"
#import "MGBoxProvider.h"

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
    box.parentBox = container;
  }

  // children layout first
  if (!container.dontLayoutChildren) {
    for (id <MGLayoutBox> box in container.boxes) {
      [box layout];
    }
  }

  // positioning time
  [MGLayoutManager positionBoxesIn:container];

  // release the lock
  container.layingOut = NO;
}

+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container
            atIndexes:(NSIndexSet *)indexes {

  // remove boxes that aren't at the given indexes
  for (int i = 0; i < container.boxes.count; i++) {
    if (![indexes containsIndex:i]) {
      UIView *box = container.boxes[i];
      if ([box isKindOfClass:UIView.class] && box.superview) {
        [box removeFromSuperview];
      }
    }
  }

  // remove boxes no longer in 'boxes'
  NSArray *gone = [MGLayoutManager findBoxesInView:container
      notInSet:container.boxes];
  [gone makeObjectsPerformSelector:@selector(removeFromSuperview)];

  // add and position boxes at the given indexes
  [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {

    // get the box
    UIView <MGLayoutBox>
        *box = index < container.boxes.count ? container.boxes[index] : nil;
    if (!box || (id)box == NSNull.null) {
      container.boxes[index] = box = [container.boxProvider boxAtIndex:index];
    }

    if (!box.superview) {
      box.parentBox = container;
      [container addSubview:box];
      [box layout];
    }

    // get and set the origin
    CGPoint origin = [self positionForBoxIn:container atIndex:index];
    origin.x += box.leftMargin;
    origin.y += box.topMargin;
    if (!CGPointEqualToPoint(origin, box.origin)) {
      box.origin = origin;
    }
  }];
}

+ (CGPoint)positionForBoxIn:(UIView <MGLayoutBox> *)container
                    atIndex:(NSUInteger)index {

  // fill missing positions and boxes
  if (index >= container.boxes.count) {
    CGFloat y = container.topPadding;
    for (int i = 0; i < index; i++) {
      CGSize size = [container.boxProvider sizeForBoxAtIndex:i];
      CGPoint origin = (CGPoint){container.leftPadding, y};
      y += size.height;
      if (i >= container.boxes.count) {
        container.boxPositions[i] = [NSValue valueWithCGPoint:origin];
        container.boxes[i] = NSNull.null;
      }
    }
  }

  // previous box position and size
  CGPoint prevPos = index
      ? [container.boxPositions[index - 1] CGPointValue]
      : CGPointZero;
  CGSize prevSize = index
      ? [container.boxProvider sizeForBoxAtIndex:index - 1]
      : CGSizeZero;

  // calc the position
  CGPoint pos;
  pos.x = container.leftPadding;
  pos.y = prevPos.y + prevSize.height;
  container.boxPositions[index] = [NSValue valueWithCGPoint:pos];

  return pos;
}

+ (void)positionBoxesIn:(UIView <MGLayoutBox> *)container {
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
    if (box.boxLayoutMode != MGBoxLayoutAutomatic) {
      continue;
    }

    // found the first existing box
    if ([container.subviews containsObject:box] || box.replacementFor) {
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
    box.parentBox = container;
  }

  // children layout first
  if (!container.dontLayoutChildren) {
    for (id <MGLayoutBox> box in container.boxes) {
      [box layout];
    }
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
  [UIView animateWithDuration:speed delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{

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
    [MGLayoutManager positionBoxesIn:container];

    // release the layout lock
    container.layingOut = NO;

  } completion:^(BOOL done) {

    // clean up
    for (UIView <MGLayoutBox> *goner in gone) {
      if (goner.superview == container && ![container.boxes containsObject:goner]) {
        [goner removeFromSuperview];
      }
    }

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
      CGPoint newOrigin = CGPointMake(container.leftPadding + box.leftMargin,
          roundToPixel(y));
      if (!CGPointEqualToPoint(newOrigin, box.origin)) {
        box.origin = newOrigin;
      }
    }
    y += box.height + box.bottomMargin;
  }

  // don't update height if we weren't positioning everyone
  if (only) {
    return;
  }

  // update size to fit the children (and possible shrink wrap)
  CGSize newSize, oldSize = [container isKindOfClass:MGScrollView.class]
      ? [(id)container contentSize]
      : container.size;
  if (container.sizingMode == MGResizingShrinkWrap) {
    newSize.width = MAX(container.leftPadding + maxWidth + container.rightPadding, container.minWidth);
    newSize.height = y + container.bottomPadding;
  } else {
    newSize.width = MAX(oldSize.width, container.leftPadding + maxWidth
        + container.rightPadding);
    newSize.height = MAX(oldSize.height, y + container.bottomPadding);
  }

  // only update size if it's changed
  if (!CGSizeEqualToSize(newSize, oldSize)) {
    if ([container isKindOfClass:MGScrollView.class]) {
      [(id)container setContentSize:newSize];
    } else {
      container.size = newSize;
    }
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
      box.origin = CGPointMake(roundToPixel(x), roundToPixel(y + box.topMargin));
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
  NSArray *sorted =
      [container.subviews sortedArrayUsingComparator:^NSComparisonResult(id view1,
          id view2) {
        int z1 = [view1 respondsToSelector:@selector(zIndex)] ? [view1 zIndex] : 0;
        int z2 = [view2 respondsToSelector:@selector(zIndex)] ? [view2 zIndex] : 0;
        if (z1 > z2) {
          return NSOrderedDescending;
        }
        if (z1 < z2) {
          return NSOrderedAscending;
        }
        return NSOrderedSame;
      }];

  for (UIView *view in sorted) {
    int sortedIndex = [sorted indexOfObject:view];
    if (sortedIndex != [container.subviews indexOfObject:view]) {
      [container insertSubview:view atIndex:sortedIndex];
    }
  }
}

float roundToPixel(float value) {
    if (UIScreen.mainScreen.scale == 1.0f) {
        return roundf(value);
    }
    //retina display, round to nearest half point
    return roundf(value * 2.0) / 2.0;
}

@end
