//
//  Created by matt on 2/04/14.
//

@interface MGWeakHandler : NSObject

@property (nonatomic, weak) NSDictionary *dict;

+ (instancetype)handlerWithDict:(NSDictionary *)dict;

@end
