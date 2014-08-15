//
//  Created by matt on 3/12/12.
//

@protocol MGLayoutBox;

typedef id (^MGBoxKeyMaker)(NSUInteger index);
typedef UIView <MGLayoutBox> *(^MGBoxMaker)(NSString *type);
typedef UIView <MGLayoutBox> *(^MGBoxCustomiser)(NSUInteger index);
typedef UIEdgeInsets(^MGBoxMarginMaker)(NSUInteger index);
typedef CGSize(^MGBoxSizeMaker)(NSUInteger index);
typedef NSUInteger(^MGCounter)();

typedef void (^MGBoxAnimator)(id box, NSUInteger index, NSTimeInterval duration,
      CGRect fromFrame, CGRect toFrame);

/**
Provides box reuse / offscreen culling, similar to `UITableView` cell reuse. Use a
box provider for tables and grids with dynamic content or a large number of items,
to reduce memory use and improve scrolling performance.

Box providers use the visible screen area to know which boxes should be added and
removed. As such, they can only be used on an [MGScrollView](MGScrollView).

    self.scroller = [MGScrollView scrollerWithSize:self.view.size];
    self.scroller.boxProvider = MGBoxProvider.provider;
*/

@interface MGBoxProvider : NSObject

#pragma mark - Initialisation

/** @name Initialisation */

/**
* Returns a new box provider instance.
*/
+ (instancetype)provider;

#pragma mark - Providing boxes and metadata

/** @name Providing boxes and metadata */

/**
Should return an <MGLayoutBox> (eg an `MGBox` or `MGLine`) correctly styled for
the given `type`. The box `type` value comes from a call to
[boxOfType:](-[MGBoxProvider boxOfType:]), typically from inside a <boxCustomiser>
block.

    boxProvider.boxMaker = ^(NSString *type) {
        if ([type isEqualToString:@"Header"]) {
            return [MGLine lineWithSize:(CGSize){320, 30}];
        } else { // normal row
            return [MGLine lineWithSize:(CGsize){320, 40}];
        }
    };
*/
@property (nonatomic, copy) MGBoxMaker boxMaker;

/**
Should return a unique key for the given index. Must conform to `NSCopying`, thus
will usually be an `NSString` or `NSNumber`.

    boxProvider.boxKeyMaker = ^id(NSUInteger index) {
        return [self.items[index] uniqueId];
    };
*/
@property (nonatomic, copy) MGBoxKeyMaker boxKeyMaker;

/**
Should return a `CGSize` for the box at the given index.

    boxProvider.boxSizeMaker = ^(NSUInteger index) {
        if (index == 0) { // header
            return (CGSize){320, 30};
        } else { // normal row
            return (CGSize){320, 40};
        }
    };
*/
@property (nonatomic, copy) MGBoxSizeMaker boxSizeMaker;

/**
Should return a `UIEdgeInsets` for the margins of the box at the given index. If no
`boxSizeMaker` is provided, the default value of `UIEdgeInsetsZero` will be used.

    boxProvider.boxMarginMaker = ^(NSUInteger index) {
        if (index == 0) { // header
            return UIEdgeInsetsMake(2, 0, 0, 0);
        } else if (index == self.items.count - 1) { // last row
            return UIEdgeInsetsMake(0, 0, 2, 0);
        } else { // normal row
            return UIEdgeInsetsZero;
        }
    };
*/
@property (nonatomic, copy) MGBoxMarginMaker boxMarginMaker;

/**
Should get a raw box with [boxOfType:](-[MGBoxProvider boxOfType:]), then
customise it appropriately according to the given index. Note that
[boxOfType:](-[MGBoxProvider boxOfType:]) may return either a completely new
box or a reused box from cache.

    boxProvider.boxCustomiser = ^(NSUInteger index) {
        if (index == 0) {
            MGLine *line = (id)[boxProvider boxOfType:@"Header"];
            line.leftItems = (id)@"Heading Title";
            return line;

        } else {
            MGLine *line = (id)[boxProvider boxOfType:@"NormalRow"];
            Item *item = self.items[index];
            line.leftItems = (id)item.title;
            line.onTap = ^{
                NSLog(@"tapped row %d", index);
            }
            return line;
        }
    };
*/
@property (nonatomic, copy) MGBoxCustomiser boxCustomiser;

/**
Should return the total number of items in the table or grid.

    boxProvider.counter = ^{
        return self.items.count;
    };
*/
@property (nonatomic, copy) MGCounter counter;

/**
* Will return a cached box of the given type if one is available. Otherwise will
* return a new box from <boxMaker>.
*/
- (UIView <MGLayoutBox> *)boxOfType:(NSString *)type;

#pragma mark - Visible indexes and boxes

/** @name Visible indexes and boxes */

/**
* Indexes of the currently visible boxes.
*/
@property (nonatomic, readonly) NSIndexSet *visibleIndexes;

/**
* A dictionary of the currently visible boxes, keyed by index numbers.
*/
@property (nonatomic, readonly) NSDictionary *visibleBoxes;

#pragma mark - Custom animations

/** @name Custom animations */

/**
An optional custom animation block for new boxes appearing on screen for the first
time. Note that this does not include boxes appearing on screen due to scrolling.

    boxProvider.appearAnimation = ^(MGBox *box, NSUInteger index,
          NSTimeInterval duration, CGRect fromFrame, CGRect toFrame) {
        box.alpha = 0;
        [UIView animateWithDuration:duration animations:^{
            box.alpha = 1;
        }];
    };
*/
@property (nonatomic, copy) MGBoxAnimator appearAnimation;

/**
An optional custom animation block for boxes disappearing due to being removed.
Note that this does not include boxes disappearing due to scrolling.

    boxProvider.disappearAnimation = ^(MGBox *box, NSUInteger index,
          NSTimeInterval duration, CGRect fromFrame, CGRect toFrame) {
        [UIView animateWithDuration:duration animations:^{
            box.alpha = 0;
        }];
    };
*/
@property (nonatomic, copy) MGBoxAnimator disappearAnimation;

/**
An optional custom animation block for boxes that have changed index position.
For example, the box previously at index 0 moves to index 1 when another
box is inserted before it.

    boxProvider.moveAnimation = ^(MGBox *box, NSUInteger index,
          NSTimeInterval duration, CGRect fromFrame, CGRect toFrame) {
        [UIView animateWithDuration:duration animations:^{
            box.frame = toFrame;
        }];
    };
*/
@property (nonatomic, copy) MGBoxAnimator moveAnimation;

#pragma mark - Relationships

/** @name Relationships */

/**
* A weak reference back to the scroller for which the provider is providing boxes.
*/
@property (nonatomic, weak) UIView <MGLayoutBox> *container;

#pragma mark - Ignore below here plz

/** @name Internal */

@property (nonatomic, assign) BOOL lockVisibleIndexes;

- (void)doAppearAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration;
- (void)doDisappearAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration;
- (void)doMoveAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration fromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame;

- (void)updateDataKeys;
- (void)updateBoxFrames;
- (void)updateVisibleIndexes;
- (void)updateVisibleBoxes:(NSMutableDictionary *)visibleBoxes
      boxToIndexMap:(NSMapTable *)boxToIndexMap;
- (void)updateOldDataKeys;
- (void)updateOldBoxFrames;

- (NSUInteger)count;

// data state checking
- (BOOL)dataAtIndexIsNew:(NSUInteger)index;
- (BOOL)dataAtIndexIsExisting:(NSUInteger)index;
- (BOOL)dataAtOldIndexIsOld:(NSUInteger)index;
- (NSUInteger)oldIndexOfDataAtIndex:(NSUInteger)index;

- (NSUInteger)indexOfBox:(UIView <MGLayoutBox> *)box;
- (NSUInteger)oldIndexOfBox:(UIView <MGLayoutBox> *)box;
- (BOOL)dataWasRemovedForBox:(UIView <MGLayoutBox> *)box;

// frames
- (CGSize)sizeForBoxAtIndex:(NSUInteger)index;
- (UIEdgeInsets)marginForBoxAtIndex:(NSUInteger)index;
- (CGRect)frameForBoxAtIndex:(NSUInteger)index;
- (CGRect)oldFrameForBoxAtIndex:(NSUInteger)index;

- (void)resetBoxCache;
- (void)reset;

@end
