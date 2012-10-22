//
//  Created by matt on 19/10/12.
//

#import "UIControl+MGEvents.h"
#import <objc/runtime.h>

static char *MGEventHandlersKey;

@implementation UIControl (MGEvents)

- (void)onControlEvent:(UIControlEvents)controlEvent do:(Block)handler {

  // get all handlers for this control event
  NSMutableArray *handlers = self.MGEventHandlers[@((int)controlEvent)];
  if (!handlers) {
    handlers = @[].mutableCopy;
    self.MGEventHandlers[@((int)controlEvent)] = handlers;
  }

  // add the handler
  MGBlockWrapper *wrapper = [MGBlockWrapper wrapperForBlock:handler];
  [self addTarget:wrapper action:@selector(doit) forControlEvents:controlEvent];
  [handlers addObject:wrapper];
}

- (void)removeHandlersForControlEvent:(UIControlEvents)controlEvent {

  // get all handlers for this control event
  NSMutableArray *handlers = self.MGEventHandlers[@((int)controlEvent)];

  // remove them
  for (MGBlockWrapper *wrapper in handlers) {
    [self removeTarget:wrapper action:NULL forControlEvents:controlEvent];
  }

  // and now release the blocks
  handlers = @[].mutableCopy;
  self.MGEventHandlers[@((int)controlEvent)] = handlers;
}

#pragma mark - Getters and setters

- (NSMutableDictionary *)MGEventHandlers {
  id handlers = objc_getAssociatedObject(self, MGEventHandlersKey);
  if (!handlers) {
    handlers = @{ }.mutableCopy;
    self.MGEventHandlers = handlers;
  }
  return handlers;
}

- (void)setMGEventHandlers:(NSMutableDictionary *)handlers {
  objc_setAssociatedObject(self, MGEventHandlersKey, handlers,
      OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
