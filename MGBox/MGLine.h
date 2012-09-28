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

@property (nonatomic, retain) NSMutableArray *leftItems;
@property (nonatomic, retain) NSMutableArray *middleItems;
@property (nonatomic, retain) NSMutableArray *rightItems;
@property (nonatomic, assign) MGUnderlineType underlineType;
@property (nonatomic, assign) MGSidePrecedence sidePrecedence;
@property (nonatomic, assign) BOOL widenAsNeeded;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) UIFont *rightFont;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *textShadowColor;
@property (nonatomic, retain) CALayer *solidUnderline;
@property (nonatomic, assign) CGFloat itemPadding;

+ (id)line;
+ (id)lineWithSize:(CGSize)size;
+ (id)lineWithLeft:(NSObject *)left right:(NSObject *)right;
+ (id)lineWithLeft:(NSObject *)left right:(NSObject *)right
             size:(CGSize)size;
+ (id)multilineWithText:(NSString *)text font:(UIFont *)font width:(CGFloat)width
                padding:(UIEdgeInsets)padding;

- (NSSet *)allItems;
- (UILabel *)makeLabel:(NSString *)text align:(UITextAlignment)align;

@end
