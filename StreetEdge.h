//
//  StreetEdge.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IntersectionNode.h"

//@class IntersectionNode;

@interface StreetEdge : NSObject

@property (nonatomic, strong) NSString *identifier;

@property (nonatomic) float max_mph; // Default to 30;

@property (nonatomic) float avg_flow_scalar_a_to_b;
@property (nonatomic) float avg_flow_scalar_b_to_a;

// Distance in pseudo-latitude longitude units. (A square grid with equal units)
@property (nonatomic, readonly) double distance;

@property (nonatomic, weak) IntersectionNode *intersectionA;
@property (nonatomic, weak) IntersectionNode *intersectionB;


// Prescience feature!

// Array of cars destined to take this route....
@property NSMutableArray* futureABCars;
@property NSMutableArray* futureBACars;

// Here are the cars currently on this edge cars!
@property (nonatomic, strong) NSMutableArray *ABCars;
@property (nonatomic, strong) NSMutableArray *BACars;
- (CGPoint)getDirectionVector:(BOOL)bToA; // to properly rotate car...
- (CGPoint)getDirectionVectorForStartNode:(IntersectionNode *)startNode; // to properly rotate car...


@property BOOL is_unidirectional; // A-->B unidirectional. Default NO
@property (nonatomic) int num_lanes_a_to_b; // DEFAULT 1. No support yet for more lanes.
@property (nonatomic) int num_lanes_b_to_a; // DEFAULT 1

@property (nonatomic, getter=getWeight) double weight;

- (IntersectionNode *)getOppositeNode: (IntersectionNode *)thisNode;
- (BOOL)isAtoBForStartNode:(IntersectionNode*)start;

/**
 Convenience constructor that allows for setting the edge's name at initilization
 @param aName a description of the information (ex road, flight path, etc.) depcited
 by this edge
 @returns an initialized and un-retained edge
 */
+ (StreetEdge *)edgeWithName:(NSString *)aName;

@end
