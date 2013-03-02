//
//  Created by matt on 14/06/12.
//

#import "MGLayoutBox.h"

@interface MGLayoutManager : NSObject

+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container;
+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container
            atIndexes:(NSIndexSet *)indexes;
+ (CGPoint)positionForBoxIn:(UIView <MGLayoutBox> *)container
                    atIndex:(NSUInteger)index;
+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container
            withSpeed:(NSTimeInterval)speed completion:(Block)completion;
+ (void)positionBoxesIn:(UIView <MGLayoutBox> *)container;
+ (void)positionAttachedBoxesIn:(UIView <MGLayoutBox> *)container;
+ (NSArray *)findBoxesInView:(UIView *)view notInSet:(id)boxes;
+ (NSSet *)findViewsInView:(UIView *)view notInSet:(id)boxes;
+ (void)stackByZIndexIn:(UIView *)container;

@end
