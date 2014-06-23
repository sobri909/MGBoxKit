//
//  NSString+MGEasySize.m
//  Pods
//
//  Created by James Van-As on 23/06/14.
//
//

#import "NSString+MGEasySize.h"

@implementation NSString (MGEasySize)

- (CGSize)easySizeWithFont:(UIFont *)font {
    CGSize size = [self sizeWithAttributes:@{NSFontAttributeName:font}];
    return CGSizeMake(ceil(size.width), ceil(size.height));
}

- (CGSize)easySizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size {
    CGSize retSize = [self boundingRectWithSize:size
                                        options:NSStringDrawingUsesLineFragmentOrigin
                      | NSStringDrawingUsesFontLeading
                                     attributes:@{NSFontAttributeName:font}
                                        context:nil].size;
    return CGSizeMake(ceil(retSize.width),
                      ceil(retSize.height));
}

@end
