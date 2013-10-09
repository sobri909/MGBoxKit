//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGLayoutBox.h"

@interface MGScrollView : UIScrollView
    <MGLayoutBox, UIGestureRecognizerDelegate, UIScrollViewDelegate>

#pragma mark - Factories

/** @name Creating scrollers */

/**
* Create a plain `MGScrollView` with `CGSizeZero`.
*/
+ (id)scroller;

/**
* Create an `MGScrollView` with the given size.
*/
+ (id)scrollerWithSize:(CGSize)size;

#pragma mark - Init

/** @name Init stage setup */

/**
* Override this method in your subclasses to do init stage setup, for example
* setting colours, layer shadows, etc. Remember to call `[super setup]`, or bad
* things might happen.
*
* @note In most cases you shouldn't need to subclass `MGScrollView`, so shouldn't
* need a custom `setup` method.
*/
- (void)setup;

#pragma mark - Layout and scrolling

/** @name Layout stage */

/**
* An animated version of [MGLayoutBox layout], taking a duration parameter and
* optional completion block.
*
* All MGLayoutBox positioning rules will be applied, the same as in the
* unanimated [layout](-[MGLayoutBox layout]) method, but with child boxes animated between previous and
* new computed positions, fading new boxes in, and fading removed boxes out.
* Child boxes will have their unanimated layout method called. If you want a
* child box to also animate the positioning of its children in the same drawing pass, call `layoutWithSpeed:completion:` on the child box first.
*/
- (void)layoutWithSpeed:(NSTimeInterval)speed
             completion:(Block)completion;

/** @name Scrolling */

/**
* A convenience method to scroll a subview into the visible viewport, with a given
* margin for better aesthetics.
*
* @param view The subview of the `MGScrollView` that you want to scroll to
* @param margin The desired amount of extra space around the view
*/
- (void)scrollToView:(UIView *)view withMargin:(CGFloat)margin;

/** @name Box edge snapping */

/**
* Toggle on or off box edge snapping, to create an effect similar to
* `UIScrollView` paging, but that is aware of individual child box edges.
*/
@property (nonatomic, assign) BOOL snapToBoxEdges;

// this doesn't need to be public now. might go private in a future release
- (void)snapToNearestBox;

/**
* Whether to adjust the scroll offset when the keyboard appears, to keep the
* active input field visible. Default is `YES`.
*/
@property (nonatomic, assign) BOOL keepFirstResponderAboveKeyboard;
@property (nonatomic, weak) UIView
    *keepAboveKeyboard __attribute__ ((deprecated));

/**
* The amount of space to allow between the the keyboard and the active input
* field when automatically scrolling to keep the field visible
* (ie keepFirstResponderAboveKeyboard).
*/
@property (nonatomic, assign) CGFloat keyboardMargin;

- (void)keyboardWillAppear:(NSNotification *)note;
- (void)restoreAfterKeyboardClose:(Block)completion __attribute__ ((deprecated));

// for the upcoming box caching/reuse functionality
@property (nonatomic, assign) CGSize viewportMargin;

@end
