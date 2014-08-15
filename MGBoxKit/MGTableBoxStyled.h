//
//  Created by Matt Greenfield on 24/05/12
//  http://bigpaua.com/
//

#import "MGTableBox.h"

/**
* `MGTableBoxStyled` is a thin wrapper of MGTableBox, providing default size,
* background colour, shadow, and corner rounding. The styling is designed to
* provide a table section style similar to pre iOS 7 `UITableView` grouped style.
* It also serves as a basic subclassing example (take a look at
* `MGTableBoxStyled.m` for example `setup` and `layout` methods).
*
* @deprecated The superclass is no longer maintained. This class should only be
* used as a loose example of subclasssing.
*/

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

__deprecated @interface MGTableBoxStyled : MGTableBox

@end

#pragma clang diagnostic pop
