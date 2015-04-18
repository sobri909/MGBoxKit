//
//  MGBoxTest.m
//  MGBoxKit
//
//  Created by Benjamin Encz on 4/18/15.
//  Copyright (c) 2015 MGBoxKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MGBox.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#import <OCMock/OCMock.h>

@interface MGBoxSubclass : MGBox

@property BOOL hasBeenInitialized;

@end

@implementation MGBoxSubclass

- (void)setup {
  [super setup];
  
  self.hasBeenInitialized = YES;
}

@end

@interface MGBoxTest : XCTestCase

@end

@implementation MGBoxTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test_box {
  MGBox *box = [MGBox box];
  
  XCTAssertTrue(CGSizeEqualToSize(box.frame.size, CGSizeZero));
}

- (void)test_box_with_size {
  CGSize boxSize = CGSizeMake(100, 100);
  MGBox *box = [MGBox boxWithSize:boxSize];

  XCTAssertTrue(CGSizeEqualToSize(box.frame.size, boxSize));
}

- (void)test_setup_is_called_when_default_box_created {
  MGBoxSubclass *box = [MGBoxSubclass box];
  
  XCTAssertTrue(box.hasBeenInitialized);
}

@end