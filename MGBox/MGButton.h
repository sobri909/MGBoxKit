//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGLayoutBox.h"
#import "NSObject+MGEvents.h"

@class MGBox;

@interface MGButton : UIButton <MGLayoutBox>

@property (nonatomic, copy) NSString *toUrl;
@property (nonatomic, copy) NSString *toPlist;
@property (nonatomic, copy) NSString *toSelector;

@property (nonatomic, assign) CGFloat maxWidth; // get rid of this

@property (nonatomic, retain) NSMutableDictionary *eventHandlers;

- (void)setup;

// event handling
- (void)onControlEvent:(UIControlEvents)controlEvent do:(Block)handler;

@end
