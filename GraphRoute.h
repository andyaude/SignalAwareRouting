//
//  GraphRoute.h

#import <Foundation/Foundation.h>

@class IntersectionNode, StreetEdge;

/**
	Describes a complete route between two nodes in a CityGraph.  Not meant
    to be constructed directly from client programs, but instead managed
    by calls to methods like shortestRouteFromNode:toNode: in CityGraph
 */
@interface GraphRoute : NSObject {

    /**
        A collection of GraphRouteStep objects that describe a route
        between two nodes in a graph
     */
    NSMutableArray *steps;
}

/**
    A collection of GraphRouteStep objects that describe a route
    between two nodes in a graph.  The first returned GraphRouteStep will
    be from the starting node, and the last will refer to the ending node
    with no further edge
 */
@property (nonatomic, readonly) NSArray *steps;

@property (nonatomic) double effective_dist_from_source;

/**
	Adds a new step to the route, moving from a node and, optionally, pointing
    to the next step in the route
	@param aNode a node in a graph along a route from a starting and ending point
	@param anEdge the edge from a node to another node, or nil if this is the last
        step in the route
 */
- (void)addStepFromNode:(IntersectionNode *)aNode withEdge:(StreetEdge *)anEdge;

/**
	Returns the number of steps needed to complete the described route
	@returns a count of the number of steps described by the route
 */
- (NSUInteger)count;

/**
	Returns the initial, origin node described by the route
	@returns the node that the route starts from.  Returns nil on error or if there
        is no starting point
 */
- (IntersectionNode *)startingNode;

/**
	Returns the point that the route leads to
	@returns the node that the route starts from
 */
- (IntersectionNode *)endingNode;

/**
	The total distance of the route, calculated by summing the weight between all the 
    steps in the route
	@returns a decimal description of the lenght of the entire route
 */
- (float)length;




@end
