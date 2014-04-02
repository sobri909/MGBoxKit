//
//  Created by matt on 2/04/14.
//

#import "MGWeakHandler.h"

@implementation MGWeakHandler

+ (instancetype)handlerWithDict:(NSDictionary *)dict {
  MGWeakHandler *handler = [[self alloc] init];
  handler.dict = dict;
  return handler;
}

@end
