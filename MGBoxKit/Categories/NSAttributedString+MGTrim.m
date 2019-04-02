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
    
  // If the string only contains characters in the given set, return (essentially) the empty string
  // http://stackoverflow.com/questions/1671605/how-to-check-if-a-string-only-contains-alphanumeric-characters-in-objective-c
  if ([[string stringByTrimmingCharactersInSet:set] isEqualToString:@""]) {
      return [self attributedSubstringFromRange:NSMakeRange(0, 0)];
  }
  // Else the string has at least one character that isn't in the set
  NSRange range = [string rangeOfCharacterFromSet:invertedSet];
  loc = (range.length > 0) ? (int)range.location : 0;

  range = [string rangeOfCharacterFromSet:invertedSet options:NSBackwardsSearch];
  len = (range.length > 0) ? (int)NSMaxRange(range) - loc : (int)string.length - loc;

  return [self attributedSubstringFromRange:NSMakeRange(loc, len)];
}

@end
