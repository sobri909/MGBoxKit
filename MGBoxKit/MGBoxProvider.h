//
//  Created by matt on 3/12/12.
//

@protocol MGLayoutBox;

typedef UIView <MGLayoutBox> *(^MGBoxMaker)();
typedef void (^MGBoxCustomiser)(id box, NSUInteger index);
typedef void (^MGBoxAnimator)(id box, NSUInteger index, NSTimeInterval duration,
      CGRect fromFrame, CGRect toFrame);
typedef CGSize(^MGBoxSizer)(NSUInteger index);
typedef NSUInteger(^MGCounter)();

/**
* Provides box reuse / offscreen culling, conceptually similar to `UITableView`
* cell reuse.
*/

@interface MGBoxProvider : NSObject

@property (nonatomic, weak) UIView <MGLayoutBox> *container;
@property (nonatomic, readonly) NSIndexSet *visibleIndexes;
@property (nonatomic, readonly) NSMutableArray *boxPositions;

@property (nonatomic, copy) MGBoxMaker boxMaker;
@property (nonatomic, copy) MGBoxCustomiser boxCustomiser;
@property (nonatomic, copy) MGBoxSizer boxSizer;
@property (nonatomic, copy) MGCounter counter;

@property (nonatomic, copy) MGBoxAnimator appearAnimation;
@property (nonatomic, copy) MGBoxAnimator disappearAnimation;
@property (nonatomic, copy) MGBoxAnimator moveAnimation;

+ (instancetype)provider;

- (void)reset;
- (void)updateVisibleIndexes;

- (void)removeBox:(UIView <MGLayoutBox> *)box;
- (UIView <MGLayoutBox> *)boxAtIndex:(NSUInteger)index;
- (NSUInteger)count;

// animations
- (void)doAppearAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration;
- (void)doDisappearAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration;
- (void)doMoveAnimationFor:(UIView <MGLayoutBox> *)box atIndex:(NSUInteger)index
      duration:(NSTimeInterval)duration fromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame;

// note: size, origin, rect include margins
- (CGSize)sizeForBoxAtIndex:(NSUInteger)index;
- (CGPoint)originForBoxAtIndex:(NSUInteger)index;
- (CGRect)footprintForBoxAtIndex:(NSUInteger)index;
- (CGRect)frameForBox:(UIView <MGLayoutBox> *)box;

@end
