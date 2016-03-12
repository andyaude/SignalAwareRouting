//
//  AAStopLight.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "StopLightView.h"

#define OFF 0.0f
#define DIM 0.30f

@interface StopLightView () {
    bool hasLeftArrow;
    AALightUnitColor _state;
}
@end

@implementation StopLightView


- (void)setupSelf {
    self.backgroundColor = [UIColor lightGrayColor];
    hasLeftArrow = NO;
    _state = RED_LIGHTUNIT;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    [self setupSelf];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return nil;
    [self setupSelf];
    return self;
}

- (UIColor *)activeRedColor {
    if (_state == RED_LIGHTUNIT)
        return [UIColor redColor];
    return [UIColor colorWithRed:DIM green:OFF blue:OFF alpha:1.0];
}

- (UIColor *)activeYellowColor {
    if (_state == YELLOW_LIGHTUNIT)
        return [UIColor yellowColor];
    return [UIColor colorWithRed:DIM green:DIM blue:OFF alpha:1.0];
    
}
- (UIColor *)activeGreenColor {
    if (_state == GREEN_LIGHTUNIT)
        return [UIColor greenColor];
    return [UIColor colorWithRed:OFF green:DIM blue:OFF alpha:1.0];
    
    
}


#define SCALAR .6
- (void)sizeToFit {
    
    CGRect oldFrame = self.frame;
    oldFrame.size = CGSizeMake(30*SCALAR, 100*SCALAR);
    self.frame = oldFrame;

}

- (BOOL)isFlipped {
    return NO;
}

- (void)drawRect:(CGRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    
    // Dark traffic light outline
    [[UIColor blackColor] setStroke];

    // Top Light
    CGRect rect = CGRectMake(4*SCALAR, 4*SCALAR, 20*SCALAR, 20*SCALAR);
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:rect];
    [[self activeRedColor] setFill];
    [circlePath stroke];
    [circlePath fill];
    
    // Center Light
    rect.origin.y += 30*SCALAR;
    UIBezierPath *circlePath2 = [UIBezierPath bezierPathWithOvalInRect:rect];
    [[self activeYellowColor] setFill];
    [circlePath2 stroke];
    [circlePath2 fill];
    
    // Green Light
    rect.origin.y += 30*SCALAR;
    UIBezierPath *circlePath3 = [UIBezierPath bezierPathWithOvalInRect:rect];
    [[self activeGreenColor] setFill];
    [circlePath3 stroke];
    [circlePath3 fill];

    
//    NSLog(@"Called to draw, state :%d", _state);
}


NSString *colorForEnum(AALightUnitColor color) {
    switch (color) {
        case GREEN_LIGHTUNIT:
            return @"Green";
            break;
        case YELLOW_LIGHTUNIT:
            return @"Yellow";
            break;
        case RED_LIGHTUNIT:
            return @"Red";
            break;
        default:
            break;
    }
    return nil;
}

- (AALightUnitColor)lightColor; {
    return _state;
}

- (void)setColor:(AALightUnitColor) color {
    
    BOOL old_diff_new = color != _state;
    _state = color;
    [self setNeedsDisplayInRect:self.bounds];
    //    [self displayIfNeeded];
    if (old_diff_new)
        NSLog(@"Color was set successfully to %@ for phase %s", colorForEnum(color), self.light_direction == NS_DIRECTION ? "North/South" : "East/West");
}


@end
