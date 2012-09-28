//
//  Created by matt on 12/08/12.
//

@interface UIView (MGEasyFrame)

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;

- (CGPoint)topLeft;
- (CGPoint)topRight;
- (CGPoint)bottomRight;
- (CGPoint)bottomLeft;

@end
