//
//  CarAndView.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 2/12/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "CarAndView.h"
#import "CityGraph.h"
#import "AAGraphRoute.h"
#import "AAGraphRouteStep.h"
#import "ClickableGraphRenderedView.h"
#import "AATLightPhaseMachine.h"
#import "SecondViewController.h"

#define DIST_TO_YELLOWIFY 0.011
#define CAR_STOP_SEP 0.0081
#define STANDARD_SPEED 1/270.0 // units per time tick?

@interface CarAndView () {
    BOOL _readyForRemoval;
    BOOL _wasClicked;
}

@property (nonatomic) BOOL inited;
@property (nonatomic) CGFloat oldDist;

@property (nonatomic) double last_speed;

@property (nonatomic) int step_index;
@property (nonatomic) BOOL isOnFinalStep;


@property (nonatomic, weak) AAGraphRouteStep *currentStep;
@end

@implementation CarAndView

- (instancetype)init {
    static long counter = 1;
    
    self = [super init];
    if (self) {
        _carView = [AACarView new];
        _carView.containingCar = self;
        _uniqueID = counter++;
        _step_index = 0;
        _oldDist = CGFLOAT_MAX;
    }
    return self;
}

-(BOOL)isSelectedByUser {
    return _wasClicked;
}


-(CGFloat)lastSpeedPerSecond {
    return _last_speed * 30;
}

- (BOOL)getIsOnGraph {
    return [self.carView superview] != nil;
}

- (BOOL)isReadyForRemoval {
    return _readyForRemoval;
}

- (IntersectionNode *)getFarNode {
    return [self.currentStep.edge getOppositeNode:self.currentStep.node];
}

- (BOOL)isInIntersectionRange {
    StreetEdge *farStep = self.currentStep.edge;
    IntersectionNode *farNode = [farStep getOppositeNode:self.currentStep.node];
    
    double dist = [ClickableGraphRenderedView distance:self.currentLongLat andPoint:farNode.latlong];
//    NSLog(@"Dist of car %f", dist);
    
    return (dist < DIST_TO_YELLOWIFY);
}




- (BOOL)carExistsInShortProxAhead {
    
    NSArray *cars = [CityGraph getCarsOnEdge:self.currentStep.edge startPoint:self.currentStep.node];
    
    IntersectionNode *farNode = [self getFarNode];
    
    NSMutableArray *forwardDirCars = [NSMutableArray new];
    
    double myDist = [ClickableGraphRenderedView distance:self.currentLongLat andPoint:farNode.latlong];
    // Filter to only cars ahead of me.
    for (CarAndView *other in cars) {
        if (other->_uniqueID == self->_uniqueID) continue; // ignore self
        
        double theirDist = [ClickableGraphRenderedView distance:other.currentLongLat andPoint:farNode.latlong];
        if (theirDist < myDist) [forwardDirCars addObject:other];
    }
    
    for (CarAndView *other in forwardDirCars) {
        double dist_between = [ClickableGraphRenderedView distance:other.currentLongLat andPoint:self.currentLongLat];
        if (dist_between < CAR_STOP_SEP) return YES;
    }
    
    return NO;
}



- (BOOL)chainedHardStopImpending {
    
    NSArray *cars = [CityGraph getCarsOnEdge:self.currentStep.edge startPoint:self.currentStep.node];
    
    IntersectionNode *farNode = [self getFarNode];
    
    NSMutableArray *forwardDirCars = [NSMutableArray new];
    
    double myDist = [ClickableGraphRenderedView distance:self.currentLongLat andPoint:farNode.latlong];
    // Filter to only cars ahead of me.
    for (CarAndView *other in cars) {
        double theirDist = [ClickableGraphRenderedView distance:other.currentLongLat andPoint:farNode.latlong];
        if (theirDist < myDist) [forwardDirCars addObject:other];
    }
    
    // TODO: BUGS??
    NSArray *sortedArray = [forwardDirCars sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        double dist_a = [ClickableGraphRenderedView distance:((CarAndView*)a).currentLongLat andPoint:self.currentLongLat];
        double dist_b = [ClickableGraphRenderedView distance:((CarAndView*)b).currentLongLat andPoint:self.currentLongLat];
        if (dist_a < dist_b) {
            return NSOrderedAscending;
        } else if (dist_a > dist_b) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    if (sortedArray.count == 0) return NO;
    
    // Check immediate next car!
    if (sortedArray.count >= 1) {
        CarAndView *closest = sortedArray[0];
        double dist_between = [ClickableGraphRenderedView distance:closest.currentLongLat andPoint:self.currentLongLat];
        if (dist_between > CAR_STOP_SEP) return NO;

    }
    
    // If we have more than immediate next car, check for more backup
    for (int i = 0; i < sortedArray.count - 1; i++) {
        CarAndView *carA = sortedArray[i];
        CarAndView *carB = sortedArray[i+1];
        
        double dist_between = [ClickableGraphRenderedView distance:carA.currentLongLat andPoint:carB.currentLongLat];
        if (dist_between > CAR_STOP_SEP) return NO;
        else {
            if (carB.hardStopped) return YES;
        }
        
    }
    
    return NO;

}

- (BOOL)checkBackedUpIntxn {
    if ([self isInIntersectionRange]) {
        AAGraphRoute *destination =  self.intendedRoute;
        NSArray *steps = [destination steps];
        AAGraphRouteStep *first = steps[self.step_index + 1];
        if (first.edge == nil) {
            return NO;
        }
        
        NSArray *cars = [CityGraph getCarsOnEdge:first.edge startPoint:first.node];
        
        
        for (CarAndView *carCand in cars) {
            double dist_between = [ClickableGraphRenderedView distance:carCand.currentLongLat andPoint:first.node.getLatLong];
            if (dist_between < CAR_STOP_SEP*1.5) {
                if ([carCand chainedHardStopImpending])
                    return YES;
            }
                
        }
    }
    return NO;
}

// Per second?
- (double)velocity_helper {
    IntersectionNode *farNode = [self getFarNode];
    AATLightPhaseMachine *lightPhase = farNode.light_phase_machine;
    
    BOOL isNS = (self.currentStep.edge == farNode.n_port || self.currentStep.edge == farNode.s_port);
    
    AALightUnitColor color = [lightPhase lightColorForDirection:( isNS ? NS_DIRECTION : EW_DIRECTION)];
    
    if ([self isInIntersectionRange]) {
        
        if ([self checkBackedUpIntxn]) {
            self.hardStopped = YES;
            return 0.0;
        } else {
            self.hardStopped = NO;
        }
        
        // Logic to run the yellow??
        if (color == GREEN_LIGHTUNIT) {
            self.hardStopped = NO;
            return STANDARD_SPEED;
        } else {
            self.hardStopped = YES;
            return 0.0; // TODO DECEL
        }
    }
    
    if ([self carExistsInShortProxAhead]) {
        return 0.0;
    }
    
    if ([self chainedHardStopImpending])
        return 0.0;
    

    
    return STANDARD_SPEED;
}

- (double)velocity {
    double result = [self velocity_helper];
    _last_speed = result;
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
    NSLog(@"Hard_stopped %d and last velocity %.3f", self.hardStopped, 30*_last_speed);
//    [self something];
}


- (void)vanquish {
    _readyForRemoval = YES; // Flag to communicate with second view controller!
}

- (void)advanceToNextStepIndex {
    

    self.step_index++;

    AAGraphRoute *destination =  self.intendedRoute;
    NSArray *steps = [destination steps];
    
    // TODO: End of route?
    AAGraphRouteStep *first = steps[self.step_index];
    
    if (first.edge == nil) {
        [self vanquish];
//        NSLog(@"Called vanquish!");
        return;
    }
    
    [self.secondVC putCarOnEdge:first.edge andStartPoint:first.node withCar:self];
    
    self.currentStep = first;
    self.oldDist = CGFLOAT_MAX;
}

// This will come in handy.
- (BOOL)didCarGoTooFarForStep:(AAGraphRouteStep *)step andStep:(CGPoint)stepP {
    StreetEdge *farStep = self.currentStep.edge;
    IntersectionNode *farNode = [farStep getOppositeNode:self.currentStep.node];
    
    double dist = [ClickableGraphRenderedView distance:self.currentLongLat andPoint:farNode.latlong];

    if (dist <= _oldDist) {
        // no;
        _oldDist = dist;
        return NO;
    } else {
//        NSLog(@"The distance increased, undoing a step");
        
        // Logic to undo a step
        CGPoint oldCenter = self.currentLongLat;
        oldCenter.x -= stepP.x;
        oldCenter.y += stepP.y; // because we're dealing with lat long and not coordinates
        self.currentLongLat = oldCenter;

        [self advanceToNextStepIndex];
        return YES; // Distance increased!
        
    }
    
    
    return NO;
    
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
        AAGraphRoute *destination =  self.intendedRoute;
        NSArray *steps = [destination steps];
        
        AAGraphRouteStep *first = steps[0];
        self.currentStep = first;
        
        if (first.edge) {
            [self.secondVC putCarOnEdge:first.edge andStartPoint:first.node withCar:self];
        }
    }
    _inited = true;
}

- (void)doTick:(NSTimeInterval )timeDiff {
    
    AAGraphRouteStep *first = self.currentStep;
    
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

    
//    [UIView animateWithDuration:0.25 animations:^{
        self.carView.transform = CGAffineTransformMakeRotation(angle);
//    }];
    
    [self turnCarYellowIfCloseToIntersection];
    
    [self didCarGoTooFarForStep:first andStep:translateMe];

    
    
//    IntersectionNode *end = [startEdge getOppositeNode:start];
    
    
}


// TODO:
#warning figure out dijkstra calculation w/ time penalty considered (word ladder calculation!)

// Will want to filter and sort other cars in the edge array. Will need logic to determine opposite side for purposes of permissive left turn.

@end
