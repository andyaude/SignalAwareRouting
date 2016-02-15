//
//  PESGraphRouteStep.m
//  PESGraph
//
//  Created by Peter Snyder on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AAGraphRouteStep.h"
#import "IntersectionNode.h"
#import "StreetEdge.h"

@implementation AAGraphRouteStep

@synthesize node, edge, isBeginningStep, isEndingStep;

#pragma mark -
#pragma mark Initilizers

- (id)init
{
    self = [super init];

    if (self) {
        
        isBeginningStep = NO;
        isEndingStep = NO;
        self.effective_cost = 0;
    }
    
    return self;
}

- (id)initWithNode:(IntersectionNode *)aNode andEdge:(StreetEdge *)anEdge
{    
    self = [super init];
    
    if (self) {
        
        isBeginningStep = NO;
        isEndingStep = (anEdge == nil);
        node = aNode;
        edge = anEdge;
    }
    
    return self;
}

- (id)initWithNode:(IntersectionNode *)aNode andEdge:(StreetEdge *)anEdge asBeginning:(bool)isBeginning
{    
    self = [super init];
    
    if (self) {
        
        isBeginningStep = isBeginning;
        isEndingStep = (anEdge == nil);
        node = aNode;
        edge = anEdge;
    }
    
    return self;
}

#pragma mark -
#pragma mark Property Implementations
- (bool)isEndingStep
{
    return (self.edge == nil);
}

#pragma mark -
#pragma mark Memory Management


@end
