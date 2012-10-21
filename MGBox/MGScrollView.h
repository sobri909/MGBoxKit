//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGLayoutBox.h"

@interface MGScrollView : UIScrollView <MGLayoutBox, UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *keepAboveKeyboard;

#pragma mark - Factories

+ (id)scroller;
+ (id)scrollerWithSize:(CGSize)size;

#pragma mark - Init

- (void)setup;

#pragma mark - Layout and scrolling

- (void)layoutWithSpeed:(NSTimeInterval)speed
             completion:(Block)completion;

// convenience method to scroll a rect into view
- (void)scrollToView:(UIView *)view withMargin:(CGFloat)margin;

// box edge snapping
- (void)snapToNearestBox;

// dealing with the keyboard
@property (nonatomic, assign) BOOL keepFirstResponderAboveKeyboard;
@property (nonatomic, assign) CGFloat keyboardMargin;

// this is done automatically now
- (void)restoreAfterKeyboardClose:(Block)completion __attribute__ ((deprecated));

@end
