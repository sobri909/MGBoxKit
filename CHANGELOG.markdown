## 5.0.2

### Fixes

- Fixed bufferedViewport for scrollers not at origin 0,0
  
## 5.0.1

- Minor import change to use single MGEvents import

## 5.0.0

### Enhancements

- Separated `MGEvents` into a separate CocoaPod and added it as a dependency

- `MGBoxProvider` box reuse now includes a "type", allowing for multiple 
  classes of boxes in a single container.

- new box block properties `onWillMoveToIndex`, `onMovedToIndex` triggered 
  during when box index positions change.

- Optimised box reuse code for smoother scrolling.

- `MGMushParser` caches `CTFont` instances for better performance.

### Upgrading

- The `MGBoxProvider` API changed, to accommodate box reuse "types". Your 
  `boxProvider` code will need adjusting to accommodate.

### Fixes

- `MGScrollView` offset correction on rotate accounts for `contentInsets`

- Fixed box/scroller post layout resizing to use `bottomPadding` and 
  `rightPadding`

- Boxes laid out via `MGBoxProvider` now properly respect their `zIndex` 
  values.
  
## 4.0.0

### Enhancements

- When using a `boxProvider`, your data's state is tracked internally, thus 
  eliminating the need to inform the provider of data changes. To use auto 
  change tracking, you need to set a `boxProvider.boxKeyMaker` block property
  that returns a unique key for each data item. Call `layout` or 
  `layoutWithDuriation:completion:` and the provider will automatically 
  perform the appropriate appear/move/disappear animations based on data changes.
  
- You can now provide custom animations for appear/move/disappear when using a 
  `boxProvider`. See 
  [#116](https://github.com/sobri909/MGBoxKit/issues/116#issuecomment-40798628) 
  for details.

- New `MGScrollView methods `saveScrollOffset` and `restoreScrollOffset` for 
  ensuring that tables/grids fall in the same visible offset after rotation.  
  See [#124](https://github.com/sobri909/MGBoxKit/issues/124) for example code.

### Upgrading

- `layoutWithSpeed:completion:` has been deprecated in favour of 
  `layoutWithDuration:completion:`. I've been wanting to do that since forever.

- `boxProvider.boxSizeMaker` should now return sizes without margins. Margins 
  are now provided separately by `boxProvider.boxMarginMaker`.

## 3.2.2

### Fixes

- `MGBoxProvider` and `MGLayoutManager` fixes for keeping internal box reuse 
  data clean
 
## 3.2.1

### Fixes

- `MGBoxProvider` bug fix for updating visible indexes during fast scrolling 

## 3.2.0 

### Enhancements

- Added `appeared` and `disappeared` methods and `onAppear` and `onDisappear` 
  block properties which fire when a box is automatically added or removed 
  during box reuse / offscreen culling.

## 3.1.0

### Enhancements

- Added `[self when:object does:Something do:Thing]` custom event observing. 
  See [#118](https://github.com/sobri909/MGBoxKit/issues/118) for details.

## 3.0.0

### Upgrading

- the `screenshot:` method changed signature to `screenshotWithShadow:scale:`

### Enhancements

- `MGBoxProvider` box reuse and offscreen culling, allowing for much larger 
  tables/grids
- `MGLine` can auto resize the width of `UITextField` items to fit
- new setters for `top`, `right`, `bottom`, `topLeft` etc
- arm64 fixes

## 2.1.0

#### Upgrading

- There shouldn't be any backwards compatibility breaks. Please let me know if 
  you find any!
- Note that the project, repo, and folders have been renamed to **MGBoxKit**

#### Enhancements

- Optional non-recursive layout: `dontLayoutChildren`
- Optional `minWidth` property
- Text colour Mush markup: "this string has {#123456|coloured text}"
- New block properties for `onTouchesBegan`, `onTouchesEnded`,  
  `onTouchesCancelled`
- New UIView convenience CGFloat getters for `top`, `right`, `bottom`, `left`
- New line spacing properties for MGLine content: `leftLineSpacing`, 
  `middleLineSpacing`, `rightLineSpacing`

## 2.0.0

#### Upgrading

- `MGBox` now requires the `CoreText` framework. Add this to your project.
- Also add these new files to your project:
  - `MGLineStyled.m/h`
  - `MGMushParser.m/h`
  - `Categories/NSAttributedString+MGTrim.m/h`
  - `Categories/UIColor+MGExpanded.m/h`
- `MGLine` now has a default `underlineType` of none. For tables using 
  `MGTableBoxStyled`, replace `MGLine` with `MGLineStyled`, or set your 
  `MGLine` instances to have a `borderStyle` of `MGBorderEtchedTop | MGBorderEdgedBottom`.

#### Enhancements

- **Mush Lightweight Markup**
  - Markup similar to Markdown/Textile, providing bold, italic, underline, and 
    monospace.  
- **MGLine Now Accepts NSAttributedStrings**
- **MGBox Borders**
  - Set individual border colours with `topBorderColor`, `rightBorderColor`, 
    `bottomBorderColor`, `leftBorderColor`.
  - Set all border colours in one go with `borderColors`.
  - Optionally modify borders directly with `topBorder`, `rightBorder`, 
    `bottomBorder`, `leftBorder`.
- **MGBox Etched Border Style**
  - `borderStyle` property replaces the deprecated `underlineType`, and is 
    available in all `MGBox` subclasses. Allows an etched border style 
    optionally for top/right/bottom/left.      
- **New MGLine Text Style Properties**
  - Properties for left/middle/right text colours, shadow colours, shadow 
    offsets, alignments.

See the documentation for usage examples of the new APIs.

#### Deprecated

- `-[MGLine underlineType]`, replaced by `-[MGBox borderStyle]`
