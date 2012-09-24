//
//  Created by matt on 24/08/12.
//

#import "MGBase.h"

@interface MGBlockWrapper : NSObject

@property (nonatomic, copy) Block block;

+ (MGBlockWrapper *)wrapperForBlock:(Block)block;
- (void)doit;

@end
