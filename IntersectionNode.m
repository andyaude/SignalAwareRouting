//
//  IntersectionNode.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "IntersectionNode.h"
#import "LightPhaseMachine.h"

@implementation IntersectionNode


- (CGPoint)getLatLong {
    return CGPointMake(self.longitude, self.latitude);
}
// Rewrite dijkstra to consider time/path.
// Verify the algorithm??
// Draw a little car that can follow the routes?

// Logic to determine direction vector (normalize this), then move the car along it. Also can rotate the car appropriately.

// Make car aware of other cars.

#warning todo:Assuming 60 second phase
- (float)calculateTurnPenaltyForInPort:(PortDirection)inp outPort:(PortDirection)outp {
    
    LightPhaseMachine *lightPhase = self.light_phase_machine;
    
    double totalPhaseLen = (lightPhase.nsPhase + lightPhase.ewPhase) + 1;
    
    if ((inp == NORTH_PORT && outp == NORTH_PORT)
        || (inp == SOUTH_PORT && outp == SOUTH_PORT)
        || (inp == EAST_PORT && outp == EAST_PORT)
        || (inp == WEST_PORT && outp == WEST_PORT))
        
        // U-Turn delay
        return (lightPhase.nsPhase + lightPhase.ewPhase)/2.; // calculate based on stop light average timing OR ACTUAL timing
    
//    if ((inp == NORTH_PORT && outp == SOUTH_PORT)
//        || (inp == SOUTH_PORT && outp == NORTH_PORT)
//        || (inp == EAST_PORT && outp == WEST_PORT)
//        || (inp == WEST_PORT && outp == EAST_PORT)) {
    
        // STRAIGHT THRU ? delay
        // STRAIGHT THRU delays
        if (inp == NORTH_PORT || inp == SOUTH_PORT)
            return lightPhase.ewPhase / totalPhaseLen ; // expected num seconds? // clear for (percent time in NS) * 0 + percent time in EW * EW
        else return lightPhase.nsPhase / totalPhaseLen;
//    }
    

#warning TODO IMPELMENT CORRECT TURN VIOLATION BEHAVIORS!!
//    if ((inp == NORTH_PORT && outp == WEST_PORT)
//        || (inp == SOUTH_PORT && outp == EAST_PORT)
//        || (inp == EAST_PORT && outp == NORTH_PORT)
//        || (inp == WEST_PORT && outp == SOUTH_PORT))
//        
//        // RIGHT Turn Delay
//#warning TODO: Make factor of cross street congestion!
//        return 20.0;
//
//    if ((inp == NORTH_PORT && outp == EAST_PORT)
//        || (inp == SOUTH_PORT && outp == WEST_PORT)
//        || (inp == EAST_PORT && outp == SOUTH_PORT)
//        || (inp == WEST_PORT && outp == NORTH_PORT))
//        
//        // LEFT Turn Delay
//#warning TODO: Determine signal phases
//        return 60.0;
//    
    NSLog(@"Uh, this shouldn't happen");
    NSAssert(0, @"Invalid turn direction");
    return 100.0;
    
        
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
#warning TODO: RIGHT TURN ON RED!??

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
            return [lightPhase predictWaitTimeForMasterInterval:times andTrafficDir:NS_DIRECTION] * 1.3;
        else return [lightPhase predictWaitTimeForMasterInterval:times andTrafficDir:EW_DIRECTION] * 1.3; // Extra wait for left turns. Scalar should depend on probe data traffic loads. :/
    
    }
    NSLog(@"Uh, this shouldn't happen");
    NSAssert(0, @"Invalid turn direction");
    return 100.0;
    
    
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

+ (IntersectionNode *)nodeWithIdentifier:(NSString *)anIdentifier {
    
    IntersectionNode *aNode = [[IntersectionNode alloc] init];
    
    aNode.identifier = anIdentifier;
    
    return aNode;
}

- (void)nillifyPortWithThisEdge:(StreetEdge *)edge {
    if (self.n_port == edge) self.n_port = nil;
    if (self.s_port == edge) self.s_port = nil;
    if (self.e_port == edge) self.e_port = nil;
    if (self.w_port == edge) self.w_port = nil;
}


@end
