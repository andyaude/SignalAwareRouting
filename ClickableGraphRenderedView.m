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
#import "AATLightPhaseMachine.h"
#import "SecondViewController.h"
#import "CarAndView.h"

#define CIRCLE_BOX_SIZE 28.0
#define ROAD_WIDTH 12.

@interface ClickableGraphRenderedView ()


@end


@implementation ClickableGraphRenderedView

- (instancetype)init {
    self = [super init];
    if (self) {
        _intxn_lights = [NSMutableDictionary new];
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
    double long_progress = (longitude - self.min_long) / (self.max_long - self.min_long);
    double lat_progress = (latitude - self.min_lati) / (self.max_lati - self.min_lati);
    
    double x_coord = long_progress * self.bounds.size.width;
    double y_coord = (1.0 - lat_progress) * self.bounds.size.height;
    
    return CGPointMake(x_coord, y_coord);
}

- (CGPoint)getLatLongForCGPoint:(CGPoint) point {
    double x_prog = point.x / self.bounds.size.width;
    double y_prog = 1.0 - point.y / self.bounds.size.height;
    
    double long_dist = (self.max_long - self.min_long);
    double lat_dist = (self.max_lati - self.min_lati);

    double longitude = self.min_long + long_dist * x_prog;
    double latitude = self.min_lati + lat_dist * y_prog;
    
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

//            NSLog(@"Placing %@ at x:%f y:%f", name, x_coord, y_coord);
            
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
//            NSLog(@"Intxn %@", edge.identifier);
            
            CGPoint pointA = [self getCGPointForLongitude:edge.intersectionA.longitude andLatitude:edge.intersectionA.latitude];
//            pointA.x += CIRCLE_BOX_SIZE/2.0; pointA.y += CIRCLE_BOX_SIZE/2.0;
            CGPoint pointB = [self getCGPointForLongitude:edge.intersectionB.longitude andLatitude:edge.intersectionB.latitude];
//            pointB.x += CIRCLE_BOX_SIZE/2.0; pointB.y += CIRCLE_BOX_SIZE/2.0;
            
            if (i == EDGE_STEP) {
                CGContextMoveToPoint(ctx,pointA.x, pointA.y);
                CGContextAddLineToPoint(ctx, pointB.x, pointB.y);
                CGContextStrokePath(ctx);
            }

            NSString *label = [NSString stringWithFormat:@"%.2f", edge.weight];
            
            CGPoint mid = CGLineMidPoint(pointA, pointB);
            

            if (i == TEXT_STEP) {
                double x_offset = [self pointsAreMostlyVertical:pointA andPointTwo:pointB] ? -45.0 : -15.0; // vert : horizontal
                double y_offset = [self pointsAreMostlyVertical:pointA andPointTwo:pointB] ? -15.0 : -20; // vert: horizontal
                
                if ([self pointsAreDiagonal:pointA andPointTwo:pointB]) {
                    x_offset = 10.0;
                    y_offset = 10.0;
                }

                
                [label drawAtPoint:CGPointMake(mid.x + x_offset , mid.y + y_offset) withAttributes:@ { NSForegroundColorAttributeName : [UIColor darkGrayColor]} ];
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
    
//    NSDictionary *edges = [self.graph edges];
    for (AAGraphRouteStep *aStep in route.steps) {
        
        if (aStep.edge) {
            
            StreetEdge *edge = aStep.edge;
//            NSLog(@"Tryna draw overlay for edge %@", edge.identifier);
            
            CGPoint pointA = [self getCGPointForLongitude:edge.intersectionA.longitude andLatitude:edge.intersectionA.latitude];
//            pointA.x += CIRCLE_BOX_SIZE/2.0; pointA.y += CIRCLE_BOX_SIZE/2.0;
            CGPoint pointB = [self getCGPointForLongitude:edge.intersectionB.longitude andLatitude:edge.intersectionB.latitude];
//            pointB.x += CIRCLE_BOX_SIZE/2.0; pointB.y += CIRCLE_BOX_SIZE/2.0;
            
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
    

    AAGraphRoute *route = [self.graph shortestRouteFromNode:nodeA toNode:nodeB considerIntxnPenalty:considerPenalty realtimeTimings:rt andTime:time andCurrentQueuePenalty:currentQueuePenalty];
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
    
    CGRect bounds = self.bounds;
    
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

// Assuming deg latitude = 69.0
// Assuming deg longitude = 53.0
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
//        loc.y += CIRCLE_BOX_SIZE/2.0;
//        loc.x += CIRCLE_BOX_SIZE/2.0;
        
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

- (void)drawCarsAndStuff {
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
        
//            int randodraw = arc4random() % 100;
            
//            if (randodraw < 30)
                [self drawRouteOverlay:car.intendedRoute andSpecialColorOrNil:override];
        }

        
        carView.hidden = NO;
        
//        NSLog(@"lat long : %@", NSStringFromCGPoint(car.currentLongLat));
        CGPoint newCenter = [self getCGPointForLongitude:car.currentLongLat.x andLatitude:car.currentLongLat.y];
//        NSLog(@"place at xy: %@", NSStringFromCGPoint(newCenter));
        carView.center = newCenter;
    }
    
    if (deferDraw) {
        [self drawRouteOverlay:deferDraw.intendedRoute andSpecialColorOrNil:[UIColor colorWithRed:0 green:1.0 blue:0. alpha:1.]];
    }

}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    
    [self drawEdges];
    [self drawAllIntxnCircles];
    
    if (drawThisRoute) {
        [self drawRouteOverlay:drawThisRoute andSpecialColorOrNil:nil];
    }

    [self drawTrafficLights];
    
    [self drawCarsAndStuff];
    
//    [self drawShortestPathFromNodeNamed:@"D" toNodeNamed:@"F"];


}


@end
