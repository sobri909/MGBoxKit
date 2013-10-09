//
//  Created by Matt Greenfield on 24/05/12
//  http://bigpaua.com/
//

#import "MGBox.h"

// may be deprecated in future. use MGBox borders instead
typedef enum {
  MGUnderlineNone, MGUnderlineTop, MGUnderlineBottom
} MGUnderlineType;

typedef enum {
  MGSidePrecedenceLeft, MGSidePrecedenceRight, MGSidePrecedenceMiddle
} MGSidePrecedence;

typedef enum {
  MGVerticalAlignmentTop, MGVerticalAlignmentCenter, MGVerticalAlignmentBottom
} MGVerticalAlignment;

typedef enum { MGLeft, MGMiddle, MGRight } MGItemPlacement;

/**
`MGLine` is roughly equivalent to `UITableViewCell`, functioning as a base
class for table rows. It can also be used generically as a layout container
for left, centre, and right justified content, providing easy text formatting
and view positioning.

Text formatting is set per side (left, middle, right) with properties for fonts,
colours, shadow colours, shadow offsets, and text alignment.

The content item arrays (leftItems, middleItems, rightItems) accept arrays of
items of kinds `NSString`, `NSAttributedString`, `UIView`, and `UIImage`.
Strings will be wrapped with `UILabel` and styled according to the line's text
styling properties. Images will be wrapped with `UIImageView`.

Strings that are suffixed with `|mush` will be parsed for lightweight `Mush`
markup and replaced with an appropriately attributed `NSAttributedString` on iOS 6
and above. For pre-iOS 6 devices, the markup will be stripped and the strings
presented plain.

    box.leftItems = @[@"String with **bold** //italics// __underlining__ and `monospacing`|mush"];

When more content items are provided than the available horizontal space allows,
items are given displayed precedence according to the sidePrecedence property.
For example, if sidePrecedence is set to MGSidePrecedenceLeft (the default),
leftItems will be displayed first, until the available space is consumed, then
remaining leftItems, middleItems, and rightItems that don't fit will not be
displayed. The items that are not displayed will remain in their respective content arrays.
*/
@interface MGLine : MGBox

#pragma mark - Factories

/** @name Creating lines */

/**
* Create a plain `MGLine` with `CGSizeZero`.
*/
+ (id)line;

/**
* Create an `MGLine` with the given size.
*/
+ (id)lineWithSize:(CGSize)size;

/**
* Create an `MGLine` with `CGSizeZero` and with the given left and right
* parameters assigned to leftItems and rightItems.
*/
+ (id)lineWithLeft:(NSObject *)left right:(NSObject *)right;

/**
* Create an `MGLine` with the given size and with the given left and right
* parameters assigned to leftItems and rightItems.
*/
+ (id)lineWithLeft:(NSObject *)left right:(NSObject *)right size:(CGSize)size;

/**
* Create an `MGLine` with multiline left text.
*
* @param left A string that will be treated as multiline and assigned to
* multilineLeft. Can include `Mush` markup if suffixed with `|mush`.
* @param right An `NSString`, `NSAttributedString`, `UIView`, `UIImage`, or
* `NSArray` of accepted types. Will be assigned to rightItems.
* @param width The returned line will have this width.
* @param minHeight A minimum acceptable row height, beyond which the line may
* extend to accommodate the multiline text. Will be assigned to minHeight.
*/
+ (id)lineWithMultilineLeft:(NSString *)left right:(id)right width:(CGFloat)width
                  minHeight:(CGFloat)height;

/**
* Create an `MGLine` with multiline right text. Parameters function the same as in
* lineWithMultilineLeft:right:width:minHeight:
*/
+ (id)lineWithLeft:(id)left multilineRight:(NSString *)right width:(CGFloat)width
         minHeight:(CGFloat)height;

/**
* Create an `MGLine` with multiline left text.
*
* @param text A string that will be treated as multiline and assigned to
* leftItems. Can include `Mush` markup if suffixed with `|mush`.
* @param font Will be assigned to the line's font property.
* @param width The returned line will have this width.
* @param padding Will be assigned to the line's padding property.
*/
+ (id)multilineWithText:(NSString *)text font:(UIFont *)font width:(CGFloat)width
                padding:(UIEdgeInsets)padding;

#pragma mark - Mixed items

/** @name Content item arrays */

/**
Accepts arbitrary arrays of items of kinds `NSString`, `NSAttributedString`,
`UIView`, and `UIImage`. Strings will be wrapped with `UILabel` and styled
according to the line's text styling property values. Images will be wrapped with
`UIImageView`.

You may also directly assign a single item, to replace all existing left items
with the given item. Cast to `id` to avoid warnings.

    box.leftItems = (id)@"This text will appear on the left";
    box.rightItems = (id)[UIImage imageNamed:@"arrow_icon"];

If a string contains a newline character it will be treated as multiline. To
force multiline presentation for a string, append a newline character.

    box.leftItems = @"Let's pretend this is a really long string.\n";

@note Strings that are suffixed with `|mush` will be parsed for `Mush` markup.
*/
@property (nonatomic, retain) NSMutableArray *leftItems;

/**
* Identical to leftItems, except that items will be centred in the container and
* text styled according to the appropriate middle text style properties.
*/
@property (nonatomic, retain) NSMutableArray *middleItems;

/**
* Identical to leftItems, except that items will be right aligned in the
* container and text styled according to the appropriate middle text style
* properties.
*/
@property (nonatomic, retain) NSMutableArray *rightItems;

/**
* Returns a set containing the contents of leftItems, middleItems, and rightItems.
*/
- (NSSet *)allItems;

#pragma mark - Multiline string items

/** @name Multiline text convenience setters */

/**
* A convenience setter for passing in multiline text. The given string will be
* treated as multiline even if it contains no newline characters, and assigned
* to leftItems.
* Can include `Mush` markup if suffixed with `|mush`.
*/
- (void)setMultilineLeft:(NSString *)text;

/**
* A convenience setter for passing in multiline text. The given string will be
* treated as multiline even if it contains no newline characters, and assigned
* to middleItems.
* Can include `Mush` markup if suffixed with `|mush`.
*/
- (void)setMultilineMiddle:(NSString *)text;

/**
* A convenience setter for passing in multiline text. The given string will be
* treated as multiline even if it contains no newline characters, and assigned
* to rightItems.
* Can include `Mush` markup if suffixed with `|mush`.
*/
- (void)setMultilineRight:(NSString *)text;

// may be deprecated in future. use MGBox borders instead
@property (nonatomic, assign) MGUnderlineType underlineType;

/** @name Layout order and positioning */

/**
Defines which content items are laid out first, thus getting use of the full line
width. The leftover space will be distributed amongst the remaining items.

- `MGSidePrecedenceLeft - Items in leftItems are laid out first (default)
- `MGSidePrecedenceMiddle` - Items in middleItems are laid out first
- `MGSidePrecedenceRight` - Items in rightItems are laid out first
*/
@property (nonatomic, assign) MGSidePrecedence sidePrecedence;

/**
Whether the given content items (in leftItems, middleItems, rightItems) should be
vertically aligned to the top, centre, or bottom.

The line's [topPadding](-[MGLayoutBox topPadding]) and
[bottomPadding](-[MGLayoutBox bottomPadding]) are taken into account, potentially
offsetting centred items from the unpadded centre. For items that conform to
MGLayoutBox, their [topMargin](-[MGLayoutBox topMargin]) and
[bottomMargin](-[MGLayoutBox bottomMargin]) values will also be applied.

- `MGVerticalAlignmentTop`
- `MGVerticalAlignmentCenter` (default)
- `MGVerticalAlignmentBottom`

@note The vertical centre with padding taken into account is available via
[paddedVerticalCenter](-[MGBox paddedVerticalCenter]).
*/
@property (nonatomic, assign) MGVerticalAlignment verticalAlignment;

#pragma mark - Styling

/** @name Fonts */

/**
* The font used for labels created for given string items.
*/
@property (nonatomic, retain) UIFont *font;

/**
* The font used for labels crated for middle string items. If `nil`, font is used
* instead.
*/
@property (nonatomic, retain) UIFont *middleFont;

/**
* The font used for labels crated for right string items. If `nil`, font is used
* instead.
*/
@property (nonatomic, retain) UIFont *rightFont;

/** @name Text Colours */

/**
* The text colour used for labels created for given string items.
*/
@property (nonatomic, retain) UIColor *textColor;

/**
* The text colour used for labels created for given middle string items. If `nil`,
* textColor is used instead.
*/
@property (nonatomic, retain) UIColor *middleTextColor;

/**
* The text colour used for labels created for given right string items. If `nil`,
* textColor is used instead.
*/
@property (nonatomic, retain) UIColor *rightTextColor;

/** @name Text shadow colours */

/**
* The text shadow colour used for labels created for given string items.
*/
@property (nonatomic, retain) UIColor *textShadowColor;

/**
* The text shadow colour used for labels created for given middle string items. If
* `nil`, textShadowColor is used instead.
*/
@property (nonatomic, retain) UIColor *middleTextShadowColor;

/**
* The text shadow colour used for labels created for given right string items. If
* `nil`, textShadowColor is used instead.
*/
@property (nonatomic, retain) UIColor *rightTextShadowColor;

/** @name Text shadow offsets */

/**
* The text shadow offset used for labels created for left string items.
* Default is `{0, 1}`.
*/
@property (nonatomic, assign) CGSize leftTextShadowOffset;

/**
* The text shadow offset used for labels created for middle string items.
* Default is `{0, 1}`.
*/
@property (nonatomic, assign) CGSize middleTextShadowOffset;

/**
* The text shadow offset used for labels created for right string items.
* Default is `{0, 1}`.
*/
@property (nonatomic, assign) CGSize rightTextShadowOffset;

/** @name Label alignments */

/**
* The alignment used for layout of left items.
* Default is `NSTextAlignmentLeft`.
*/
@property (nonatomic, assign) NSTextAlignment leftItemsAlignment;

/**
* The alignment used for layout of middle items.
* Default is `NSTextAlignmentCenter`.
*/
@property (nonatomic, assign) NSTextAlignment middleItemsAlignment;

/**
* The alignment used for layout of right items.
* Default is `NSTextAlignmentRight`.
*/
@property (nonatomic, assign) NSTextAlignment rightItemsAlignment;

/** @name Line spacing */

/**
* The line spacing to use for multiline strings in leftItems.
*/
@property (nonatomic, assign) CGFloat leftLineSpacing;

/**
* The line spacing to use for multiline strings in middleItems.
*/
@property (nonatomic, assign) CGFloat middleLineSpacing;

/**
* The line spacing to use for multiline strings in rightItems.
*/
@property (nonatomic, assign) CGFloat rightLineSpacing;

/** @name Column widths */

@property (nonatomic, assign) CGFloat leftWidth;
@property (nonatomic, assign) CGFloat middleWidth;
@property (nonatomic, assign) CGFloat rightWidth;

/** @name Performance tuning */

/**
* Boolean to decide whether labels will have clear or opaque background colour,
* for _[questionable]_ performance benefit. If opaque, labels will be given a
* background to match the line's background. Default is `NO`, thus labels are
* created with `UIColor.clearColor` backgrounds.
*/
@property (nonatomic, assign) BOOL opaqueLabels;

// may be deprecated in future. use MGBox borders instead
@property (nonatomic, retain) CALayer *solidUnderline;

#pragma mark - Sizing

/** @name Sizing and padding */

/**
* If `YES`, the line will widen as needed, to accommodate all given items.
* Default is `NO`.
*/
@property (nonatomic, assign) BOOL widenAsNeeded;

/**
* Amount of padding to place to the left and right of each given item. If an item
* conforms to MGLayoutBox, then the item padding is in addition to the item's
* [leftMargin](-[MGLayoutBox leftMargin]) and
* [rightMargin](-[MGLayoutBox rightMargin]) values.
*/
@property (nonatomic, assign) CGFloat itemPadding;

/**
* The minimum line height to maintain when automatically resizing a line to
* accommodate content items and multiline text.
*
* If both minHeight and maxHeight are zero, the line's height is fixed,
* and will not automatically resize to accommodate content items or multiline
* text.
*/
@property (nonatomic, assign) CGFloat minHeight;

/**
The maximum line height to allow when automatically resizing a line to
accommodate content items and multiline text.

If both minHeight and maxHeight are zero, the line's height is fixed,
and will not automatically resize to accommodate content items or multiline
text.

A maxHeight of zero when minHeight is non-zero allows the line to increase in
height without restriction.

    MGLine *line = [MGLine lineWithLeft:@"a really long string\n" right:nil];
    line.minHeight = 40; // the line will be at least 40 high
    line.maxHeight = 0; // the line will grow as high as it needs to accommodate the string
*/
@property (nonatomic, assign) CGFloat maxHeight;

// this probably shouldn't be public. i wouldn't rely on it remaining so
- (UILabel *)makeLabel:(id)text placement:(MGItemPlacement)placement;

#pragma mark - Metrics getters

/** @name Metrics getters */

/**
* Returns the available space for left items, after taking line padding and space
* already consumed by middle and right items into account.
*/
- (CGFloat)leftSpace;

/**
* Returns the available space for middle items, after taking line padding and space
* already consumed by left and right items into account.
*/
- (CGFloat)middleSpace;

/**
* Returns the available space for right items, after taking line padding and space
* already consumed by left and middle items into account.
*/
- (CGFloat)rightSpace;

@end
