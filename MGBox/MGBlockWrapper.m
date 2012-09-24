//
//  Created by matt on 24/08/12.
//

#import "MGBlockWrapper.h"

@implementation MGBlockWrapper

+ (MGBlockWrapper *)wrapperForBlock:(Block)block {
  MGBlockWrapper *wrapper = [[MGBlockWrapper alloc] init];
  wrapper.block = block;
  return wrapper;
}

- (void)doit {
  if (self.block) {
    self.block();
  }
}

@end
