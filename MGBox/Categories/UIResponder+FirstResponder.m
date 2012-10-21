//
//  By VJK on Stack Overflow: http://stackoverflow.com/a/10358135/790036
//

#import "UIResponder+FirstResponder.h"
#import <objc/runtime.h>

static char *FirstResponderKey;

@implementation UIResponder (FirstResponder)

- (id)currentFirstResponder {
  [UIApplication.sharedApplication sendAction:@selector(findFirstResponder:)
      to:nil from:self forEvent:nil];
  id obj = objc_getAssociatedObject(self, FirstResponderKey);
  objc_setAssociatedObject(self, FirstResponderKey, nil, OBJC_ASSOCIATION_ASSIGN);
  return obj;
}

- (void)setCurrentFirstResponder:(id)responder {
  objc_setAssociatedObject(self, FirstResponderKey, responder,
      OBJC_ASSOCIATION_ASSIGN);
}

- (void)findFirstResponder:(id)sender {
  [sender setCurrentFirstResponder:self];
}

@end
