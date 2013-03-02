//
// a fork of UIColor-Expanded, originally by Erica Sadun
// license is apparently BSD (original includes no stated license)
//

#define RGB(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define GREY(w,a) [UIColor colorWithWhite:w alpha:a]

#define SUPPORTS_UNDOCUMENTED_API 0

@interface UIColor (MGExpanded)

@property (nonatomic, readonly) CGColorSpaceModel colorSpaceModel;
@property (nonatomic, readonly) BOOL canProvideRGBComponents;

// Only valid if canProvideRGBComponents is YES
@property (nonatomic, readonly) CGFloat red;
@property (nonatomic, readonly) CGFloat green;
@property (nonatomic, readonly) CGFloat blue;

// Only valid if colorSpaceModel == kCGColorSpaceModelMonochrome
@property (nonatomic, readonly) CGFloat white;

@property (nonatomic, readonly) CGFloat alpha;
@property (nonatomic, readonly) CGFloat hue;
@property (nonatomic, readonly) CGFloat saturation;
@property (nonatomic, readonly) CGFloat brightness;
@property (nonatomic, readonly) UInt32 rgbHex;

- (NSString *)colorSpaceString;
- (NSArray *)arrayFromRGBAComponents;

- (BOOL)red:(CGFloat *)r green:(CGFloat *)g blue:(CGFloat *)b alpha:(CGFloat *)a;
- (BOOL)hue:(CGFloat *)h saturation:(CGFloat *)s brightness:(CGFloat *)b
      alpha:(CGFloat *)a;

- (UIColor *)colorByLuminanceMapping;
- (UIColor *)colorByMultiplyingByRed:(CGFloat)red green:(CGFloat)green
                                blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (UIColor *)colorByAddingRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue
                        alpha:(CGFloat)alpha;
- (UIColor *)colorByLighteningToRed:(CGFloat)red green:(CGFloat)green
                               blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (UIColor *)colorByDarkeningToRed:(CGFloat)red green:(CGFloat)green
                              blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (UIColor *)colorByAddingHue:(CGFloat)hue saturation:(CGFloat)saturation
                   brightness:(CGFloat)brightness alpha:(CGFloat)alpha;

- (UIColor *)colorByMultiplyingBy:(CGFloat)f;
- (UIColor *)colorByAdding:(CGFloat)f;
- (UIColor *)colorByAdding:(CGFloat)f alpha:(CGFloat)alpha;
- (UIColor *)colorByLighteningTo:(CGFloat)f;
- (UIColor *)colorByDarkeningTo:(CGFloat)f;
- (UIColor *)colorByMultiplyingByColor:(UIColor *)color;
- (UIColor *)colorByAddingColor:(UIColor *)color;
- (UIColor *)colorByLighteningToColor:(UIColor *)color;
- (UIColor *)colorByDarkeningToColor:(UIColor *)color;

- (NSString *)stringFromColor;
- (NSString *)hexStringFromColor;

+ (UIColor *)randomColor;
+ (UIColor *)semiRandomColor;
+ (UIColor *)colorWithString:(NSString *)stringToConvert;
+ (UIColor *)colorWithRGBHex:(UInt32)hex;
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert;
+ (UIColor *)colorWithName:(NSString *)cssColorName;

@end

#if SUPPORTS_UNDOCUMENTED_API
// Methods which rely on undocumented methods of UIColor+MGExpanded
@interface UIColor (Undocumented_Expanded)

- (NSString *)fetchStyleString;
- (UIColor *)rgbColor; // Via Poltras

@end
#endif // SUPPORTS_UNDOCUMENTED_API
