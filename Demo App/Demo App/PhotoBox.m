//
//  Created by matt on 28/09/12.
//

#import "PhotoBox.h"

@implementation PhotoBox

#pragma mark - Init

- (void)setup {

  // positioning
  self.topMargin = 8;
  self.leftMargin = 8;

  // background
  self.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1];

  // shadow
  self.layer.shadowColor = [UIColor colorWithWhite:0.12 alpha:1].CGColor;
  self.layer.shadowOffset = CGSizeMake(0, 0.5);
  self.layer.shadowRadius = 1;
  self.layer.shadowOpacity = 1;
}

#pragma mark - Factories

+ (PhotoBox *)photoAddBoxWithSize:(CGSize)size {

  // basic box
  PhotoBox *box = [PhotoBox boxWithSize:size];

  // style and tag
  box.backgroundColor = [UIColor colorWithRed:0.74 green:0.74 blue:0.75 alpha:1];
  box.tag = -1;

  // add the add image
  UIImage *add = [UIImage imageNamed:@"add"];
  UIImageView *addView = [[UIImageView alloc] initWithImage:add];
  [box addSubview:addView];
  addView.center = (CGPoint){box.width / 2, box.height / 2};
  addView.alpha = 0.2;
  addView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
      | UIViewAutoresizingFlexibleRightMargin
      | UIViewAutoresizingFlexibleBottomMargin
      | UIViewAutoresizingFlexibleLeftMargin;

  return box;
}

+ (PhotoBox *)photoBoxFor:(int)i size:(CGSize)size {

  // box with photo number tag
  PhotoBox *box = [PhotoBox boxWithSize:size];
  box.tag = i;

  // add a loading spinner
  UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  spinner.center = CGPointMake(box.width / 2, box.height / 2);
  spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
      | UIViewAutoresizingFlexibleRightMargin
      | UIViewAutoresizingFlexibleBottomMargin
      | UIViewAutoresizingFlexibleLeftMargin;
  spinner.color = UIColor.lightGrayColor;
  [box addSubview:spinner];
  [spinner startAnimating];

  // do the photo loading async, because internets
  __weak id wbox = box;
  box.asyncLayoutOnce = ^{
    [wbox loadPhoto];
  };

  return box;
}

#pragma mark - Layout

- (void)layout {
  [super layout];

  // speed up shadows
  self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
}

#pragma mark - Photo box loading

- (void)loadPhoto {

  // photo url
  id photosDir = @"http://bigpaua.com/images/MGBox";
  id fullPath = [NSString stringWithFormat:@"%@/%d.jpg", photosDir, self.tag];
  NSURL *url = [NSURL URLWithString:fullPath];

  // fetch the remote photo
  NSData *data = [NSData dataWithContentsOfURL:url];

  // do UI stuff back in UI land
  dispatch_async(dispatch_get_main_queue(), ^{

    // ditch the spinner
    UIActivityIndicatorView *spinner = self.subviews.lastObject;
    [spinner stopAnimating];
    [spinner removeFromSuperview];

    // failed to get the photo?
    if (!data) {
      self.alpha = 0.3;
      return;
    }

    // got the photo, so lets show it
    UIImage *image = [UIImage imageWithData:data];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:imageView];
    imageView.size = self.size;
    imageView.alpha = 0;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth
        | UIViewAutoresizingFlexibleHeight;

    // fade the image in
    [UIView animateWithDuration:0.2 animations:^{
      imageView.alpha = 1;
    }];
  });
}

@end
