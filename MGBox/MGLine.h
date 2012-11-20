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

typedef enum { MGLeft, MGMiddle, MGRight } MGItemPlacement;

@interface MGLine : MGBox

#pragma mark - Mixed items

@property (nonatomic, retain) NSMutableArray *leftItems;
@property (nonatomic, retain) NSMutableArray *middleItems;
@property (nonatomic, retain) NSMutableArray *rightItems;

#pragma mark - Multiline string items

@property (nonatomic, copy) NSString *multilineLeft;
@property (nonatomic, copy) NSString *multilineMiddle;
@property (nonatomic, copy) NSString *multilineRight;

#pragma mark - Styling

// may be deprecated in future. use MGBox borders instead
@property (nonatomic, assign) MGUnderlineType underlineType;

// which content items are laid out first (thus get use of the full line width)
@property (nonatomic, assign) MGSidePrecedence sidePrecedence;

// label styling
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) UIFont *middleFont;
@property (nonatomic, retain) UIFont *rightFont;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *middleTextColor;
@property (nonatomic, retain) UIColor *rightTextColor;
@property (nonatomic, retain) UIColor *textShadowColor;
@property (nonatomic, retain) UIColor *middleTextShadowColor;
@property (nonatomic, retain) UIColor *rightTextShadowColor;
@property (nonatomic, assign) CGSize leftTextShadowOffset;
@property (nonatomic, assign) CGSize middleTextShadowOffset;
@property (nonatomic, assign) CGSize rightTextShadowOffset;
@property (nonatomic, assign) NSTextAlignment leftItemsTextAlignment;
@property (nonatomic, assign) NSTextAlignment middleItemsTextAlignment;
@property (nonatomic, assign) NSTextAlignment rightItemsTextAlignment;

// may be deprecated in future. use MGBox borders instead
@property (nonatomic, retain) CALayer *solidUnderline;

#pragma mark - Sizing

@property (nonatomic, assign) BOOL widenAsNeeded;
@property (nonatomic, assign) CGFloat itemPadding;
@property (nonatomic, assign) CGFloat minHeight;
@property (nonatomic, assign) CGFloat maxHeight;

#pragma mark - Factories

+ (id)line;
+ (id)lineWithSize:(CGSize)size;
+ (id)lineWithLeft:(NSObject *)left right:(NSObject *)right;
+ (id)lineWithLeft:(NSObject *)left right:(NSObject *)right size:(CGSize)size;

+ (id)lineWithMultilineLeft:(NSString *)left right:(id)right width:(CGFloat)width
                  minHeight:(CGFloat)height;
+ (id)lineWithLeft:(id)left multilineRight:(NSString *)right width:(CGFloat)width
         minHeight:(CGFloat)height;

+ (id)multilineWithText:(NSString *)text font:(UIFont *)font width:(CGFloat)width
                padding:(UIEdgeInsets)padding;

#pragma mark - Getters

- (NSSet *)allItems;
- (UILabel *)makeLabel:(id)text placement:(MGItemPlacement)placement;

@end
