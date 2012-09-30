//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGLayoutBox.h"
#import "NSObject+MGEvents.h"

@class MGBox;

@interface MGButton : UIButton <MGLayoutBox>

@property (nonatomic, assign) CGFloat maxWidth; // get rid of this

- (void)setup;

// event handling
@property (nonatomic, retain) NSMutableDictionary *eventHandlers;
- (void)onControlEvent:(UIControlEvents)controlEvent do:(Block)handler;

@end
