//
//  Created by matt on 7/11/12.
//

#import <CoreText/CoreText.h>

/**
`MGMushParser` is used by MGLine to provide lightweight `Mush` markup for
row text. It can also be used standalone to parse an `NSString` with `Mush`
markup into a resulting `NSAttributedString`.

- **Bold** is achieved with \*\*double asterisks\*\*
- _Italics_ are achieved with //double slashes//
- <u>Underlining</u> is achieved with \_\_double underscores\_\_
- `Monospacing` is achieved with \`single backticks\`
- Coloured text is achieved with {#123456|the coloured text}
*/

@interface MGMushParser : NSObject

@property (nonatomic, copy) NSString *mush;
@property (nonatomic, retain) UIFont *baseFont;
@property (nonatomic, retain) UIColor *baseColor;

/** @name Convenience NSString to NSAttributedString Static Method */

/**
* A convenience static method, to take an `NSString` and return an appropriately
* attributed `NSAttributedString`.
*
* @param markdown An `NSString` containing text marked up with `Mush`
* @param font The base font to use, from which bold and italic variants will be
* derived
* @param color The text colour to use for the resulting attributed string
*/
+ (NSAttributedString *)attributedStringFromMush:(NSString *)markdown
                                            font:(UIFont *)font
                                           color:(UIColor *)color;
- (void)parse;
- (void)strip;
- (NSAttributedString *)attributedString;

@end
