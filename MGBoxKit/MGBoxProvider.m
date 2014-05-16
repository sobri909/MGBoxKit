//
//  Created by matt on 3/12/12.
//

#import "MGBoxProvider.h"
#import "MGLayoutBox.h"
#import "MGLayoutManager.h"

@implementation MGBoxProvider {
    NSDictionary *_oldVisibleBoxes;
    NSOrderedSet *_dataKeys, *_oldDataKeys;
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
    _visibleIndexes = nil;
    _oldBoxFrames = nil;
    _oldDataKeys = nil;
    _dataKeys = nil;
}

#pragma mark - Internal state list updates

- (void)updateDataKeys {
    _count = NSNotFound;
    NSMutableOrderedSet *dataKeys = [NSMutableOrderedSet orderedSetWithCapacity:self.count];
    for (int i = 0; i < self.count; i++) {
        [dataKeys addObject:[self keyForBoxAtIndex:i]];
    }
    _dataKeys = dataKeys;
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
    CGRect viewport = self.container.bufferedViewport;
    NSMutableIndexSet *visibleIndexes = NSMutableIndexSet.indexSet;
    for (int i = 0; i < self.count; i++) {
        if (CGRectIntersectsRect([self frameForBoxAtIndex:i], viewport)) {
            [visibleIndexes addIndex:i];
        }
    }
    _visibleIndexes = visibleIndexes;
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
            NSUInteger oldIndex = [_oldDataKeys indexOfObject:dataKey];
            box = _visibleBoxes[@(oldIndex)];
        }
        if (!box) {
            box = self.boxCustomiser(index);
            [box layout];
        }
        visibleBoxes[@(index)] = box;
        newBoxes[index] = box;
    }];

    // throw any gone boxes into the cache
    for (UIView <MGLayoutBox> *box in self.visibleBoxes.allValues) {
        if (![visibleBoxes.allValues containsObject:box] && box.cacheKey) {
            [_boxCache addObject:box];
        }
    }

    // boxes should now be true to the data
    _oldVisibleBoxes = _visibleBoxes;
    _visibleBoxes = visibleBoxes;
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

- (NSUInteger)indexOfBox:(UIView <MGLayoutBox> *)box {
    for (id key in self.visibleBoxes) {
        if (self.visibleBoxes[key] == box) {
            return [key integerValue];
        }
    }
    return NSNotFound;
}

- (NSUInteger)oldIndexOfBox:(UIView <MGLayoutBox> *)box {
    for (id key in _oldVisibleBoxes) {
        if (_oldVisibleBoxes[key] == box) {
            return [key integerValue];
        }
    }
    NSLog(@"oldIndexOfBox NSNotFound: %@", box);
    return NSNotFound;
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
    id dataKey = _dataKeys[index];
    NSUInteger oldIndex = [_oldDataKeys indexOfObject:dataKey];
    return [_oldBoxFrames[oldIndex] CGRectValue];
}

@end
