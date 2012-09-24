//
//  Created by matt on 9/06/12.
//

#import "MGBox.h"

@interface MGTableBox : MGBox

@property (nonatomic, retain) NSMutableArray *topLines;
@property (nonatomic, retain) NSMutableArray *middleLines;
@property (nonatomic, retain) NSMutableArray *bottomLines;
@property (nonatomic, retain) UIView *content;

@end
