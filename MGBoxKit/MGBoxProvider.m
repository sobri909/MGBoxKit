//
//  Created by matt on 3/12/12.
//

#import "MGBoxProvider.h"
#import "MGLayoutBox.h"

@implementation MGBoxProvider {
    NSMutableIndexSet *_visibleIndexes;
    NSDictionary *_previouslyVisibleBoxes;
    NSArray *_previousDataKeys;
    NSMutableArray *_dataKeys;
    NSMutableSet *_boxCache;
}

- (id)init {
    self = [super init];
    _boxCache = NSMutableSet.set;
    _boxPositions = @[].mutableCopy;
    _visibleIndexes = NSMutableIndexSet.indexSet;
    _dataKeys = @[].mutableCopy;
    return self;
}

+ (instancetype)provider {
  return [[self alloc] init];
}

- (void)reset {
    [_boxCache removeAllObjects];
    [_visibleIndexes removeAllIndexes];
    [_dataKeys removeAllObjects];
    _previousDataKeys = nil;
}

#pragma mark - Internal state list updates

- (void)updateDataKeys {
    _previousDataKeys = _dataKeys.copy;
    _dataKeys = @[].mutableCopy;
    for (int i = 0; i < self.count; i++) {
        [_dataKeys addObject:[self keyForBoxAtIndex:i]];
    }
}

- (void)updateVisibleIndexes {
    CGRect viewport = self.container.bufferedViewport;
    for (int i = 0; i < self.count; i++) {
        CGRect frame = [self footprintForBoxAtIndex:i];
        BOOL visible = CGRectIntersectsRect(frame, viewport);
        BOOL have = [_visibleIndexes containsIndex:i];
        if (visible && !have) {
            [_visibleIndexes addIndex:i];
        }
        if (!visible && have) {
            [_visibleIndexes removeIndex:i];
        }
    }

    // prune any indexes beyond the end
    [_visibleIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        if (index >= self.count) {
            [_visibleIndexes removeIndex:index];
        }
    }];
}

- (void)updateVisibleBoxes {

    // null pad a new boxes array
    NSMutableArray *newBoxes = @[].mutableCopy;
    NSMutableDictionary *visibleBoxes = @{}.mutableCopy;
    while (newBoxes.count < self.count) {
        [newBoxes addObject:NSNull.null];
    }

    // move existing boxes or make new boxes
    [_visibleIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        UIView <MGLayoutBox> *box;
        if ([self dataAtIndexIsExisting:index]) {
            id dataKey = _dataKeys[index];
            NSUInteger oldIndex = [_previousDataKeys indexOfObject:dataKey];
            box = _visibleBoxes[@(oldIndex)];
        }
        if (!box) {
            if (_boxCache.count) {
                box = _boxCache.anyObject;
                [_boxCache removeObject:box];
                box.alpha = 1;
            } else {
                box = self.boxMaker();
            }
            self.boxCustomiser(box, index);
        }
        visibleBoxes[@(index)] = box;
        newBoxes[index] = box;
    }];

    // throw any gone boxes into the cache
    for (id box in self.visibleBoxes.allValues) {
        if (![visibleBoxes.allValues containsObject:box]) {
            [_boxCache addObject:box];
        }
    }

    // boxes should now be true to the data
    _previouslyVisibleBoxes = _visibleBoxes;
    _visibleBoxes = visibleBoxes;
}

- (NSUInteger)count {
    return self.counter();
}

#pragma mark - Individual box state updates

- (id)keyForBoxAtIndex:(NSUInteger)index {
    if (self.boxKeyMaker) {
        return self.boxKeyMaker(index);
    }
    return @(index);
}

#pragma mark - Animations

- (void)doAppearAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration {
    if (self.appearAnimation) {
        self.appearAnimation(box, index, duration, box.frame, box.frame);
    } else {
        box.alpha = 0;
        [UIView animateWithDuration:duration delay:0
              options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
              animations:^{
                  box.alpha = 1;
              } completion:nil];
    }
}

- (void)doDisappearAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration {
    if (self.disappearAnimation) {
        self.disappearAnimation(box, index, duration, box.frame, box.frame);
    } else {
        [UIView animateWithDuration:duration delay:0
              options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
              animations:^{
                  box.alpha = 0;
              } completion:nil];
    }
}

- (void)doMoveAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration fromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame {
    if (self.moveAnimation) {
        self.moveAnimation(box, index, duration, fromFrame, toFrame);
    } else {
        [UIView animateWithDuration:duration delay:0
              options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
              animations:^{
                  box.frame = toFrame;
              } completion:nil];
    }
}

#pragma mark - Data checking

- (BOOL)dataAtIndexIsOld:(NSUInteger)index {
    return ![_dataKeys containsObject:_previousDataKeys[index]];
}

- (BOOL)dataAtIndexIsExisting:(NSUInteger)index {
    return [_previousDataKeys containsObject:_dataKeys[index]];
}

- (BOOL)dataAtIndexIsNew:(NSUInteger)index {
    return ![_previousDataKeys containsObject:_dataKeys[index]];
}

- (NSUInteger)indexOfBox:(UIView <MGLayoutBox> *)box {
    for (id key in self.visibleBoxes) {
        if (self.visibleBoxes[key] == box) {
            return [key integerValue];
        }
    }
    return NSNotFound;
}

- (NSUInteger)oldIndexOfBox:(UIView <MGLayoutBox> *)box {
    for (id key in _previouslyVisibleBoxes) {
        if (_previouslyVisibleBoxes[key] == box) {
            return [key integerValue];
        }
    }
    return NSNotFound;
}

#pragma mark - Frames

- (CGSize)sizeForBoxAtIndex:(NSUInteger)index {
    return self.boxSizer(index);
}

- (CGPoint)originForBoxAtIndex:(NSUInteger)index {
    if (index >= self.boxPositions.count) {
        [self.container layout];
    }
    return [self.boxPositions[index] CGPointValue];
}

- (CGRect)footprintForBoxAtIndex:(NSUInteger)index {
    return (CGRect){[self originForBoxAtIndex:index], [self sizeForBoxAtIndex:index]};
}

- (CGRect)frameForBox:(UIView <MGLayoutBox> *)box {
    CGRect frame = [self footprintForBoxAtIndex:[self indexOfBox:box]];
    frame.origin.x += box.leftMargin;
    frame.origin.y += box.topMargin;
    frame.size.width -= (box.leftMargin + box.rightMargin);
    frame.size.height -= (box.topMargin + box.bottomMargin);
    return frame;
}

@end
