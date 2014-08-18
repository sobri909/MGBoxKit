//
//  Created by matt on 14/06/12.
//

#import "MGLayoutManager.h"
#import "MGScrollView.h"
#import "MGBoxProvider.h"
#import <tgmath.h>

CGFloat roundToPixel(CGFloat value) {
  return UIScreen.mainScreen.scale == 1 ? round(value) : round(value * 2.0) / 2.0;
}

@implementation MGLayoutManager

+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container {

  // layout locked?
  if (container.layingOut) {
    return;
  }
  container.layingOut = YES;

    // box provider style layout
    if (container.boxProvider) {
        [container.boxProvider updateDataKeys];
        [container.boxProvider updateBoxFrames];
        [container.boxProvider updateVisibleIndexes];
        [self layoutVisibleBoxesIn:container duration:0 completion:nil];
        [self updateContentSizeFor:container];
        [container.boxProvider updateOldDataKeys];
        [container.boxProvider updateOldBoxFrames];
        container.layingOut = NO;
        return;
    }

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

+ (void)layoutVisibleBoxesIn:(UIView <MGLayoutBox> *)container
      duration:(NSTimeInterval)duration completion:(Block)completion {
    MGBoxProvider *provider = container.boxProvider;

    NSMapTable *boxToIndexMap = [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality
                                                      valueOptions:NSMapTableStrongMemory];
    NSMutableDictionary *visibleBoxes = NSMutableDictionary.new;

    NSMutableOrderedSet *appearingBoxes = NSMutableOrderedSet.new;
    NSMutableOrderedSet *appearingBoxesWithAnimation = NSMutableOrderedSet.new;
    NSMutableOrderedSet *disappearingBoxes = NSMutableOrderedSet.new;
    NSMutableOrderedSet *disappearingBoxesWithAnimation = NSMutableOrderedSet.new;
    NSMutableOrderedSet *movingBoxes = NSMutableOrderedSet.new;

    // move existing boxes or make new boxes
    [provider.visibleIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        UIView <MGLayoutBox> *box;
        BOOL newData = [provider dataAtIndexIsNew:index];
        if (!newData) {
            NSUInteger oldIndex = [provider oldIndexOfDataAtIndex:index];
            box = provider.visibleBoxes[@(oldIndex)];
        }
        if (!box) {
            box = provider.boxCustomiser(index);
            [box layout];
            if (!newData) {
                CGRect oldFrame = [provider oldFrameForBoxAtIndex:index];
                [UIView performWithoutAnimation:^{
                    box.frame = oldFrame;
                }];
            }
            box.hidden = YES;
        }
        visibleBoxes[@(index)] = box;

        if (newData) {
            // fresh data, animate in
            box.hidden = NO;
            box.frame = [provider frameForBoxAtIndex:index];
            [appearingBoxes addObject:box];
            [appearingBoxesWithAnimation addObject:box];
        } else {
            NSUInteger oldIndex = [provider oldIndexOfDataAtIndex:index];
            if (oldIndex != index && oldIndex != NSNotFound) {
                // data has actually moved, we'll update the frame to the new pos later
                [movingBoxes addObject:box];
                if ([box respondsToSelector:@selector(willMoveToIndex:)]) {
                    [box willMoveToIndex:index];
                }
            } else {
                CGRect boxFrame = [provider frameForBoxAtIndex:index];
                // must be a box being recycled onto screen
                if (box.hidden) {
                    box.frame = boxFrame;
                    [appearingBoxes addObject:box];
                } else {
                    if (!CGRectEqualToRect(boxFrame, box.frame)) {
                        box.frame = boxFrame;
                    }
                }
            }
        }
        if (box.superview != container) {
            [container addSubview:box];
            box.parentBox = container;
            box.frame = [provider frameForBoxAtIndex:index];
        }
        if (box.hidden) {
            box.hidden = NO;
        }
        if (box.alpha != 1) {
            box.alpha = 1;
        }
        [boxToIndexMap setObject:@(index) forKey:box];
    }];

    [provider updateVisibleBoxes:visibleBoxes
                   boxToIndexMap:boxToIndexMap];

    // collate boxes that have scrolled offscreen
    for (UIView <MGLayoutBox> *box in container.subviews) {
        if (![box conformsToProtocol:@protocol(MGLayoutBox)]) {
            continue;
        }
        if (![visibleBoxes.allValues containsObject:box]) {
            // box must have scrolled off-screen
            if ([provider dataWasRemovedForBox:box]) {
                // data has disappeared, animate out
                NSUInteger oldIndex = [provider oldIndexOfBox:box];
                if (oldIndex != NSNotFound) {
                    [disappearingBoxesWithAnimation addObject:box];

                }
            } else if (!box.hidden){
                box.hidden = YES;
                [disappearingBoxes addObject:box];
            }
        }
    }

    // zIndex stacking
    [MGLayoutManager stackByZIndexIn:container];

    // do disappear animations
    if (duration) {
        for (UIView <MGLayoutBox> *box in disappearingBoxesWithAnimation) {
            NSUInteger index = [provider oldIndexOfBox:box];
            [provider doDisappearAnimationFor:box atIndex:index duration:duration];
        }
    }

    // do appear animations
    if (duration) {
        for (UIView <MGLayoutBox> *box in appearingBoxesWithAnimation) {
            NSUInteger index = [provider indexOfBox:box];
            [provider doAppearAnimationFor:box atIndex:index duration:duration];
        }
    }

    // do move animations
    for (UIView <MGLayoutBox> *box in movingBoxes) {
        NSUInteger index = [provider indexOfBox:box];
        CGRect toFrame = [provider frameForBoxAtIndex:index];
        if (duration) {
            [provider doMoveAnimationFor:box atIndex:index duration:duration
                               fromFrame:box.frame toFrame:toFrame];
        } else {
            box.frame = toFrame;
        }
        if ([box respondsToSelector:@selector(movedToIndex:)]) {
            [box movedToIndex:index];
        }
    }

    // call appeared and disappeared
    for (UIView <MGLayoutBox> *box in disappearingBoxes) {
        if ([box respondsToSelector:@selector(disappeared)]) {
            [box disappeared];
        }
    }
    for (UIView <MGLayoutBox> *box in appearingBoxes) {
        if ([box respondsToSelector:@selector(appeared)]) {
            [box appeared];
        }
    }

    // remove the removeables and finish up
    Block fini = ^{
        for (UIView <MGLayoutBox> *box in disappearingBoxesWithAnimation) {
            box.hidden = YES;
        }
        if (completion) {
            completion();
        }
    };

    if (duration) {
        dispatch_after(dispatch_time(0,
                                     (int64_t)(duration * NSEC_PER_SEC)),
                                        dispatch_get_main_queue(), ^{
             fini();
        });
    } else {
        fini();
    }
}

+ (NSOrderedSet *)framesForBoxesIn:(UIView <MGLayoutBox> *)container {
    switch (container.contentLayoutMode) {
        case MGLayoutTableStyle:
            return [self stackTableStyle:container];
        case MGLayoutGridStyle:
            return [self stackGridStyle:container];
        default:
            return nil;
    }
}

+ (void)positionBoxesIn:(UIView <MGLayoutBox> *)container {
    switch (container.contentLayoutMode) {
        case MGLayoutTableStyle:
            [self stackTableStyle:container onlyMove:nil];
            break;
        case MGLayoutGridStyle:
            [self stackGridStyle:container onlyMove:nil];
            break;
    }

    // position attached and replacement boxes
    [MGLayoutManager positionAttachedBoxesIn:container];

    // zindex time
    [self stackByZIndexIn:container];
}

+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container duration:(NSTimeInterval)duration
      completion:(Block)completion {

  // layout locked?
  if (container.layingOut) {
    return;
  }
  container.layingOut = YES;

  // box provider style layout
  if (container.boxProvider) {
    [container.boxProvider updateDataKeys];
    [container.boxProvider updateBoxFrames];
    [container.boxProvider updateVisibleIndexes];
    [self layoutVisibleBoxesIn:container duration:duration completion:completion];
    [container.boxProvider updateOldDataKeys];
    [self updateContentSizeFor:container];
    [container.boxProvider updateOldBoxFrames];
    container.layingOut = NO;
    return;
  }


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
    [UIView performWithoutAnimation:^{
        CGFloat offsetY = container.topPadding;
        for (UIView <MGLayoutBox> *box in newTopBoxes) {
            box.x = container.leftPadding + box.leftMargin;
            offsetY += box.topMargin;
            box.y = offsetY;
            offsetY += box.height + box.bottomMargin;
        }

        // move top new boxes above the top
        for (UIView <MGLayoutBox> *box in newTopBoxes) {
            box.y -= (offsetY - container.topPadding);
        }
    }];

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
  [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{

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

#pragma mark - Layout strategies

+ (NSOrderedSet *)stackGridStyle:(UIView <MGLayoutBox> *)container {
    MGBoxProvider *provider = container.boxProvider;
    NSMutableOrderedSet *frames = [NSMutableOrderedSet orderedSetWithCapacity:provider.count];

    CGFloat x = container.leftPadding, y = container.topPadding, rowBottom = 0;
    for (int index = 0; index < provider.count; index++) {
        UIEdgeInsets margin = [provider marginForBoxAtIndex:index];
        CGRect frame = (CGRect){
              (CGPoint){roundToPixel(x + margin.left), roundToPixel(y + margin.top)},
              [provider sizeForBoxAtIndex:index]
        };

        // next row?
        if (CGRectGetMaxX(frame) + margin.right > container.width) {
            frame.origin = (CGPoint){
                  roundToPixel(container.leftPadding + margin.left),
                  roundToPixel(rowBottom + margin.top)
            };
            y = rowBottom;
        }

        // prep for next
        x = CGRectGetMaxX(frame) + margin.right;
        rowBottom = MAX(rowBottom, CGRectGetMaxY(frame) + margin.bottom);

        frames[index] = [NSValue valueWithCGRect:frame];
    }

    return frames;
}

+ (NSOrderedSet *)stackTableStyle:(UIView <MGLayoutBox> *)container {
    MGBoxProvider *provider = container.boxProvider;
    NSMutableOrderedSet *frames = [NSMutableOrderedSet orderedSetWithCapacity:provider.count];

    CGFloat y = container.topPadding;
    for (int index = 0; index < provider.count; index++) {
        UIEdgeInsets margin = [provider marginForBoxAtIndex:index];
        CGRect frame = (CGRect){
              (CGPoint){container.leftPadding + margin.left, y + margin.top},
              [provider sizeForBoxAtIndex:index]
        };
        y = CGRectGetMaxY(frame) + margin.bottom;
        frames[index] = [NSValue valueWithCGRect:frame];
    }

    return frames;
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

    [self updateContentSizeFor:container];
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

  // don't update size if we weren't positioning everyone
  if (only) {
    return;
  }

    [self updateContentSizeFor:container];
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

+ (void)updateContentSizeFor:(UIView <MGLayoutBox> *)container {
    CGSize newSize, oldSize = [container isKindOfClass:MGScrollView.class]
          ? [(id)container contentSize]
          : container.size;
    if (container.sizingMode == MGResizingShrinkWrap) {
        newSize = (CGSize){
              container.leftPadding + container.rightPadding,
              container.topPadding + container.bottomPadding
        };
    } else {
        newSize = oldSize;
    }

    if (container.boxProvider) {
        MGBoxProvider *provider = container.boxProvider;
        for (int index = 0; index < provider.count; index++) {
            CGRect frame = [provider frameForBoxAtIndex:index];
            UIEdgeInsets margin = [provider marginForBoxAtIndex:index];
            newSize.width = MAX(newSize.width, CGRectGetMaxX(frame) + margin.right);
            newSize.height = MAX(newSize.height, CGRectGetMaxY(frame) + margin.bottom);
        }

    } else {
        for (UIView <MGLayoutBox> *box in container.boxes) {
            newSize.width = MAX(newSize.width, box.right + box.rightMargin);
            newSize.height = MAX(newSize.height, box.bottom + box.bottomMargin);
        }
    }

    // add final right and bottom padding
    newSize.width += container.rightPadding;
    newSize.height += container.bottomPadding;

    // only update size if it's changed
    if (!CGSizeEqualToSize(newSize, oldSize)) {
        if ([container isKindOfClass:MGScrollView.class]) {
            [(id)container setContentSize:newSize];
        } else {
            container.size = newSize;
        }
    }
}

+ (void)stackByZIndexIn:(UIView *)container {
    NSArray *sorted =
        [container.subviews sortedArrayUsingComparator:^NSComparisonResult(id<MGLayoutBox> view1,
                                                                           id<MGLayoutBox> view2) {
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

    for (NSInteger sortedIndex = sorted.count - 1; sortedIndex >= 0; sortedIndex--) {
        UIView *view = sorted[sortedIndex];
        if (sortedIndex != [container.subviews indexOfObject:view]) {
            [container insertSubview:view atIndex:sortedIndex];
        }
    }
}

@end
