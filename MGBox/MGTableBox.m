//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGTableBox.h"

@implementation MGTableBox

- (void)layout {

  // cleanse
  [self.boxes removeAllObjects];

  // put in the lines
  [self.boxes addObjectsFromArray:self.topLines.array];
  [self.boxes addObjectsFromArray:self.middleLines.array];
  [self.boxes addObjectsFromArray:self.bottomLines.array];

  // and all together now
  [super layout];
}

- (void)layoutWithSpeed:(NSTimeInterval)speed completion:(Block)completion {

  // cleanse
  [self.boxes removeAllObjects];

  // put in the lines
  [self.boxes addObjectsFromArray:self.topLines.array];
  [self.boxes addObjectsFromArray:self.middleLines.array];
  [self.boxes addObjectsFromArray:self.bottomLines.array];

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
  return _topLines;
}

- (NSMutableOrderedSet *)bottomLines {
  if (!_bottomLines) {
    _bottomLines = NSMutableOrderedSet.orderedSet;
  }
  return _bottomLines;
}

@end
