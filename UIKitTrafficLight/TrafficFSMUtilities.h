//
//  AARoadModelViewUtils.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CarView;

@interface TrafficFSMUtilities : NSObject

typedef enum {
    NORTH_APPROACH,
    SOUTH_APPROACH,
    EASTWARD_APPROACH,
    WESTWARD_APPROACH
} AApproachDirs;


+(CGPoint)stopLineForRoads:(NSArray *)roads andApproachDir:(AApproachDirs)dir andCarSize:(CGFloat)squareSize;
+(CGPoint)getBaseCoordinateForRoads:(NSArray *)roads andApproachDir:(AApproachDirs)dir;
+(CarView *)getNextCarAhead:(CarView *)curCar allCars:(NSArray *)allCars;


@end
