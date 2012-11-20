//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGBox.h"
#import "MGLayoutManager.h"
#import "UIColor+MGExpanded.h"

@implementation MGBox {
  BOOL fixedPositionEstablished;
  BOOL asyncDrawing, asyncDrawOnceing;
}

// MGLayoutBox protocol
@synthesize boxes, parentBox, boxLayoutMode, contentLayoutMode;
@synthesize asyncLayout, asyncLayoutOnce, asyncQueue;
@synthesize margin, topMargin, bottomMargin, leftMargin, rightMargin;
@synthesize padding, topPadding, rightPadding, bottomPadding, leftPadding;
@synthesize attachedTo, replacementFor, sizingMode;
@synthesize fixedPosition, zIndex, layingOut, slideBoxesInFromEmpty;

// MGLayoutBox protocol optionals
@synthesize tapper, tappable, onTap;
@synthesize swiper, swipable, onSwipe;
@synthesize longPresser, longPressable, onLongPress;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  [self setup];
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  [self setup];
  return self;
}

+ (id)box {
  MGBox *box = [[self alloc] initWithFrame:CGRectZero];
  return box;
}

+ (id)boxWithSize:(CGSize)size {
  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  MGBox *box = [[self alloc] initWithFrame:frame];
  return box;
}

- (void)setup {

  // defaults
  self.borderStyle = MGBorderNone;
  self.boxLayoutMode = MGBoxLayoutAutomatic;
  self.contentLayoutMode = MGLayoutTableStyle;
  self.sizingMode = MGResizingNone;
}

- (void)layout {
  [MGLayoutManager layoutBoxesIn:self];

  // async draws
  if (self.asyncLayout || self.asyncLayoutOnce) {
    dispatch_async(self.asyncQueue, ^{
      if (self.asyncLayout && !asyncDrawing) {
        asyncDrawing = YES;
        self.asyncLayout();
        asyncDrawing = NO;
      }
      if (self.asyncLayoutOnce && !asyncDrawOnceing) {
        asyncDrawOnceing = YES;
        self.asyncLayoutOnce();
        self.asyncLayoutOnce = nil;
        asyncDrawOnceing = NO;
      }
    });
  }
}

- (void)layoutWithSpeed:(NSTimeInterval)speed
             completion:(Block)completion {
  [MGLayoutManager layoutBoxesIn:self withSpeed:speed completion:completion];

  // async draws
  if (self.asyncLayout || self.asyncLayoutOnce) {
    dispatch_async(self.asyncQueue, ^{
      if (self.asyncLayout && !asyncDrawing) {
        asyncDrawing = YES;
        self.asyncLayout();
        asyncDrawing = NO;
      }
      if (self.asyncLayoutOnce && !asyncDrawOnceing) {
        asyncDrawOnceing = YES;
        self.asyncLayoutOnce();
        self.asyncLayoutOnce = nil;
        asyncDrawOnceing = NO;
      }
    });
  }
}

#pragma mark - Sugar

- (UIImage *)screenshot:(float)scale {
  CGRect frame = CGRectMake(0, 0, self.width + 40, self.height + 40);

  // UIImageView of self
  UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
  [[UIBezierPath bezierPathWithRoundedRect:self.bounds
      cornerRadius:self.layer.cornerRadius] addClip];
  [self.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
  UIGraphicsEndImageContext();

  // setup the shadow
  CGFloat cx = roundf(frame.size.width / 2), cy = roundf(frame.size.height / 2);
  cy = (int)self.height % 2 ? cy + 0.5 : cy; // avoid blur
  imageView.center = CGPointMake(cx, cy);
  imageView.layer.backgroundColor = UIColor.clearColor.CGColor;
  imageView.layer.borderColor = [UIColor colorWithWhite:0.65 alpha:0.7].CGColor;
  imageView.layer.borderWidth = 1;
  imageView.layer.cornerRadius = self.layer.cornerRadius;
  imageView.layer.shadowColor = UIColor.blackColor.CGColor;
  imageView.layer.shadowOffset = CGSizeZero;
  imageView.layer.shadowOpacity = 0.2;
  imageView.layer.shadowRadius = 10;

  // final UIImage
  UIView *canvas = [[UIView alloc] initWithFrame:frame];
  [canvas addSubview:imageView];
  UIGraphicsBeginImageContextWithOptions(frame.size, NO, scale);
  [canvas.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *final = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return final;
}

#pragma mark - Interaction

- (void)tapped {
  if (self.onTap) {
    self.onTap();
  }
}

- (void)swiped {
  if (self.onSwipe) {
    self.onSwipe();
  }
}

- (void)longPressed {
  if (self.onLongPress) {
    self.onLongPress();
  }
}

#pragma mark - Setters

- (void)setRasterize:(BOOL)should {
  _rasterize = should;
  if (should) {
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = UIScreen.mainScreen.scale;
  } else {
    self.layer.shouldRasterize = NO;
  }
}

- (void)setMargin:(UIEdgeInsets)_margin {
  self.topMargin = _margin.top;
  self.rightMargin = _margin.right;
  self.bottomMargin = _margin.bottom;
  self.leftMargin = _margin.left;
}

- (void)setPadding:(UIEdgeInsets)_padding {
  self.topPadding = _padding.top;
  self.rightPadding = _padding.right;
  self.bottomPadding = _padding.bottom;
  self.leftPadding = _padding.left;
}

- (void)setFixedPosition:(CGPoint)pos {
  self.boxLayoutMode = MGBoxLayoutFixedPosition;
  fixedPositionEstablished = YES;
  fixedPosition = pos;
}

- (void)setAttachedTo:(id)buddy {
  self.boxLayoutMode = MGBoxLayoutAttached;
  attachedTo = buddy;
}

- (void)setTappable:(BOOL)can {
  if (tappable == can) {
    return;
  }
  tappable = can;
  if (can) {
    [self addGestureRecognizer:self.tapper];
  } else if (self.tapper) {
    [self removeGestureRecognizer:self.tapper];
  }
}

- (void)setSwipable:(BOOL)can {
  if (swipable == can) {
    return;
  }
  swipable = can;
  if (can) {
    [self addGestureRecognizer:self.swiper];
  } else if (self.swiper) {
    [self removeGestureRecognizer:self.swiper];
  }
}

- (void)setLongPressable:(BOOL)can {
  if (longPressable == can) {
    return;
  }
  longPressable = can;
  if (can) {
    [self addGestureRecognizer:self.longPresser];
  } else if (self.longPresser) {
    [self removeGestureRecognizer:self.longPresser];
  }
}

- (void)setOnTap:(Block)_onTap {
  onTap = [_onTap copy];
  if (onTap) {
    self.tappable = YES;
  }
}

- (void)setOnSwipe:(Block)_onSwipe {
  onSwipe = [_onSwipe copy];
  if (onSwipe) {
    self.swipable = YES;
  }
}

- (void)setOnLongPress:(Block)_onLongPress {
  onLongPress = _onLongPress;
  if (onLongPress) {
    self.longPressable = YES;
  }
}

#pragma mark Border and background setters

- (void)setBackgroundColor:(UIColor *)color {
  super.backgroundColor = color;
  if (self.borderStyle) {
    self.borderStyle = self.borderStyle;
  }
}

- (void)setBorderStyle:(MGBorderStyle)style {
  _borderStyle = style;
  if (style == MGBorderNone) {
    self.borderColors = UIColor.clearColor;
    return;
  }
  self.topBorderColor = (style & MGBorderEtchedTop) == MGBorderEtchedTop
      ? [self.backgroundColor colorByAdding:0.16 alpha:-0.5]
      : UIColor.clearColor;
  self.bottomBorderColor = (style & MGBorderEtchedBottom) == MGBorderEtchedBottom
      ? [self.backgroundColor colorByAdding:-0.16 alpha:-0.5]
      : UIColor.clearColor;
  self.leftBorderColor = (style & MGBorderEtchedLeft) == MGBorderEtchedLeft
      ? [self.backgroundColor colorByAdding:0.16 alpha:-0.5]
      : UIColor.clearColor;
  self.rightBorderColor = (style & MGBorderEtchedRight) == MGBorderEtchedRight
      ? [self.backgroundColor colorByAdding:-0.16 alpha:-0.5]
      : UIColor.clearColor;
}

- (void)setBorderColors:(id)colors {
  if ([colors isKindOfClass:UIColor.class]) {
    self.topBorderColor = colors;
    self.bottomBorderColor = colors;
    self.leftBorderColor = colors;
    self.rightBorderColor = colors;
  } else if ([colors isKindOfClass:NSArray.class]) {
    self.topBorderColor = colors[0];
    self.leftBorderColor = colors[1];
    self.bottomBorderColor = colors[2];
    self.rightBorderColor = colors[3];
  }
}

- (void)setTopBorderColor:(UIColor *)color {
  _topBorderColor = color;
  if (color.alpha) {
    self.topBorder.backgroundColor = color;
    [self insertSubview:self.topBorder atIndex:0];
  } else {
    [self.topBorder removeFromSuperview];
    self.topBorder = nil;
  }
}

- (void)setBottomBorderColor:(UIColor *)color {
  _bottomBorderColor = color;
  if (color.alpha) {
    self.bottomBorder.backgroundColor = color;
    [self insertSubview:self.bottomBorder atIndex:0];
  } else {
    [self.bottomBorder removeFromSuperview];
    self.bottomBorder = nil;
  }
}

- (void)setLeftBorderColor:(UIColor *)color {
  _leftBorderColor = color;
  if (color.alpha) {
    self.leftBorder.backgroundColor = color;
    [self insertSubview:self.leftBorder atIndex:0];
  } else {
    [self.leftBorder removeFromSuperview];
    self.leftBorder = nil;
  }
}

- (void)setRightBorderColor:(UIColor *)color {
  _rightBorderColor = color;
  if (color.alpha) {
    self.rightBorder.backgroundColor = color;
    [self insertSubview:self.rightBorder atIndex:0];
  } else {
    [self.rightBorder removeFromSuperview];
    self.rightBorder = nil;
  }
}

#pragma mark - Getters

- (NSMutableOrderedSet *)boxes {
  if (!boxes) {
    boxes = NSMutableOrderedSet.orderedSet;
  }
  return boxes;
}

- (UIEdgeInsets)margin {
  return UIEdgeInsetsMake(self.topMargin, self.leftMargin, self.bottomMargin,
      self.rightMargin);
}

- (UIEdgeInsets)padding {
  return UIEdgeInsetsMake(self.topPadding, self.leftPadding, self.bottomPadding,
      self.rightPadding);
}

- (CGPoint)fixedPosition {
  if (!fixedPositionEstablished) {
    fixedPosition = self.frame.origin;
    fixedPositionEstablished = YES;
  }
  return fixedPosition;
}

- (dispatch_queue_t)asyncQueue {
  if (!asyncQueue) {
    asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  }
  return asyncQueue;
}

#pragma mark - Border getters

- (UIView *)topBorder {
  if (_topBorder) {
    return _topBorder;
  }

  CGRect frame = CGRectMake(0, 0, self.width, 1);
  _topBorder = [[UIView alloc] initWithFrame:frame];
  _topBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth
      | UIViewAutoresizingFlexibleBottomMargin;
  _topBorder.tag = -2;

  return _topBorder;
}

- (UIView *)bottomBorder {
  if (_bottomBorder) {
    return _bottomBorder;
  }

  CGRect frame = CGRectMake(0, self.height - 1, self.width, 1);
  _bottomBorder = [[UIView alloc] initWithFrame:frame];
  _bottomBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth
      | UIViewAutoresizingFlexibleTopMargin;
  _bottomBorder.tag = -2;

  return _bottomBorder;
}

- (UIView *)leftBorder {
  if (_leftBorder) {
    return _leftBorder;
  }

  CGRect frame = CGRectMake(0, 0, 1, self.height);
  _leftBorder = [[UIView alloc] initWithFrame:frame];
  _leftBorder.autoresizingMask = UIViewAutoresizingFlexibleHeight
      | UIViewAutoresizingFlexibleRightMargin;
  _leftBorder.tag = -2;

  return _leftBorder;
}

- (UIView *)rightBorder {
  if (_rightBorder) {
    return _rightBorder;
  }

  CGRect frame = CGRectMake(self.width - 1, 0, 1, self.height);
  _rightBorder = [[UIView alloc] initWithFrame:frame];
  _rightBorder.autoresizingMask = UIViewAutoresizingFlexibleHeight
      | UIViewAutoresizingFlexibleLeftMargin;
  _rightBorder.tag = -2;

  return _rightBorder;
}

#pragma mark - Gesture recognisers

- (UITapGestureRecognizer *)tapper {
  if (!tapper) {
    tapper = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(tapped)];
    tapper.delegate = self;
  }
  return tapper;
}

- (UISwipeGestureRecognizer *)swiper {
  if (!swiper) {
    swiper = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(swiped)];
    swiper.delegate = self;
  }
  return swiper;
}

- (UILongPressGestureRecognizer *)longPresser {
  if (!longPresser) {
    longPresser = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(longPressed)];
  }
  return longPresser;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recogniser
       shouldReceiveTouch:(UITouch *)touch {
  return ![touch.view isKindOfClass:UIControl.class];
}

@end
