//
//  AARoadModelViewUtils.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "TrafficFSMUtilities.h"
#import "CarView.h"

@implementation TrafficFSMUtilities

+(UIView *)chooseNSRoad:(NSArray *)roads {
    assert(roads.count == 2);
    
    UIView *roadCandidate = roads[0];
    if (roadCandidate.frame.size.height > roadCandidate.frame.size.width)
        return roadCandidate;
    else
        return roads[1];
}

+(UIView *)chooseEWRoad:(NSArray *)roads {
    assert(roads.count == 2);
    UIView *roadCandidate = roads[0];
    if (roadCandidate.frame.size.width > roadCandidate.frame.size.height)
        return roadCandidate;
    else
        return roads[1];
}


+(CarView *)getNextCarAhead:(CarView *)curCar allCars:(NSArray *)allCars {
    
    AApproachDirs approach = [curCar approachDir];
    
    CGPoint curCarCenter = curCar.center;
    
    CarView *nextGuy = nil;
    
    CGFloat smallest_pos_ahead_dist = -1;
    
    for (CarView *car in allCars) {
        if ([car approachDir] != approach || curCar == car) continue;
        CGPoint candidateCenter = car.center;
        
        CGFloat nextAheadBy = CGFLOAT_MAX;
        
        if (approach == NORTH_APPROACH) {
            
            // candidate has higher y, is more southbound
            if (candidateCenter.y >= curCarCenter.y) continue;
            
            // Down - less down
            nextAheadBy = curCarCenter.y - candidateCenter.y;

        } else if (approach == SOUTH_APPROACH) {
            // candidate has lower y, is more northbound
            if (candidateCenter.y <= curCarCenter.y) continue;
            nextAheadBy = candidateCenter.y - curCarCenter.y;
            
        } else if (approach == WESTWARD_APPROACH) {
            // candidate has lower y, is more northbound
            if (candidateCenter.x >= curCarCenter.x) continue;
            nextAheadBy = curCarCenter.x - candidateCenter.x;
            
        } else if (approach == EASTWARD_APPROACH) {
            if (candidateCenter.x <= curCarCenter.x) continue;
            nextAheadBy = candidateCenter.x - curCarCenter.x;
            
        }
        
        assert(nextAheadBy != CGFLOAT_MAX && nextAheadBy >= 0);
        
        if (!nextGuy) {
            nextGuy = car;
            smallest_pos_ahead_dist = nextAheadBy;
        } else {
            if (nextAheadBy < smallest_pos_ahead_dist) {
                nextGuy = car;
                smallest_pos_ahead_dist = nextAheadBy;
            }
        }
        
        
    }
    
    return nextGuy;
    
}


+(CGPoint)getBaseCoordinateForRoads:(NSArray *)roads andApproachDir:(AApproachDirs)dir {
    assert(roads.count == 2);
    UIView *northRoad = [self chooseNSRoad:roads];
    UIView *eastRoad = [self chooseEWRoad:roads];
    
    if (dir == NORTH_APPROACH) {
        
        CGPoint base = northRoad.center;
        float center_right_lane = base.x + northRoad.bounds.size.width/8.0;
        float min_y_coord = northRoad.frame.origin.y + northRoad.frame.size.height - 20.0; // bottom
        return (CGPoint) {center_right_lane, min_y_coord};
        
    } else if (dir == SOUTH_APPROACH) {
        CGPoint base = northRoad.center;
        float center_right_lane = base.x - northRoad.bounds.size.width/2.0;
        float min_y_coord = northRoad.frame.origin.y; // TOP
        return (CGPoint) {center_right_lane, min_y_coord};
        
    } else if (dir == WESTWARD_APPROACH) {
        CGPoint base = eastRoad.center;
        float center_right_lane = base.y - eastRoad.bounds.size.height/2.0 + 3;
        float start_x_coord = eastRoad.frame.origin.x + eastRoad.frame.size.width; // far right
        return (CGPoint) {start_x_coord, center_right_lane};
        
    } else if (dir == EASTWARD_APPROACH) {
        CGPoint base = eastRoad.center;
        float center_right_lane = base.y + eastRoad.bounds.size.height/8.0;
        float start_x = eastRoad.frame.origin.x; // far left
        return (CGPoint) {start_x, center_right_lane};

        
    } else {
        NSAssert(0, @"Invalid approach direction");
        return CGPointZero;
    }
}

// Warning: Sensitive to placement in larger container
+(CGPoint)stopLineForRoads:(NSArray *)roads andApproachDir:(AApproachDirs)dir andCarSize:(CGFloat)squareSize {
    
    UIView *northRoad = [self chooseNSRoad:roads];
    UIView *eastRoad = [self chooseEWRoad:roads];
    
    // If this is buggy, reason the whole thing through again??
    if (dir == NORTH_APPROACH) {
        CGFloat upwardYLim = eastRoad.frame.origin.y + eastRoad.frame.size.height;
        return (CGPoint){ -1.0, upwardYLim };
    } else if (dir == SOUTH_APPROACH) {
        CGFloat downwardYLim = eastRoad.frame.origin.y - squareSize;
        return (CGPoint){ -1.0, downwardYLim };
    } else if (dir == EASTWARD_APPROACH) {
        CGFloat maxRightwardXLim = northRoad.frame.origin.x - squareSize;
        return (CGPoint){ maxRightwardXLim, -1.0 };

    } else if (dir == WESTWARD_APPROACH) { // WEST APPRAOCH
        CGFloat minLeftwardXLim = northRoad.frame.origin.x + northRoad.frame.size.width;
        return (CGPoint){ minLeftwardXLim, -1.0 };
    }
    else {
        NSAssert(0, @"Invalid approach direction");
        return CGPointZero;
    }
    
}


@end
