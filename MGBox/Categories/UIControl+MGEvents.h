//
//  Created by matt on 19/10/12.
//

#import "MGBase.h"

@interface UIControl (MGEvents)

@property (nonatomic, retain) NSMutableDictionary *MGEventHandlers;

- (void)onControlEvent:(UIControlEvents)controlEvent do:(Block)handler;
- (void)removeHandlersForControlEvent:(UIControlEvents)controlEvent;

@end
