//
//  CityGraph.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "CityGraph.h"
#import "IntersectionNode.h"
#import "StreetEdge.h"
#import "AAGraphRoute.h"
#import "CarAndView.h"

@implementation CityGraph
@synthesize nodes = nodes;
@synthesize edges = edges;

#define CARS_PER_SEC 0.5


- (id)init
{
    self = [super init];
    
    if (self) {
        
//        nodeEdges = [[NSMutableDictionary alloc] init];
        nodes = [[NSMutableDictionary alloc] init];
        edges = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (IntersectionNode *)nodeInGraphWithIdentifier:(NSString *)anIdentifier
{
    return [nodes objectForKey:anIdentifier];
}

+ (NSArray *)getCarsOnEdge:(StreetEdge *)edge startPoint:(IntersectionNode *)start {
    if (edge.intersectionA == start) {
        return edge.ABCars;
    } else {
        return edge.BACars;
    }

}

- (void)removeCarFromGraph:(CarAndView *)car {
    // Sanity check!
    for (StreetEdge *edge in [edges allValues]) {
        [edge.ABCars removeObject:car];
        [edge.BACars removeObject:car];
    }
}


- (void)putCarOnEdge:(StreetEdge *)edge startPoint:(IntersectionNode*)node andCar:(CarAndView *)car {
    
    // Sanity check!
    for (StreetEdge *edge in [edges allValues]) {
        [edge.ABCars removeObject:car];
        [edge.BACars removeObject:car];
    }
    
    if (edge.intersectionA == node) {
        [edge.ABCars addObject:car];
    } else {
        [edge.BACars addObject:car];
    }
}

- (StreetEdge *)edgeFromNode:(IntersectionNode *)sourceNode toNeighboringNode:(IntersectionNode *)destinationNode
{
    if (sourceNode.n_port && [sourceNode.n_port getOppositeNode:sourceNode] == destinationNode) return sourceNode.n_port;
    if (sourceNode.s_port && [sourceNode.s_port getOppositeNode:sourceNode] == destinationNode) return sourceNode.s_port;
    if (sourceNode.e_port && [sourceNode.e_port getOppositeNode:sourceNode] == destinationNode) return sourceNode.e_port;
    if (sourceNode.w_port && [sourceNode.w_port getOppositeNode:sourceNode] == destinationNode) return sourceNode.w_port;
    
    return nil;
}

- (PortDirection)getPortDirForNode:(IntersectionNode *)intxnNode andEdge:(StreetEdge *)edge {
    if (intxnNode.n_port == edge) return NORTH_PORT;
    if (intxnNode.s_port == edge) return SOUTH_PORT;
    if (intxnNode.e_port == edge) return EAST_PORT;
    if (intxnNode.w_port == edge) return WEST_PORT;
    NSAssert(0, @"Error with edges and port direction!");
    return -1;
}

// TODO: UNTESTED MESS
- (NSNumber *)weightFromNode:(IntersectionNode *)sourceNode viaNode:(IntersectionNode *)viaNode toNeighboringNode:(IntersectionNode *)destinationNode andConsiderLightPenalty:(BOOL)considerPenalty andRT:(BOOL)rt andTime:(double)time andQueuePenalty:(BOOL)queuePenalty
{
    StreetEdge *firstEdge = [self edgeFromNode:sourceNode toNeighboringNode:viaNode];
    StreetEdge *lastEdge = [self edgeFromNode:viaNode toNeighboringNode:destinationNode];
    
    double baseWeight = lastEdge.weight;

    if (firstEdge) {
        
    PortDirection inPort = [self getPortDirForNode:viaNode andEdge:firstEdge];
    PortDirection outPort = [self getPortDirForNode:viaNode andEdge:lastEdge];
        
    if (considerPenalty) {
        
        double penalty;
        if (!rt)
            penalty = [sourceNode calculateTurnPenaltyForInPort:inPort outPort:outPort];
        else
            penalty = [sourceNode calculateRealtimePenalty:inPort outPort:outPort withRealTimestamp:time+baseWeight];
        
        
        baseWeight += penalty;
        
//        NSLog(@"Penalty from source:%@ via:%@ dest:%@ amount :%.2f, forTime %.2f t+b %.2f", sourceNode.identifier, viaNode.identifier, destinationNode.identifier, penalty, time, time+baseWeight-penalty);
    }
    } else if (considerPenalty) {
//        NSLog(@"Didn't have a first edge and was supposed to add penalty...");
    }
    
    if (queuePenalty) {
        NSUInteger numCarsOnRoadAlready = 0;
        if (firstEdge.intersectionA == sourceNode)
            numCarsOnRoadAlready = firstEdge.ABCars.count;
        else
            numCarsOnRoadAlready = firstEdge.BACars.count;
        
        if (numCarsOnRoadAlready > 0) {
            double queuePen = 3.0 * numCarsOnRoadAlready;
            double car_ratio = numCarsOnRoadAlready / (firstEdge.getWeight * CARS_PER_SEC);
                                                       
            double scalar = car_ratio < 1.0 ? sqrt(car_ratio) : pow(car_ratio, 2.0); // severely penalize a full road. Not so much penalty for unfilled road!
            
            baseWeight += queuePen * scalar; // Add 2 seconds * logbase2 of (numcarsonroad)
//            NSLog(@" QueuePen %@ %.2f scalar %.2f", firstEdge.identifier, queuePen, scalar);

        }
        
    }
    
    return (lastEdge) ? @(baseWeight) : nil;
}

// TLDR implement later if needed
//- (NSInteger)edgeCount
//{
//    NSInteger edgeCount = 0;
//    
//    for (NSString *nodeIdentifier in nodeEdges) {
//        
//        edgeCount += [(NSDictionary *)[nodeEdges objectForKey:nodeIdentifier] count];
//    }
//    
//    return edgeCount;
//}

- (NSSet *)neighborsOfNode:(IntersectionNode *)aNode
{
    if (!aNode) return nil;
    
    NSSet *edgesFromNode = [aNode getEdgeSet];
    
    // If we don't have any record of the given node in the collection, determined by its identifier,
    // return nil
    if (edgesFromNode == nil) {
        
        return nil;
        
    } else {
        
        NSMutableSet *neighboringNodes = [NSMutableSet set];
        
        for (StreetEdge *neighboredge in edgesFromNode) {
            [neighboringNodes addObject:[neighboredge getOppositeNode:aNode]];
        }
        
        return neighboringNodes;
    }
}

- (NSSet *)neighborsOfNodeWithIdentifier:(NSString *)aNodeIdentifier
{
    IntersectionNode *identifiedNode = [nodes objectForKey:aNodeIdentifier];
    
    return (identifiedNode == nil) ? nil : [self neighborsOfNode:identifiedNode];
}

- (void)assignToPortBasedOnDir:(IntersectionNode *)theNode edge:(StreetEdge *)edge andDir:(PortDirection)dir {
    switch (dir) {
        case NORTH_PORT:
            theNode.n_port = edge;
            break;
        case SOUTH_PORT:
            theNode.s_port = edge;
            break;
        case EAST_PORT:
            theNode.e_port = edge;
            break;
        case WEST_PORT:
            theNode.w_port = edge;
            break;
    }
}

- (void)justAddNode:(IntersectionNode *)node {
    [nodes setObject:node forKey:node.identifier];
}

// We are assuming two way streets!
- (void)addEdge:(StreetEdge *)anEdge fromNode:(IntersectionNode *)aNode fromPortDir:(PortDirection)fromDir toNode:(IntersectionNode *)anotherNode toPortDir:(PortDirection) toDir
{
    [nodes setObject:aNode forKey:aNode.identifier];
    [nodes setObject:anotherNode forKey:anotherNode.identifier];
    
    [edges setObject:anEdge forKey:anEdge.identifier];
    
    // If we don't have any edges leaving from from the given node (aNode),
    // create a new record in the node dictionary.  Otherwise just add the new edge / connection to the
    // collection
    anEdge.intersectionA = aNode;
    anEdge.intersectionB = anotherNode;
    [self assignToPortBasedOnDir:aNode edge:anEdge andDir:fromDir];
    [self assignToPortBasedOnDir:anotherNode edge:anEdge andDir:toDir];
    
}


- (BOOL)removeEdgeFromNode:(IntersectionNode*)aNode toNode:(IntersectionNode*)anotherNode
{
    
    StreetEdge *targetEdge = nil;
    
    if (aNode.n_port && [aNode.n_port getOppositeNode:aNode] == anotherNode) {
        targetEdge = aNode.n_port;
    }
    if (aNode.s_port && [aNode.s_port getOppositeNode:aNode] == anotherNode) {
        targetEdge = aNode.s_port;
    }
    if (aNode.e_port && [aNode.e_port getOppositeNode:aNode] == anotherNode) {
        targetEdge = aNode.e_port;
    }
    if (aNode.w_port && [aNode.w_port getOppositeNode:aNode] == anotherNode) {
        targetEdge = aNode.w_port;
    }
    
    if (targetEdge) {
        [aNode nillifyPortWithThisEdge:targetEdge];
        [anotherNode nillifyPortWithThisEdge:targetEdge];
        [edges removeObjectForKey:targetEdge.identifier];
        return YES;
    }

    return NO;
}

- (void)addBiDirectionalEdge:(StreetEdge *)anEdge fromNode:(IntersectionNode *)aNode fromPort:(PortDirection)fromDir toNode:(IntersectionNode *)anotherNode
                       toDir:(PortDirection)toDir
{
    [self addEdge:anEdge fromNode:aNode fromPortDir:fromDir toNode:anotherNode toPortDir:toDir];
    anEdge.is_unidirectional = NO;
}

- (BOOL)removeBiDirectionalEdgeFromNode:(IntersectionNode*)aNode toNode:(IntersectionNode*)anotherNode
{
    // First, make sure edges exist in both directions.  If they don't, return NO and do nothing
    StreetEdge *toEdge = [self edgeFromNode:aNode toNeighboringNode:anotherNode];
    StreetEdge *fromEdge = [self edgeFromNode:anotherNode toNeighboringNode:aNode];
    
    if (toEdge == nil || fromEdge == nil) {
        
        return NO;
        
    } else {
        
        [self removeEdgeFromNode:aNode toNode:anotherNode];
        return YES;
        
    }
}

// Returns the quickest possible path between two nodes, using Dijkstra's algorithm
// http://en.wikipedia.org/wiki/Dijkstra's_algorithm
- (AAGraphRoute *)shortestRouteFromNode:(IntersectionNode *)startNode toNode:(IntersectionNode *)endNode considerIntxnPenalty:(BOOL)penalty realtimeTimings:(BOOL)realtime andTime:(double)time andCurrentQueuePenalty:(BOOL)currentQueuePenalty
{
    NSMutableDictionary *unexaminedNodes = [NSMutableDictionary dictionaryWithDictionary:self.nodes];
    
    // The shortest yet found distance to the origin for each node in the graph.  If we haven't
    // yet found a path back to the origin from a node, or if there isn't one, mark with -1
    // (which is used equivlently to how infinity is used in some Dijkstra implementations)
    NSMutableDictionary *distancesFromSource = [NSMutableDictionary dictionaryWithCapacity:[unexaminedNodes count]];
    
    // A collection that stores the previous node in the quickest path back to the origin for each
    // examined node in the graph (so you can retrace the fastest path from any examined node back
    // looking up the value that coresponds to any node identifier.  That value will be the previous
    // node in the path
    NSMutableDictionary *previousNodeInOptimalPath = [NSMutableDictionary dictionaryWithCapacity:[unexaminedNodes count]];
    
    // Since NSNumber doesn't have a state for infinitiy, but since we know that all weights have to be
    // positive, we can treat -1 as infinity
    NSNumber *infinity = [NSNumber numberWithInt:-1];
    
    // Set every node to be infinitely far from the origin (ie no path back has been found yet).
    for (NSString *nodeIdentifier in unexaminedNodes) {
        
        [distancesFromSource setValue:infinity
                               forKey:nodeIdentifier];
    }
    
    // Set the distance from the source to itself to be zero
    [distancesFromSource setValue:[NSNumber numberWithInt:0]
                           forKey:startNode.identifier];
    
    NSString *currentlyExaminedIdentifier = nil;
    
//    double cum_time = time;
    
    while ([unexaminedNodes count] > 0) {
        
        // Find the node, of all the unexamined nodes, that we know has the closest path back to the origin
        NSString *identifierOfSmallestDist = [self keyOfSmallestValue:distancesFromSource withInKeys:[unexaminedNodes allKeys]];
        
        // If we failed to find any remaining nodes in the graph that are reachable from the source,
        // stop processing
        if (identifierOfSmallestDist == nil) {
            
            break;
            
        } else {
            
            IntersectionNode *nodeMostRecentlyExamined = [self nodeInGraphWithIdentifier:identifierOfSmallestDist];
            
            // If the next closest node to the origin is the target node, we don't need to consider any more
            // possibilities, we've already hit the shortest distance!  So, we can remove all other
            // options from consideration.
            if ([identifierOfSmallestDist isEqualToString:endNode.identifier]) {
                
                currentlyExaminedIdentifier = endNode.identifier;
                break;
                
            } else {
                
                // Otherwise, remove the node thats the closest to the source and continue the search by looking
                // for the next closest item to the orgin.
                [unexaminedNodes removeObjectForKey:identifierOfSmallestDist];
                
                // Now, iterate over all the nodes that touch the one closest to the graph
                for (IntersectionNode *neighboringNode in [self neighborsOfNodeWithIdentifier:identifierOfSmallestDist]) {
                    
                    if (neighboringNode == [previousNodeInOptimalPath objectForKey:nodeMostRecentlyExamined.identifier]) continue;
                    
                    // Calculate the distance to the origin, from the neighboring node, through the most recently
                    // examined node.  If its less than the shortest path we've found from the neighboring node
                    // to the origin so far, save / store the new shortest path amount for the node, and set
                    // the currently being examined node to be the optimal path home
                    // The distance of going from the neighbor node to the origin, going through the node we're about to eliminate
                    
                    NSNumber *distanceFromNeighborToOrigin = [distancesFromSource objectForKey:neighboringNode.identifier];
                    
                    // need to consider full candidate route??
#warning routing logic mindfuck
                    
                    NSNumber *alt = [NSNumber numberWithFloat:
                                     [[distancesFromSource objectForKey:identifierOfSmallestDist] floatValue] +
                                     [[self weightFromNode:[previousNodeInOptimalPath objectForKey:nodeMostRecentlyExamined.identifier]
                                                   viaNode:nodeMostRecentlyExamined
                                                    toNeighboringNode:neighboringNode
                                                    andConsiderLightPenalty:penalty andRT:realtime andTime:time andQueuePenalty:currentQueuePenalty] floatValue]];
                    
                    
                    // If its quicker to get to the neighboring node going through the node we're about the remove
                    // than through any other path, record that the node we're about to remove is the current fastes
                    if ([distanceFromNeighborToOrigin isEqualToNumber:infinity] || [alt compare:distanceFromNeighborToOrigin] == NSOrderedAscending) {
                        
                        [distancesFromSource setValue:alt forKey:neighboringNode.identifier];
                        [previousNodeInOptimalPath setValue:nodeMostRecentlyExamined forKey:neighboringNode.identifier];
                    }
                }
            }
        }
    }
    
    // There are two situations that cause the above loop to exit,
    // 1. We've found a path between the origin and the destination node, or
    // 2. there are no more possible routes to consider to the destination, in which case no possible
    // solution / route exists.
    //
    // If the key of the destination node is equal to the node we most recently found to be in the shortest path
    // between the origin and the destination, we're in situation 2.  Otherwise, we're in situation 1 and we
    // should just return nil and be done with it
    if ( currentlyExaminedIdentifier == nil || ! [currentlyExaminedIdentifier isEqualToString:endNode.identifier]) {
        
        return nil;
        
    } else {
        
        // If we did successfully find a path, create and populate a route object, describing each step
        // of the path.
        AAGraphRoute *route = [[AAGraphRoute alloc] init];
        
        // We do this by first building the route backwards, so the below array with have the last step
        // in the route (the destination) in the 0th position, and the origin in the last position
        NSMutableArray *nodesInRouteInReverseOrder = [NSMutableArray array];
        
        [nodesInRouteInReverseOrder addObject:endNode];
        
        IntersectionNode *lastStepNode = endNode;
        IntersectionNode *previousNode;
        
        while ((previousNode = [previousNodeInOptimalPath objectForKey:lastStepNode.identifier])) {
            
            [nodesInRouteInReverseOrder addObject:previousNode];
            lastStepNode = previousNode;
        }
        
        // Now, finally, at this point, we can reverse the array and build the complete route object, by stepping through
        // the nodes and piecing them togheter with their routes
        NSUInteger numNodesInPath = [nodesInRouteInReverseOrder count];
        for (int i = (int)numNodesInPath - 1; i >= 0; i--) {
            
            IntersectionNode *currentGraphNode = [nodesInRouteInReverseOrder objectAtIndex:i];
            IntersectionNode *nextGraphNode = (i - 1 < 0) ? nil : [nodesInRouteInReverseOrder objectAtIndex:(i - 1)];
            
            [route addStepFromNode:currentGraphNode withEdge:nextGraphNode ? [self edgeFromNode:currentGraphNode toNeighboringNode:nextGraphNode] : nil];
        }
        
        route.effective_dist_from_source = [[distancesFromSource objectForKey:endNode.identifier] doubleValue];
        
//        NSLog(@"Distances from source :%@", distancesFromSource);
        return route;
    }
}

- (id)keyOfSmallestValue:(NSDictionary *)aDictionary withInKeys:(NSArray *)anArray
{
    id keyForSmallestValue = nil;
    NSNumber *smallestValue = nil;
    
    NSNumber *infinity = [NSNumber numberWithInt:-1];
    
    for (id key in anArray) {
        
        // Check to see if we have or proxie for infinity here.  If so, ignore this value
        NSNumber *currentTestValue = [aDictionary objectForKey:key];
        
        if ( ! [currentTestValue isEqualToNumber:infinity]) {
            
            if (smallestValue == nil || [smallestValue compare:currentTestValue] == NSOrderedDescending) {
                
                keyForSmallestValue = key;
                smallestValue = currentTestValue;
            }
        }
    }
    
    return keyForSmallestValue;
}
@end
