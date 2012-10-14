//
//  Created by matt on 9/06/12.
//

#import "MGBox.h"

@interface MGTableBox : MGBox

@property (nonatomic, retain) NSMutableOrderedSet *topLines;
@property (nonatomic, retain) NSMutableOrderedSet *middleLines;
@property (nonatomic, retain) NSMutableOrderedSet *bottomLines;

- (NSOrderedSet *)allLines;

@end
