//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGLayoutBox.h"

@interface MGScrollView : UIScrollView <MGLayoutBox, UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *keepAboveKeyboard;

// factories
+ (id)scroller;
+ (id)scrollerWithSize:(CGSize)size;

// init
- (void)setup;

// layout and scrolling
- (void)layoutWithSpeed:(NSTimeInterval)speed
             completion:(Block)completion;
- (void)scrollToView:(UIView *)view withMargin:(CGFloat)margin;
- (void)snapToNearestBox;
- (void)keyboardWillAppear:(NSNotification *)note;
- (void)restoreAfterKeyboardClose:(Block)completion;

@end
