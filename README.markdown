# MGBox2 - Simple, quick iOS Tables, Grids, and more

Designed for rapid table and grid creation with minimal code, easy customisation, attractive default styling, using modern blocks based design patterns, and without need for fidgety tweaking or awkward design patterns. 

Includes blocks based gesture recognisers, observers, control events, and custom events.

`MGBox`, `MGScrollView`, and `MGButton` can also be used as generic `UIView` wrappers to get the benefits of view padding, margins, and zIndex, amongst others.

## Layout Features

- Table layouts (similar to `UITableView`, but less fuss)
- Grid layouts (similar to `UICollectionView`, but less fuss)
- Table rows automatically layout `NSStrings`, `UIImages`, and multiline text  
- Animated adding/removing/reordering rows, items, sections, etc
- Margins, Padding, zIndex, Fixed Positioning, and more
- Optional asynchronous blocks based layout
- Optional scroll view box edge snapping

## Code Convenience Features

- Blocks based tap, swipe, and hold gesture recognisers
- Blocks based custom event observing and triggering
- Blocks based UIControl event handlers
- Blocks based keypath observers
- UIView easy frame accessors

## Example Screenshots

Complex tables, sections, and grids created with simple code.

### The Demo App:

![Demo App Screenshot 1](http://cloud.github.com/downloads/sobri909/MGBox2/DemoApp1.png)
![Demo App Screenshot 2](http://cloud.github.com/downloads/sobri909/MGBox2/DemoApp2.png)
![Demo App Screenshot 3](http://cloud.github.com/downloads/sobri909/MGBox2/DemoApp3.png)


### Created with the convenience "screenshot" method:

![IfAlarm Screenshot 1](http://cloud.github.com/downloads/sobri909/MGBox2/IfAlarm1.png)
![IfAlarm Screenshot 2](http://cloud.github.com/downloads/sobri909/MGBox2/IfAlarm2.png)

(From [IfAlarm](http://ifalarm.com))

## Setup

Add the `MGBox` folder to your project. (ARC and Xcode 4.5 are required)

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
[scroller.boxes addObject:section]`
```

#### Add Some Rows:

```objc
// a default row size
CGSize rowSize = (CGSize){304, 44};

// a header row
MGLine *header = [MGLine lineWithLeft:@"My First Table" right:nil size:rowSize];
header.leftPadding = header.rightPadding = 16;
[section.topLines addObject:header];

// a string on the left and a horse on the right
MGLine *row = [MGLine lineWithLeft:@"Left text" right:[UIImage imageNamed:@"horse"] size:rowSize];
row.leftPadding = row.rightPadding = 16;
[section.topLines addObject:row];
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
grid.contentLayoutMode = MGLayoutStackHorizontalWithWrap;
[scroller.boxes addObject:grid];
```

#### Add Some Views to the Grid:

```objc
// add ten 100x100 boxes
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

Layout the box (and all descendent boxes) without animation.

### [box layoutWithSpeed:completion:]

Same as above, but with boxes animated between previous and new computed positions, fading new boxes in, and fading removed boxes out.

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

When `layout` or `layoutWithSpeed:completion:` is called, each descendent box in the tree is positioned according to the container box's `contentLayoutMode` (ie table or grid), taking into acount the container's padding and the child's margins.

Getters and setters are provided for:

* `padding` (`UIEdgeInsets`)
* `margin` (`UIEdgeInsets`)
* `leftPadding`, `topPadding`, `rightPadding`, `bottomPadding`
* `leftMargin`, `topMargin`, `rightMargin`, `bottomMargin`

### Z-Index

The same as in CSS - a `zIndex` property of `MGBox` that affects the stacking order of boxes during layout.

### Fixed Positioning

Set a box's `fixedPosition` property to a desired `CGPoint` to force it to stay in a fixed position when its containing `MGScrollView` scrolls.

### Attached Positioning

Assign another view to a box's `attachedTo` property to force the box to position at the same origin. Optionally adjust the offset by fiddling with the box's top and left margins.

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
    if (object.isFlat) {
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

`MGButton` provides a nice easy `onControlEvent:do:` method, which frees you from the awkward muck of adding targets, selectors, etc. 

```objc
[button onControlEvent:UIControlEventTouchUpInside do:^{
    NSLog(@"i've been touched up inside. golly.");
}];
```

Ideally this would be available for all `UIControls`, rather than only `MGButton` subclasses. That's on the todo list.

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

If your custom `MGBox` has a shadow, it's useful to adjust its `shadowPath` in the `layout` method, after `[super layout]`, because shadows without shadow paths make iOS cry.

## The Difference Between 'boxes' and 'subviews'

This distinction can present an occasional trap. When `layout` or `layoutWithSpeed:completion:` are called, the layout engine only applies `MGBox` layout rules to boxes in the container's `boxes` set. All other `UIViews` in `subviews` will simply be ignored, with no `MGBox` style layout rules applied (their `zIndex` will be treated as `0`).

All `MGBoxes` that are subviews but are not in `boxes` will be removed during layout. Any `MGBoxes` in `boxes` that are not yet subviews will be added as subviews.

So as a general rule of thumb: Put `MGBoxes` into `boxes`, everything else into `subviews`, then call one of the `layout` methods when you're done. As long as you stick to that, you won't get tripped up.

## MGLine

`MGLine` is essentially a table row, although it can also be used more generically if it takes your fancy.

Although `MGLine` is an `MGBox` subclass, it instead sources its content views from `leftItems`, `middleItems`, and `rightItems`.

The items arrays can contain `NSStrings`, `UIImages`, or any arbitrary `UIViews` you want to add to the line (eg switches, sliders, buttons, etc).

### MGLine Side Precedence

The `sidePrecedence` property decides whether content on the left, right, or middle takes precedence when space runs out. `UILabels` will be shortened to fit. `UIImages` and `UIViews` will be removed from the centre outwards if there's not enough room to fit them in.

### MGLine Fonts

The `font` and `rightFont` properties define what fonts are used to wrap `NSStrings`. The `textColor` property rotates the canvas a random number of degrees. I'm not sure what `textShadowColor` does. Coffee please.

### MGLine Item Padding

The `itemPadding` property defines how much padding to apply to the left and right of each item. This is added to the `leftMargin` and `rightMargin` values of any `MGBoxes` you might have added as line items. 

## MGTableBox, MGTableBoxStyled

`MGTableBox` is a thin wrapper of `MGBox` which you can mostly pretend doesn't exist, unless you want to create a custom table section style. In which case you will want to subclass it.

`MGTableBoxStyled` is a styled subclass of `MGTableBox`, which provides the default table style you see in the screenshots and demo app.

When using these classes for table sections, add your rows (eg `MGLine` objects) to their `topLines`, `middleLines`, and `bottomLines` arrays (instead of the standard `boxes` set).

## MGScrollView Box Edge Snapping

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

#### More

There's a few more undocumented features, if you're the type to go poking through the source. Enjoy!
