//
//  DemoViewController.h
//  MGBox2 Demo App
//
//  Created by Matt Greenfield on 25/09/12.
//  Copyright (c) 2012 Big Paua. All rights reserved.
//

@class MGScrollView, MGBox;

@interface DemoViewController : UIViewController

@property (nonatomic, weak) IBOutlet MGScrollView *scroller;

- (MGBox *)photoAddBox;
- (BOOL)allPhotosLoaded;

@end
