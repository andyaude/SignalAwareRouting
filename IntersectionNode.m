//
//  IntersectionNode.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "IntersectionNode.h"
#import "AATLightPhaseMachine.h"

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
- (float)calculateTurnPenaltyForInPort:(PortDirection)inp outPort:(PortDirection)outp useRealTiming:(BOOL)real_timing {
    
    if ((inp == NORTH_PORT && outp == NORTH_PORT)
        || (inp == SOUTH_PORT && outp == SOUTH_PORT)
        || (inp == EAST_PORT && outp == EAST_PORT)
        || (inp == WEST_PORT && outp == WEST_PORT))
        
        // U-Turn delay
        return 60.0; // calculate based on stop light average timing OR ACTUAL timing
    
    if ((inp == NORTH_PORT && outp == SOUTH_PORT)
        || (inp == SOUTH_PORT && outp == NORTH_PORT)
        || (inp == EAST_PORT && outp == WEST_PORT)
        || (inp == WEST_PORT && outp == EAST_PORT))
        
        // STRAIGHT THRU ? delay
        return 15.0; // calculate based on stop light average timing OR ACTUAL timing
    
    if ((inp == NORTH_PORT && outp == WEST_PORT)
        || (inp == SOUTH_PORT && outp == EAST_PORT)
        || (inp == EAST_PORT && outp == NORTH_PORT)
        || (inp == WEST_PORT && outp == SOUTH_PORT))
        
        // RIGHT Turn Delay
#warning TODO: Make factor of cross street congestion!
        return 20.0;

    if ((inp == NORTH_PORT && outp == EAST_PORT)
        || (inp == SOUTH_PORT && outp == WEST_PORT)
        || (inp == EAST_PORT && outp == SOUTH_PORT)
        || (inp == WEST_PORT && outp == NORTH_PORT))
        
        // LEFT Turn Delay
#warning TODO: Determine signal phases
        return 90.0;
    
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
    _light_phase_machine = [[AATLightPhaseMachine alloc] init];
    
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
