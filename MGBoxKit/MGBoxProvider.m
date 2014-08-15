//
//  Created by matt on 3/12/12.
//

#import "MGBoxProvider.h"
#import "MGLayoutBox.h"
#import "MGLayoutManager.h"

@implementation MGBoxProvider {
    NSMapTable *_boxToIndexMap, *_oldBoxToIndexMap;
    NSOrderedSet *_dataKeys, *_oldDataKeys, *_removedDataKeys;
    NSOrderedSet *_boxFrames, *_oldBoxFrames;
    NSMutableOrderedSet *_boxCache;
    NSUInteger _count;
}

- (id)init {
    self = [super init];
    [self reset];
    return self;
}

+ (instancetype)provider {
  return [[self alloc] init];
}

- (void)resetBoxCache {
    _boxCache = NSMutableOrderedSet.orderedSet;
}

- (void)reset {
    _count = NSNotFound;
    _boxCache = NSMutableOrderedSet.orderedSet;
    _oldBoxToIndexMap = nil;
    _boxToIndexMap = nil;
    _visibleIndexes = nil;
    _oldBoxFrames = nil;
    _oldDataKeys = nil;
    _removedDataKeys = nil;
    _dataKeys = nil;
}

#pragma mark - Internal state list updates

- (void)updateDataKeys {
    _count = NSNotFound;
    NSMutableOrderedSet *dataKeys = [NSMutableOrderedSet orderedSetWithCapacity:self.count];
    for (int i = 0; i < self.count; i++) {
        [dataKeys addObject:[self keyForBoxAtIndex:i]];
    }

    NSAssert(dataKeys.count == self.count, @"Expected %d data keys but have %d. boxKeyMaker "
          "must return unique values.", (int)self.count, (int)dataKeys.count);

    _dataKeys = dataKeys;
    NSMutableOrderedSet *removed = _oldDataKeys.mutableCopy;
    [removed minusOrderedSet:_dataKeys];
    _removedDataKeys = removed;
}

- (void)updateBoxFrames {
    _boxFrames = [MGLayoutManager framesForBoxesIn:self.container];
}

- (void)updateOldDataKeys {
    _oldDataKeys = _dataKeys;
}

- (void)updateOldBoxFrames {
    _oldBoxFrames = _boxFrames;
}

- (void)updateVisibleIndexes {
    if (self.lockVisibleIndexes) {
        return;
    }
    CGRect viewport = self.container.bufferedViewport;
    NSMutableIndexSet *visibleIndexes = NSMutableIndexSet.indexSet;
    for (int i = 0; i < self.count; i++) {
        if (CGRectIntersectsRect([self frameForBoxAtIndex:i], viewport)) {
            [visibleIndexes addIndex:i];
        }
    }
    _visibleIndexes = visibleIndexes;
}

- (void)updateVisibleBoxes:(NSMutableDictionary *)visibleBoxes
             boxToIndexMap:(NSMapTable *)boxToIndexMap {
    _oldBoxToIndexMap = _boxToIndexMap;

    // throw any gone boxes into the cache
    for (UIView <MGLayoutBox> *box in self.visibleBoxes.allValues) {
        if (![visibleBoxes.allValues containsObject:box] && box.cacheKey) {
            [_boxCache addObject:box];
        }
    }

    // boxes should now be true to the data
    _visibleBoxes = visibleBoxes;
    _boxToIndexMap = boxToIndexMap;

}

- (NSUInteger)count {
    if (_count == NSNotFound) {
        _count = self.counter();
    }
    return _count;
}

- (UIView <MGLayoutBox> *)boxOfType:(NSString *)type {
    for (int i = 0; i < _boxCache.count; i++) {
        UIView <MGLayoutBox> *box = _boxCache[i];
        if ([box.cacheKey isEqualToString:type]) {
            [_boxCache removeObject:box];
            box.alpha = 1;
            return box;
        }
    }
    UIView <MGLayoutBox> *box = self.boxMaker(type);
    box.cacheKey = type;
    return box;
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
              options:UIViewAnimationOptionAllowUserInteraction animations:^{
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
              options:UIViewAnimationOptionAllowUserInteraction animations:^{
            box.frame = toFrame;
        } completion:nil];
    }
}

#pragma mark - Data checking


- (BOOL)dataAtIndexIsNew:(NSUInteger)index {
    return ![_oldDataKeys containsObject:_dataKeys[index]];
}

- (BOOL)dataAtIndexIsExisting:(NSUInteger)index {
    return [_oldDataKeys containsObject:_dataKeys[index]];
}

- (BOOL)dataAtOldIndexIsOld:(NSUInteger)index {
    return ![_dataKeys containsObject:_oldDataKeys[index]];
}

- (NSUInteger)oldIndexOfDataAtIndex:(NSUInteger)index {
    return _oldDataKeys ? [_oldDataKeys indexOfObject:_dataKeys[index]] : NSNotFound;
}

- (BOOL)dataWasRemovedForBox:(UIView <MGLayoutBox> *)box {
    NSUInteger index = [self oldIndexOfBox:box];
    if (index == NSNotFound) {
        return NO;
    }
    return _removedDataKeys ? [_removedDataKeys containsObject:_oldDataKeys[index]] : NO;
}

- (NSUInteger)indexOfBox:(UIView <MGLayoutBox> *)box {
    id value = [_boxToIndexMap objectForKey:box];
    if (!value) {
        return NSNotFound;
    }
    return [value unsignedIntegerValue];
}

- (NSUInteger)oldIndexOfBox:(UIView <MGLayoutBox> *)box {
    id value = [_oldBoxToIndexMap objectForKey:box];
    if (!value) {
        return NSNotFound;
    }
    return [value unsignedIntegerValue];
}

#pragma mark - Frames

- (CGSize)sizeForBoxAtIndex:(NSUInteger)index {
    return self.boxSizeMaker(index);
}

- (UIEdgeInsets)marginForBoxAtIndex:(NSUInteger)index {
    return self.boxMarginMaker ? self.boxMarginMaker(index) : UIEdgeInsetsZero;
}

- (CGRect)frameForBoxAtIndex:(NSUInteger)index {
    return [_boxFrames[index] CGRectValue];
}

- (CGRect)oldFrameForBoxAtIndex:(NSUInteger)index {
    if (index >= _oldBoxFrames.count) {
        return CGRectZero;
    }
    id dataKey = _dataKeys[index];
    NSUInteger oldIndex = [_oldDataKeys indexOfObject:dataKey];
    return [_oldBoxFrames[oldIndex] CGRectValue];
}

@end
