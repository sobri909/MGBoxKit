//
//  Created by matt on 9/11/12.
//

/**
* Provides a convenience method similar to
* `-[NSString stringByTrimmingCharactersInSet:]` to trim specified characters from
* the beginning and end of attributed strings.
*/

@interface NSAttributedString (MGTrim)

/**
Similar to `-[NSString stringByTrimmingCharactersInSet:]`, call this method
on an attributed string, providing a set of characters you would like removed.

    NSCharacterSet *whitespace = NSCharacterSet.whitespaceAndNewlineCharacterSet;

    id trimmedString;
    if ([string isKindOfClass:NSAttributedString.class]) {
      trimmedString = [string attributedStringByTrimming:whitespace];
    } else {
      trimmedString = [string stringByTrimmingCharactersInSet:whitespace];
    }
*/
- (NSAttributedString *)attributedStringByTrimming:(NSCharacterSet *)set;

@end
