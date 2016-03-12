//
//  CarAndView.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 2/12/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AACarView.h"
#import "AAGraphRoute.h"
#import "StreetEdge.h"

@class CityGraph, SecondViewController;
@interface CarAndView : NSObject

@property (strong, nonatomic) AACarView *carView;

@property (weak, nonatomic) SecondViewController *secondVC;

@property (nonatomic) CGPoint currentLongLat;

@property (nonatomic) AAGraphRoute *intendedRoute;

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

- (BOOL)isDrivingAtoBNode;
- (CGPoint)getDirectionVectorForEdge:(StreetEdge *)edge andIsAToB:(BOOL)isAToB;

- (void)initializeIfNeeded;
- (void)markStartTime:(NSTimeInterval)time;
- (void)didClickOnCar;

- (BOOL)isSelectedByUser;
- (void)setUnselected;

-(CGFloat)lastSpeedPerSecond;

// Respond to timer tick
- (void)doTick:(NSTimeInterval) timeDiff;

@end
