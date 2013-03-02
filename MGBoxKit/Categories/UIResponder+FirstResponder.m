//
//  By VJK on Stack Overflow: http://stackoverflow.com/a/10358135/790036
//

#import "UIResponder+FirstResponder.h"
#import <objc/runtime.h>

static char *MGFirstResponderKey = "MGFirstResponderKey";

@implementation UIResponder (FirstResponder)

- (id)currentFirstResponder {
  [UIApplication.sharedApplication sendAction:@selector(findFirstResponder:)
      to:nil from:self forEvent:nil];
  id obj = objc_getAssociatedObject(self, MGFirstResponderKey);
  objc_setAssociatedObject(self, MGFirstResponderKey, nil, OBJC_ASSOCIATION_ASSIGN);
  return obj;
}

- (void)setCurrentFirstResponder:(id)responder {
  objc_setAssociatedObject(self, MGFirstResponderKey, responder,
      OBJC_ASSOCIATION_ASSIGN);
}

- (void)findFirstResponder:(id)sender {
  [sender setCurrentFirstResponder:self];
}

@end
