//
//  AARoadModelViewUtils.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AACarView;

@interface AARoadModelViewUtils : NSObject

typedef enum {
    NORTH_APPROACH,
    SOUTH_APPROACH,
    EASTWARD_APPROACH,
    WESTWARD_APPROACH
} AApproachDirs;


// NSArray of road/uiview thingies?
// Or make a road UIView subclass?
+(CGPoint)stopLineForRoads:(NSArray *)roads andApproachDir:(AApproachDirs)dir andCarSize:(CGFloat)squareSize;
+(CGPoint)getBaseCoordinateForRoads:(NSArray *)roads andApproachDir:(AApproachDirs)dir;
+(AACarView *)getNextCarAhead:(AACarView *)curCar allCars:(NSArray *)allCars;


@end
