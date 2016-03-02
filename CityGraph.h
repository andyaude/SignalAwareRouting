//
//  CityGraph.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IntersectionNode.h"

@class StreetEdge, AAGraphRoute, CarAndView;

@interface CityGraph : NSObject {

/**
 A collection of PESGraphNodes managed by the graph.  Keys will be identifiers for
 each node in the graph, with coresponding values also being NSMutableDictionaries.
 The keys in each sub NSMutableDictionary will then also be identifiers for nodes,
 with those coresponding values being PESGraphEdge objects
 */
//NSMutableDictionary *nodeEdges;

/**
 A collection of all nodes included in the graph
 */
NSMutableDictionary *nodes;
NSMutableDictionary *edges;

}


@property (nonatomic, readonly) NSDictionary *nodes;
@property (nonatomic, readonly) NSDictionary *edges;

/**
 Returns a count of the number of edges currently in the graph.  Bi-directional edges are counted
 as two edges, for this count
 @returns an integer, >= 0, counting the number of edges in the graph.
 */
//- (NSInteger)edgeCount;

/**
	Returns a node in the graph with the given unique identifier, or nil if no such node exists
	@param anIdentifier a string identifier coresponding to the indentifier property of a node
 in the graph
	@returns Either nil or the node with the given identifier
 */
- (IntersectionNode *)nodeInGraphWithIdentifier:(NSString *)anIdentifier;

/**
 Returns an edge object describing the edge from the given node to the destination node.  If no
 such edge exists, returns nil
 @param sourceNode the node to check the weight from
 @param destinationNode the node to check the weight to
 @returns either nil, or the edge object describing the connection from one node to the other
 */
- (StreetEdge *)edgeFromNode:(IntersectionNode *)sourceNode toNeighboringNode:(IntersectionNode *)destinationNode;

/**
	Returns the distance / weight from one node to another.  If either node is not
 found in the graph, or there is no edge from the source node to the destination node,
 nil is retuned.  This is a simple convenience wrapper around toNeighboringNode:
	@param sourceNode the node to check the weight from
	@param destinationNode the node to check the weight to
	@returns either nil, or a number object describing the weight from one node to the other
 */
- (NSNumber *)weightFromNode:(IntersectionNode *)sourceNode viaNode:(IntersectionNode *)viaNode toNeighboringNode:(IntersectionNode *)destinationNode andConsiderLightPenalty:(BOOL)considerPenalty andRT:(BOOL)rt andTime:(double)time andQueuePenalty:(BOOL)queuePenalty;

/**
	Returns an unordered collection of all nodes that receive edges from the given node.
	@param aNode a node to test for neighbors of
	@returns a set of zero or more other nodes.  Returns nil if aNode is not a member of the
 graph
 */
- (NSSet *)neighborsOfNode:(IntersectionNode *)aNode;

/**
 Returns an unordered collection of all nodes that receive edges from the node identified
 by the given uniquely identifiying string.  This is just a conveninece wrapper around
 nodeInGraphWithIdentifier: and neighborsOfNode:
 @param aNodeIdentifier the unique identifier of one of the nodes in the graph
 @returns a set of zero or more other nodes.  Returns nil if no node in the graph is identified by
 aNodeIdentifier
 */
- (NSSet *)neighborsOfNodeWithIdentifier:(NSString *)aNodeIdentifier;

/**
	Adds a directional, weighted edge between two nodes in the graph.  If any provided nodes are not
 currently found in the graph, they're added
	@param anEdge the edge describing the connection between the two nodes
	@param aNode the node that the edge travels from
	@param anotherNode the node that the edge travels to
 */
- (void)addEdge:(StreetEdge *)anEdge fromNode:(IntersectionNode *)aNode fromPortDir:(PortDirection)fromDir toNode:(IntersectionNode *)anotherNode toPortDir:(PortDirection) toDir;
/**
 Removes a directional, weighted edge between two nodes in the graph.  If the edge does not exist, the
 method does nothing.
 @param aNode the node that the edge travels from
 @param anotherNode the node that the edge travels to
 @returns a boolean description of whether an edge was removed
 */
- (BOOL)removeEdgeFromNode:(IntersectionNode*)aNode toNode:(IntersectionNode*)anotherNode;

/**
 Adds a weighted edge that travels in both directions from the two given nodes in the graph.  If any
 provided nodes are not currently found in the graph, they're added to the collection
 @param anEdge the edge describing the connection between the two nodes
 @param aNode one of the two nodes on one side of the edge
 @param anotherNode the other of the two nodes on the other side of the edge
 */
- (void)addBiDirectionalEdge:(StreetEdge *)anEdge fromNode:(IntersectionNode *)aNode fromPort:(PortDirection)fromDir toNode:(IntersectionNode *)anotherNode toDir:(PortDirection)toDir;
/**
 Removes a bi-directional, weighted edge between two nodes in the graph.  If either edge does not exist, the
 method does nothing.
 @param aNode the node that the edge travels from
 @param anotherNode the node that the edge travels to
 @returns a boolean description of whether a bi-directional edge was removed
 */
- (BOOL)removeBiDirectionalEdgeFromNode:(IntersectionNode*)aNode toNode:(IntersectionNode*)anotherNode;

/**
	Returns a route object that describes the quickest path between the two given nodes.  If no route
	is possible, or either of the given start or end nodes are not in the graph, returns nil.
	@param startNode a node in the graph to begin calculating a path from
	@param endNode a node in graph to calculate a route to
	@returns either a PESGraphRoute object or nil, if no route is possible
 */
- (AAGraphRoute *)shortestRouteFromNode:(IntersectionNode *)startNode toNode:(IntersectionNode *)endNode considerIntxnPenalty:(BOOL)penalty realtimeTimings:(BOOL)realtime andTime:(double)time andCurrentQueuePenalty:(BOOL)currentQueuePenalty;

- (void)justAddNode:(IntersectionNode *)node;

- (void)putCarOnEdge:(StreetEdge *)edge startPoint:(IntersectionNode*)node andCar:(CarAndView *)car;
+ (NSArray *)getCarsOnEdge:(StreetEdge *)edge startPoint:(IntersectionNode *)start;
- (void)removeCarFromGraph:(CarAndView *)car;

@end
