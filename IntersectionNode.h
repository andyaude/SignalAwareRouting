//
//  IntersectionNode.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class StreetEdge;
@class AATLightPhaseMachine;

typedef enum {
    NORTH_PORT,
    SOUTH_PORT,
    EAST_PORT,
    WEST_PORT
} PortDirection;


@interface IntersectionNode : NSObject;

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *title;

// EDGES. (TODO: CAN ADD MORE!)
@property (nonatomic, weak) StreetEdge *n_port;
@property (nonatomic, weak) StreetEdge *s_port;
@property (nonatomic, weak) StreetEdge *w_port;
@property (nonatomic, weak) StreetEdge *e_port;

- (NSSet *)getEdgeSet;

@property (nonatomic) double latitude; // center point ?
@property (nonatomic) double longitude; // center point ?
@property (nonatomic, getter=getLatLong) CGPoint latlong; // center point ?


// IF STOP SIGN
@property (nonatomic) BOOL is_stop_sign;
@property (nonatomic) NSDictionary *stop_info;

// STOPLIGHT
@property (nonatomic) NSArray *forbidden_turns;
@property (nonatomic) BOOL is_stop_light;
@property (nonatomic) NSDictionary *stoplight_info;

// Strongify -- main owner of the phase machine
@property (nonatomic, strong) AATLightPhaseMachine *light_phase_machine;

- (float)calculateTurnPenaltyForInPort:(PortDirection)inp outPort:(PortDirection)outp useRealTiming:(BOOL)real_timing;
- (BOOL)isTurnForbidden:(PortDirection)inp outPort:(PortDirection)outp;


/**
	Convenience method to return an initialized and un-retained node
	@param anIdentifier a unique identifier for the node.  Must be unique for all nodes in a graph
 @returns an initialized and un-retained edge
 */
+ (IntersectionNode *)nodeWithIdentifier:(NSString *)anIdentifier;
- (void)nillifyPortWithThisEdge:(StreetEdge *)edge;


@end
