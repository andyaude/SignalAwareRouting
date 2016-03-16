//
//  IntersectionNode.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "IntersectionNode.h"
#import "LightPhaseMachine.h"
#import "StreetEdge.h"
#import "CarController.h"

@implementation IntersectionNode


- (CGPoint)getLongLat {
    return CGPointMake(self.longitude, self.latitude);
}
// Rewrite dijkstra to consider time/path.
// Verify the algorithm??
// Draw a little car that can follow the routes?

// Logic to determine direction vector (normalize this), then move the car along it. Also can rotate the car appropriately.

// Make car aware of other cars.

- (float)calculateTurnPenaltyForInPort:(PortDirection)inp outPort:(PortDirection)outp {
    
    LightPhaseMachine *lightPhase = self.light_phase_machine;
    
    double totalPhaseLen = (lightPhase.nsPhase + lightPhase.ewPhase) + 1;
    double percentOfTimeEast = lightPhase.ewPhase / totalPhaseLen;
    double percentOfTimeNorth = 1 - percentOfTimeEast;
    
    if ((inp == NORTH_PORT && outp == NORTH_PORT)
        || (inp == SOUTH_PORT && outp == SOUTH_PORT)
        || (inp == EAST_PORT && outp == EAST_PORT)
        || (inp == WEST_PORT && outp == WEST_PORT))
        
        // U-Turn delay
        return (lightPhase.nsPhase + lightPhase.ewPhase)/2.;
    
    
    // Entering north/South...
    if (inp == NORTH_PORT || inp == SOUTH_PORT) {
        return percentOfTimeEast * lightPhase.ewPhase; // expected num seconds? // clear for (percent time in NS) * 0 + percent time in EW * EW
    }
    else {
        return percentOfTimeNorth * lightPhase.nsPhase;
    }

    

    
        
}


- (float)calculateRealtimePenalty:(PortDirection)inp outPort:(PortDirection)outp withRealTimestamp:(NSTimeInterval)times {
    
    LightPhaseMachine *lightPhase = self.light_phase_machine;
    
    if ((inp == NORTH_PORT && outp == NORTH_PORT)
        || (inp == SOUTH_PORT && outp == SOUTH_PORT)
        || (inp == EAST_PORT && outp == EAST_PORT)
        || (inp == WEST_PORT && outp == WEST_PORT))
        
        // U-Turn delay
        // Forever and a half, basically. Downrank. TODO FIX
        return (lightPhase.nsPhase + lightPhase.ewPhase)/2.;
    
    if ((inp == NORTH_PORT && outp == SOUTH_PORT)
        || (inp == SOUTH_PORT && outp == NORTH_PORT)
        || (inp == EAST_PORT && outp == WEST_PORT)
        || (inp == WEST_PORT && outp == EAST_PORT)) {
        
        // STRAIGHT THRU delays
        if (inp == NORTH_PORT || inp == SOUTH_PORT)
            return [lightPhase predictWaitTimeForMasterInterval:times andTrafficDir:NS_DIRECTION];
        else return [lightPhase predictWaitTimeForMasterInterval:times andTrafficDir:EW_DIRECTION];
    }
    
    
    
    if ((inp == NORTH_PORT && outp == WEST_PORT)
        || (inp == SOUTH_PORT && outp == EAST_PORT)
        || (inp == EAST_PORT && outp == NORTH_PORT)
        || (inp == WEST_PORT && outp == SOUTH_PORT)) {
        
        // RIGHT Turn Delay
        if (inp == NORTH_PORT || inp == SOUTH_PORT)
            return [lightPhase predictWaitTimeForMasterInterval:times andTrafficDir:NS_DIRECTION];
        else return [lightPhase predictWaitTimeForMasterInterval:times andTrafficDir:EW_DIRECTION]; // 2.0 for right turn on red
    }
    
    
    if ((inp == NORTH_PORT && outp == EAST_PORT)
        || (inp == SOUTH_PORT && outp == WEST_PORT)
        || (inp == EAST_PORT && outp == SOUTH_PORT)
        || (inp == WEST_PORT && outp == NORTH_PORT)) {
        
        // LEFT Turn Delay
        if (inp == NORTH_PORT || inp == SOUTH_PORT)
            return [lightPhase predictWaitTimeForMasterInterval:times andTrafficDir:NS_DIRECTION] * 1.0;
        else return [lightPhase predictWaitTimeForMasterInterval:times andTrafficDir:EW_DIRECTION] * 1.0; // Extra wait for left turns. Scalar should depend on probe data traffic loads. :/
    
    }
    NSLog(@"Uh, this shouldn't happen");
    NSAssert(0, @"Invalid turn direction");
    return 100.0;
    
    
}

// Ever minute a car spends at an intxn increases the urgency/priority of the edge in the system
- (NSUInteger)getCountForIntxn:(IntersectionNode *)intxn andPort:(StreetEdge *)port andTimeSpentWaiting:(BOOL)timeSpentWaiting{
    
    if(port) {
        BOOL isA_B = port.intersectionA == intxn;
        NSArray *theArray = isA_B ? port.BACars : port.ABCars;
        // if true intxn --> B... then we are itnerested in B-A> cars.
        if (!timeSpentWaiting)
            return [theArray count];
        else {
            int penalties = 0;
            
            for (NSUInteger i = 0; i < theArray.count; i++) {
                penalties += [theArray[i] getTimeSpentWaitingOnThisEdge] / 60;
            }
            return [theArray count] + penalties;
            
            // Counts how many cars have waited an egregious time
//            NSUInteger baseNumCars = [theArray count];
//            NSUInteger waitersPenalty = [[theArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
//                CarAndView *car = (CarAndView *)evaluatedObject;
//                return [car getTimeSpentWaitingOnThisEdge] > 90; // waiting longer than 90?
//            }]] count] * 3;
//            return baseNumCars + waitersPenalty;
        }
        
    }

    
    return 0;
    
}

- (double)getPrescientCountForIntxn:(IntersectionNode *)intxn andPort:(StreetEdge *)port {
    
    if(port) {
        
        double scaled_count = 0;
        
        BOOL isA_B = port.intersectionA == intxn;
        // if true intxn --> B... then we are itnerested in B-A> cars.
        NSArray *carsOnAB = port.futureBACars;

        if (!isA_B)
            carsOnAB = port.futureABCars;
    
        for (int i = 0; i < carsOnAB.count; i++) {
            CarController *car = carsOnAB[i];
            int num_steps = [car numStepsUntilEdge:port];
            // count of prescient cars!
            scaled_count += 1.0 / (double) num_steps / (double)(num_steps) ;
        }
        

        return scaled_count;
    }
    
    
    return 0;
    
}

// Set queued to NO if you want all cars on link, not just the queued ones.
- (NSUInteger)countIncomingCarsQueued:(BOOL)queued andIsNS:(BOOL)isNS andIntxn:(IntersectionNode *)intxn{
    
    int count = 0;
    
    if (!isNS) {
        
        count += [self getCountForIntxn:intxn andPort:intxn.e_port andTimeSpentWaiting:queued];
        count += [self getCountForIntxn:intxn andPort:intxn.w_port andTimeSpentWaiting:queued];
        
    } else {
        count += [self getCountForIntxn:intxn andPort:intxn.n_port andTimeSpentWaiting:queued];
        count += [self getCountForIntxn:intxn andPort:intxn.s_port andTimeSpentWaiting:queued];
    }
    return count;
}

- (double)countPrescientCarsAndisNS:(BOOL)isNS andIntxn:(IntersectionNode *)intxn{
    
    double count = 0;
    
    if (!isNS) {
        
        count += [self getPrescientCountForIntxn:intxn andPort:intxn.e_port];
        count += [self getPrescientCountForIntxn:intxn andPort:intxn.w_port];
        
    } else {
        count += [self getPrescientCountForIntxn:intxn andPort:intxn.n_port];
        count += [self getPrescientCountForIntxn:intxn andPort:intxn.s_port];
    }
    return count;
}

- (NSSet *)getEdgeSet {
    NSMutableSet *arr = [NSMutableSet new];
    if (self.n_port) [arr addObject:self.n_port];
    if (self.s_port) [arr addObject:self.s_port];
    if (self.e_port) [arr addObject:self.e_port];
    if (self.w_port) [arr addObject:self.w_port];
    return arr;
}

- (void)createPhaseMachineIfNeeded {
    _light_phase_machine = [[LightPhaseMachine alloc] init];
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self createPhaseMachineIfNeeded];
    }
    return self;
}

+ (IntersectionNode *)nodeWithIdentifier:(NSString *)anIdentifier andLatitude:(double)latitude andLongitude:(double)longitude {
    
    IntersectionNode *aNode = [[IntersectionNode alloc] init];
    
    aNode.identifier = anIdentifier;
    aNode.longitude = longitude;
    aNode.latitude = latitude;
    
    return aNode;
}

- (void)nillifyPortWithThisEdge:(StreetEdge *)edge {
    if (self.n_port == edge) self.n_port = nil;
    if (self.s_port == edge) self.s_port = nil;
    if (self.e_port == edge) self.e_port = nil;
    if (self.w_port == edge) self.w_port = nil;
}


@end
