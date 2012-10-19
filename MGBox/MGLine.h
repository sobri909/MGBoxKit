//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGBox.h"

typedef enum {
  MGUnderlineNone, MGUnderlineTop, MGUnderlineBottom
} MGUnderlineType;

typedef enum {
  MGSidePrecedenceLeft, MGSidePrecedenceRight, MGSidePrecedenceMiddle
} MGSidePrecedence;

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

@property (nonatomic, assign) MGUnderlineType underlineType;
@property (nonatomic, assign) MGSidePrecedence sidePrecedence;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) UIFont *middleFont;
@property (nonatomic, retain) UIFont *rightFont;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *textShadowColor;
@property (nonatomic, assign) NSTextAlignment leftItemsTextAlignment;
@property (nonatomic, assign) NSTextAlignment middleItemsTextAlignment;
@property (nonatomic, assign) NSTextAlignment rightItemsTextAlignment;

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
- (UILabel *)makeLabel:(NSString *)text
                 align:(UITextAlignment)align __attribute__((deprecated));
- (UILabel *)makeLabel:(NSString *)text align:(UITextAlignment)align
                  font:(UIFont *)font;

@end
