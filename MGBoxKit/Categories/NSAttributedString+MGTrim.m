//
//  Created by matt on 9/11/12.
//
// taken from:
// http://www.cocoabuilder.com/archive/cocoa/168226-nsattributedstring-attributedstringbytrimming.html
//

#import "NSAttributedString+MGTrim.h"

@implementation NSAttributedString (MGTrim)

- (NSAttributedString *)attributedStringByTrimming:(NSCharacterSet *)set {
  NSCharacterSet *invertedSet = set.invertedSet;
  NSString *string = self.string;
  unsigned int loc, len;

  NSRange range = [string rangeOfCharacterFromSet:invertedSet];
  loc = (range.length > 0) ? (int)range.location : 0;

  range = [string rangeOfCharacterFromSet:invertedSet options:NSBackwardsSearch];
  len = (range.length > 0) ? (int)NSMaxRange(range) - loc : (int)string.length - loc;

  return [self attributedSubstringFromRange:NSMakeRange(loc, len)];
}

@end
