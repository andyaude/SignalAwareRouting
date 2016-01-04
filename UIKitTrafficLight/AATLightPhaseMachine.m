//
//  AATLightPhaseMachne.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "AATLightPhaseMachine.h"

// NS_PHASE,
//EW_PHASE,
//
//// All red
//ALL_RED_TURNING_NS,
//ALL_RED_TURNING_EW

NSString *nameForPhaseEnum(AATIntersectionPhase phase) {
    switch (phase) {
        case NS_PHASE:
            return @"North/South Green";
            break;
        case EW_PHASE:
            return @"East/West Green";
            break;
        case ALL_RED_TURNING_NS:
            return @"All red, turning NS green";
            break;
        case ALL_RED_TURNING_EW:
            return @"All red, turning EW green";
            break;
        default:
            return @"Undefined phase";
            break;
    }
    return nil;
}


@interface AATLightPhaseMachine ()
@property (nonatomic) NSTimeInterval master_time_interval;
@end
@implementation AATLightPhaseMachine

- (instancetype) init {
    self = [super init];
    if (!self) return nil;
    
    self.ewPhase = 10.0;
    self.nsPhase = 10.0;
    self.all_red_duration = 1.0; // CHANGEME 1 to 4
    self.yellow_duration = 3.0; // CHANGEME
    
    return self;
}

- (float)getCurrentPhaseProgress {
    switch (self.phase) {
        case NS_PHASE:
            return self.current_phase_time_interval/self.nsPhase;
        case EW_PHASE:
            return self.current_phase_time_interval/self.ewPhase;

        case ALL_RED_TURNING_EW:
        case ALL_RED_TURNING_NS:
            return self.current_phase_time_interval/self.all_red_duration;

        default:
            return -1.0f;
            break;
    }

}

- (void)setNewPhase: (AATIntersectionPhase)phase {
    NSLog(@"Set new phase: %@", nameForPhaseEnum(phase));
    self.phase = phase;
    self.current_phase_yellow = NO;
    self.current_phase_time_interval = 0;
}

- (AATIntersectionPhase)nextPhaseForTurningPhase:(AATIntersectionPhase)phase {
    assert (phase == ALL_RED_TURNING_NS || phase == ALL_RED_TURNING_EW);
    if (phase == ALL_RED_TURNING_NS) return NS_PHASE;
    else return EW_PHASE;
}

- (BOOL)shouldAdvanceToYellowPhase: (AATrafficLightDirection)dir {
    if (dir == NS_DIRECTION) {
        
        if (self.phase == NS_PHASE) {
            if (self.current_phase_time_interval >= self.nsPhase - self.yellow_duration)
                return YES;
        }
        
    } else if (dir == EW_DIRECTION) {
        if (self.phase == EW_PHASE) {
            if (self.current_phase_time_interval >= self.ewPhase - self.yellow_duration)
                return YES;
        }
    }
    
    return NO;
}

- (void)setPhaseForMasterTimeInterval:(NSTimeInterval)time {
    
    NSTimeInterval curDiff = time - self.master_time_interval;
    
    self.master_time_interval = time;
    
    self.current_phase_time_interval += curDiff;
    
    
    // When All RED turns over to a new direction
    if (self.phase == ALL_RED_TURNING_NS || self.phase == ALL_RED_TURNING_EW) {
        if (self.current_phase_time_interval >= self.all_red_duration) {
            [self setNewPhase:[self nextPhaseForTurningPhase:self.phase]];
            
        }
    }
    
    // NS Green
    if (self.phase == NS_PHASE) {
        // Turn Green to Yellow
        if ([self shouldAdvanceToYellowPhase:NS_DIRECTION]) {
            self.current_phase_yellow = YES;
        }
        
        // Yellow->Red
        if (self.current_phase_time_interval >= self.nsPhase) {
            [self setNewPhase:ALL_RED_TURNING_EW];
        }
    }

    // EW Green
    else if (self.phase == EW_PHASE) {
        // Turn Greens to Yellow
        if ([self shouldAdvanceToYellowPhase:EW_DIRECTION]) {
            self.current_phase_yellow = YES;
        }
        
        // Yellow->Red
        if (self.current_phase_time_interval >= self.ewPhase) {
            [self setNewPhase:ALL_RED_TURNING_NS];
        }
    }
    
    
}

- (AALightUnitColor)lightColorForDirection:(AATrafficLightDirection)direction {
    
//    NSLog(@"Self.phase = %d and curPhaseInterval: %.2f", self.phase, self.current_phase_time_interval);
    
    if (direction == NS_DIRECTION) {
        
        if (self.phase == NS_PHASE) {
            return self.current_phase_yellow ? YELLOW_LIGHTUNIT : GREEN_LIGHTUNIT;
        }
        
        
    } else if (direction == EW_DIRECTION) {
        
        if (self.phase == EW_PHASE) {
            return self.current_phase_yellow ? YELLOW_LIGHTUNIT : GREEN_LIGHTUNIT;
        }
    }
    
    // all red turning, or not your turn.
    return RED_LIGHTUNIT;
}


@end