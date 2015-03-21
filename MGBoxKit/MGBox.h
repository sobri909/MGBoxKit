//
//  Created by Matt Greenfield on 24/05/12.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MGLayoutBox.h"

/**
* `MGBox` is the most base view class of **MGBoxKit**, and functions as
* a generic `UIView` wrapper/replacement. You can use in any situation you might
* usually use a plain `UIView`, giving you the added benefits of **MGBoxKit**
* layout features (margins, padding, zIndex, table/grid layouts, etc).
*
* A plain `MGBox` has no default styling, thus is visually and functionally the
* same as a plain `UIView`, but with extra layout sugar on top.
*
* @warning To layout child boxes inside an `MGBox`, add them to
* [boxes]([MGLayoutBox boxes]) instead of `subviews`,
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
* An animated version of [layout](-[MGLayoutBox layout]), taking a duration
* parameter and optional completion block.
*
* All <MGLayoutBox> positioning rules will be applied, the same as in the
* unanimated [layout](-[MGLayoutBox layout]) method, but with child boxes
* animated between previous and new computed positions, fading new boxes in,
* and fading removed boxes out. Child boxes will have their unanimated layout
* method called. If you want a child box to also animate the positioning of its
* children in the same drawing pass, call `layoutWithDuration:completion:` on
* the child box first.
*/
- (void)layoutWithDuration:(NSTimeInterval)duration completion:(Block)completion;

/** @name Performance */

/**
* A convenience boolean to toggle on and off layer rasterisation. Sets the
* `layer.shouldRasterize` and `layer.rasterizationScale` properties as appropriate.
*/
@property (nonatomic, assign) BOOL rasterize;

/** @name Borders */

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
Pass in a `UIColor` to set all borders to the same colour. Or pass in an
`NSArray` of four `UIColor` values to set top, left, bottom, and right border
colours (in that order).

    // all borders the same colour
    box.borderColors = UIColor.redColor;

    // individual colours
    box.borderColors = @[
        UIColor.redColor, UIColor.greenColor,
        UIColor.blueColor, UIColor.blackColor
    ];
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
* Returns the box's size minus its padding.
*/
- (CGSize)innerSize;

/**
* Returns the box's width minus its left and right padding.
* @deprecated Use innerSize.width instead.
*/
- (CGFloat)innerWidth __deprecated;

/**
* Returns the box's height minus its top and bottom padding.
* @deprecated Use innerSize.height instead.
*/
- (CGFloat)innerHeight __deprecated;

/**
* A convenience method to return a screenshot of the box, with added drop shadow.
*/
- (UIImage *)screenshotWithShadow:(BOOL)shadow scale:(float)scale;

/** @name Tapping */

/**
 * If set to YES this box can trigger tap events simultaneously with other views.
 * Defaults to NO.
 */
@property (nonatomic, assign) BOOL allowSimultaneousTaps;

/**
 * Analagous to UIButton's highlighted property.  Highlighted is set to YES if
 * a touch down event occurs on the MGBox, and set to NO on touch up or cancelled
 * events.
 */
@property (nonatomic, assign) BOOL highlighted;

/**
 * A convenience block that is called whenever the highlighted property changes
 */
@property (nonatomic, copy) void (^onHighlightChanged)(BOOL highlighted);

@end
