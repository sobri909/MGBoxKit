//
//  Created by matt on 24/08/12.
//

#define CLAMP(x,low,high) (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

#ifndef MGEVENTS
#define MGEVENTS <MGEvents/MGEvents.h>
#endif
#import MGEVENTS
#import "UIView+MGEasyFrame.h"
#import "UIResponder+FirstResponder.h"
