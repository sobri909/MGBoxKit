//
//  Created by matt on 2/04/14.
//

#import "MGObserver.h"

@implementation MGObserver

+ (MGObserver *)observerFor:(NSObject *)object keypath:(NSString *)keypath
    block:(Block)block {
  MGObserver *observer = [[MGObserver alloc] init];
  observer.block = block;
  [object addObserver:observer forKeyPath:keypath options:0 context:nil];
  return observer;
}

- (void)observeValueForKeyPath:(NSString *)keypath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context {
  if (self.block) {
    self.block();
  }
}

@end
