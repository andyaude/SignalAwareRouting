//
//  ClickableGraphRenderedView.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CityGraph.h"
#import "GraphRoute.h"

@class TrafficGridViewController;

@interface ClickableGraphRenderedView : UIView {
    GraphRoute *drawThisRoute;
}

@property (nonatomic, weak) CityGraph *graph;



@property (nonatomic) float minLong;
@property (nonatomic) float maxLong;

@property (nonatomic) float minLati;
@property (nonatomic) float maxLati;

@property (nonatomic) BOOL drawAllPaths;


@property (nonatomic) NSString *curRouteText;

@property (nonatomic, weak) TrafficGridViewController *containingViewController;

- (void)drawShortestPathFromNodeNamed:(NSString *)first toNodeNamed:(NSString *)second consider:(BOOL)considerPenalty inRealtime:(BOOL)rt withTime:(NSTimeInterval) time andCurrentQueuePenalty:(BOOL)queue;

+ (double)distance:(CGPoint)latLongOne andPoint:(CGPoint)latLongTwo;
- (void)removeAllSubviews;

@end
