//
//  DemoViewController.m
//  MGBox2 Demo App
//
//  Created by Matt Greenfield on 25/09/12.
//  Copyright (c) 2012 Big Paua. All rights reserved.
//

#import "DemoViewController.h"
#import "MGScrollView.h"
#import "MGTableBoxStyled.h"
#import "MGLineStyled.h"
#import "PhotoBox.h"

#define TOTAL_IMAGES           28
#define IPHONE_INITIAL_IMAGES  3
#define IPAD_INITIAL_IMAGES    11

#define ROW_SIZE               (CGSize){304, 44}

#define IPHONE_PORTRAIT_PHOTO  (CGSize){148, 148}
#define IPHONE_LANDSCAPE_PHOTO (CGSize){152, 152}

#define IPHONE_PORTRAIT_GRID   (CGSize){312, 0}
#define IPHONE_LANDSCAPE_GRID  (CGSize){160, 0}
#define IPHONE_TABLES_GRID     (CGSize){320, 0}

#define IPAD_PORTRAIT_PHOTO    (CGSize){128, 128}
#define IPAD_LANDSCAPE_PHOTO   (CGSize){122, 122}

#define IPAD_PORTRAIT_GRID     (CGSize){136, 0}
#define IPAD_LANDSCAPE_GRID    (CGSize){390, 0}
#define IPAD_TABLES_GRID       (CGSize){624, 0}

#define HEADER_FONT            [UIFont fontWithName:@"HelveticaNeue" size:18]

@implementation DemoViewController {
  MGBox *photosGrid, *tablesGrid, *table1, *table2;
  UIImage *arrow;
  BOOL phone;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // iPhone or iPad?
  UIDevice *device = UIDevice.currentDevice;
  phone = device.userInterfaceIdiom == UIUserInterfaceIdiomPhone;

  // i'll be using this a lot
  arrow = [UIImage imageNamed:@"arrow"];

  // setup the main scroller (using a grid layout)
  self.scroller.contentLayoutMode = MGLayoutGridStyle;
  self.scroller.bottomPadding = 8;

  // iPhone or iPad grid?
  CGSize photosGridSize = phone ? IPHONE_PORTRAIT_GRID : IPAD_PORTRAIT_GRID;

  // the photos grid
  photosGrid = [MGBox boxWithSize:photosGridSize];
  photosGrid.contentLayoutMode = MGLayoutGridStyle;
  [self.scroller.boxes addObject:photosGrid];

  // the tables grid
  CGSize tablesGridSize = phone ? IPHONE_TABLES_GRID : IPAD_TABLES_GRID;
  tablesGrid = [MGBox boxWithSize:tablesGridSize];
  tablesGrid.contentLayoutMode = MGLayoutGridStyle;
  [self.scroller.boxes addObject:tablesGrid];

  // the features table
  table1 = MGBox.box;
  [tablesGrid.boxes addObject:table1];
  table1.sizingMode = MGResizingShrinkWrap;

  // the subsections table
  table2 = MGBox.box;
  [tablesGrid.boxes addObject:table2];
  table2.sizingMode = MGResizingShrinkWrap;

  // add photo boxes to the grid
  int initialImages = phone ? IPHONE_INITIAL_IMAGES : IPAD_INITIAL_IMAGES;
  for (int i = 1; i <= initialImages; i++) {
    int photo = [self randomMissingPhoto];
    [photosGrid.boxes addObject:[self photoBoxFor:photo]];
  }

  // add a blank "add photo" box
  [photosGrid.boxes addObject:self.photoAddBox];

  // load some table sections
  if (phone) {
    [self loadIntroSection];
  } else {
    [self loadLayoutFeaturesSection:NO];
    [self loadConviniFeaturesSection:NO];
  }
  [tablesGrid layout];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self willAnimateRotationToInterfaceOrientation:self.interfaceOrientation
      duration:1];
  [self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
}

#pragma mark - Rotation and resizing

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)o {
  return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orient
                                         duration:(NSTimeInterval)duration {

  BOOL portrait = UIInterfaceOrientationIsPortrait(orient);

  // grid size
  photosGrid.size = phone ? portrait
      ? IPHONE_PORTRAIT_GRID
      : IPHONE_LANDSCAPE_GRID : portrait
      ? IPAD_PORTRAIT_GRID
      : IPAD_LANDSCAPE_GRID;

  // photo sizes
  CGSize size = phone
      ? portrait ? IPHONE_PORTRAIT_PHOTO : IPHONE_LANDSCAPE_PHOTO
      : portrait ? IPAD_PORTRAIT_PHOTO : IPAD_LANDSCAPE_PHOTO;

  // apply to each photo
  for (MGBox *photo in photosGrid.boxes) {
    photo.size = size;
    photo.layer.shadowPath
        = [UIBezierPath bezierPathWithRect:photo.bounds].CGPath;
    photo.layer.shadowOpacity = 0;
  }

  // relayout the sections
  [self.scroller layoutWithSpeed:duration completion:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orient {
  for (MGBox *photo in photosGrid.boxes) {
    photo.layer.shadowOpacity = 1;
  }
}

#pragma mark - Photo Box factories

- (CGSize)photoBoxSize {
  BOOL portrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);

  // what size plz?
  return phone
      ? portrait ? IPHONE_PORTRAIT_PHOTO : IPHONE_LANDSCAPE_PHOTO
      : portrait ? IPAD_PORTRAIT_PHOTO : IPAD_LANDSCAPE_PHOTO;
}

- (MGBox *)photoBoxFor:(int)i {

  // make the photo box
  PhotoBox *box = [PhotoBox photoBoxFor:i size:[self photoBoxSize]];

  // remove the box when tapped
  __weak id wbox = box;
  box.onTap = ^{
    MGBox *section = (id)box.parentBox;

    // remove
    [section.boxes removeObject:wbox];

    // if we don't have an add box, and there's photos left, add one
    if (![self photoBoxWithTag:-1] && [self randomMissingPhoto]) {
      [section.boxes addObject:self.photoAddBox];
    }

    // animate
    [section layoutWithSpeed:0.3 completion:nil];
    [self.scroller layoutWithSpeed:0.3 completion:nil];
  };

  return box;
}

- (PhotoBox *)photoAddBox {

  // make the box
  PhotoBox *box = [PhotoBox photoAddBoxWithSize:[self photoBoxSize]];

  // deal with taps
  __weak MGBox *wbox = box;
  box.onTap = ^{

    // a new photo number
    int photo = [self randomMissingPhoto];

    // replace the add box with a photo loading box
    int idx = [photosGrid.boxes indexOfObject:wbox];
    [photosGrid.boxes removeObject:wbox];
    [photosGrid.boxes insertObject:[self photoBoxFor:photo] atIndex:idx];
    [photosGrid layout];

    // all photos are in now?
    if (![self randomMissingPhoto]) {
      return;
    }

    // add another add box
    PhotoBox *addBox = self.photoAddBox;
    [photosGrid.boxes addObject:addBox];

    // animate the section and the scroller
    [photosGrid layoutWithSpeed:0.3 completion:nil];
    [self.scroller layoutWithSpeed:0.3 completion:nil];
    [self.scroller scrollToView:addBox withMargin:8];
  };

  return box;
}

#pragma mark - Photo Box helpers

- (int)randomMissingPhoto {
  int photo;
  id existing;

  do {
    if (self.allPhotosLoaded) {
      return 0;
    }
    photo = arc4random_uniform(TOTAL_IMAGES) + 1;
    existing = [self photoBoxWithTag:photo];
  } while (existing);

  return photo;
}

- (MGBox *)photoBoxWithTag:(int)tag {
  for (MGBox *box in photosGrid.boxes) {
    if (box.tag == tag) {
      return box;
    }
  }
  return nil;
}

- (BOOL)allPhotosLoaded {
  return photosGrid.boxes.count == TOTAL_IMAGES && ![self photoBoxWithTag:-1];
}

#pragma mark - Main menu sections

- (void)loadIntroSection {

  // intro section
  MGTableBoxStyled *menu = MGTableBoxStyled.box;
  [table1.boxes addObject:menu];

  // header line
  MGLineStyled
      *header = [MGLineStyled lineWithLeft:@"MGBox Demo" right:nil size:ROW_SIZE];
  header.font = HEADER_FONT;
  [menu.topLines addObject:header];

  // layout menu line
  MGLineStyled
      *layoutLine = [MGLineStyled lineWithLeft:@"Layout Features" right:arrow
      size:ROW_SIZE];
  [menu.topLines addObject:layoutLine];

  // load the features table on tap
  layoutLine.onTap = ^{
    [self loadLayoutFeaturesSection:YES];
  };

  // convenience features menu line
  MGLineStyled
      *conviniLine = [MGLineStyled lineWithLeft:@"Code Convenience Features"
      right:arrow size:ROW_SIZE];
  [menu.topLines addObject:conviniLine];

  // load the features table on tap
  conviniLine.onTap = ^{
    [self loadConviniFeaturesSection:YES];
  };
}

- (void)loadLayoutFeaturesSection:(BOOL)animated {
  if (phone && table1.boxes.count > 1) {
    [table1.boxes removeObject:table1.boxes.lastObject];
  }

  // make the table
  MGTableBoxStyled *layout = MGTableBoxStyled.box;
  [table1.boxes addObject:layout];

  // header
  MGLineStyled *head = [MGLineStyled lineWithLeft:@"Layout Features" right:nil
      size:ROW_SIZE];
  [layout.topLines addObject:head];
  head.font = HEADER_FONT;

  MGLineStyled *grids = [MGLineStyled lineWithLeft:@"Grid layouts" right:arrow
      size:ROW_SIZE];
  [layout.topLines addObject:grids];
  grids.onTap = ^{
    [self loadGridLayoutSection];
  };

  MGLineStyled *tables = [MGLineStyled lineWithLeft:@"Table layouts" right:arrow
      size:ROW_SIZE];
  [layout.topLines addObject:tables];
  tables.onTap = ^{
    [self loadTableLayoutSection];
  };

  MGLineStyled *anims = [MGLineStyled lineWithLeft:@"Animated layout" right:arrow
      size:ROW_SIZE];
  [layout.topLines addObject:anims];
  anims.onTap = ^{
    [self loadAnimatedLayoutSection];
  };

  MGLineStyled
      *asyncs = [MGLineStyled lineWithLeft:@"Asynchronous layout" right:arrow
      size:ROW_SIZE];
  [layout.topLines addObject:asyncs];
  asyncs.onTap = ^{
    [self loadAsyncLayoutSection];
  };

  MGLineStyled
      *more = [MGLineStyled lineWithLeft:@"CSS style properties" right:arrow
      size:ROW_SIZE];
  [layout.topLines addObject:more];
  more.onTap = ^{
    [self loadMoreLayoutSection];
  };

  MGLineStyled
      *markup = [MGLineStyled lineWithLeft:@"Lightweight text markup" right:arrow
      size:ROW_SIZE];
  [layout.topLines addObject:markup];
  markup.onTap = ^{
    [self loadMarkupSection];
  };

  // animate and scroll
  if (animated) {
    [table1 layoutWithSpeed:0.3 completion:nil];
    [self.scroller layoutWithSpeed:0.3 completion:nil];
    [self.scroller scrollToView:layout withMargin:8];
  } else {
    [table1 layout];
  }
}

- (void)loadConviniFeaturesSection:(BOOL)animated {
  if (phone && table1.boxes.count > 1) {
    [table1.boxes removeObject:table1.boxes.lastObject];
  }

  // make the section
  MGTableBoxStyled *convini = MGTableBoxStyled.box;
  [table1.boxes addObject:convini];

  // header
  MGLineStyled
      *head = [MGLineStyled lineWithLeft:@"Code Convenience Features" right:nil
      size:ROW_SIZE];
  [convini.topLines addObject:head];
  head.font = HEADER_FONT;

  // stuff
  MGLineStyled
      *gestures = [MGLineStyled lineWithLeft:@"Blocks Based Tap, Swipe, and Hold"
      right:arrow size:ROW_SIZE];
  [convini.topLines addObject:gestures];
  gestures.onTap = ^{
    [self loadGesturesSection];
  };

  // stuff
  MGLineStyled
      *triggers = [MGLineStyled lineWithLeft:@"Blocks Based Custom Events"
      right:arrow size:ROW_SIZE];
  [convini.topLines addObject:triggers];
  triggers.onTap = ^{
    [self loadCustomEventsSection];
  };

  // stuff
  MGLineStyled *cont = [MGLineStyled lineWithLeft:@"Blocks Based UIControl Events"
      right:arrow size:ROW_SIZE];
  [convini.topLines addObject:cont];
  cont.onTap = ^{
    [self loadControlEventsSection];
  };

  // stuff
  MGLineStyled
      *obs = [MGLineStyled lineWithLeft:@"Blocks Based Observers" right:arrow
      size:ROW_SIZE];
  [convini.topLines addObject:obs];
  obs.onTap = ^{
    [self loadObserversSection];
  };

  // stuff
  MGLineStyled *views = [MGLineStyled lineWithLeft:@"UIView Easy Frame Accessors"
      right:arrow size:ROW_SIZE];
  [convini.topLines addObject:views];
  views.onTap = ^{
    [self loadEasyFrameSection];
  };

  // animate and scroll
  if (animated) {
    [table1 layoutWithSpeed:0.3 completion:nil];
    [self.scroller layoutWithSpeed:0.3 completion:nil];
    [self.scroller scrollToView:convini withMargin:8];
  } else {
    [table1 layout];
  }
}

#pragma mark - Layout features sections

- (void)loadGridLayoutSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled
      *head = [MGLineStyled lineWithLeft:@"Grids" right:nil size:ROW_SIZE];
  [section.topLines addObject:head];
  head.font = HEADER_FONT;

  id waffle = @"Similar to CSS's **float:left**, but without the "
      "float clear hassles.\n\n"
      "Set the container's **contentLayoutMode**, add your boxes to it, "
      "and you're done.\n\n"
      "Optionally set each grid item's **margin** or **padding** values to get the "
      "desired spacing.|mush";

  // stuff
  MGLineStyled *line = [MGLineStyled multilineWithText:waffle font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line];

  // animate
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

- (void)loadTableLayoutSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled
      *head1 = [MGLineStyled lineWithLeft:@"Tables" right:nil size:ROW_SIZE];
  [section.topLines addObject:head1];
  head1.font = HEADER_FONT;

  id waffle1 = @"Similar to **UITableView**, but without the awkward "
      "design patterns.\n\n"
      "Create a table section, add some rows to it, and you're done.\n\n"
      "Add or remove rows or sections simply by adding/removing them from their "
      "containing box.|mush";

  // stuff
  MGLineStyled *waf1 = [MGLineStyled multilineWithText:waffle1 font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:waf1];

  // header
  MGLineStyled
      *head2 = [MGLineStyled lineWithLeft:@"Table Rows" right:nil size:ROW_SIZE];
  [section.topLines addObject:head2];
  head2.font = HEADER_FONT;

  id waffle2 = @"**MGLine** provides a quick, no nonsense interface for building "
      "table rows with left, middle, and right content, as "
      "well as rows with multiline text.\n\n"
      "**NSString** and **UIImage** objects can be added directly to an **MGLine** "
      "and will be automatically wrapped in a **UILabel** or **UIImageView**.|mush";

  // stuff
  MGLineStyled *waf2 = [MGLineStyled multilineWithText:waffle2 font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:waf2];

  // animate
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

- (void)loadAnimatedLayoutSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled *head = [MGLineStyled lineWithLeft:@"Animated Layout" right:nil
      size:ROW_SIZE];
  [section.topLines addObject:head];
  head.font = HEADER_FONT;

  id waffle = @"**MGBox** and **MGScrollView** provide **layout** and "
      "**layoutWithSpeed:completion:** methods.\n\n"
      "**layout** automatically positions all child boxes according to their "
      "**margin**, **padding**, and **boxLayoutMode** values.\n\n"
      "**layoutWithSpeed:completion:** does the same, with the addition of "
      "fading in new boxes, fading out removed boxes, and animating existing "
      "boxes from old position to new.\n\n"
      "This allows effortless animation of changes to grids, tables, "
      "table sections, or any arbitrary tree of **MGBLayoutBox** objects.|mush";

  // stuff
  MGLineStyled *line = [MGLineStyled multilineWithText:waffle font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line];

  // animate
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

- (void)loadAsyncLayoutSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled *head = [MGLineStyled lineWithLeft:@"Asynchronous Layout" right:nil
      size:ROW_SIZE];
  [section.topLines addObject:head];
  head.font = HEADER_FONT;

  id waffle = @"**MGBox** and **MGScrollView** provide **asyncLayout** and "
      "**asyncLayoutOnce** block properties.\n\n"
      "The photo grid boxes in this demo are an example of async layout. "
      "Each box is given an initial size and a loading indicator. When **layout** or "
      "**layoutWithSpeed:completion:** is called on the parent **MGBox**, the "
      "**asyncLayoutOnce** block is called in the background to load an image from "
      "a server, then update the box once finished.\n\n"
      "Each **MGBox** has an optional **asyncQueue** property, if for example you want "
      "to perform their processes in serial or at a different priority.|mush";

  // stuff
  MGLineStyled *line = [MGLineStyled multilineWithText:waffle font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line];

  // animate
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

- (void)loadMoreLayoutSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled
      *head1 = [MGLineStyled lineWithLeft:@"Margins, Padding, Z-Index" right:nil
      size:ROW_SIZE];
  [section.topLines addObject:head1];
  head1.font = HEADER_FONT;

  id waffle1 = @"**MGBox** and **MGScrollView** have top/bottom/left/right "
      "**padding** and **margin**, and **zIndex** properties which are taken into account "
      "when laying out themselves and their children.|mush";

  // stuff
  MGLineStyled *line1 = [MGLineStyled multilineWithText:waffle1 font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line1];

  // header
  MGLineStyled *head2 = [MGLineStyled lineWithLeft:@"Fixed Positioning" right:nil
      size:ROW_SIZE];
  [section.topLines addObject:head2];
  head2.font = HEADER_FONT;

  id waffle2 = @"Similar to CSS's **position:fixed**, an **MGBox** can be given fixed "
      "positioning inside an **MGScrollView**, allowing them to stay in a "
      "constant position while other views scroll.|mush";

  // stuff
  MGLineStyled *line2 = [MGLineStyled multilineWithText:waffle2 font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line2];

  // header
  MGLineStyled
      *head3 = [MGLineStyled lineWithLeft:@"Attached Positioning" right:nil
      size:ROW_SIZE];
  [section.topLines addObject:head3];
  head3.font = HEADER_FONT;

  id waffle3 = @"An **MGBox**'s origin can be attached to another view's origin, "
      "making the box appear at the same location. Offset the box by adjusting "
      "its top and left margins.|mush";

  // stuff
  MGLineStyled *line3 = [MGLineStyled multilineWithText:waffle3 font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line3];

  // animate
  //table2.size = TABLE_SIZE;
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

- (void)loadMarkupSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled
      *head = [MGLineStyled lineWithLeft:@"Lightweight Text Markup" right:nil
      size:ROW_SIZE];
  [section.topLines addObject:head];
  head.font = HEADER_FONT;

  id waffle1
      = @"**MGLine** supports lightweight markup for **bold**, "
          "//italic//, __underlined__, and `monospaced` text.\n\n"
          "**Note:** On pre iOS 6 devices marked up text will fallback to "
          "displaying without formatting.|mush";
  id waffle2 = @"**bold** with asterisks.\n"
      "//italicise// with slashes.\n"
      "__underline__ with underscores.\n"
      "`monospace` with backticks.";

  // stuff
  MGLineStyled *line1 = [MGLineStyled multilineWithText:waffle1 font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 0, 16)];
  line1.borderStyle &= ~MGBorderEtchedBottom;
  [section.topLines addObject:line1];

  // stuff
  MGLineStyled *line2 = [MGLineStyled multilineWithText:waffle2 font:nil width:304
      padding:UIEdgeInsetsMake(8, 16, 16, 16)];
  line2.borderStyle &= ~MGBorderEtchedTop;
  [section.topLines addObject:line2];

  // animate
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

#pragma mark - Convenience features sections

- (void)loadGesturesSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled *head = [MGLineStyled lineWithLeft:@"Blocks Based Tap, Swipe, Hold"
      right:nil size:ROW_SIZE];
  [section.topLines addObject:head];
  head.font = HEADER_FONT;

  id waffle = @"**MGBox** and **MGScrollView** provide zero effort, "
      "blocks based gesture recognisers.\n\n"
      "Set a block for the **onTap**, **onSwipe**, or **onLongPress** properties "
      "and you're done.\n\n"
      "Toggle them on and off with the **tappable**, **swipeable**, "
      "and **longPressable** boolean properties.|mush";

  // stuff
  MGLineStyled *line = [MGLineStyled multilineWithText:waffle font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line];

  // animate
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

- (void)loadCustomEventsSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled
      *head = [MGLineStyled lineWithLeft:@"Blocks Based Custom Events" right:nil
      size:ROW_SIZE];
  [section.topLines addObject:head];
  head.font = HEADER_FONT;

  id waffle = @"The **NSObject+MGEvents** category provides custom event triggering "
      "and observing for all objects.\n\n"
      "`[object on:@\"CustomEvent\"`\n"
      "`        do:^{ ... }];`\n\n"
      "`[object trigger:@\"CustomEvent\"];`\n\n"
      "No fuss. It just works. On all objects.|mush";

  // stuff
  MGLineStyled *line = [MGLineStyled multilineWithText:waffle font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line];

  // animate
  //table2.size = TABLE_SIZE;
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

- (void)loadControlEventsSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled *head = [MGLineStyled lineWithLeft:@"Blocks Based UIControl Events"
      right:nil size:ROW_SIZE];
  head.leftPadding = head.rightPadding = 16;
  [section.topLines addObject:head];
  head.font = HEADER_FONT;

  id waffle = @"The **UIControl+MGEvents** category provides blocks based control "
      "event handling for buttons, sliders, switches, etc.\n\n"
      "`[button onControlEvent:...`\n"
      "`        do:^{ ... }];`|mush";

  // stuff
  MGLineStyled *line = [MGLineStyled multilineWithText:waffle font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line];

  // animate
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

- (void)loadObserversSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled
      *head = [MGLineStyled lineWithLeft:@"Blocks Based Observers" right:nil
      size:ROW_SIZE];
  [section.topLines addObject:head];
  head.font = HEADER_FONT;

  id waffle = @"No more awkward crashes caused by dangling observers "
      "after dealloc.\n\n"
      "With **NSObject+MGEvents**, simply add a block as an observer of a keypath, "
      "and the rest is taken care of.\n\n"
      "`[object onChangeOf:@\"keyPath\"`\n"
      "`                do:^{ ... }];`|mush";

  // stuff
  MGLineStyled *line = [MGLineStyled multilineWithText:waffle font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line];

  // animate
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

- (void)loadEasyFrameSection {

  // empty table2 out
  [table2.boxes removeAllObjects];

  // make the section
  MGTableBoxStyled *section = MGTableBoxStyled.box;
  [table2.boxes addObject:section];

  // header
  MGLineStyled
      *head = [MGLineStyled lineWithLeft:@"UIView Easy Frame Accessors" right:nil
      size:ROW_SIZE];
  [section.topLines addObject:head];
  head.font = HEADER_FONT;

  id waffle = @"Messing about with view frames is a hassle when "
      "you only want to change one thing.\n\n"
      "**UIView+MGEasyFrame** category provides getters and setters for **size**, "
      "**origin**, **width**, **height**, **x**, and **y**. And getters for "
      "**topLeft**, **topRight**, **bottomLeft**, and **bottomRight**.|mush";

  // stuff
  MGLineStyled *line = [MGLineStyled multilineWithText:waffle font:nil width:304
      padding:UIEdgeInsetsMake(16, 16, 16, 16)];
  [section.topLines addObject:line];

  // animate
  [table2 layoutWithSpeed:0.3 completion:nil];
  [self.scroller layoutWithSpeed:0.3 completion:nil];

  // scroll
  [self.scroller scrollToView:section withMargin:8];
}

@end
