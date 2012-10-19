//
//  Created by Matt Greenfield on 24/05/12.
//  Copyright (c) 2012 Big Paua. All rights reserved.
//  http://bigpaua.com/
//

#import "MGLayoutBox.h"

@interface MGBox : UIView <MGLayoutBox, UIGestureRecognizerDelegate>

// init methods
+ (id)box;
+ (id)boxWithSize:(CGSize)size;
- (void)setup;

// layout
- (void)layoutWithSpeed:(NSTimeInterval)speed
             completion:(Block)completion;

// sugar
- (UIImage *)screenshot:(float)scale;

@end
