//
//  Created by matt on 9/06/12.
//

#import "MGBox.h"

/**
* `MGTableBox` is a thin wrapper of `MGBox` that provides different storage sets
* for child boxes, as replacements for the standard [boxes](-[MGLayoutBox boxes])
* array.
*
* [boxes](-[MGLayoutBox boxes]) is replaced by topLines, middleLines, bottomLines,
* to provide a convenient way to organise table rows in table sections. For
* example you might store a section header in topLines, store the footer
* in bottomLines, and use middleLines for the main content table rows.
*
* @warning When using an `MGTableBox` you can't add child boxes to the standard
* [boxes](-[MGLayoutBox boxes]) array, as its contents will be replaced by the
* contents of topLines, middleLines, and bottomLines on each
* [layout](-[MGLayoutBox layout]) call. You must instead use the replacement sets.
*/
@interface MGTableBox : MGBox

/** @name Alternative content sets */

/**
* Table rows to be displayed at the top of the table (eg a table header).
*
* @note See the [boxes](-[MGLayoutBox boxes]) documentation for usage details.
*/
@property (nonatomic, retain) NSMutableOrderedSet *topLines;

/**
* Table rows to be displayed below topLines and above bottomLines in the table.
*
* @note See the [boxes](-[MGLayoutBox boxes]) documentation for usage details.
*/
@property (nonatomic, retain) NSMutableOrderedSet *middleLines;

/**
* Table rows to be displayed at the bottom of the table (eg a table footer).
*
* @note See the [boxes](-[MGLayoutBox boxes]) documentation for usage details.
*/
@property (nonatomic, retain) NSMutableOrderedSet *bottomLines;

/**
* Returns an ordered set containing the contents of topLines, middleLines,
* and bottomLines.
*/
- (NSOrderedSet *)allLines;

@end
