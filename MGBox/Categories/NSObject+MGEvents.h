//
//  Created by matt on 24/09/12.
//

#import "MGBase.h"

@interface NSObject (MGEvents)

// event handling
@property (nonatomic, retain) NSMutableDictionary *MGEventHandlers;

- (void)on:(NSString *)eventName do:(Block)handler;
- (void)on:(NSString *)eventName doOnce:(Block)handler;
- (void)trigger:(NSString *)eventName;

// observing
@property (nonatomic, retain) NSMutableDictionary *MGObservers;

- (void)onChangeOf:(NSString *)keypath do:(Block)block;


@end
