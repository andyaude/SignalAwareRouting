//
//  AAStopLight.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StopLightView : UIView

typedef enum  {
    RED_LIGHTUNIT,
    YELLOW_LIGHTUNIT,
    GREEN_LIGHTUNIT,
    YELLOW_ARROW_LIGHTUNIT,
    RED_ARROW_LIGHTUNIT
} AALightUnitColor;

typedef enum
{
    NS_DIRECTION,
    EW_DIRECTION,
    
} AATrafficLightDirection;

- (void)setColor:(AALightUnitColor) color;
- (AALightUnitColor)lightColor;


@property (nonatomic) AATrafficLightDirection light_direction;

@end
