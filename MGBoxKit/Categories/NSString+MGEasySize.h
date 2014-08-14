//
//  NSString+MGEasySize.h
//  Pods
//
//  Created by James Van-As on 23/06/14.
//
//

#import <Foundation/Foundation.h>

@interface NSString (MGEasySize)

- (CGSize)easySizeWithFont:(UIFont *)font;
- (CGSize)easySizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size;

@end
