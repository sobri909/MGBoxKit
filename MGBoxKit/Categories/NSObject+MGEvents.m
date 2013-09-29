//
//  Created by matt on 24/09/12.
//

#import "NSObject+MGEvents.h"
#import <objc/runtime.h>

static char *MGObserversKey = "MGObserversKey";
static char *MGEventHandlersKey = "MGEventHandlersKey";
static char *MGDeallocActionKey = "MGDeallocActionKey";

@interface MGObserver : NSObject

@property (nonatomic, weak) NSObject *observee;
@property (nonatomic, copy) NSString *keypath;
@property (nonatomic, copy) Block block;

+ (MGObserver *)observerFor:(NSObject *)object keypath:(NSString *)keypath
                      block:(Block)block;

@end

@implementation MGObserver

+ (MGObserver *)observerFor:(NSObject *)object keypath:(NSString *)keypath
                      block:(Block)block {
  MGObserver *observer = [[MGObserver alloc] init];
  observer.observee = object;
  observer.keypath = keypath;
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

- (void)dealloc {
  [self.observee removeObserver:self forKeyPath:self.keypath];
}

@end


@interface MGDeallocAction : NSObject
@property (nonatomic, copy) Block block;
@end

@implementation MGDeallocAction
- (void)dealloc {
  if (_block)
    _block();
}
@end


@implementation NSObject (MGEvents)

#pragma mark - Custom events

- (void)on:(NSString *)eventName do:(Block)handler {
  [self on:eventName do:handler once:NO context:NO];
}

- (void)on:(NSString *)eventName doOnce:(Block)handler {
  [self on:eventName do:handler once:YES context:NO];
}

- (void)on:(NSString *)eventName doWithContext:(BlockWithContext)handler {
  [self on:eventName do:(Block)handler once:NO context:YES];
}

- (void)on:(NSString *)eventName do:(Block)handler once:(BOOL)once
   context:(BOOL)isContextBlock {

  // get all handlers for this event type
  NSMutableArray *handlers = self.MGEventHandlers[eventName];
  if (!handlers) {
    handlers = @[].mutableCopy;
    self.MGEventHandlers[eventName] = handlers;
  }

  if (isContextBlock) {
    [handlers addObject:@{@"blockWithContext" : [handler copy], @"once" : @(once)
    }];
  } else {
    [handlers addObject:@{@"block" : [handler copy], @"once" : @(once)}];
  }
}

- (void)trigger:(NSString *)eventName {
  [self trigger:eventName withContext:nil];
}

- (void)trigger:(NSString *)eventName withContext:(id)context {
  NSMutableArray *handlers = self.MGEventHandlers[eventName];
  for (NSDictionary *handler in handlers.copy) {
    if (handler[@"blockWithContext"]) {
      BlockWithContext block = handler[@"blockWithContext"];
      block(context);
    } else {
      Block block = handler[@"block"];
      block();
    }
    if ([handler[@"once"] boolValue]) {
      [handlers removeObject:handler];
    }
  }
}

#pragma mark - Property observing

- (void)onChangeOf:(NSString *)keypath do:(Block)block {

  // get observers for this keypath
  NSMutableArray *observers = self.MGObservers[keypath];
  if (!observers) {
    observers = @[].mutableCopy;
    self.MGObservers[keypath] = observers;

  }

  // make and store an observer
  MGObserver
      *observer = [MGObserver observerFor:self keypath:keypath block:block];
  [observers addObject:observer];
    
  MGDeallocAction *deallocAction = MGDeallocAction.new;
  __unsafe_unretained typeof(self) unsafeSelf = self;
  deallocAction.block = ^{
      //because we are observing ourself and the MGObserver weak reference gets nilled,
      //we need to force an obervation removal
      [unsafeSelf removeObserver:observer forKeyPath:observer.keypath];
      [observers removeObject:observer];
  };
  objc_setAssociatedObject(self, MGDeallocActionKey, deallocAction,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Getters

- (NSMutableDictionary *)MGEventHandlers {
  id handlers = objc_getAssociatedObject(self, MGEventHandlersKey);
  if (!handlers) {
    handlers = @{}.mutableCopy;
    self.MGEventHandlers = handlers;
  }
  return handlers;
}

- (NSMutableDictionary *)MGObservers {
  id observers = objc_getAssociatedObject(self, MGObserversKey);
  if (!observers) {
    observers = @{}.mutableCopy;
    self.MGObservers = observers;
  }
  return observers;
}

#pragma mark - Setters

- (void)setMGEventHandlers:(NSMutableDictionary *)handlers {
  objc_setAssociatedObject(self, MGEventHandlersKey, handlers,
      OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setMGObservers:(NSMutableDictionary *)observers {
  objc_setAssociatedObject(self, MGObserversKey, observers,
      OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
