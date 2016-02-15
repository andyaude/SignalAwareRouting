//
//  StreetEdge.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "StreetEdge.h"
#import "IntersectionNode.h"

@implementation StreetEdge

+ (StreetEdge *)edgeWithName:(NSString *)aName {
    
    StreetEdge *anEdge = [[StreetEdge alloc] init];
    
    anEdge.identifier = aName;
    return anEdge;
}

// Num seconds to clear this stretch of road.
- (double)getWeight {
        // x = vt... x/v -> t
    
    double miles_per_second = self.max_mph / 60.0 / 60.0;
    
    return self.distance / miles_per_second;
    
}

- (IntersectionNode *)getOppositeNode: (IntersectionNode *)thisNode {
    assert (thisNode == self.intersectionA || thisNode == self.intersectionB);
    
    if (thisNode != self.intersectionA) return self.intersectionA;
    else return self.intersectionB;
    
}

- (CGPoint)getDirectionVectorForStartNode:(IntersectionNode *)startNode {
    if (self.intersectionA == startNode)
        return [self getDirectionVector:NO];
    else
        return [self getDirectionVector:YES];
}

- (CGPoint)getDirectionVector:(BOOL)bToA {// to properly rotate car...
    double x_diff = self.intersectionB.longitude - self.intersectionA.longitude;
    double y_diff = (self.intersectionB.latitude - self.intersectionA.latitude) *-1; // 
    
    double magnitude = sqrt(pow(x_diff,2) + pow(y_diff,2));
    x_diff /= magnitude;
    y_diff /= magnitude;
    
    if (bToA) {
        x_diff *= -1;
        y_diff *= -1;
    }
    
    return CGPointMake(x_diff, y_diff);
}


// Assuming deg latitude = 69.0
// Assuming deg longitude = 53.0
- (double)distance {
    double lat_a = [self.intersectionA latitude];
    double lat_b = [self.intersectionB latitude];
    
    double long_a = [self.intersectionA longitude];
    double long_b = [self.intersectionB longitude];
    
#warning UNTRUE
    double diff_lat = fabs(lat_a - lat_b) * 10.0;
    double diff_long = fabs(long_a - long_b) * 10.;
    
    return sqrt(diff_lat * diff_lat + diff_long * diff_long);
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        // Distance in MILES!
        self.max_mph = 30.0;
        
        self.avg_flow_scalar_a_to_b = 1.0;
        self.avg_flow_scalar_b_to_a = 1.0;
        
        self.num_lanes_a_to_b = 1;
        self.num_lanes_b_to_a = 1;
        
        self.ABCars = [NSMutableArray new];
        self.BACars = [NSMutableArray new];
        
        self.is_unidirectional = NO;
    }
    
    return self;
}

@end