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

@interface MGBox : UIView <MGLayoutBox, UIGestureRecognizerDelegate>

// init methods
+ (id)box;
+ (id)boxWithSize:(CGSize)size;
- (void)setup;

// layout
- (void)layoutWithSpeed:(NSTimeInterval)speed
             completion:(Block)completion;

// performance
@property (nonatomic, assign) BOOL rasterize;

// borders
@property (nonatomic, assign) MGBorderStyle borderStyle;
@property (nonatomic, retain) UIColor *topBorderColor;
@property (nonatomic, retain) UIColor *bottomBorderColor;
@property (nonatomic, retain) UIColor *leftBorderColor;
@property (nonatomic, retain) UIColor *rightBorderColor;
@property (nonatomic, retain) UIView *topBorder;
@property (nonatomic, retain) UIView *bottomBorder;
@property (nonatomic, retain) UIView *leftBorder;
@property (nonatomic, retain) UIView *rightBorder;

- (void)setBorderColors:(id)colors;

// sugar
- (UIImage *)screenshot:(float)scale;

@end
