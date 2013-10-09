//
//  Created by Matt Greenfield on 24/05/12.
//  http://bigpaua.com/
//

#import "MGLayoutBox.h"

typedef enum {
  MGBorderNone = 0,
  MGBorderEtchedTop = 1 << 1,
  MGBorderEtchedBottom = 1 << 2,
  MGBorderEtchedLeft = 1 << 3,
  MGBorderEtchedRight = 1 << 4,
  MGBorderEtchedAll = (MGBorderEtchedTop | MGBorderEtchedBottom
      | MGBorderEtchedLeft | MGBorderEtchedRight)
} MGBorderStyle;

/**
* `MGBox` is the most base view class of **MGBoxKit**, and functions as
* a generic `UIView` wrapper/replacement. You can use in any situation you might
* usually use a plain `UIView`, giving you the added benefits of **MGBoxKit**
* layout features (margins, padding, zIndex, table/grid layouts, etc).
*
* A plain `MGBox` has no default styling, thus is visually and functionally the
* same as a plain `UIView`, but with extra layout sugar on top.
*
* @warning To layout child boxes inside an `MGBox`, instead of adding them to
* `subviews`, add them to the [boxes]([MGLayoutBox boxes]) array.
*/

@interface MGBox : UIView <MGLayoutBox, UIGestureRecognizerDelegate>

/** @name Creating boxes */

/**
* Create a plain `MGBox` with `CGSizeZero`.
*/
+ (instancetype)box;

/**
* Create an `MGBox` with the given size.
*/
+ (instancetype)boxWithSize:(CGSize)size;

/** @name Init stage setup */

/**
* Override this method in your subclasses to do init stage setup, for example
* setting border styles, colours, layer shadows, etc. Remember to call
* `[super setup]`, or bad things might happen.
*/
- (void)setup;

/** @name Layout */

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
- (void)layoutWithSpeed:(NSTimeInterval)speed completion:(Block)completion;

// ignore these. they're not really here yet
- (void)willEnterViewport;
- (void)didLeaveViewport;

/** @name Performance */

/**
* A convenience boolean to toggle on and off layer rasterisation. Sets the
* `layer.shouldRasterize` and `layer.rasterizationScale` properties as appropriate.
*/
@property (nonatomic, assign) BOOL rasterize;

/** @name Borders */

/**
A convenience property allowing you to toggle on and off etched border style
for individual or all edges.

Possible `MGBorderStyle` values:

* MGBorderNone
* MGBorderEtchedTop
* MGBorderEtchedBottom
* MGBorderEtchedLeft
* MGBorderEtchedRight
* MGBorderEtchedAll
*/
@property (nonatomic, assign) MGBorderStyle borderStyle;

/**
* Setter for the top border colour.
*/
@property (nonatomic, retain) UIColor *topBorderColor;

/**
* Setter for the bottom border colour.
*/
@property (nonatomic, retain) UIColor *bottomBorderColor;

/**
* Setter for the left border colour.
*/
@property (nonatomic, retain) UIColor *leftBorderColor;

/**
* Setter for the right border colour.
*/
@property (nonatomic, retain) UIColor *rightBorderColor;

/**
* The top border view. Modify this directly to achieve deeper border
* customisation.
*/
@property (nonatomic, retain) UIView *topBorder;

/**
* The bottom border view. Modify this directly to achieve deeper border
* customisation.
*/
@property (nonatomic, retain) UIView *bottomBorder;

/**
* The left border view. Modify this directly to achieve deeper border
* customisation.
*/
@property (nonatomic, retain) UIView *leftBorder;

/**
* The right border view. Modify this directly to achieve deeper border
* customisation.
*/
@property (nonatomic, retain) UIView *rightBorder;

/**
* Pass in a `UIColor` to set all borders to the same colour. Or pass in an
* `NSArray` of four `UIColor` values to set top, left, bottom, and right border
* colours (in that order).
*/
- (void)setBorderColors:(id)colors;

/** @name Metrics */

/**
* Taking the box's [topPadding](-[MGLayoutBox topPadding]) and
* [bottomPadding](-[MGLayoutBox bottomPadding]) into account, returns the y value
* for the vertical centre.
*/
- (CGFloat)paddedVerticalCenter;

/**
* Returns the box's width minus its left and right padding.
*/
- (CGFloat)innerWidth;

/**
* Returns the box's height minus its top and bottom padding.
*/
- (CGFloat)innerHeight;

/**
* A convenience method to return a screenshot of the box, with added drop shadow.
*/
- (UIImage *)screenshot:(float)scale;

@end
