# MGBox2 - Simple, quick iOS tables, grids, and more

Designed for rapid table and grid creation with minimal code, easy customisation, attractive default styling, using modern blocks based design patterns, and without need for fidgety tweaking or awkward design patterns. 

Includes blocks based gesture recognisers, observers, control events, and custom events.

`MGBox`, `MGScrollView`, and `MGButton` can also be used as generic `UIView` wrappers to get the benefits of view padding, margins, and zIndex, amongst others.

## Layout Features

- Table layouts (similar to `UITableView`, but less fuss)
- Grid layouts (similar to `UICollectionView`, but less fuss)
- Table rows automatically layout `NSStrings`, `UIImages`, 
  `NSAttributedStrings`, and multiline text
- Table rows accept `Mush` lightweight markup for bold, italics, underline, and 
  monospace
- Animated adding/removing/reordering rows, boxes, sections, etc
- CSS-like `margin`, `padding`, `zIndex`, `fixedPosition`, and more
- Separate top/right/bottom/left borders, and optional etched border style
- Optional asynchronous blocks based layout
- Automatically keeps input fields above the keyboard  
- Optional scroll view box edge snapping

## Code Convenience Features

- Blocks based tap, swipe, and hold gesture recognisers
- Blocks based custom event observing and triggering
- Blocks based UIControl event handlers
- Blocks based keypath observers
- UIView easy frame accessors

## Example Screenshots

Complex tables, sections, and grids created with simple code.

### From the Demo App

![Demo App Screenshot](http://cloud.github.com/downloads/sobri909/MGBox2/DemoApp6.png)

### From [IfAlarm](http://ifalarm.com)

Created with the convenience `-[MGBox screenshot:]` method.

![IfAlarm Screenshot 1](http://cloud.github.com/downloads/sobri909/MGBox2/IfAlarm1.png)
![IfAlarm Screenshot 2](http://cloud.github.com/downloads/sobri909/MGBox2/IfAlarm2.png)

### From [Flowies](http://flowi.es)

![Flowies Screenshot 1](http://cloud.github.com/downloads/sobri909/MGBox2/Flowies1.png)

## Setup

1. Add the `MGBox` folder to your project. (ARC and Xcode 4.5 are required)
2. Add the `CoreText` and `QuartzCore` frameworks to your project. 

Have a poke around the Demo App to see some of the features in use. 

## Example Usage

### Building a Table (Similar to UITableView)

#### Create a Scroll View:

```objc
MGScrollView *scroller = [MGScrollView scrollerWithSize:self.bounds.size];
[self.view addSubview:scroller];
```

#### Add a Table Section:

```
MGTableBoxStyled *section = MGTableBoxStyled.box;
[scroller.boxes addObject:section];
```

#### Add Some Rows:

```objc
// a default row size
CGSize rowSize = (CGSize){304, 40};

// a header row
MGLineStyled *header = [MGLineStyled lineWithLeft:@"My First Table" right:nil size:rowSize];
header.leftPadding = header.rightPadding = 16;
[section.topLines addObject:header];

// a string on the left and a horse on the right
MGLineStyled *row1 = [MGLineStyled lineWithLeft:@"Left text" 
    right:[UIImage imageNamed:@"horse.png"] size:rowSize];
[section.topLines addObject:row1];

// a string with Mush markup
MGLineStyled *row2 = MGLineStyled.line;
row2.multilineLeft = @"This row has **bold** text, //italics// text, __underlined__ text, "
    "and some `monospaced` text. The text will span more than one line, and the row will "
    "automatically adjust its height to fit.|mush";
row2.minHeight = 40;
[section.topLines addObject:row2];
```

#### Animate and Scroll the Section Into View

```objc
[scroller layoutWithSpeed:0.3 completion:nil];
[scroller scrollToView:section withMargin:8];
```

### Build a Grid (Similar to UICollectionView or CSS's float:left)

#### Create the Grid Container:

```objc
MGBox *grid = [MGBox boxWithSize:self.bounds.size];
grid.contentLayoutMode = MGLayoutGridStyle;
[scroller.boxes addObject:grid];
```

#### Add Some Views to the Grid:

```objc
// add ten 100x100 boxes, with 10pt top and left margins
for (int i = 0; i < 10; i++) {
    MGBox *box = [MGBox boxWithSize:(CGSize){100, 100}];
    box.leftMargin = box.topMargin = 10;
    [grid.boxes addObject:box];
}
```

#### Animate and Scroll the Grid Into View:

```objc
[grid layoutWithSpeed:0.3 completion:nil];
[scroller layoutWithSpeed:0.3 completion:nil];
[scroller scrollToView:grid withMargin:10];
```

## Animated and Asynchronous Layout

All `MGBoxes`, `MGScrollViews`, and subclasses support two layout methods (`layout`, `layoutWithSpeed:completion:`) and two async layout block properties (`asyncLayout` and `asyncLayoutOnce`).

### [box layout]

Layout the box's children (and all descendents) without animation.

### [box layoutWithSpeed:completion:]

Same as above, but with child boxes animated between previous and new computed positions, fading new boxes in, and fading removed boxes out. Child boxes will have their unanimated `layout` method called. If you want a child box to also animate the positioning of its children in the same drawing pass, call its `layoutWithSpeed:completion:` method first.

```objc
[grid layoutWithSpeed:0.3 completion:nil];
[scroller layoutWithSpeed:0.3 completion:nil];
```

### box.asyncLayout and box.asyncLayoutOnce

`asyncLayout` blocks are performed on every call to `layout` or `layoutWithSpeed:completion:`.

```objc
box.asyncLayout = ^{

    // do slow things on a background thread
    NSLog(@"things things things");

    // update the box presentation back in UI land
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"that took a while!");
    });    
};
```

`asyncLayoutOnce` blocks are performed only on the first call to `layout` or `layoutWithSpeed:completion:`, thus are useful for initial table or grid setup, when things like loading data over the network might be a performance factor.

```objc
box.asyncLayoutOnce = ^{

    // do slow things once, on a background thread
    NSLog(@"things things things");

    // update the box presentation back in UI land
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"aaand we're done");
    });
};
```

Assign a specific queue to the `asyncQueue` property if you want to use a different priority or perhaps perform a bunch of expensive processes in serial.

```objc
dispatch_queue_t queue = dispatch_queue_create("SerialQueue", DISPATCH_QUEUE_SERIAL);
for (MGBox *box in scroller.boxes) {
    box.asyncQueue = queue;
}
```

## MGBox's CSS-like Positioning and Stacking

### Margins and Padding

When `layout` or `layoutWithSpeed:completion:` is called, each descendent box in the tree is positioned according to the container box's `contentLayoutMode` (ie table or grid), taking into account the container's padding and the child's margins.

Getters and setters are provided for:

* `padding` (`UIEdgeInsets`)
* `margin` (`UIEdgeInsets`)
* `leftPadding`, `topPadding`, `rightPadding`, `bottomPadding`
* `leftMargin`, `topMargin`, `rightMargin`, `bottomMargin`

### Z-Index

The same as in CSS. The `zIndex` property of `MGBox` affects the stacking order of boxes during layout.

### Fixed Positioning

Set a box's `fixedPosition` property to a desired `CGPoint` to force it to stay in a fixed position when its containing `MGScrollView` scrolls.

### Attached Positioning

Assign another view to a box's `attachedTo` property to force the box to position at the same origin. Optionally adjust the offset by fiddling with the box's top and left margins.

## MGBox Borders

`MGBox` provides setters for individual top/right/bottom/left border colours, as well as a built in etched border style.

Set border colours individually with `topBorderColor`, etc. Set all border colours in one go with `borderColors`, like thus:

```objc
MGBox *box = MGBox.box;

// all borders the same colour
box.borderColors = UIColor.redColor;

// individual colours (order is top, left, bottom, right)
box.borderColors = @[
  UIColor.redColor, UIColor.greenColor, 
  UIColor.blueColor, UIColor.blackColor
];
```

The `borderStyle` property provides etched borders. Like thus:

```objc
// just top and bottom etches (as you'd see in a table row)
box.borderStyle = MGBorderEtchedTop | MGBorderEtchedBottom;

// borders on all sides except left
box.borderStyle = MGBorderEtchedAll & ~MGBorderEtchedLeft;

// no borders
box.borderStyle = MGBorderNone;
```

## Blocks Based Observers, Custom Events, Control Events, and Gestures

### Tap, Swipe, and Hold

Simply assign a block to the appropriate property. You can toggle them on and off with `tappable`, `swipable`, `longPressable` booleans. Access the gesture recognisers directly through the `tapper`, `swiper`, and `longPresser` properties.

```objc
box.onTap = ^{
    NSLog(@"you tapped my box!");    
};
box.onSwipe = ^{
    NSLog(@"you swiped, m'lord?");
};
box.onLongPress = ^{
    NSLog(@"you can let go now.");
};
```

### Blocks Based Observers

`NSObject+MGEvents` provides blocks based observing for all objects' keypaths. No more worrying about crashes caused by dangling observers after dealloc.

```objc
[earth onChangeOf:@"isFlat" do:^{
    if (earth.isFlat) {
        NSLog(@"the earth is now flat");
    } else {
        NSLog(@"the earth is no longer flat.");
    }
}];
```

### Blocks Based Custom Events

`NSObject+MGEvents` provides the ability to define custom events, assign block handlers, and trigger the events when you see fit.

```objc
[earth on:@"ChangingShape" do:^{
    NSLog(@"the earth is changing shape");
}];

[earth trigger:@"ChangingShape"];
```

### Blocks Based UIControl Event Handlers

`UIControl+MGEvents` provides a nice easy `onControlEvent:do:` method for all UIControls, which frees you from the muck of adding targets, selectors, etc. 

```objc
[button onControlEvent:UIControlEventTouchUpInside do:^{
    NSLog(@"i've been touched up inside. golly.");
}];
```

## UIView+MGEasyFrame Category

Fussing about with view frames can be tedious, especially when all you want to do is change a width or height, or know where the bottom right corner is.

`UIView+MGEasyFrame` provides getters and setters for:

* `size`, `width`, `height`
* `origin`, `x`, `y`

And getters for:

* `topLeft`, `topRight`, `bottomRight`, `bottomLeft`

## Subclassing Tips

While `MGLine` and `MGScrollView` rarely need subclassing, it's often useful to subclass `MGBox` when building things like items in a grid container, or for any generic views that you might want to layout using `MGBox` style layout rules (eg margins, zIndex, etc).

Also, if you want to create a custom table section style, you'll want to subclass `MGTableBox`, looking at `MGTableBoxStyled` as an example.

All `MGBoxes` have a convenience `setup` method which is called from both `initWithFrame:` and `initWithCoder:`, thus making it a good location to apply any custom styling such as shadows, background colours, corner radiuses, etc. You should probably call `[super setup]` in here.

Additionally you might want to override the standard `layout` method, if you want to perform some tasks before or after layout. You should almost certainly call `[super layout]` in your custom layout method.

If your custom `MGBox` has a shadow, it's useful to adjust its `shadowPath` in the `layout` method, after `[super layout]`, because shadows without shadowPaths make iOS cry.

## The Difference Between 'boxes' and 'subviews'

This distinction can present an occasional trap. When `layout` or `layoutWithSpeed:completion:` are called, the layout engine only applies `MGBox` layout rules to boxes in the container's `boxes` set. All other views in `subviews` will simply be ignored, with no `MGBox` style layout rules applied (their `zIndex` will be treated as `0`).

All `MGBoxes` that are subviews but are not in `boxes` will be removed during layout. Any `MGBoxes` in `boxes` that are not yet subviews will be added as subviews.

So as a general rule of thumb: Put `MGBoxes` into `boxes`, everything else into `subviews`, then call one of the `layout` methods when you're done. As long as you stick to that, you won't get tripped up.

## MGLine

`MGLine` is essentially a table row, although it can also be used more generically if it takes your fancy.

Although `MGLine` is an `MGBox` subclass, it instead sources its content views from `leftItems`, `middleItems`, and `rightItems`.

The items arrays can contain `NSStrings`, `UIImages`, or any arbitrary `UIViews` you want to add to the line (eg switches, sliders, buttons, etc).

### MGLine Multiline Text

`MGLine` can automatically wrap long strings, as well as mix and match them with other items in the same line. For example you might want multiline text on the left and an image on the right, or vice versa.

```objc
MGLine *line1 = [MGLine lineWithMultilineLeft:@"a long string on the left" 
    right:[UIImage imageNamed:@"Sharonda"] width:320 minHeight:40];
MGLine *line2 = [MGLine lineWithleft:[UIImage imageNamed:@"Felicia" 
    multilineRight:@"a long string on the right" width:320 minHeight:40];
```

Any string containing a newline char will be treated as multiline, so as a shorthand you can also do something like this:

```objc
MGLine *line = [MGLine lineWithLeft:@"a long string\n" right:nil];
```

### MGLine Mush Text Markup and Attributed Strings

`MGLine` can automatically parse Mush markup into bold, italics, underlined, and monospaced attributed strings. It will also accept any given `NSAttributedString`. Append "|mush" to any string to pass to `MGLine` to indicate that you want it parsed.

```objc
MGLineStyled *line1 = MGLineStyled.line;
line1.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
line1.leftItems = (id)@"**Some bold on the left**|mush";
line1.rightItems = (id)@"//Some italics on the right//|mush";

MGLineStyled *line2 = MGLineStyled.line;
line2.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
line2.multilineLeft = @"Pretend this is a //very long string//, and pretend it "
  "has some reason to include `some monospaced text`.|mush";
line2.minHeight = 40;
```

Note that iOS 6 is required to use `NSAttributedString` in a `UILabel`, so `MGLine` will fall back to presenting plain old strings on iOS 5 devices (with the markup stripped out).

### MGLine Side Precedence

The `sidePrecedence` property decides whether content on the left, right, or middle takes precedence when space runs out. `UILabels` will be shortened to fit. `UIImages` and `UIViews` will be removed from the centre outwards if there's not enough room to fit them in.

### MGLine Fonts, Text Colours, Text Shadows, and Text Alignment

The `font`, `middleFont`, and `rightFont` properties define what fonts are used to wrap `NSStrings`. If no right or middle font is set, the main `font` value is used.

The `textColor`, `middleTextColor`, and `rightTextColor` properties are fairly self explanatory. Again, if a right or middle colour isn't set, the main `textColor` value is used.

The `textShadowColor`, `middleTextShadowColor`, and `rightTextShadowColor` properties follow the trend.

The `leftTextShadowOffset`, `middleTextShadowOffset`, `rightTextShadowOffset` properties define text shadow offsets. They all default to {0, 1}.

The properties `leftItemsTextAlignment`, `middleItemsTextAlignment`, `rightItemsTextAlignment` are passed on to the labels created for your strings.

### MGLine Item Padding

The `itemPadding` property defines how much padding to apply to the left and right of each item. This is added to the `leftMargin` and `rightMargin` values of any `MGBoxes` you might have added as line items. 

### MGLine Min and Max Height

By default the `minHeight` and `maxHeight` properties are both zero, thus causing the line's size to be unchanged by the size of its contents. But if either of them is non-zero, the line height will adjust to fit the highest content item, within the given bounds. 

A `maxHeight` of zero when `minHeight` is non-zero allows the line to increase in height without restriction.

```objc
MGLine *line = [MGLine lineWithLeft:@"a really long string\n" right:nil];
line.minHeight = 40; // the line will be at least 40 high
line.maxHeight = 0; // the line will grow as high as it needs to accommodate the string
```

## MGTableBox, MGTableBoxStyled

`MGTableBox` is a thin wrapper of `MGBox` which you can mostly pretend doesn't exist, unless you want to create a custom table section style. In which case you will want to subclass it.

`MGTableBoxStyled` is a styled subclass of `MGTableBox`, which provides the default table style you see in the screenshots and demo app.

When using these classes for table sections, add your rows (eg `MGLine` objects) to their `topLines`, `middleLines`, and `bottomLines` arrays (instead of the standard `boxes` set).

## MGScrollView

### MGScrollView Input Fields Above Keyboard

`MGScrollViews` will by default automatically scroll to keep any selected input field visible when the keyboard appears. You can adjust the amount of margin with the `keyboardMargin` property, and disable the feature with the `keepFirstResponderAboveKeyboard` property.

### MGScrollView Box Edge Snapping

You might like this for your project, or it might annoy you. It's one of those things.

### When You Make the Scroll View:

```objc
scroller.delegate = self;
```

### In Your ViewController.h:

Own up to being a `UIScrollViewDelegate`

```objc
@interface ViewController : UIViewController <UIScollViewDelegate>
```

### In Your ViewController.m:

```objc
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [(id)scrollView snapToNearestBox];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [(id)scrollView snapToNearestBox];
    }
}
```

## Take a Screenshot of Your Box (with OS X screenshot style drop shadow)

```objc
UIImage *screenshot = [box screenshot:0]; // 0 = device scale, 1 = old school, 2 = retina
```

## License

No need to give credit or mention `MGBox` in your app. No one reads those things anyway. The license is otherwise BSD standard.

If you want to give back, you could always [buy one of my apps](http://bigpaua.com) ;)

## More

There's a few more undocumented features, if you're the type to go poking around the source. Enjoy!
