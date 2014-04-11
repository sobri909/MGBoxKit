//
//  Created by matt on 3/12/12.
//

#import "MGBoxProvider.h"
#import "MGLayoutBox.h"

@implementation MGBoxProvider {
  NSMutableSet *boxCache;
  NSMutableDictionary *boxes;
  NSMutableArray *boxPositions;
  NSMutableIndexSet *visibleIndexes;
}

- (id)init {
  self = [super init];
  boxes = @{}.mutableCopy;
  boxCache = NSMutableSet.set;
  boxPositions = @[].mutableCopy;
  visibleIndexes = NSMutableIndexSet.indexSet;
  return self;
}

+ (instancetype)provider {
  return [[self alloc] init];
}

- (void)reset {
  [boxes removeAllObjects];
  [boxCache removeAllObjects];
  [visibleIndexes removeAllIndexes];
  [self.container.boxes removeAllObjects];
}

#pragma mark - Box visibility

- (void)updateVisibleIndexes {
  CGRect viewport = self.container.bufferedViewport;

  // remove any indexes that are no longer visible
  [visibleIndexes enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
    CGRect frame = [self frameForBoxAtIndex:i];
    if (!CGRectIntersectsRect(frame, viewport)) {
      [visibleIndexes removeIndex:i];
    }
  }];

  // add newly visible indexes to the start
  int index = visibleIndexes.count ? (int)visibleIndexes.firstIndex : 0;
  while (index >= 0 && index < self.count) {
    if ([visibleIndexes containsIndex:index]) {
      index--;
      continue;
    }

    CGRect frame = [self frameForBoxAtIndex:index];
    if (CGRectIntersectsRect(frame, viewport)) {
      [visibleIndexes addIndex:index];
    } else {
      break;
    }

    index--;
  }

  // add newly visible indexes to the end
  index = (int)visibleIndexes.lastIndex;
  while (index < self.count) {
    if ([visibleIndexes containsIndex:index]) {
      index++;
      continue;
    }

    CGRect frame = [self frameForBoxAtIndex:index];
    if (CGRectIntersectsRect(frame, viewport)) {
      [visibleIndexes addIndex:index];
    } else {
      break;
    }

    index++;
  }
}

#pragma mark - Boxes in and out

- (void)removeBoxAtIndex:(NSUInteger)index {
  id key = @(index);
  id box = boxes[key];
  [boxCache addObject:box];
  [boxes removeObjectForKey:key];
  self.container.boxes[index] = NSNull.null;
}

- (UIView <MGLayoutBox> *)boxAtIndex:(NSUInteger)index {
  id key = @(index);
  id box = boxes[key];
  if (!box) {
    if (boxCache.count) {
      box = boxCache.anyObject;
      [boxCache removeObject:box];
    } else {
      box = self.boxMaker();
    }
    self.boxCustomiser(box, index);
    boxes[key] = box;
  }
  return box;
}

- (CGSize)sizeForBoxAtIndex:(NSUInteger)index {
    return self.boxSizer(index);
}

- (CGPoint)originForBoxAtIndex:(NSUInteger)index {
    if (index >= self.boxPositions.count) {
        [self.container layout];
    }
    return [self.boxPositions[index] CGPointValue];
}

- (CGRect)frameForBoxAtIndex:(NSUInteger)index {
    return (CGRect){[self originForBoxAtIndex:index], [self sizeForBoxAtIndex:index]};
}

- (NSUInteger)count {
  return self.counter();
}

- (NSIndexSet *)visibleIndexes {
  return visibleIndexes;
}

- (NSMutableArray *)boxPositions {
    return boxPositions;
}

@end
