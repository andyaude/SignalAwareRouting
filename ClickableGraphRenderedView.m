//
//  ClickableGraphRenderedView.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "ClickableGraphRenderedView.h"
#import "StreetEdge.h"
#import "AAGraphRoute.h"
#import "AAGraphRouteStep.h"
#import "LightPhaseMachine.h"
#import "TrafficGridViewController.h"
#import "CarAndView.h"

#define CIRCLE_BOX_SIZE 28.0
#define ROAD_WIDTH 16.
#define RIGHT_SIDE_OF_ROAD_OFFSET 4.0

@interface ClickableGraphRenderedView ()


@end


@implementation ClickableGraphRenderedView

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

CGPoint CGLineMidPoint(CGPoint one, CGPoint two)
{
    CGPoint midPoint = CGPointZero;
    midPoint.x = (one.x + two.x) / 2.0;
    midPoint.y = (one.y + two.y) / 2.0;
    return midPoint;
}

- (CGPoint)getCGPointForLongitude:(double)longitude andLatitude:(double)latitude {
    double long_progress = (longitude - self.minLong) / (self.maxLong - self.minLong);
    double lat_progress = (latitude - self.minLati) / (self.maxLati - self.minLati);
    
    double xCoord = long_progress * self.bounds.size.width;
    double yCoord = (1.0 - lat_progress) * self.bounds.size.height;
    
    return CGPointMake(xCoord, yCoord);
}

- (CGPoint)getLatLongForCGPoint:(CGPoint) point {
    double xProg = point.x / self.bounds.size.width;
    double yProg = 1.0 - point.y / self.bounds.size.height;
    
    double long_dist = (self.maxLong - self.minLong);
    double lat_dist = (self.maxLati - self.minLati);

    double longitude = self.minLong + long_dist * xProg;
    double latitude = self.minLati + lat_dist * yProg;
    
    return CGPointMake(longitude, latitude);
}

- (void)drawAllIntxnCircles {
    
#define CIRCLE_STEP 0
#define TEXT_STEP 1
    
    CGRect bounds = self.bounds;
    
    CGRect circleSpace = CGRectInset(bounds, 100, 100);
    circleSpace.size = CGSizeMake(CIRCLE_BOX_SIZE, CIRCLE_BOX_SIZE);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    

    
    NSDictionary *nodes = self.graph.nodes;
    
    for (int i = 0; i < 2; i++) {
        for (NSString * name in nodes) {
            IntersectionNode *obj = nodes[name];
            
            CGPoint updated = [self getCGPointForLongitude:obj.longitude andLatitude:obj.latitude];
            
            NSString *label = obj.identifier;
            
            circleSpace.origin = updated;
            updated.x -= CIRCLE_BOX_SIZE /2.;
            updated.y -= CIRCLE_BOX_SIZE /2.;
            circleSpace.origin = updated;

            
            if (i == CIRCLE_STEP)
                CGContextAddEllipseInRect(ctx, circleSpace);

            if (i == TEXT_STEP) {
                [label drawAtPoint:CGPointMake(updated.x + CIRCLE_BOX_SIZE/4.0 , updated.y + 0) withAttributes:@ { NSForegroundColorAttributeName : [UIColor whiteColor]} ];
            }

        }
        if (i == CIRCLE_STEP) {
            CGContextSetFillColor(ctx, CGColorGetComponents([[UIColor blueColor] CGColor]));
            CGContextFillPath(ctx);
        }
    
    }

}

- (BOOL)pointsAreDiagonal:(CGPoint)pointOne andPointTwo:(CGPoint)pointTwo {
    double diffY = fabs(pointOne.y - pointTwo.y);
    double diffX = fabs(pointOne.x - pointTwo.x);
    
    double result = atan2(diffY, diffX);
    
    // Tuned by hand.
    return fabs(result - 0.60) < .20;
}

- (BOOL)pointsAreMostlyVertical:(CGPoint)pointOne andPointTwo:(CGPoint)pointTwo {
    double diffY = fabs(pointOne.y - pointTwo.y);
    double diffX = fabs(pointOne.x - pointTwo.x);
    return diffY > diffX;
}

#define EDGE_STEP 0

- (void)drawEdges {
    NSDictionary *edges = [self.graph edges];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    [[UIColor grayColor] set];
    CGContextSetLineWidth(ctx, ROAD_WIDTH);


    for (int i = 0; i < 2; i++) {
        for (NSString * name in edges) {
            StreetEdge *edge = edges[name];
            
            CGPoint pointA = [self getCGPointForLongitude:edge.intersectionA.longitude andLatitude:edge.intersectionA.latitude];
            CGPoint pointB = [self getCGPointForLongitude:edge.intersectionB.longitude andLatitude:edge.intersectionB.latitude];
            
            if (i == EDGE_STEP) {
                CGContextMoveToPoint(ctx,pointA.x, pointA.y);
                CGContextAddLineToPoint(ctx, pointB.x, pointB.y);
                CGContextStrokePath(ctx);
            }

            NSString *label = [NSString stringWithFormat:@"%.2f", edge.weight];
            
            CGPoint mid = CGLineMidPoint(pointA, pointB);
            

            if (i == TEXT_STEP) {
                double xOffset = [self pointsAreMostlyVertical:pointA andPointTwo:pointB] ? -45.0 : -15.0; // vert : horizontal
                double yOffset = [self pointsAreMostlyVertical:pointA andPointTwo:pointB] ? -15.0 : -20; // vert: horizontal
                
                if ([self pointsAreDiagonal:pointA andPointTwo:pointB]) {
                    xOffset = 10.0;
                    yOffset = 10.0;
                }
                
                [label drawAtPoint:CGPointMake(mid.x + xOffset , mid.y + yOffset) withAttributes:
                            @{ NSForegroundColorAttributeName : [UIColor darkGrayColor]} ];
            }
            
        }
        
    }
    
    CGContextRestoreGState(ctx);

    
}

- (void)drawRouteOverlay:(AAGraphRoute *)route andSpecialColorOrNil:(UIColor *)colorOrNil {
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    if (!colorOrNil)
        [[UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.1] set];
    else
        [colorOrNil set];
    
    CGContextSetLineWidth(ctx,2.5f);
    
    for (AAGraphRouteStep *aStep in route.steps) {
        
        if (aStep.edge) {
            
            StreetEdge *edge = aStep.edge;
    
            CGPoint pointA = [self getCGPointForLongitude:edge.intersectionA.longitude andLatitude:edge.intersectionA.latitude];
            CGPoint pointB = [self getCGPointForLongitude:edge.intersectionB.longitude andLatitude:edge.intersectionB.latitude];
        
            CGContextMoveToPoint(ctx,pointA.x, pointA.y);
            CGContextAddLineToPoint(ctx, pointB.x, pointB.y);
            CGContextStrokePath(ctx);
        
        }
    }
        
    
    CGContextRestoreGState(ctx);
    
}

- (void)drawShortestPathFromNodeNamed:(NSString *)first toNodeNamed:(NSString *)second consider:(BOOL)considerPenalty inRealtime:(BOOL)rt withTime:(NSTimeInterval) time andCurrentQueuePenalty:(BOOL)currentQueuePenalty {
    IntersectionNode *nodeA = [self.graph nodeInGraphWithIdentifier:first];
    IntersectionNode *nodeB = [self.graph nodeInGraphWithIdentifier:second];
    

    AAGraphRoute *route = [self.graph shortestRouteFromNode:nodeA toNode:nodeB considerIntxnPenalty:considerPenalty realtimeTimings:rt andTime:time andCurrentQueuePenalty:currentQueuePenalty andIsAdaptiveTimedSystem:[[self.containingViewController adaptiveCycleTimesSwitch] isOn]];
    NSLog(@"Route :%@",route);
    self.curRouteText = [route description];
    drawThisRoute = route;
    [self setNeedsDisplay];
}

- (void)setColorForDirection:(IntersectionNode *)node andDirection:(AATrafficLightDirection)dir {

    if (node.light_phase_machine) {
        AALightUnitColor color = [node.light_phase_machine lightColorForDirection:dir];
        switch (color) {
            case RED_LIGHTUNIT:
                [[UIColor redColor] set];
                break;
            case YELLOW_LIGHTUNIT:
                [[UIColor yellowColor] set];
                break;
            case GREEN_LIGHTUNIT:
                [[UIColor greenColor] set];
                break;
            default:
                break;
        }
    }

}

- (void)drawTrafficLights {
        
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    
    [[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.6] set];

    CGContextSetLineWidth(ctx,3.0f);

    
    NSDictionary *nodes = self.graph.nodes;
    
        for (NSString * name in nodes) {
            IntersectionNode *obj = nodes[name];
            
            CGPoint center = [self getCGPointForLongitude:obj.longitude andLatitude:obj.latitude];
            center.x += CIRCLE_BOX_SIZE/7.; center.y += CIRCLE_BOX_SIZE/7.;

            CGPoint off_left = center; off_left.x -= 8.0;
            CGPoint off_right = center; off_right.x += 8.0;
            
            CGPoint off_up = center; off_up.y -= 8.0;
            CGPoint off_down = center; off_down.y += 8.0;

            [self setColorForDirection:obj andDirection:EW_DIRECTION];
            CGContextMoveToPoint(ctx, off_left.x, off_left.y);
            CGContextAddLineToPoint(ctx, off_right.x, off_right.y);
            CGContextStrokePath(ctx);

            
            [self setColorForDirection:obj andDirection:NS_DIRECTION];
            CGContextMoveToPoint(ctx, off_up.x, off_up.y);
            CGContextAddLineToPoint(ctx, off_down.x, off_down.y);
            CGContextStrokePath(ctx);


            
        }
}

+ (double)distance:(CGPoint)latLongOne andPoint:(CGPoint)latLongTwo {
    double lat_a = latLongOne.y;
    double lat_b = latLongTwo.y;
    
    double long_a = latLongOne.x;
    double long_b = latLongTwo.x;
    
    double diff_lat = fabs(lat_a - lat_b);
    double diff_long = fabs(long_a - long_b);
    
    return sqrt(diff_lat * diff_lat + diff_long * diff_long);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint touchPoint = [[touches anyObject] locationInView:self];
//    NSLog(@"Touched here %@", NSStringFromCGPoint([self getLatLongForCGPoint:touchPoint]));
    
    NSDictionary *nodes = self.graph.nodes;
    
    IntersectionNode *foundNode = NULL;
    
    for (NSString * name in nodes) {
        IntersectionNode *obj = nodes[name];
        CGPoint loc = [self getCGPointForLongitude:obj.longitude andLatitude:obj.latitude];
        
        double dist = [[self class] distance:loc andPoint:touchPoint];
        if (dist < 30.0) {
            NSLog(@"Found node %@", obj.identifier);
            [self.containingViewController editNode:obj atPoint:touchPoint];
            break;
        }
    }
}

- (void)removeAllSubviews {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (CGPoint)getOffsetForRightOfRoad:(CarAndView *)cv {
    StreetEdge *edge = [cv getCurrentEdge];
    IntersectionNode *farNode = [cv getFarNode];
    IntersectionNode *nearNode = [edge getOppositeNode:farNode];
    CGPoint dirVector = [edge getDirectionVectorForStartNode:nearNode];
    
    // 4 or so pixels total offset.
    CGPoint result = { -RIGHT_SIDE_OF_ROAD_OFFSET* dirVector.y, RIGHT_SIDE_OF_ROAD_OFFSET* dirVector.x };
    return result;
    
}
- (void)drawCarsAndPaths {
    NSArray *carViews = [self.containingViewController getCarsToDraw];
    
    CarAndView *deferDraw = nil;
    
    for (CarAndView *car in carViews) {
        AACarView *carView = car.carView;
        if (!carView.superview) {
            [self addSubview:carView];
        }
        
        [car initializeIfNeeded];
        
        UIColor *override = nil;
        
        // For normal D-I routes show as RED
        if (!car.shadowRandomCar)
            override = [UIColor colorWithRed:1.0 green:.2 blue:.2 alpha:0.3];
        
        if ([car isSelectedByUser]) {
            deferDraw = car;
        } else {
        
            if (self.drawAllPaths)
                [self drawRouteOverlay:car.intendedRoute andSpecialColorOrNil:override];
        }

        
        carView.hidden = NO;
        CGPoint newCenter = [self getCGPointForLongitude:car.currentLongLat.x andLatitude:car.currentLongLat.y];
        CGPoint offsetForRightOfRoad = [self getOffsetForRightOfRoad:car];
        newCenter.x += offsetForRightOfRoad.x;
        newCenter.y += offsetForRightOfRoad.y;
        carView.center = newCenter;
    }
    
    if (deferDraw) {
        [self drawRouteOverlay:deferDraw.intendedRoute andSpecialColorOrNil:[UIColor colorWithRed:0 green:1.0 blue:0. alpha:1.]];
    }

}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    
    [self drawEdges];
    [self drawAllIntxnCircles];
    
    if (drawThisRoute) {
        [self drawRouteOverlay:drawThisRoute andSpecialColorOrNil:nil];
    }

    [self drawTrafficLights];
    
    [self drawCarsAndPaths];

}


@end
