//
//  FirstViewController.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "TrafficFSMViewController.h"
#import "StopLightView.h"
#import "LightPhaseMachine.h"
#import "CarView.h"

@interface TrafficFSMViewController ()
{
    double _timeMultiplier;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *northSouthRoad;
@property (weak, nonatomic) IBOutlet UIView *eastWestRoad;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet StopLightView *testLightSW;
@property (weak, nonatomic) IBOutlet StopLightView *testLightEast;
@property (weak, nonatomic) IBOutlet StopLightView *testLightNorth;
@property (weak, nonatomic) IBOutlet StopLightView *testLightWest;


@property (strong, nonatomic) LightPhaseMachine *phaseMachine;
@property (strong, nonatomic) NSArray *allLights;

@property (strong, nonatomic) NSTimer *activeTimer;
@property (weak, nonatomic) IBOutlet UILabel *NsPhaseLabel;
@property (weak, nonatomic) IBOutlet UILabel *ewphaselabel;
@property (weak, nonatomic) IBOutlet UILabel *timeRateLabel;

@property (strong, nonatomic) NSMutableArray *activeCars;
@property (strong, nonatomic) NSArray *road_pair;


@end

@implementation TrafficFSMViewController

#define CAR_SIZE 20.0
#define CAR_MOVE_ITERATION (1.0 * _timeMultiplier)

#pragma mark CarMoveStuff

#pragma -

- (BOOL)isNSGreen {
    return [self.testLightNorth lightColor] == GREEN_LIGHTUNIT;
}
- (BOOL)isEWGreen {
    return [self.testLightEast lightColor] == GREEN_LIGHTUNIT;
}

- (void)pruneOutOfBoundsCars {
    
    NSMutableArray *removalCandidates = [NSMutableArray new];
    
    
    for (CarView *car in self.activeCars) {
        
        CGPoint carOrigin = car.frame.origin;
        CGPoint ewOrigin = self.eastWestRoad.frame.origin;
        CGPoint nsOrigin = self.northSouthRoad.frame.origin;
        if (carOrigin.x < ewOrigin.x - 5) [removalCandidates addObject:car];
        else if (carOrigin.x > (ewOrigin.x + self.eastWestRoad.frame.size.width)) [removalCandidates addObject:car];
        else if (carOrigin.y < nsOrigin.y - 5.0) [removalCandidates addObject:car];
        else if (carOrigin.y > (nsOrigin.y + self.northSouthRoad.frame.size.height)) [removalCandidates addObject:car];
    }
    
    [removalCandidates makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self.activeCars removeObjectsInArray:removalCandidates];

}

CGFloat distanceTwoViewCenters(UIView *viewOne, UIView *viewTwo) {
    
    CGFloat accumulator = 0;
    
    CGPoint viewOneCenter = viewOne.center;
    CGPoint viewTwoCenter = viewTwo.center;
    
    accumulator += powf(viewOneCenter.x - viewTwoCenter.x, 2.0);
    accumulator += powf(viewOneCenter.y - viewTwoCenter.y, 2.0);
    return sqrtf(accumulator);
}

#define BUFFER (4.0 + (_timeMultiplier / 2.0))
#define INTERCAR_SPACING (2 * CAR_SIZE + (_timeMultiplier * 2.0))
#define INTERCAR_SPACING_STOPPED (CAR_SIZE + (_timeMultiplier / 2.0))



- (BOOL)shouldCarBeInMotion:(CarView *)car {
    BOOL doMoveCar = NO;
    CGPoint approach_max = [TrafficFSMUtilities stopLineForRoads:self.road_pair andApproachDir:car.approachDir andCarSize:CAR_SIZE];
    
    
    if (car.approachDir == NORTH_APPROACH) {
        float curCarY = car.frame.origin.y;
        if (curCarY < approach_max.y || (curCarY > approach_max.y + BUFFER) || [self isNSGreen])
            doMoveCar = YES;
        
    }
    
    else if (car.approachDir == SOUTH_APPROACH) {
        float curCarY = car.frame.origin.y;
        if (curCarY > approach_max.y || (curCarY < approach_max.y - BUFFER) || [self isNSGreen])
            doMoveCar = YES;
        
    }
    
    else if (car.approachDir == EASTWARD_APPROACH) {
        float curCarX = car.frame.origin.x;
        if (curCarX > approach_max.x || (curCarX < approach_max.x - BUFFER) || [self isEWGreen])
            doMoveCar = YES;
        
    }
    
    else if (car.approachDir == WESTWARD_APPROACH) {
        float curCarX = car.frame.origin.x;
        if (curCarX < approach_max.x || (curCarX > approach_max.x + BUFFER) || [self isEWGreen])
            doMoveCar = YES;
    }
    
    return doMoveCar;

}

- (CGFloat)howMuchFartherNextCar:(CarView *)local nextCar:(CarView *)nextCar {
    if (local.approachDir == NORTH_APPROACH || local.approachDir == SOUTH_APPROACH) {
        CGFloat prelim = local.center.y - nextCar.center.y;
        return fabs(prelim);
    } else {
        CGFloat prelim = local.center.x - nextCar.center.x;
        return fabs(prelim);
    }
}

- (void)moveCarsIntelligently {

    [self pruneOutOfBoundsCars];

    for (CarView *car in self.activeCars) {
        
        BOOL shouldBeInMotion = [self shouldCarBeInMotion:car];
        
        CarView *firstNextCarAhead = [TrafficFSMUtilities getNextCarAhead:car allCars:self.activeCars];

        BOOL farthestNextInMotion = [self shouldCarBeInMotion:firstNextCarAhead];
        
        CarView *curNextCar = firstNextCarAhead;
        while (curNextCar && farthestNextInMotion) {
            curNextCar = [TrafficFSMUtilities getNextCarAhead:curNextCar allCars:self.activeCars];
            if (!curNextCar) break;
            
            farthestNextInMotion = [self shouldCarBeInMotion:curNextCar];
        }

        // If next car is moving, we need the larger intercar spacing
        CGFloat max_intercar = (farthestNextInMotion) ? INTERCAR_SPACING :INTERCAR_SPACING_STOPPED;

        if (firstNextCarAhead && distanceTwoViewCenters(car, firstNextCarAhead) < max_intercar)
            shouldBeInMotion = NO;
        
        if (shouldBeInMotion)
            [car moveInApproachDir:CAR_MOVE_ITERATION];
    }
}

- (void)placeNewCarForApproach:(AApproachDirs)approachDir {
    
    
    CGPoint startingPoint = [TrafficFSMUtilities getBaseCoordinateForRoads:self.road_pair andApproachDir:approachDir];
    CGSize carSize = CGSizeMake(CAR_SIZE, CAR_SIZE);
    
    CarView *car = [[CarView alloc] initWithFrame:(CGRect){startingPoint,carSize}];
    car.trafficFsmRequiresTransform = YES;
    [car setApproachDir:approachDir];
    car.backgroundColor = [UIColor clearColor];
    car.clipsToBounds = NO;
    [self.scrollView addSubview:car];
    
    [self.activeCars addObject:car];
    
    self.mySlider.value -= 0.1;
}

- (void)layoutTrafficLights {
    
    self.allLights = @[ self.testLightEast, self.testLightNorth, self.testLightSW, self.testLightWest];
    [self.allLights makeObjectsPerformSelector:@selector(sizeToFit)];
    
    self.testLightEast.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.testLightWest.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.testLightNorth.transform = CGAffineTransformMakeRotation(M_PI);
    
}

- (void)setLightDirections {
    self.testLightNorth.light_direction = self.testLightSW.light_direction = NS_DIRECTION;
    self.testLightEast.light_direction = self.testLightWest.light_direction = EW_DIRECTION;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.activeCars = [NSMutableArray new];
    _timeMultiplier = 1.0;
    self.phaseMachine = [[LightPhaseMachine alloc] init];
    [self layoutTrafficLights];
    [self setLightDirections];
    self.road_pair = @[self.eastWestRoad, self.northSouthRoad];

    [self placeNewCarForApproach:NORTH_APPROACH];
    [self placeNewCarForApproach:SOUTH_APPROACH];
    // Do any additional setup after loading the view, typically from a nib.
}



- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)redrawLightsBasedOnPhaseMachine {
    for (StopLightView *light in self.allLights) {
        [light setColor:[self.phaseMachine lightColorForDirection:light.light_direction]];
    }
}

- (void)timerTick:(id)something {
    self.masterTime += 1.0/30.0 * _timeMultiplier;
    
    [self.phaseMachine setPhaseForMasterTimeInterval:self.masterTime];
    [self redrawLightsBasedOnPhaseMachine];
    
    float progress = [self.phaseMachine getCurrentPhaseProgress];
    self.progressView.progress = progress;
    
    [self moveCarsIntelligently];
}

- (IBAction)cycleNow:(id)sender {
    
    // there must be some invariant so that master time doesn't get incremented beyond a specified amount...
    self.masterTime += 0.50;
    
    [self.phaseMachine setPhaseForMasterTimeInterval:self.masterTime];
    [self redrawLightsBasedOnPhaseMachine];
    
    NSLog(@"Actually changing master time : %.2f", self.masterTime);
//    static int phase = RED_LIGHTUNIT;
//    
//    phase++;
//    
//    [self.testLightSW setColor:phase % 3];
}
- (IBAction)startTimer:(id)sender {
    
    UIButton *sender_as_label = (UIButton *)sender;
    
    if (!self.activeTimer) {
        self.activeTimer = [NSTimer scheduledTimerWithTimeInterval:2.0/60.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [sender_as_label setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.activeTimer invalidate];
        self.activeTimer = nil;
        [sender_as_label setTitle:@"Start timer" forState:UIControlStateNormal];
    }
}
- (IBAction)changedEWPhaseLenSlider:(UISlider *)sender {
    [self.phaseMachine setEwPhase:sender.value];
    self.ewphaselabel.text = [NSString stringWithFormat:@".%1f", sender.value];
}

- (IBAction)changedNSPhaseLenSlider:(UISlider *)sender {
    [self.phaseMachine setNsPhase:sender.value];
    self.NsPhaseLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}

- (IBAction)changedTimeRateSlider:(UISlider *)sender {
    _timeMultiplier = sender.value;
    self.timeRateLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}

- (IBAction)dispatchNewNorthCar:(id)sender {
    [self placeNewCarForApproach:NORTH_APPROACH];
}

- (IBAction)dispatchNewSouthCar:(id)sender {
    [self placeNewCarForApproach:SOUTH_APPROACH];
}
- (IBAction)dispatchNewEastCar:(id)sender {
    [self placeNewCarForApproach:EASTWARD_APPROACH];

}

- (IBAction)dispatchNewWestCar:(id)sender {
    [self placeNewCarForApproach:WESTWARD_APPROACH];

}

@end
