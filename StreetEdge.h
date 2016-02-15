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

// Distance in latitude longitude units
@property (nonatomic, readonly) double distance; // TODO: DETERMINE UNITS! OR CAN USE GETTER for lazy load!

@property (nonatomic, weak) IntersectionNode *intersectionA;
@property (nonatomic, weak) IntersectionNode *intersectionB;


// Here be cars! 
@property (nonatomic, strong) NSMutableArray *ABCars;
@property (nonatomic, strong) NSMutableArray *BACars;
- (CGPoint)getDirectionVector:(BOOL)bToA; // to properly rotate car...
- (CGPoint)getDirectionVectorForStartNode:(IntersectionNode *)startNode; // to properly rotate car...


@property BOOL is_unidirectional; // A-->B unidirectional. Default NO
@property (nonatomic) int num_lanes_a_to_b; // DEFAULT 1
@property (nonatomic) int num_lanes_b_to_a; // DEFAULT 1

@property (nonatomic, getter=getWeight) double weight;

- (IntersectionNode *)getOppositeNode: (IntersectionNode *)thisNode;

/**
 Convenience initializer that allows for setting the edge's name at initilization
 @param aName a description of the information (ex road, flight path, etc.) depcited
 by this edge
 @returns an initialized and un-retained edge
 */
+ (StreetEdge *)edgeWithName:(NSString *)aName;

@end
