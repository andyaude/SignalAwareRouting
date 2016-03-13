//
//  AATLightPhaseMachne.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StopLightView.h"

@interface LightPhaseMachine : NSObject {
    NSTimeInterval _nextEWTime;
    NSTimeInterval _nextNSTime;
}

typedef enum
{
    NS_PHASE,
    EW_PHASE,
    
    // All red
    ALL_RED_TURNING_NS,
    ALL_RED_TURNING_EW
    
    // Left turn arrows?
} AATIntersectionPhase;

@property BOOL current_phase_yellow;


-(void)setPhaseForMasterTimeInterval:(NSTimeInterval)time;
- (float)getCurrentPhaseProgress;


// You shouldn't need this... Deprecated
- (NSTimeInterval)getMasterInterval;

@property (nonatomic) NSTimeInterval phase_offset;

@property (nonatomic) NSTimeInterval current_phase_time_interval;

// Starts out in NS Green (start of cycle)
@property (nonatomic) NSTimeInterval ewPhase;
@property (nonatomic) NSTimeInterval nsPhase;

@property (nonatomic) AATIntersectionPhase phase;

@property (nonatomic) NSTimeInterval yellow_duration;
@property (nonatomic) NSTimeInterval all_red_duration;


- (AALightUnitColor)lightColorForDirection:(AATrafficLightDirection)phase;

#warning this is totally wrong!
- (double)predictWaitTimeForMasterInterval:(NSTimeInterval)time andTrafficDir:(AATrafficLightDirection)dir;

// Adaptive timing!
- (void)setNextNSToDuration:(NSTimeInterval)interval;
- (void)setNextEWToDuration:(NSTimeInterval)interval;
// For info purposes only
- (NSTimeInterval)getNextNSPhase;
- (NSTimeInterval)getNextEWPhase;



@end
