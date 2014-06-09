//
//  Created by matt on 24/08/12.
//

#define CLAMP(x,low,high) (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

#import <MGEvents/MGEvents.h>
#import "UIView+MGEasyFrame.h"
#import "UIResponder+FirstResponder.h"
