//
// Created by matt on 7/11/12.
//

#import "MGMushParser.h"

@implementation MGMushParser {
  NSMutableAttributedString *working;
  UIFont *bold, *italic, *monospace;
}

- (id)initWithTextile:(NSString *)markdown {
  self = [self init];
  working = [[NSMutableAttributedString alloc] initWithString:markdown];
  return self;
}

+ (NSAttributedString *)attributedStringFromMush:(NSString *)markdown
                                            font:(UIFont *)font
                                           color:(UIColor *)color {
  MGMushParser *parser = [[MGMushParser alloc] init];
  parser.mush = markdown;
  parser.baseColor = color;
  parser.baseFont = font;
  if ([UILabel instancesRespondToSelector:@selector(attributedText)]) {
    [parser parse];
  } else {
    [parser strip];
  }
  return parser.attributedString;
}

- (void)parse {

  // apply base colour and font
  id base = @{
    NSForegroundColorAttributeName:self.baseColor,
    NSFontAttributeName:self.baseFont
  };
  [working addAttributes:base range:(NSRange){0, working.length}];

  // patterns
  id boldParser = @{
    @"regex":@"(\\*{2})(.+?)(\\*{2})",
    @"replace":@[@"", @1, @""],
    @"attributes":@[@{ }, @{ NSFontAttributeName:bold }, @{ }]
  };

  id italicParser = @{
    @"regex":@"(/{2})(.+?)(/{2})",
    @"replace":@[@"", @1, @""],
    @"attributes":@[@{ }, @{ NSFontAttributeName:italic }, @{ }]
  };

  id underlineParser = @{
    @"regex":@"(_{2})(.+?)(_{2})",
    @"replace":@[@"", @1, @""],
    @"attributes":@[@{ }, @{ NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle) }, @{ }]
  };

  id monospaceParser = @{
    @"regex":@"(`)(.+?)(`)",
    @"replace":@[@"", @1, @""],
    @"attributes":@[@{ }, @{ NSFontAttributeName:monospace }, @{ }]
  };

  [self applyParser:boldParser];
  [self applyParser:italicParser];
  [self applyParser:underlineParser];
  [self applyParser:monospaceParser];
}

- (void)strip {

  // patterns
  id boldParser = @{
    @"regex":@"(\\*{2})(.+?)(\\*{2})",
    @"replace":@[@"", @1, @""]
  };

  id italicParser = @{
    @"regex":@"(/{2})(.+?)(/{2})",
    @"replace":@[@"", @1, @""]
  };

  id underlineParser = @{
    @"regex":@"(_{2})(.+?)(_{2})",
    @"replace":@[@"", @1, @""]
  };

  id monospaceParser = @{
    @"regex":@"(`)(.+?)(`)",
    @"replace":@[@"", @1, @""]
  };

  [self applyParser:boldParser];
  [self applyParser:italicParser];
  [self applyParser:underlineParser];
  [self applyParser:monospaceParser];
}

- (void)applyParser:(NSDictionary *)parser {
  id regex = [NSRegularExpression regularExpressionWithPattern:parser[@"regex"]
      options:0 error:nil];
  NSString *markdown = working.string.copy;

  __block int nudge = 0;
  [regex enumerateMatchesInString:markdown options:0
      range:(NSRange){0, markdown.length}
      usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags,
          BOOL *stop) {

        NSMutableArray *substrs = @[].mutableCopy;
        NSMutableArray *replacements = @[].mutableCopy;

        // fetch match substrings
        for (int i = 0; i < match.numberOfRanges - 1; i++) {
          NSRange nudged = [match rangeAtIndex:i + 1];
          nudged.location -= nudge;
          substrs[i] = [working attributedSubstringFromRange:nudged].mutableCopy;
        }

        // make replacement substrings
        for (int i = 0; i < match.numberOfRanges - 1; i++) {
          NSString *repstr = parser[@"replace"][i];
          replacements[i] = [repstr isKindOfClass:NSNumber.class]
              ? substrs[repstr.intValue]
              : [[NSMutableAttributedString alloc] initWithString:repstr];
        }

        // apply attributes
        for (int i = 0; i < match.numberOfRanges - 1; i++) {
          id attributes = parser[@"attributes"][i];
          if (attributes) {
            NSMutableAttributedString *repl = replacements[i];
            [repl addAttributes:attributes range:(NSRange){0, repl.length}];
          }
        }

        // replace
        for (int i = 0; i < match.numberOfRanges - 1; i++) {
          NSRange nudged = [match rangeAtIndex:i + 1];
          nudged.location -= nudge;
          nudge += [substrs[i] length] - [replacements[i] length];
          [working replaceCharactersInRange:nudged
              withAttributedString:replacements[i]];
        }
      }];
}

#pragma mark - Setters

- (void)setMush:(NSString *)mush {
  _mush = mush;
  working = [[NSMutableAttributedString alloc] initWithString:mush];
}

- (void)setBaseFont:(UIFont *)font {
  _baseFont = font;

  if (!font) {
    return;
  }

  // base ctfont
  CGFloat size = font.pointSize;
  CFStringRef name = (__bridge CFStringRef)font.fontName;
  CTFontRef ctBase = CTFontCreateWithName(name, size, NULL);

  // bold font
  CTFontRef ctBold = CTFontCreateCopyWithSymbolicTraits(ctBase, 0, NULL,
      kCTFontBoldTrait, kCTFontBoldTrait);
  CFStringRef boldName = CTFontCopyName(ctBold, kCTFontPostScriptNameKey);
  bold = [UIFont fontWithName:(__bridge NSString *)boldName size:size];

  // italic font
  CTFontRef ctItalic = CTFontCreateCopyWithSymbolicTraits(ctBase, 0, NULL,
      kCTFontItalicTrait, kCTFontItalicTrait);
  CFStringRef italicName = CTFontCopyName(ctItalic, kCTFontPostScriptNameKey);
  italic = [UIFont fontWithName:(__bridge NSString *)italicName size:size];

  monospace = [UIFont fontWithName:@"CourierNewPSMT" size:size];
}

#pragma mark - Getters

- (NSAttributedString *)attributedString {
  return working;
}

@end
