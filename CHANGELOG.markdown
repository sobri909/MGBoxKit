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
