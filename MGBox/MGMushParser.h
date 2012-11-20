//
//  Created by matt on 7/11/12.
//

#import <CoreText/CoreText.h>

@interface MGMushParser : NSObject

@property (nonatomic, copy) NSString *mush;
@property (nonatomic, retain) UIFont *baseFont;
@property (nonatomic, retain) UIColor *baseColor;

+ (NSAttributedString *)attributedStringFromMush:(NSString *)markdown
                                            font:(UIFont *)font
                                           color:(UIColor *)color;
- (void)parse;
- (void)strip;
- (NSAttributedString *)attributedString;

@end
