//
//  AACarView.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AARoadModelViewUtils.h"

@class CarAndView;
@interface AACarView : UIView

-(void)setApproachDir:(AApproachDirs)approach;
-(AApproachDirs)approachDir;

-(void)moveInApproachDir:(CGFloat)units;

@property (nonatomic, weak) AACarView *stopped_behind;

@property (nonatomic, weak) CarAndView *containingCar;

@property (nonatomic) BOOL stopped;

@property (nonatomic, strong) UIColor *overrideColor;

@end
