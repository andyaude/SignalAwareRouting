//
//  PESGraphRoute.m
//  PESGraph
//
//  Created by Peter Snyder on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AAGraphRoute.h"
#import "AAGraphRouteStep.h"
#import "IntersectionNode.h"
#import "StreetEdge.h"

@implementation AAGraphRoute

@synthesize steps;

- (id)init
{
    self = [super init];

    if (self) {

        steps = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addStepFromNode:(IntersectionNode *)aNode withEdge:(StreetEdge *)anEdge
{
    AAGraphRouteStep *aStep = [[AAGraphRouteStep alloc] initWithNode:aNode
                                                                andEdge:anEdge
                                                            asBeginning:([steps count] == 0)];
    
    [steps addObject:aStep];
}

- (NSString *)description
{
    NSMutableString *string = [NSMutableString string];
    
    [string appendString:@"Start: "];
    
    for (AAGraphRouteStep *aStep in steps) {
        
        if (aStep.edge) {

            [string appendFormat:@" %@ ->", aStep.node.identifier];

        } else {
            
            [string appendFormat:@"%@ (%.2f)", aStep.node.identifier, self.effective_dist_from_source];
            
        }
    }

    return string;
}

- (NSUInteger)count {
    
    return [steps count];    
}

- (IntersectionNode *)startingNode {
    
    return ([self count] > 0) ? [[steps objectAtIndex:0] node] : nil;
}

- (IntersectionNode *)endingNode {
    
    return ([self count] > 0) ? [[steps objectAtIndex:([self count] - 1)] node] : nil;
}

- (float)length {
    
    float totalLength = 0;
    
    for (AAGraphRouteStep *aStep in steps) {
        
        if (aStep.edge) {

            totalLength += aStep.edge.weight;
        }
    }
 
    return totalLength;
}

#pragma mark -
#pragma mark Memory Management


@end
