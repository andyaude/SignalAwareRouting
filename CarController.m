//
//  CarAndView.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 2/12/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "CarController.h"
#import "CityGraph.h"
#import "GraphRoute.h"
#import "GraphRouteStep.h"
#import "ClickableGraphRenderedView.h"
#import "LightPhaseMachine.h"
#import "TrafficGridViewController.h"

// Should random cars count in E2E calculations?
#define REPORT_E2E_DELAY_EVEN_IF_SHADOW 0

// How far should car back off of intersection when light is Y/R?
#define DIST_TO_YELLOWIFY 0.006

// Minimum separation between cars
#define CAR_MIN_SEP 0.0062

// Calibrated to 30 mph considering graph distances
#define STANDARD_SPEED 1/262.0 // units per time tick?

@interface CarController () {
    BOOL _readyForRemoval;
    BOOL _wasClicked;
}

@property (nonatomic) BOOL inited;
@property (nonatomic) CGFloat oldDist;

@property (nonatomic) double lastSpeed;

@property (nonatomic) int stepIndex;
@property (nonatomic) BOOL isOnFinalStep;


// Start time interval
@property (nonatomic) NSTimeInterval startTimeInterval;
@property (nonatomic) NSTimeInterval endTimeInterval;

@property (nonatomic) NSTimeInterval timeStoppedOnThisEdge;
@property (nonatomic) NSTimeInterval lastTimeStopped; // -1 if in motion



@property (nonatomic, weak) GraphRouteStep *currentStep;
@end

@implementation CarController

- (instancetype)init {
    static long counter = 1;
    
    self = [super init];
    if (self) {
        _carView = [CarView new];
        _carView.containingCar = self;
        _uniqueID = counter++;
        _stepIndex = 0;
        _oldDist = CGFLOAT_MAX;
        self.timeStoppedOnThisEdge = 0.0;
        self.lastTimeStopped = -1.0;
    }
    return self;
}

-(BOOL)isSelectedByUser {
    return _wasClicked;
}

- (int)numStepsUntilEdge:(StreetEdge *)edge {
    int ns = 1;
    GraphRoute *destination =  self.intendedRoute;
    NSArray *steps = [destination steps];
    
    for (int i = self.stepIndex; i < steps.count; i++) {
        GraphRouteStep *step = steps[i];
        if (step.edge == edge) break;
        ns++;
    }
    return ns;
}

-(CGFloat)lastSpeedPerSecond {
    return _lastSpeed * 30;
}

- (BOOL)getIsOnGraph {
    return [self.carView superview] != nil;
}

- (BOOL)isReadyForRemoval {
    return _readyForRemoval;
}

- (StreetEdge *)getCurrentEdge {
    return self.currentStep.edge;
}

- (IntersectionNode *)getFarNode {
    return [self.currentStep.edge getOppositeNode:self.currentStep.node];
}

- (BOOL)isInIntersectionRange {
    StreetEdge *farStep = self.currentStep.edge;
    IntersectionNode *farNode = [farStep getOppositeNode:self.currentStep.node];
    
    double dist = [ClickableGraphRenderedView distance:self.currentLongLat andPoint:farNode.longLat];
    
    return (dist < DIST_TO_YELLOWIFY);
}



- (BOOL)carIsWithinExpandedFollowDist:(CarController *)other {
    double distBetween = [ClickableGraphRenderedView distance:other.currentLongLat andPoint:self.currentLongLat];
    if (distBetween <= 1.3*CAR_MIN_SEP) return YES;
    return NO;

}

- (NSArray *)carsAheadOfMeSorted {
    NSArray *cars = [CityGraph getCarsOnEdge:self.currentStep.edge startPoint:self.currentStep.node];
    
    IntersectionNode *farNode = [self getFarNode];
    
    NSMutableArray *forwardDirCars = [NSMutableArray new];
    
    double myDist = [ClickableGraphRenderedView distance:self.currentLongLat andPoint:farNode.longLat];
    // Filter to only cars ahead of me.
    for (CarController *other in cars) {
        double theirDist = [ClickableGraphRenderedView distance:other.currentLongLat andPoint:farNode.longLat];
        if (theirDist < myDist) [forwardDirCars addObject:other];
    }
    
    NSArray *sortedArray = [forwardDirCars sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        double dist_a = [ClickableGraphRenderedView distance:((CarController*)a).currentLongLat andPoint:self.currentLongLat];
        double dist_b = [ClickableGraphRenderedView distance:((CarController*)b).currentLongLat andPoint:self.currentLongLat];
        if (dist_a < dist_b) {
            return NSOrderedAscending;
        } else if (dist_a > dist_b) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];

    return sortedArray;
}

- (CarController *)getImmediateNextCar {
    NSArray *carsAhead = [self carsAheadOfMeSorted];
    if (!carsAhead || carsAhead.count == 0) return nil;
    return carsAhead[0];
}


- (BOOL)chainedHardStopImpending {
    
    NSArray *carsAhead = [self carsAheadOfMeSorted];
    
    if (carsAhead.count == 0) return NO;
    
    // Check immediate next car!
    if (carsAhead.count >= 1) {
        CarController *closest = carsAhead[0];
        double distBetween = [ClickableGraphRenderedView distance:closest.currentLongLat andPoint:self.currentLongLat];
        if (distBetween > 1.31*CAR_MIN_SEP) return NO;
        // Next car is hard stopped. That means we'll end up hard stopped. :(
        if (closest.hardStopped) return YES;

    }
    
    // If we have more than 1 immediate next car, check for more backup
    for (int i = 0; i < carsAhead.count - 1; i++) {
        CarController *carA = carsAhead[i];
        CarController *carB = carsAhead[i+1];
        
        double distBetween = [ClickableGraphRenderedView distance:carA.currentLongLat andPoint:carB.currentLongLat];
        // No worry, the next car is far enough away anyway
        if (distBetween > 1.31*CAR_MIN_SEP) return NO;
        
        // Next car is hard stopped. That means we'll end up hard stopped. :(
        if (carB.hardStopped) return YES;
        
    }
    
    return NO;

}

- (void)markStartTime:(NSTimeInterval)time {
    self.startTimeInterval = time;
}

- (BOOL)checkBackedUpIntxn {
    if ([self isInIntersectionRange]) {
        GraphRoute *destination =  self.intendedRoute;
        NSArray *steps = [destination steps];
        GraphRouteStep *first = steps[self.stepIndex + 1];
        if (first.edge == nil) {
            return NO;
        }
        
        NSArray *cars = [CityGraph getCarsOnEdge:first.edge startPoint:first.node];
        
        if (cars.count > 0) {
            CarController *firstCarOnEdge = cars[0];
            double dist_between = [ClickableGraphRenderedView distance:firstCarOnEdge.currentLongLat andPoint:first.node.longLat];
             if (dist_between < CAR_MIN_SEP*0.35)
                 return YES;
        }
        
    }
    return NO;
}

// Calculates velocity in terms of pixel values
- (double)velocity_helper {
    IntersectionNode *farNode = [self getFarNode];
    LightPhaseMachine *lightPhase = farNode.light_phase_machine;
    
    BOOL isNS = (self.currentStep.edge == farNode.n_port || self.currentStep.edge == farNode.s_port);
    
    AALightUnitColor color = [lightPhase lightColorForDirection:( isNS ? NS_DIRECTION : EW_DIRECTION)];
    
    // Respect the signal.
    if ([self isInIntersectionRange]) {
        
        if ([self checkBackedUpIntxn]) {
            self.hardStopped = YES;
            return 0.0;
        } else {
            self.hardStopped = NO;
        }
        
        // Only go forward on green lights. The true yellow time has been halved to simulate running a yellow...
        if (color == GREEN_LIGHTUNIT) {
            self.hardStopped = NO;
            return STANDARD_SPEED;
        } else {
            self.hardStopped = YES;
            return 0.0;
        }
    }
    
    // If no signal, get the immediate next car on the edge.
    CarController *immediateNextCar = [self getImmediateNextCar];
    
    if (immediateNextCar) {

        // Distance is way too close? Stop
        double distBetween = [ClickableGraphRenderedView distance:immediateNextCar.currentLongLat andPoint:self.currentLongLat];
        if (distBetween < CAR_MIN_SEP) return 0;

    
        // Here's the magic where we implement 2x following distance while cars ahead are in motion!
        BOOL chainedStop = [self chainedHardStopImpending];
            if (chainedStop)
                return STANDARD_SPEED; // We must creep up to "very short prox" distance.
            else {
                // If the cars in front are flowing, we need to bcak off
                if ([self carIsWithinExpandedFollowDist:immediateNextCar])
                    return 0; // stay back!
            }
    }

    // If no car, proceed ahead!
    return STANDARD_SPEED;
}

- (double)velocity {
    double result = [self velocity_helper];
    _lastSpeed = result;
    
    // State machine logic to properly accumulate time spent stopped on this edge... It works...
    if (_lastTimeStopped == -1.) {
        if (result == 0.0)
            _lastTimeStopped = [self.secondVC masterTime];
    } else { // previously stopped
            self.timeStoppedOnThisEdge += [self.secondVC masterTime] - _lastTimeStopped;
        if (result == 0) {
            _lastTimeStopped = [self.secondVC masterTime];
        } else {
            _lastTimeStopped = -1.;
        }
    }
    
    return result;
}



- (void)setUnselected {
    _wasClicked = NO;
}

- (void)didClickOnCar {
    NSLog(@"Did click on car %ld", _uniqueID);
    
    if (_wasClicked) {
        _wasClicked = NO;
    } else {
    
        [self.secondVC unselectAllCars];
        _wasClicked = YES;
    
    }
    
    // Force show path update even if simulation is paused!
    [self.secondVC.clickableRenderView setNeedsDisplay];
    NSLog(@"Hard_stopped %d and last velocity %.3f timeWaiting %.2f", self.hardStopped, 30*_lastSpeed, self.timeStoppedOnThisEdge);
}


- (void)vanquish {
    _readyForRemoval = YES; // Flag to communicate with second view controller!
    self.endTimeInterval = [self.secondVC masterTime];
    
    if (!self.shadowRandomCar)
        [self.secondVC reportE2EDelayForID:self.uniqueID andInterval:self.endTimeInterval - self.startTimeInterval];
    else {
        if (REPORT_E2E_DELAY_EVEN_IF_SHADOW){
            [self.secondVC reportE2EDelayForID:self.uniqueID andInterval:self.endTimeInterval - self.startTimeInterval];
        }
    }
}

- (void)advanceToNextStepIndex {
    

    self.stepIndex++;

    GraphRoute *destination =  self.intendedRoute;
    NSArray *steps = [destination steps];
    
    GraphRouteStep *first = steps[self.stepIndex];
    
    // End of route!
    if (first.edge == nil) {
        [self vanquish];
        return;
    }
    
    [self.secondVC putCarOnEdge:first.edge andStartPoint:first.node withCar:self];
    
    BOOL isA_to_B = [first.edge isAtoBForStartNode:first.node];
    if (isA_to_B)
        [first.edge.futureABCars removeObject:self];
    else
        [first.edge.futureBACars removeObject:self];
    
    self.currentStep = first;
    self.oldDist = CGFLOAT_MAX;
    
    self.lastTimeStopped = -1;
    self.timeStoppedOnThisEdge = 0.0;
    
}

// This method checks if the car needs to turn onto the next node...
- (void)placeCarOnNextStepIfNeeded:(GraphRouteStep *)step currentStepSize:(CGPoint)stepP {
    StreetEdge *farStep = self.currentStep.edge;
    IntersectionNode *farNode = [farStep getOppositeNode:self.currentStep.node];
    
    double dist = [ClickableGraphRenderedView distance:self.currentLongLat andPoint:farNode.longLat];

    if (dist <= _oldDist) {
        _oldDist = dist;
        return;
    } else {
        
        // Distance increased too far, logic to undo a step
        CGPoint oldCenter = self.currentLongLat;
        oldCenter.x -= stepP.x;
        oldCenter.y += stepP.y; // because we're dealing with lat long and not coordinates
        self.currentLongLat = oldCenter;

        [self advanceToNextStepIndex];
        return; // Distance increased!
        
    }
}

- (void)turnCarYellowIfCloseToIntersection {
    
    if ([self isInIntersectionRange]) {
         self.carView.overrideColor = [UIColor yellowColor];
    } else {
        
        if (_wasClicked)
            self.carView.overrideColor = [UIColor redColor];
        else
            self.carView.overrideColor = nil;
    }
}

- (void)initializeIfNeeded {
    if (!_inited) {
        GraphRoute *destination =  self.intendedRoute;
        NSArray *steps = [destination steps];
        
        GraphRouteStep *first = steps[0];
        self.currentStep = first;
        
        if (first.edge) {
            [self.secondVC putCarOnEdge:first.edge andStartPoint:first.node withCar:self];
        }
        
        //  Tell future intersections that we'll be a future car!
        for (NSUInteger i = 1; i < steps.count; i++) {
            GraphRouteStep *dst_step = steps[i];
            StreetEdge *streetEdge = dst_step.edge;
            BOOL isA_to_B = [streetEdge isAtoBForStartNode:dst_step.node];
            if (isA_to_B)
                [streetEdge.futureABCars addObject:self];
            else
                [streetEdge.futureBACars addObject:self];
            
        }
        
    }
    _inited = true;
}

- (NSTimeInterval)getTimeSpentWaitingOnThisEdge {
    return self.timeStoppedOnThisEdge;
}

- (void)doTick:(NSTimeInterval )timeDiff {
    
    GraphRouteStep *first = self.currentStep;
    
    StreetEdge *startEdge = first.edge;

    IntersectionNode *start = first.node;
    CGPoint dirVector = [startEdge getDirectionVectorForStartNode:start];
    
    CGPoint up = CGPointMake(0, -1);
    
    double angle =  atan2(dirVector.y, dirVector.x) - atan2(up.y, up.x);
    
    CGPoint translateMe = dirVector;
    translateMe.x *= [self velocity] * timeDiff;
    translateMe.y *= [self velocity] * timeDiff;
    
    CGPoint oldCenter = self.currentLongLat;
    oldCenter.x += translateMe.x;
    oldCenter.y -= translateMe.y; // because we're dealing with lat long and not coordinates
    self.currentLongLat = oldCenter;
    
    self.carView.transform = CGAffineTransformMakeRotation(angle);
    
    [self turnCarYellowIfCloseToIntersection];
    
    [self placeCarOnNextStepIfNeeded:first currentStepSize:translateMe];

    
}

@end
