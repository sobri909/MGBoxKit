//
//  Created by matt on 3/12/12.
//

@protocol MGLayoutBox;

typedef UIView <MGLayoutBox> *(^MGBoxMaker)(NSUInteger index);
typedef CGSize(^MGBoxSizer)(NSUInteger index);
typedef NSUInteger(^MGCounter)();

/**
* A work-in-progress implementation of box caching/reuse, conceptually similar to
* `UITableView` cell reuse.
*/

@interface MGBoxProvider : NSObject

@property (nonatomic, weak) UIView <MGLayoutBox> *container;
@property (nonatomic, readonly) NSIndexSet *visibleIndexes;

@property (nonatomic, copy) MGBoxMaker boxMaker;
@property (nonatomic, copy) MGBoxSizer boxSizer;
@property (nonatomic, copy) MGCounter counter;

+ (MGBoxProvider *)provider;

- (void)reset;
- (void)updateVisibleIndexes;

- (UIView <MGLayoutBox> *)boxAtIndex:(NSUInteger)index;
- (CGSize)sizeForBoxAtIndex:(NSUInteger)index;
- (NSUInteger)count;



@end
