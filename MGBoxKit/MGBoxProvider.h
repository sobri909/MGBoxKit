//
//  Created by matt on 3/12/12.
//

@protocol MGLayoutBox;

typedef UIView <MGLayoutBox> *(^MGBoxMaker)();
typedef void (^MGBoxCustomiser)(id box, NSUInteger index);
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

+ (instancetype)provider;

- (void)reset;
- (void)updateVisibleIndexes;

- (void)removeBoxAtIndex:(NSUInteger)index;
- (UIView <MGLayoutBox> *)boxAtIndex:(NSUInteger)index;
- (NSUInteger)count;

// note: size, origin, rect include margins
- (CGSize)sizeForBoxAtIndex:(NSUInteger)index;
- (CGPoint)originForBoxAtIndex:(NSUInteger)index;
- (CGRect)frameForBoxAtIndex:(NSUInteger)index;

@end
