//
//  DemoViewController.h
//  MGBox2 Demo App
//
//  Created by Matt Greenfield on 25/09/12.
//  Copyright (c) 2012 Big Paua. All rights reserved.
//

@class MGScrollView, PhotoBox;

@interface DemoViewController : UIViewController

@property (nonatomic, weak) IBOutlet MGScrollView *scroller;

- (PhotoBox *)photoAddBox;
- (BOOL)allPhotosLoaded;

@end
