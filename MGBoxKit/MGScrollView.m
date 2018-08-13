//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGScrollView.h"
#import "MGLayoutManager.h"
#import "MGBoxProvider.h"
#import "UIView+MGEasyFrame.h"

// default keyboardMargin
#define KEYBOARD_MARGIN 8

@implementation MGScrollView {
    CGFloat keyboardNudge;
    BOOL fixedPositionEstablished;
    BOOL asyncDrawing, asyncDrawOnceing;
    CGRect keyboardFrame;
    CGRect _previousFrame;
    CGSize _previousContentSize;
    CGPoint _previousContentOffset;
    UIEdgeInsets _previousContentInset;
}

// MGLayoutBox protocol
@synthesize boxes, boxProvider, parentBox;
@synthesize boxLayoutMode, contentLayoutMode;
@synthesize asyncLayout, asyncLayoutOnce, asyncQueue;
@synthesize margin, topMargin, bottomMargin, leftMargin, rightMargin;
@synthesize padding, topPadding, rightPadding, bottomPadding, leftPadding;
@synthesize attachedTo, replacementFor, sizingMode, minWidth;
@synthesize fixedPosition, zIndex, layingOut, slideBoxesInFromEmpty;
@synthesize dontLayoutChildren;

// MGLayoutBox protocol optionals
@synthesize onAppear, onDisappear;
@synthesize tapper, tappable, onTap;

#pragma mark - Factories

+ (id)scroller {
  MGScrollView *scroller = [[self alloc] initWithFrame:CGRectZero];
  return scroller;
}

+ (id)scrollerWithSize:(CGSize)size {
  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  MGScrollView *scroller = [[self alloc] initWithFrame:frame];
  return scroller;
}

#pragma mark - Init and setup

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

- (void)setup {

  // defaults
  self.keyboardMargin = KEYBOARD_MARGIN;
  self.keepFirstResponderAboveKeyboard = YES;
    self.sizingMode = MGResizingShrinkWrap;

  self.delegate = self;

  // watch for the keyboard
  [NSNotificationCenter.defaultCenter addObserver:self
      selector:@selector(keyboardWillAppear:) name:UIKeyboardWillShowNotification
      object:nil];
  [NSNotificationCenter.defaultCenter addObserver:self
      selector:@selector(keyboardWillDisappear:)
      name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Layout

- (void)layout {
  [MGLayoutManager layoutBoxesIn:self];

  // async draws
  if (self.asyncLayout || self.asyncLayoutOnce) {
    dispatch_async(self.asyncQueue, ^{
        if (self.asyncLayout && !self->asyncDrawing) {
            self->asyncDrawing = YES;
            self.asyncLayout();
            self->asyncDrawing = NO;
        }
        if (self.asyncLayoutOnce && !self->asyncDrawOnceing) {
            self->asyncDrawOnceing = YES;
            self.asyncLayoutOnce();
            self.asyncLayoutOnce = nil;
            self->asyncDrawOnceing = NO;
        }
    });
  }
}

- (void)layoutWithDuration:(NSTimeInterval)duration completion:(MGBlock)completion {
    [MGLayoutManager layoutBoxesIn:self duration:duration completion:completion];
}

- (void)layoutSubviews {
  [super layoutSubviews];

  // deal with fixed position
  for (UIView <MGLayoutBox> *box in self.subviews) {
    if ([box conformsToProtocol:@protocol(MGLayoutBox)] && box.boxLayoutMode
        == MGBoxLayoutFixedPosition) {
      box.y = box.fixedPosition.y + self.contentOffset.y;
    }
  }
}

- (void)appeared {
    if (self.onAppear) {
        self.onAppear();
    }
}

- (void)disappeared {
    if (self.onDisappear) {
        self.onDisappear();
    }
}

#pragma mark - Interaction

- (void)tapped {
  if (self.onTap) {
    self.onTap();
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recogniser
       shouldReceiveTouch:(UITouch *)touch {

  // say yes to UIScrollView's internal recognisers
  if (recogniser == self.panGestureRecognizer || recogniser
      == self.gestureRecognizers[0]) {
    return YES;
  }

  // say no if a UIControl got there first (iOS 6 makes this unnecessary)
  return ![touch.view isKindOfClass:UIControl.class];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.allowTouchesToPassThrough) {
        for (UIView *view in self.subviews) {
            if (CGRectContainsPoint(view.frame, point)) {
                return [super pointInside:point withEvent:event];
            }
        }
        return NO;
    } else {
        return [super pointInside:point withEvent:event];
    }
}

#pragma mark - Scrolling

- (void)scrollToView:(UIView *)view withMargin:(CGFloat)_margin {
  CGRect frame = [self convertRect:view.frame fromView:view.superview];
  [self scrollRectToVisible:CGRectInset(frame, -_margin, -_margin) animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.boxProvider) {
        [self.boxProvider updateVisibleIndexes];
        [MGLayoutManager layoutVisibleBoxesIn:self duration:0 completion:nil];

        // Apple bug workaround
        if (self.showsVerticalScrollIndicator) {
            self.showsVerticalScrollIndicator = NO;
            self.showsVerticalScrollIndicator = YES;
        }
    }
}

#pragma mark - Edge snapping

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if (self.snapToBoxEdges) {
    [self snapToNearestBox];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
  if (self.snapToBoxEdges && !decelerate) {
    [self snapToNearestBox];
  }
}

- (void)snapToNearestBox {
  if (self.contentSize.height <= self.frame.size.height) {
    return;
  }
  if ([self.boxes count] < 2) {
    return;
  }

  CGSize size = self.frame.size;
  CGPoint offset = self.contentOffset;
  CGFloat fromBottom = self.contentSize.height - (offset.y + size.height);
  CGFloat fromTop = offset.y;
  CGFloat newY = 0;

  // near the bottom? then snap to
  UIView *last = [self.boxes lastObject];
  if (fromBottom < last.frame.size.height / 2 && fromBottom < fromTop) {
    newY = self.contentSize.height - size.height;
  } else { // find nearest box
    CGFloat oldY = offset.y;
    CGFloat diff = self.contentSize.height;
    for (UIView *box in self.boxes) {
      if (ABS(box.frame.origin.y - self.bottomPadding - oldY) < diff) {
        diff = ABS(box.frame.origin.y - oldY);
        newY = box.frame.origin.y - self.bottomPadding;
      }
    }
  }

  [UIView animateWithDuration:0.1 animations:^{
    self.contentOffset = CGPointMake(0, newY);
  }];
}

#pragma mark - Dealing with the keyboard

- (void)keyboardWillAppear:(NSNotification *)note {
    if (!self.keepFirstResponderAboveKeyboard) {
        return;
    }

    UIView *view;

    UIResponder *first = self.currentFirstResponder;
    if ([first isKindOfClass:UIView.class] && [(id)first isDescendantOfView:self]) {
        view = (id)first;
    } else {
        return;
    }

  // target rect in local space
  CGRect target = [view.superview convertRect:view.frame toView:nil];

  // keyboard's frame
  if (note) {
    keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  }

  // determine overage
  CGFloat targetBottom = target.origin.y + target.size.height;
  CGFloat over = targetBottom + self.keyboardMargin - keyboardFrame.origin.y;

  // need to nudge?
  keyboardNudge = over > 0 ? over : 0;
  if (keyboardNudge <= 0) {
    return;
  }

  // animate the scroll
  double d = note
      ? [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
      : 0.1;
  int curve = note
      ? [note.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]
      : UIViewAnimationCurveEaseInOut;
  [UIView animateWithDuration:d delay:0 options:curve animations:^{
    CGPoint offset = self.contentOffset;
    offset.y += over;
    self.contentOffset = offset;
  } completion:nil];
}

- (void)keyboardWillDisappear:(NSNotification *)note {

  if (!self.keepFirstResponderAboveKeyboard) {
      return;
  }

  double d = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  int curve = [note.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
  [UIView animateWithDuration:d delay:0 options:curve animations:^{
    CGPoint offset = self.contentOffset;
    offset.y -= self->keyboardNudge;
    self.contentOffset = offset;
    self->keyboardNudge = 0;
  } completion:nil];
}

#pragma mark - Scroll Offset Handling

- (void)restoreScrollOffset {
    
    [self.boxProvider resetBoxCache];
    [self.boxProvider updateDataKeys];
    [self.boxProvider updateBoxFrames];
    self.boxProvider.lockVisibleIndexes = YES;
    [MGLayoutManager updateContentSizeFor:self];
    self.boxProvider.lockVisibleIndexes = NO;

    CGSize sizeMinusInsets = CGSizeMake(_previousFrame.size.width -
                                        _previousContentInset.right -
                                        _previousContentInset.left,
                                        _previousFrame.size.height -
                                        _previousContentInset.top -
                                        _previousContentInset.bottom);

    CGPoint maxOffset = CGPointMake(MAX(sizeMinusInsets.width, _previousContentSize.width) - sizeMinusInsets.width,
                                    MAX(sizeMinusInsets.height, _previousContentSize.height) - sizeMinusInsets.height);

    CGPoint scrollRange = CGPointMake(maxOffset.x, maxOffset.y);
    CGPoint scrollRatio = CGPointMake(scrollRange.x > 0 ? (_previousContentOffset.x + _previousContentInset.left) / scrollRange.x : 0,
                                      scrollRange.y > 0 ? (_previousContentOffset.y + _previousContentInset.top) / scrollRange.y : 0);

    sizeMinusInsets = CGSizeMake(self.frame.size.width -
                                 self.contentInset.right -
                                 self.contentInset.left,
                                 self.frame.size.height -
                                 self.contentInset.top -
                                 self.contentInset.bottom);

    maxOffset = CGPointMake(MAX(sizeMinusInsets.width, self.contentSize.width) - sizeMinusInsets.width,
                            MAX(sizeMinusInsets.height, self.contentSize.height) - sizeMinusInsets.height);

    CGPoint newOffset = (CGPoint){
        -self.contentInset.left + scrollRatio.x * maxOffset.x,
        -self.contentInset.top + scrollRatio.y * maxOffset.y
    };


    if (CGPointEqualToPoint(newOffset, self.contentOffset)) {
        [self scrollViewDidScroll:self];
    } else {
        self.contentOffset = newOffset;
    }

    [self.boxProvider updateOldBoxFrames];
    [self.boxProvider updateOldDataKeys];
}

- (void)saveScrollOffset {
    _previousFrame = self.frame;
    _previousContentOffset = self.contentOffset;
    _previousContentSize = self.contentSize;
    _previousContentInset = self.contentInset;
}

#pragma mark - Setters

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

- (void)setOnTap:(MGBlock)_onTap {
  onTap = [_onTap copy];
  if (onTap) {
    self.tappable = YES;
  }
}

- (void)setBoxProvider:(MGBoxProvider *)provider {
  boxProvider = provider;
  provider.container = self;
}

#pragma mark - Getters

- (NSMutableArray *)boxes {
  if (!boxes) {
    boxes = @[].mutableCopy;
  }
  return boxes;
}

- (CGRect)bufferedViewport {
    UIEdgeInsets buffer = UIEdgeInsetsMake(-self.viewportMargin.height,
          -self.viewportMargin.width, -self.viewportMargin.height, -self.viewportMargin.width);
    CGRect frame = (CGRect){CGPointZero, self.size};
    return CGRectOffset(UIEdgeInsetsInsetRect(frame, buffer), self.contentOffset.x,
          self.contentOffset.y);
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

- (UITapGestureRecognizer *)tapper {
  if (!tapper) {
    tapper = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(tapped)];
    tapper.delegate = self;
  }
  return tapper;
}

#pragma mark - Fini

- (void)dealloc {
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
