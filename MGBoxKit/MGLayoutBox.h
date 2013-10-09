//
//  Created by matt on 17/06/12.
//

#import "MGBase.h"
#import "UIView+MGEasyFrame.h"

@class MGBoxProvider;

typedef enum {
  MGBoxLayoutAutomatic,
  MGBoxLayoutFixedPosition,
  MGBoxLayoutAttached,
  MGBoxLayoutNone
} MGBoxLayoutMode;

typedef enum {
  MGResizingNone, MGResizingExpandWidthToFill, MGResizingShrinkWrap
} MGBoxResizingMode;

typedef enum {
  MGLayoutTableStyle, MGLayoutGridStyle
} MGContentLayoutMode;

/**
* The documentation below describes the shared default layout and interaction
* functionality provided by the main base classes: <MGBox>, <MGLine>,
* and <MGScrollView>. <MGLine> provides further table row layout features, and
* <MGBox> provides additional border styling features, described in their
* respective manual pages.
*
* Only `MGLayoutBox` views can be added to a container's <boxes> array.
* `MGLayoutBox` views in <boxes> will be laid out using **MGBoxKit** layout
* features (margins, padding, zIndex, etc).
*
* You should not implement this protocol yourself, but instead use or subclass
* <MGBox>, <MGLine>, <MGTableBox>, or <MGScrollView> (or the provided example
* subclasses, <MGTableBoxStyled>, <MGLineStyled>), which already implement
* the protocol.
*/

@protocol MGLayoutBox <NSObject>

/** @name Relationships */

/**
* Functions as a higher level `subviews`, but accepts only views conforming to
* the `MGLayoutBox` protocol (eg <MGBox>, <MGLine>, etc). During the
* next <layout> pass all boxes in this array will be added to `subviews`,
* and any `MGLayoutBox` subviews that are not found in `boxes` will be removed
* from `subviews`.
*/
@property (nonatomic, retain) NSMutableArray *boxes;

// pretend you didn't see this. the future isn't now
@property (nonatomic, retain) MGBoxProvider *boxProvider;

/**
* Similar to `superview`, although in some cases may have a different value.
*/
@property (nonatomic, weak) UIView <MGLayoutBox> *parentBox;

/** @name Async drawing */

/**
A block assigned to `asyncLayout` will be executed on <asyncQueue> on every
call to <[MGLayoutBox layout]> or <-[MGScrollView layoutWithSpeed:completion:]>,
after the standard layout pass has completed. Useful for performing any CPU or
network intensive data gathering that will result in presentation changes.

    box.asyncLayout = ^{

        // fetch a remote image on a background thread
        [self fetchRemoteImage];

        // update the box presentation on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showLoadedImage];
        });
    };
*/
@property (nonatomic, copy) Block asyncLayout;

/**
* The same as <asyncLayout>, except a block assigned to this will only execute
* once, on the first <layout> pass.
*/
@property (nonatomic, copy) Block asyncLayoutOnce;

/**
The background queue used for <asyncLayout> and <asyncLayoutOnce>. Default is
`DISPATCH_QUEUE_PRIORITY_DEFAULT`. Assign a specific queue if you want to use a
different priority or perform a bunch of expensive processes in serial.

    dispatch_queue_t queue = dispatch_queue_create("SerialQueue", DISPATCH_QUEUE_SERIAL);
    for (MGBox *box in scroller.boxes) {
        box.asyncQueue = queue;
    }
*/
@property (nonatomic, assign) dispatch_queue_t asyncQueue;

/** @name Styling and positioning */

@property (nonatomic, retain) NSMutableArray *boxPositions;

/**
* Provides access to getting and setting all edge margins in a single pass with
* a `UIEdgeInsets` value. Positive values add an external margin while negative
* values create an inset.
*/
@property (nonatomic, assign) UIEdgeInsets margin;

/**
* The box's top margin. Positive values add an external margin (pushing the box
* further down the screen) while negative values create an inset (potentially
* overlapping the box above, or outside of its container).
*/
@property (nonatomic, assign) CGFloat topMargin;

/**
* The box's bottom margin. Positive values add an external margin (pushing the
* next box further down the screen) while negative values
* create an inset (raising the next box higher up the screen).
*/
@property (nonatomic, assign) CGFloat bottomMargin;

/**
* The box's left margin. Positive values add an external margin (pushing the box
* further to the right) while negative values create an inset (potentially
* overlapping the box to the left, or outside of its container).
*/
@property (nonatomic, assign) CGFloat leftMargin;

/**
* The box's right margin. Positive values add an external margin (pushing the
* next box further to the right) while negative values create an inset (pulling
* the next box closer).
*/
@property (nonatomic, assign) CGFloat rightMargin;

@property (nonatomic, assign) MGBoxLayoutMode boxLayoutMode;
@property (nonatomic, assign) MGBoxResizingMode sizingMode;

/**
* Provides fixed position functionality within an <MGScrollView>, similar to
* CSS's `position:fixed`. Assign a `CGPoint` to this property and it will act as
* a fixed frame origin within the scroll view's frame, regardless of current
* scroll offset.
*/
@property (nonatomic, assign) CGPoint fixedPosition;

/**
Assigning a `UIView` to this property will cause the box to set its origin to
the same as the given view's. Useful in situations where you want to replace one
box with another.

    MGBox *newBox = [MGBox boxWithSize:oldBox.size];
    newBox.replacementFor = oldBox;

    [scroller.boxes addObject:newBox];
    [scroller.boxes removeObject:oldBox];

    [scroller layout];
*/
@property (nonatomic, weak) UIView *replacementFor;

/**
* Assigning a `UIView` to this property will cause the box to set its origin to
* the same as the given view's, offset by the box's <leftMargin> and
* <topMargin> values.
*
* @warning If the box and given view do not have the same `superview`, a portal
* will open to Android Land, and all further code will be interpreted as though
* run in a Java VM.
*/
@property (nonatomic, weak) UIView *attachedTo;

/**
* Similar to CSS's zIndex. Modifies the view stacking order, with lower numbers
* layered below higher numbers. Normal (non-MGLayoutBox) views are treated as
* having a `zIndex` of zero.
*/
@property (nonatomic, assign) int zIndex;

/** @name Child positioning */

/**
* Provides access to getting and setting all edge padding in a single pass with
* a `UIEdgeInsets` value. Positive values add inner padding while negative
* values create an outset.
*/
@property (nonatomic, assign) UIEdgeInsets padding;

/**
* The box's top padding. Positive values add inner top padding (pushing inner
* boxes down) while negative values create an outset (potentially raising inner
* boxes outside the box frame).
*/
@property (nonatomic, assign) CGFloat topPadding;

/**
* The box's right padding. Positive values add inner right padding (causing the
* boxes frame to widen) while negative values create an outset (potentially
* causing child boxes to overlap the frame edge).
*/
@property (nonatomic, assign) CGFloat rightPadding;

/**
* The box's bottom padding. Positive values add inner bottom padding (causing the
* boxes frame to become taller) while negative values create an outset
* (potentially causing child boxes to overlap the frame edge).
*/
@property (nonatomic, assign) CGFloat bottomPadding;

/**
* The box's left padding. Positive values add inner left padding (pushing child
* boxes to the right) while negative values create an outset (potentially causing
* child boxes to overlap the frame edge).
*/
@property (nonatomic, assign) CGFloat leftPadding;

/**
* Define whether child boxes will be laid out in a table list or in a grid.
* - `MGLayoutTableStyle` for a table layout, similar to `UITableView`
* - `MGLayoutGridStyle` for a grid layout, similar to `UICollectionView`.
* Default is `MGLayoutTableStyle`.
*/
@property (nonatomic, assign) MGContentLayoutMode contentLayoutMode;

/** @name Layout stage */

@property (nonatomic, assign) BOOL dontLayoutChildren;
@property (nonatomic, assign) BOOL slideBoxesInFromEmpty;
@property (nonatomic, assign) BOOL layingOut;

/**
This is the main layout method, which should be called on a container box once
you have finished adding, removing, positioning, and styling child boxes.

MGScrollView and [MGBox](MGBox) also provide animated layout methods:

- -[MGScrollView layoutWithSpeed:completion:]
- -[MGBox layoutWithSpeed:completion:]
*/
- (void)layout;

@optional

// resizing
@property (nonatomic, assign) CGFloat minWidth;
@property (nonatomic, assign) CGFloat maxWidth;

/** @name Tap gestures */

/** The tap gesture recogniser used for <onTap> blocks and the <tapped> method. */
@property (nonatomic, retain) UITapGestureRecognizer *tapper;

/** Boolean to toggle the tap gesture recogniser on and off. */
@property (nonatomic, assign) BOOL tappable;

/**
A block assigned to this property to will be executed when <tapper> registers a
tap.

    box.onTap = ^{
        NSLog(@"i've been tapped!");
    };
*/
@property (nonatomic, copy) Block onTap;

/**
* This method fires when <tapper> registers a tap. The default implementation
* executes the <onTap> block.
*/
- (void)tapped;

/** @name Swipe gestures */

/**
* The swipe gesture recogniser used for <onSwipe> blocks and the <swiped>
* method.
*/
@property (nonatomic, retain) UISwipeGestureRecognizer *swiper;

/** Boolean to toggle the swipe gesture recogniser on and off. */
@property (nonatomic, assign) BOOL swipable;

/**
* A block assigned to this property to will be executed when <swiper> registers a
* swipe.
*/
@property (nonatomic, copy) Block onSwipe;

/**
* This method fires when <swiper> registers a swipe. The default implementation
* executes the <onSwipe> block.
*/
- (void)swiped;

/** @name Long press gestures */

/**
* The long press gesture recogniser used for <onLongPress> blocks and the
* <longPressed> method.
*/
@property (nonatomic, retain) UILongPressGestureRecognizer *longPresser;

/** Boolean to toggle the long press gesture recogniser on and off. */
@property (nonatomic, assign) BOOL longPressable;

/**
* A block assigned to this property to will be executed when <longPresser>
* registers a long press.
*/
@property (nonatomic, copy) Block onLongPress;

/**
* This method fires when <longPresser> registers a long press. The default
* implementation executes the <onLongPress> block.
*/
- (void)longPressed;

@property (nonatomic, copy) Block onTouchesBegan;
@property (nonatomic, copy) Block onTouchesCancelled;
@property (nonatomic, copy) Block onTouchesEnded;

// for containers using MGBoxProvider
- (CGRect)bufferedViewport;

@end
