//
//  Created by matt on 17/06/12.
//

#import "MGBase.h"
#import "UIView+MGEasyFrame.h"

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

@protocol MGLayoutBox <NSObject>

// relationships
@property (nonatomic, retain) NSMutableOrderedSet *boxes;
@property (nonatomic, weak) UIView <MGLayoutBox> *parentBox;

// async drawing
@property (nonatomic, copy) Block asyncLayout;
@property (nonatomic, copy) Block asyncLayoutOnce;
@property (nonatomic, assign) dispatch_queue_t asyncQueue;

// self size and positioning
@property (nonatomic, assign) UIEdgeInsets margin;
@property (nonatomic, assign) CGFloat topMargin;
@property (nonatomic, assign) CGFloat bottomMargin;
@property (nonatomic, assign) CGFloat leftMargin;
@property (nonatomic, assign) CGFloat rightMargin;
@property (nonatomic, assign) MGBoxLayoutMode boxLayoutMode;
@property (nonatomic, assign) MGBoxResizingMode sizingMode;
@property (nonatomic, assign) CGPoint fixedPosition;
@property (nonatomic, weak) UIView *replacementFor;
@property (nonatomic, weak) UIView *attachedTo;
@property (nonatomic, assign) int zIndex;

// child positioning
@property (nonatomic, assign) UIEdgeInsets padding;
@property (nonatomic, assign) CGFloat topPadding;
@property (nonatomic, assign) CGFloat rightPadding;
@property (nonatomic, assign) CGFloat bottomPadding;
@property (nonatomic, assign) CGFloat leftPadding;
@property (nonatomic, assign) MGContentLayoutMode contentLayoutMode;

// layout
@property (nonatomic, assign) BOOL slideBoxesInFromEmpty;
@property (nonatomic, assign) BOOL layingOut;
- (void)layout;

@optional

// resizing
@property (nonatomic, assign) CGFloat maxWidth;

// tap
@property (nonatomic, retain) UITapGestureRecognizer *tapper;
@property (nonatomic, assign) BOOL tappable;
@property (nonatomic, copy) Block onTap;
- (void)tapped;

// swipe
@property (nonatomic, retain) UISwipeGestureRecognizer *swiper;
@property (nonatomic, assign) BOOL swipable;
@property (nonatomic, copy) Block onSwipe;
- (void)swiped;

// long press
@property (nonatomic, retain) UILongPressGestureRecognizer *longPresser;
@property (nonatomic, assign) BOOL longPressable;
@property (nonatomic, copy) Block onLongPress;
- (void)longPressed;

@end
