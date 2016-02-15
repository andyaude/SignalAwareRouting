//
//  PESGraphRouteStep.h
//  PESGraph
//
//  Created by Peter Snyder on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IntersectionNode, StreetEdge;

/**
	An object that describes a step in a route between two nodes in a graph.
    Each object represents a node and, if applicable, an edge / path leading
    from the node to another node.  If this is the last step in the route,
    the edge will be empty.
 
    This class is not intented to be used directly, but instead from a
    PESGraphRoute object
 */
@interface AAGraphRouteStep : NSObject {

    /**
        The node that this step is starting at / traveling from
     */
    IntersectionNode *node;

    /**
        The path from this node to the next node in the route, if one exists.
        Will be nil if the current step is the last step in the chain
     */
    StreetEdge *edge;
    
    /**
        Whether or not the current step is the first step in the route between
        two nodes in a graph
     */
    bool isBeginningStep;
}

@property (nonatomic, strong, readonly) IntersectionNode *node;
@property (nonatomic, strong, readonly) StreetEdge *edge;
@property (nonatomic, readonly) bool isBeginningStep;

@property (nonatomic) double effective_cost;

/**
	Whether or not this is the last step in the chain.  Identical to checking whether
    the object's edge is nil
 */
@property (nonatomic, readonly) bool isEndingStep;

/**
    Returns an initilized object with a given node and edge
    @param aNode the node this step in the route is traveling from
    @param anEdge the edge object describing the path from the node to the next node in the route.  If nil, this step is
        treated as the last step in the route        
    @returns an object describing a single in the overall route
 */
- (id)initWithNode:(IntersectionNode *)aNode andEdge:(StreetEdge *)anEdge;

/**
	Returns an initilized object with a given node and edge, and a flag to determine whether its the first step in the route.
	@param aNode the node this step in the route is traveling from
	@param anEdge the edge object describing the path from the node to the next node in the route.  If nil, this step is
		treated as the last step in the route        
	@param isBeginning whether this step is the first step in the route
    @returns an object describing a single in the overall route
 */
- (id)initWithNode:(IntersectionNode *)aNode andEdge:(StreetEdge *)anEdge asBeginning:(bool)isBeginning;


@end
