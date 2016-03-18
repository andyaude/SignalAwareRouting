//
//  CarAndView.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 2/12/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CarView.h"
#import "GraphRoute.h"
#import "StreetEdge.h"

@class CityGraph, TrafficGridViewController;
@interface CarController : NSObject

@property (strong, nonatomic) CarView *carView;

@property (weak, nonatomic) TrafficGridViewController *parentVC;

@property (nonatomic) CGPoint currentLongLat;

@property (nonatomic) GraphRoute *intendedRoute;

@property (nonatomic) long uniqueID;

@property (nonatomic) BOOL shadowRandomCar;


- (BOOL)isReadyForRemoval;

@property (nonatomic, getter=getIsOnGraph) BOOL isOnGraphView;

@property (nonatomic) BOOL hardStopped;


// Which direction should the car go?
// Who should maintain the state?
// The graph, the edges, or the car itself?

- (StreetEdge *)getCurrentEdge;
- (IntersectionNode *)getFarNode;

- (void)initializeIfNeeded;
- (void)markStartTime:(NSTimeInterval)time;
- (void)didClickOnCar;

- (BOOL)isSelectedByUser;
- (void)setUnselected;

-(CGFloat)lastSpeedPerSecond;
- (NSTimeInterval)getTimeSpentWaitingOnThisEdge;

// Respond to timer tick
- (void)doTick:(NSTimeInterval) timeDiff;

// For Prescience
- (int)numStepsUntilEdge:(StreetEdge *)edge;

@end
