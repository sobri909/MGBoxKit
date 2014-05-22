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
* Provides box reuse / offscreen culling, conceptually similar to `UITableView`
* cell reuse.
*/

@interface MGBoxProvider : NSObject

@property (nonatomic, weak) UIView <MGLayoutBox> *container;
@property (nonatomic, readonly) NSIndexSet *visibleIndexes;
@property (nonatomic, readonly) NSDictionary *visibleBoxes;

@property (nonatomic, copy) MGBoxMaker boxMaker;
@property (nonatomic, copy) MGBoxKeyMaker boxKeyMaker;
@property (nonatomic, copy) MGBoxSizeMaker boxSizeMaker;
@property (nonatomic, copy) MGBoxMarginMaker boxMarginMaker;
@property (nonatomic, copy) MGBoxCustomiser boxCustomiser;
@property (nonatomic, copy) MGCounter counter;

@property (nonatomic, copy) MGBoxAnimator appearAnimation;
@property (nonatomic, copy) MGBoxAnimator disappearAnimation;
@property (nonatomic, copy) MGBoxAnimator moveAnimation;

+ (instancetype)provider;

- (void)updateDataKeys;
- (void)updateBoxFrames;
- (void)updateVisibleIndexes;
- (void)updateVisibleBoxes:(NSMutableDictionary *)visibleBoxes
             boxToIndexMap:(NSMapTable *)boxToIndexMap;
- (void)updateOldDataKeys;
- (void)updateOldBoxFrames;

- (NSUInteger)count;

// animations
- (void)doAppearAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration;
- (void)doDisappearAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration;
- (void)doMoveAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration fromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame;

// data state checking
- (BOOL)dataAtIndexIsNew:(NSUInteger)index;
- (BOOL)dataAtIndexIsExisting:(NSUInteger)index;
- (BOOL)dataAtOldIndexIsOld:(NSUInteger)index;
- (NSUInteger)oldIndexOfDataAtIndex:(NSUInteger)index;

- (NSUInteger)indexOfBox:(UIView <MGLayoutBox> *)box;
- (NSUInteger)oldIndexOfBox:(UIView <MGLayoutBox> *)box;
- (BOOL)dataWasRemovedForBox:(UIView <MGLayoutBox> *)box;

- (UIView <MGLayoutBox> *)boxOfType:(NSString *)type;

// frames
- (CGSize)sizeForBoxAtIndex:(NSUInteger)index;
- (UIEdgeInsets)marginForBoxAtIndex:(NSUInteger)index;
- (CGRect)frameForBoxAtIndex:(NSUInteger)index;
- (CGRect)oldFrameForBoxAtIndex:(NSUInteger)index;

- (void)resetBoxCache;
- (void)reset;

@end
