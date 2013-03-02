//
//  By VJK on Stack Overflow: http://stackoverflow.com/a/10358135/790036
//

@interface UIResponder (FirstResponder)

/**
Easy access to the current first responder. Useful for when the keyboard is open
and you want to know which text field is active.

Call this method on any `UIResponder` (eg any `UIView`) and the current first
responder will be returned.

    // which text field is active?
    UIResponder *active = self.view.currentFirstResponder;

@note This method does not use view tree walking, but instead uses a clever trick
invented by [VJK on Stack Overflow](http://stackoverflow.com/a/10358135/790036),
and as such is very fast.
*/
- (id)currentFirstResponder;

@end
