//
//  Created by matt on 14/06/12.
//

#import "MGLayoutBox.h"

@interface MGLayoutManager : NSObject

+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container;
+ (void)layoutBoxesIn:(UIView <MGLayoutBox> *)container duration:(NSTimeInterval)duration
      completion:(Block)completion;
+ (void)layoutVisibleBoxesIn:(UIView <MGLayoutBox> *)container
      duration:(NSTimeInterval)duration completion:(Block)completion;
+ (NSOrderedSet *)framesForBoxesIn:(UIView <MGLayoutBox> *)container;
+ (void)positionBoxesIn:(UIView <MGLayoutBox> *)container;
+ (void)positionAttachedBoxesIn:(UIView <MGLayoutBox> *)container;
+ (NSArray *)findBoxesInView:(UIView *)view notInSet:(id)boxes;
+ (NSSet *)findViewsInView:(UIView *)view notInSet:(id)boxes;
+ (void)updateContentSizeFor:(UIView <MGLayoutBox> *)container;
+ (void)stackByZIndexIn:(UIView *)container;

@end
