//
//  Created by matt on 24/08/12.
//

typedef void(^Block)();
typedef void(^BlockWithContext)(id context);

@interface MGBlockWrapper : NSObject

@property (nonatomic, copy) Block block;

+ (MGBlockWrapper *)wrapperForBlock:(Block)block;
- (void)doit;

@end
