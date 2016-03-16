//
//  AACarView.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrafficFSMUtilities.h"

@class CarController;
@interface CarView : UIView

-(void)setApproachDir:(AApproachDirs)approach;
-(AApproachDirs)approachDir;

-(void)moveInApproachDir:(CGFloat)units;

@property (nonatomic, weak) CarView *stopped_behind;

@property (nonatomic, weak) CarController *containingCar;

@property (nonatomic) BOOL stopped;
@property (nonatomic) BOOL trafficFsmRequiresTransform;

@property (nonatomic, strong) UIColor *overrideColor;

@end
