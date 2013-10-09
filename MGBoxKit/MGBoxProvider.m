//
//  Created by matt on 3/12/12.
//

#import "MGBoxProvider.h"
#import "MGLayoutBox.h"
#import "MGLayoutManager.h"

@implementation MGBoxProvider {
  NSMutableDictionary *boxes;
  NSMutableIndexSet *visibleIndexes;
}

- (id)init {
  self = [super init];
  boxes = @{}.mutableCopy;
  visibleIndexes = NSMutableIndexSet.indexSet;
  return self;
}

+ (MGBoxProvider *)provider {
  return [[self alloc] init];
}

- (void)reset {
  [boxes removeAllObjects];
  [visibleIndexes removeAllIndexes];
  [self.container.boxes removeAllObjects];
}

#pragma mark - Box visibility

- (void)updateVisibleIndexes {
  CGRect viewport = self.container.bufferedViewport;

  // remove any indexes that are no longer visible
  [visibleIndexes enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
    CGRect frame;
    frame.origin = [MGLayoutManager positionForBoxIn:self.container atIndex:i];
    frame.size = [self sizeForBoxAtIndex:i];

    if (!CGRectIntersectsRect(frame, viewport)) {
      [visibleIndexes removeIndex:i];
    }
  }];

  // add newly visible indexes to the start
  int index = visibleIndexes.count ? visibleIndexes.firstIndex : 0;
  while (index >= 0) {
    if ([visibleIndexes containsIndex:index]) {
      index--;
      continue;
    }

    CGRect frame;
    frame.origin = [MGLayoutManager positionForBoxIn:self.container
        atIndex:index];
    frame.size = [self sizeForBoxAtIndex:index];

    if (CGRectIntersectsRect(frame, viewport)) {
      [visibleIndexes addIndex:index];
    } else {
      break;
    }

    index--;
  }

  // add newly visible indexes to the end
  index = visibleIndexes.lastIndex;
  while (index < self.count) {
    if ([visibleIndexes containsIndex:index]) {
      index++;
      continue;
    }

    CGRect frame;
    frame.origin = [MGLayoutManager positionForBoxIn:self.container
        atIndex:index];
    frame.size = [self sizeForBoxAtIndex:index];

    if (CGRectIntersectsRect(frame, viewport)) {
      [visibleIndexes addIndex:index];
    } else {
      break;
    }

    index++;
  }
}

#pragma mark - Box detail factories

- (UIView <MGLayoutBox> *)boxAtIndex:(NSUInteger)index {
  id key = @(index);
  id box = boxes[key];
  if (!box) {
    boxes[key] = box = self.boxMaker(index);
  }
  return box;
}

- (CGSize)sizeForBoxAtIndex:(NSUInteger)index {
  id key = @(index);
  UIView <MGLayoutBox> *box = boxes[key];
  if (box) {
    CGSize size = box.size;
    size.width += box.leftMargin + box.rightMargin;
    size.height += box.topMargin + box.bottomMargin;
    return size;
  } else {
    return self.boxSizer(index);
  }
}

- (NSUInteger)count {
  return self.counter();
}

- (NSIndexSet *)visibleIndexes {
  return visibleIndexes;
}

@end
