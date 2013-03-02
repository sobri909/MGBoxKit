//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGTableBox.h"

@implementation MGTableBox

- (void)layout {
  self.height = 0;

  // refresh
  self.boxes = self.allLines.mutableCopy;

  // and all together now
  [super layout];
}

- (void)layoutWithSpeed:(NSTimeInterval)speed completion:(Block)completion {

  // refresh
  self.boxes = self.allLines.mutableCopy;

  // and smoothly together now
  [super layoutWithSpeed:speed completion:completion];
}

#pragma mark - Getters

- (NSMutableOrderedSet *)topLines {
  if (!_topLines) {
    _topLines = NSMutableOrderedSet.orderedSet;
  }
  return _topLines;
}

- (NSMutableOrderedSet *)middleLines {
  if (!_middleLines) {
    _middleLines = NSMutableOrderedSet.orderedSet;
  }
  return _middleLines;
}

- (NSMutableOrderedSet *)bottomLines {
  if (!_bottomLines) {
    _bottomLines = NSMutableOrderedSet.orderedSet;
  }
  return _bottomLines;
}

- (NSOrderedSet *)allLines {
  NSMutableOrderedSet *all = self.topLines.mutableCopy;
  [all addObjectsFromArray:self.middleLines.array];
  [all addObjectsFromArray:self.bottomLines.array];
  return all;
}

@end
