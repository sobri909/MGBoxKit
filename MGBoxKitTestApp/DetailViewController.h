//
//  DetailViewController.h
//  MGBoxKit
//
//  Created by Benjamin Encz on 4/18/15.
//  Copyright (c) 2015 MGBoxKit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

