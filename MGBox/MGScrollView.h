//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGLayoutBox.h"

@interface MGScrollView : UIScrollView <MGLayoutBox, UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *keepAboveKeyboard;

- (void)layoutWithSpeed:(NSTimeInterval)speed
             completion:(Block)completion;
- (void)snapToNearestBox;
- (void)keyboardWillAppear:(NSNotification *)note;
- (void)restoreAfterKeyboardClose:(Block)completion;
- (void)setup;

@end
