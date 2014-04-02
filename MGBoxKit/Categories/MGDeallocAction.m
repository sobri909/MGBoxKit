//
//  Created by matt on 2/04/14.
//

#import "MGDeallocAction.h"

@implementation MGDeallocAction

- (void)dealloc {
  if (self.block) {
    self.block();
  }
}

@end
