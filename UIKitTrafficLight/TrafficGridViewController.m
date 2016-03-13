//
//  SecondViewController.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "TrafficGridViewController.h"
#import "IntersectionNode.h"
#import "StreetEdge.h"
#import "GraphRoute.h"
#import "ClickableGraphRenderedView.h"
#import "LightPhaseMachine.h"
#import "StopLightTimingOptionsPopoverViewController.h"
#import "SimulationSettingsViewController.h"

#import "CarController.h"

@interface TrafficGridViewController ()
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic,strong) UIPopoverController *timingsPopover;
@property (nonatomic,strong) UIPopoverController *simSettingsPopover;
#pragma clang diagnostic pop

@end

@implementation TrafficGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _timeMultiplier = 1.0;

    CityGraph *theGraph = [CityGraph new];
    self.graph = theGraph;
    [self establishGraph];
    
    _allCars = [NSMutableArray new];
    _drawAllPaths = YES;
    _frequentUIUpdates = YES;

    [self setEmitButtonsEnabled:NO];

    // Make this smarter?
    [self updateSpawnButtons];
    
    self.clickableRenderView.graph = theGraph;
    self.clickableRenderView.containingViewController = self;
    
    [self.scrollView setDelegate:self];
    
    [self.clickableRenderView setNeedsDisplay];
    
    _e2eDelays = [NSMutableDictionary new];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.clickableRenderView;
    
}
- (NSArray *)getCarsToDraw {
    return _allCars;
}

- (IBAction)considerPenaltyChanged:(UISwitch *)sender {
    if (!sender.on)
        [self.rtPenaltySwitch setOn:NO animated:YES];
}
- (IBAction)rtPenaltyChanged:(UISwitch *)sender {
    if (sender.on) {
        [self.considerLightSwitch setOn:YES animated:YES];
        if (self.adaptiveCycleTimesSwitch.on)
            [self.adaptiveCycleTimesSwitch setOn:NO animated:YES];
    }
}
- (IBAction)adaptiveCycleChanged:(UISwitch *)sender {
    if (sender.on) {
        [self.rtPenaltySwitch setOn:NO animated:YES];
    }
}

- (IBAction)segmentControlChanged:(id)sender {
    [self.activeTimer invalidate];
    self.activeTimer = nil;
    [self resetAll:nil];
}

- (IBAction)openSimSettingsController:(UIButton *)sender {
    UIStoryboard *story = self.storyboard;
    SimulationSettingsViewController *vc = [story instantiateViewControllerWithIdentifier:@"simSettingsController"];
    vc.trafficVC = self;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.simSettingsPopover = [[UIPopoverController alloc] initWithContentViewController:vc];
#pragma clang diagnostic pop

    vc.parentDrawAllPaths = &_drawAllPaths;
    vc.parentFrequentUIUpdates = &_frequentUIUpdates;
    
    CGRect loc;
    loc.origin = sender.center;
    loc.size = CGSizeMake(0, 0);
    
    [self.simSettingsPopover presentPopoverFromRect:loc inView:sender.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (double)aggregateSpeed {
    double sum = 0;
    for (int i = 0; i < _allCars.count; i++)
        sum += [_allCars[i] lastSpeedPerSecond];
    return sum /= _allCars.count;
}

- (void)editNode:(IntersectionNode *)node atPoint:(CGPoint)point {
    UIStoryboard *story = self.storyboard;
    StopLightTimingOptionsPopoverViewController *vc = [story instantiateViewControllerWithIdentifier:@"StopTimings"];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.timingsPopover = [[UIPopoverController alloc] initWithContentViewController:vc];
#pragma clang diagnostic pop
    vc.intxnnode = node;
    CGRect loc;
    loc.origin = point;
    loc.size = CGSizeMake(0, 0);
    
    [self.timingsPopover presentPopoverFromRect:loc inView:self.clickableRenderView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
}

- (void)setShortCycleTimes {
    CityGraph *graph = self.graph;
    NSDictionary *nodeNames = graph.nodes;
    for (NSString *name in nodeNames) {
        IntersectionNode *node = nodeNames[name];
        LightPhaseMachine *phaseMachine = node.light_phase_machine;
        phaseMachine.nsPhase = 10.0;
        phaseMachine.ewPhase = 10.0;
        phaseMachine.phase_offset = 0.0;

    }
    
    self.routeLabel.text = @"WARNING: SHORT CYCLES / NO SYNC";
    
}


float randomFloat(float min, float max)
{
    assert(max > min);
    float random = ((float) rand()) / (float) RAND_MAX;
    float range = max - min;
    return (random*range) + min;
}

- (void)setRandomOffsetTimes {
    CityGraph *graph = self.graph;
    NSDictionary *nodeNames = graph.nodes;
    for (NSString *name in nodeNames) {
        IntersectionNode *node = nodeNames[name];
        LightPhaseMachine *phaseMachine = node.light_phase_machine;
        
        phaseMachine.phase_offset = randomFloat(-60.0, 60.0);
        
    }
    
    self.routeLabel.text = @"WARNING: TOTALLY RANDOM TIMING/PHASES";
    
}

- (void)unselectAllCars {
    [_allCars makeObjectsPerformSelector:@selector(setUnselected)];
}


- (void)establishGraph {
    
    switch (self.scenarioSegment.selectedSegmentIndex) {
        case 0:
            [self establishBasicGraph];
            self.startEmitNodename = @"A";
            self.endEmitNodename = @"S";
        break;
        case 1:
            [self establishGreenFlowGraph];
            self.startEmitNodename = @"D";
            self.endEmitNodename = @"L";
            break;
        case 2:
            [self establishRushhourGraph];
            self.startEmitNodename = @"D";
            self.endEmitNodename = @"L";
            break;

    }
   
}
- (void)establishBasicGraph {
    
    CityGraph *graph = self.graph;
    
    self.routeLabel.text = @"Timing notes: Orignally configured for 6 \"best\" flows for A->S .";

    
    self.clickableRenderView.minLong = 45.13;
    self.clickableRenderView.maxLong = 45.48;
    self.clickableRenderView.minLati = 45.03;
    self.clickableRenderView.maxLati = 45.275;
    
    IntersectionNode *aNode = [IntersectionNode nodeWithIdentifier:@"A" andLatitude:45.26 andLongitude:45.16];
    
    IntersectionNode *ATNode = [IntersectionNode nodeWithIdentifier:@"AT" andLatitude:45.26 andLongitude:45.01];
    
    IntersectionNode *bNode = [IntersectionNode nodeWithIdentifier:@"B" andLatitude:45.26 andLongitude:45.24];
    [graph justAddNode:bNode];
    bNode.light_phase_machine.phase_offset = 15.0;
    
    
    IntersectionNode *cNode = [IntersectionNode nodeWithIdentifier:@"C" andLatitude:45.15 andLongitude:45.234];
    [graph justAddNode:cNode];
    cNode.light_phase_machine.phase_offset = 30.0;
    cNode.light_phase_machine.ewPhase = 50.0;
    
    IntersectionNode *dNode = [IntersectionNode nodeWithIdentifier:@"D" andLatitude:45.14 andLongitude:45.16];
    
    IntersectionNode *eNode = [IntersectionNode nodeWithIdentifier:@"E" andLatitude:45.07 andLongitude:45.165];
    [graph justAddNode:eNode];
    eNode.light_phase_machine.ewPhase = 4.0;

    IntersectionNode *fNode = [IntersectionNode nodeWithIdentifier:@"F" andLatitude:45.26 andLongitude:45.37];
    
    IntersectionNode *gNode = [IntersectionNode nodeWithIdentifier:@"G" andLatitude:45.15 andLongitude:45.31];
    [graph justAddNode:gNode];
    gNode.light_phase_machine.nsPhase = 10.0;
    
//    IntersectionNode *hNode = [IntersectionNode nodeWithIdentifier:@"H" andLatitude:45.045 andLongitude:45.24];
//    [graph justAddNode:hNode];
//    hNode.light_phase_machine.nsPhase = 4.0;

    
    IntersectionNode *INode = [IntersectionNode nodeWithIdentifier:@"I" andLatitude:45.26 andLongitude:45.45];
    [graph justAddNode:INode];
    INode.latitude = 45.26; INode.longitude = 45.45;
    INode.light_phase_machine.phase_offset = 18.0;
    
    IntersectionNode *JNode = [IntersectionNode nodeWithIdentifier:@"J" andLatitude:45.05 andLongitude:45.315];
    [graph justAddNode:JNode];
    JNode.light_phase_machine.phase_offset = 32.0;

    IntersectionNode *kNode = [IntersectionNode nodeWithIdentifier:@"K" andLatitude:45.15 andLongitude:45.38];

    IntersectionNode *lNode = [IntersectionNode nodeWithIdentifier:@"L" andLatitude:45.15 andLongitude:45.46];
    [graph justAddNode:lNode];
    lNode.light_phase_machine.phase_offset = 15.0;

    
    IntersectionNode *RNode = [IntersectionNode nodeWithIdentifier:@"R" andLatitude:45.05 andLongitude:45.38];
    [graph justAddNode:RNode];
    RNode.light_phase_machine.phase_offset = 25.0;
    
    IntersectionNode *SNode = [IntersectionNode nodeWithIdentifier:@"S" andLatitude:45.05 andLongitude:45.46];
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> AT"] fromNode:aNode fromPort:WEST_PORT toNode:ATNode toDir:EAST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> B"] fromNode:aNode fromPort:EAST_PORT toNode:bNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> D"] fromNode:aNode fromPort:SOUTH_PORT toNode:dNode toDir:NORTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <--> C"] fromNode:dNode fromPort:EAST_PORT toNode:cNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"B <--> F"] fromNode:bNode fromPort:EAST_PORT toNode:fNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <--> E"] fromNode:dNode fromPort:SOUTH_PORT toNode:eNode toDir:NORTH_PORT];

    BOOL EtoJ = YES;
    if (EtoJ) {
        [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"E <--> J"] fromNode:eNode fromPort:EAST_PORT toNode:JNode toDir:WEST_PORT];

    } else {   //  Removes the E-J bypass and returns to a square grid. uncomment H if you want to use it

//        [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"E <--> H"] fromNode:eNode fromPort:EAST_PORT toNode:hNode toDir:WEST_PORT];
//        [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"H <--> C"] fromNode:hNode fromPort:NORTH_PORT toNode:cNode toDir:SOUTH_PORT];
//        [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"H <--> J"] fromNode:hNode fromPort:EAST_PORT toNode:JNode toDir:WEST_PORT];
    }
    
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> B"] fromNode:cNode fromPort:NORTH_PORT toNode:bNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> G"] fromNode:cNode fromPort:EAST_PORT toNode:gNode toDir:WEST_PORT];

    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"G <--> K"] fromNode:gNode fromPort:EAST_PORT toNode:kNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"J <--> G"] fromNode:JNode fromPort:NORTH_PORT toNode:gNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"K <--> F"] fromNode:kNode fromPort:NORTH_PORT toNode:fNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"F <--> I"] fromNode:fNode fromPort:EAST_PORT toNode:INode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"K <--> L"] fromNode:kNode fromPort:EAST_PORT toNode:lNode toDir:WEST_PORT];

    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"I <--> L"] fromNode:INode fromPort:SOUTH_PORT toNode:lNode toDir:NORTH_PORT];

    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"J <--> R"] fromNode:JNode fromPort:EAST_PORT toNode:RNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"R <--> S"] fromNode:RNode fromPort:EAST_PORT toNode:SNode toDir:WEST_PORT];

    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"R <--> K"] fromNode:RNode fromPort:NORTH_PORT toNode:kNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"S <--> L"] fromNode:SNode fromPort:NORTH_PORT toNode:lNode toDir:SOUTH_PORT];

    
    // If you want to experiment with 10 second cycle times...
//    [self setShortCycleTimes];
//    [self setRandomOffsetTimes]; // experiment with random offsets to hopefully beat gridlocks
}

- (void)establishGreenFlowGraph {
    
    NSLog(@"Green flow graph");
    self.routeLabel.text = @"Timing notes: Originally, D to L offsets configured for Green Flow";

    CityGraph *graph = self.graph;
    
    self.clickableRenderView.minLong = 45.13;
    self.clickableRenderView.maxLong = 45.48;
    self.clickableRenderView.minLati = 45.03;
    self.clickableRenderView.maxLati = 45.275;
    
    IntersectionNode *aNode = [IntersectionNode nodeWithIdentifier:@"A" andLatitude:45.26 andLongitude:45.16];
    
    IntersectionNode *bNode = [IntersectionNode nodeWithIdentifier:@"B" andLatitude:45.26 andLongitude:45.24];
    [graph justAddNode:bNode];
    bNode.light_phase_machine.phase_offset = 15.0;
    
    
    IntersectionNode *cNode = [IntersectionNode nodeWithIdentifier:@"C" andLatitude:45.15 andLongitude:45.234];
    [graph justAddNode:cNode];
    cNode.light_phase_machine.phase_offset = 14.0;
    
    IntersectionNode *dNode = [IntersectionNode nodeWithIdentifier:@"D"andLatitude:45.14 andLongitude:45.16];
    [graph justAddNode:dNode];
    dNode.light_phase_machine.phase_offset = 30.0;
    
    
    IntersectionNode *gNode = [IntersectionNode nodeWithIdentifier:@"G" andLatitude:45.15 andLongitude:45.31];
    [graph justAddNode:gNode];
    gNode.light_phase_machine.phase_offset = -7.0;
    
    IntersectionNode *eNode = [IntersectionNode nodeWithIdentifier:@"E" andLatitude:45.07 andLongitude:45.165];
    [graph justAddNode:eNode];
    eNode.light_phase_machine.ewPhase = 4.0;
    
    IntersectionNode *fNode = [IntersectionNode nodeWithIdentifier:@"F" andLatitude:45.26 andLongitude:45.37];
    
    IntersectionNode *lNode = [IntersectionNode nodeWithIdentifier:@"L" andLatitude:45.15 andLongitude:45.46];
    [graph justAddNode:lNode];
    lNode.light_phase_machine.phase_offset = 16.0;
    lNode.light_phase_machine.ewPhase = 50;
    lNode.light_phase_machine.nsPhase = 10;

    
    IntersectionNode *kNode = [IntersectionNode nodeWithIdentifier:@"K" andLatitude:45.15 andLongitude:45.38];
    [graph justAddNode:kNode];
    kNode.light_phase_machine.phase_offset = -26.0;
    
    IntersectionNode *JNode = [IntersectionNode nodeWithIdentifier:@"J" andLatitude:45.05 andLongitude:45.315];
    [graph justAddNode:JNode];
    JNode.light_phase_machine.phase_offset = 32.0;
    
    
    IntersectionNode *RNode = [IntersectionNode nodeWithIdentifier:@"R" andLatitude:45.05 andLongitude:45.38];
    [graph justAddNode:RNode];
    RNode.light_phase_machine.phase_offset = 25.0;
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> B"] fromNode:aNode fromPort:EAST_PORT toNode:bNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> D"] fromNode:aNode fromPort:SOUTH_PORT toNode:dNode toDir:NORTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <--> C"] fromNode:dNode fromPort:EAST_PORT toNode:cNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"B <--> F"] fromNode:bNode fromPort:EAST_PORT toNode:fNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <--> E"] fromNode:dNode fromPort:SOUTH_PORT toNode:eNode toDir:NORTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"E <--> J"] fromNode:eNode fromPort:EAST_PORT toNode:JNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> B"] fromNode:cNode fromPort:NORTH_PORT toNode:bNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> G"] fromNode:cNode fromPort:EAST_PORT toNode:gNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"G <--> K"] fromNode:gNode fromPort:EAST_PORT toNode:kNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"J <--> G"] fromNode:JNode fromPort:NORTH_PORT toNode:gNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"K <--> F"] fromNode:kNode fromPort:NORTH_PORT toNode:fNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"K <--> L"] fromNode:kNode fromPort:EAST_PORT toNode:lNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"J <--> R"] fromNode:JNode fromPort:EAST_PORT toNode:RNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"R <--> K"] fromNode:RNode fromPort:NORTH_PORT toNode:kNode toDir:SOUTH_PORT];

}

- (void)establishRushhourGraph {
    NSLog(@"Rush hour graph");
    CityGraph *graph = self.graph;
    
    self.routeLabel.text = @"Timing: Originally D to L ALL GREEN. J->G is infinitely starved when C->L is fully loaded.";

    
    // Cross section starvation can result otherwise!
    BOOL withDecongestionOffset = NO;
    
    self.clickableRenderView.minLong = 45.13;
    self.clickableRenderView.maxLong = 45.48;
    self.clickableRenderView.minLati = 45.03;
    self.clickableRenderView.maxLati = 45.275;
    
    IntersectionNode *aNode = [IntersectionNode nodeWithIdentifier:@"A" andLatitude:45.26 andLongitude:45.16];
    
    IntersectionNode *bNode = [IntersectionNode nodeWithIdentifier:@"B" andLatitude:45.26 andLongitude:45.24];
    [graph justAddNode:bNode];
    bNode.light_phase_machine.phase_offset = 15.0;
    
    
    IntersectionNode *cNode = [IntersectionNode nodeWithIdentifier:@"C" andLatitude:45.15 andLongitude:45.234];
    [graph justAddNode:cNode];
    if (withDecongestionOffset) cNode.light_phase_machine.phase_offset = -25.0;
    
    IntersectionNode *dNode = [IntersectionNode nodeWithIdentifier:@"D" andLatitude:45.14 andLongitude:45.16];

    
    IntersectionNode *gNode = [IntersectionNode nodeWithIdentifier:@"G" andLatitude:45.15 andLongitude:45.31];
    [graph justAddNode:gNode];
    if (withDecongestionOffset)  gNode.light_phase_machine.phase_offset = -15.0;
    
    IntersectionNode *eNode = [IntersectionNode nodeWithIdentifier:@"E" andLatitude:45.07 andLongitude:45.165];
    [graph justAddNode:eNode];
    eNode.light_phase_machine.ewPhase = 5.0;
    
    IntersectionNode *fNode = [IntersectionNode nodeWithIdentifier:@"F" andLatitude:45.26 andLongitude:45.37];
    
    
    IntersectionNode *lNode = [IntersectionNode nodeWithIdentifier:@"L" andLatitude:45.15 andLongitude:45.46];
    [graph justAddNode:lNode];
    if (withDecongestionOffset) lNode.light_phase_machine.phase_offset = 15.0;
    lNode.light_phase_machine.ewPhase = 50;
    lNode.light_phase_machine.nsPhase = 10;
    
    IntersectionNode *kNode = [IntersectionNode nodeWithIdentifier:@"K" andLatitude:45.15 andLongitude:45.38];
    [graph justAddNode:kNode];
    if (withDecongestionOffset)  kNode.light_phase_machine.phase_offset = 0.0;
    
    
    IntersectionNode *JNode = [IntersectionNode nodeWithIdentifier:@"J" andLatitude:45.05 andLongitude:45.315];
    [graph justAddNode:JNode];
    JNode.light_phase_machine.phase_offset = 32.0;
    
    
    IntersectionNode *RNode = [IntersectionNode nodeWithIdentifier:@"R" andLatitude:45.05 andLongitude:45.38];
    [graph justAddNode:RNode];
    RNode.light_phase_machine.phase_offset = 25.0;
    
    
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> B"] fromNode:aNode fromPort:EAST_PORT toNode:bNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> D"] fromNode:aNode fromPort:SOUTH_PORT toNode:dNode toDir:NORTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <--> C"] fromNode:dNode fromPort:EAST_PORT toNode:cNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"B <--> F"] fromNode:bNode fromPort:EAST_PORT toNode:fNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <--> E"] fromNode:dNode fromPort:SOUTH_PORT toNode:eNode toDir:NORTH_PORT];
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"E <--> J"] fromNode:eNode fromPort:EAST_PORT toNode:JNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> B"] fromNode:cNode fromPort:NORTH_PORT toNode:bNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> G"] fromNode:cNode fromPort:EAST_PORT toNode:gNode toDir:WEST_PORT];
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"G <--> K"] fromNode:gNode fromPort:EAST_PORT toNode:kNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"J <--> G"] fromNode:JNode fromPort:NORTH_PORT toNode:gNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"K <--> F"] fromNode:kNode fromPort:NORTH_PORT toNode:fNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"K <--> L"] fromNode:kNode fromPort:EAST_PORT toNode:lNode toDir:WEST_PORT];
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"J <--> R"] fromNode:JNode fromPort:EAST_PORT toNode:RNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"R <--> K"] fromNode:RNode fromPort:NORTH_PORT toNode:kNode toDir:SOUTH_PORT];

    
// Set Random offset times to relieve congestion if desired.
//    [self setRandomOffsetTimes];
}

- (IBAction)startTimer:(id)sender {
    
    if (!self.activeTimer) {
        self.activeTimer = [NSTimer timerWithTimeInterval:2.0/60.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.activeTimer forMode:NSRunLoopCommonModes];
        [self setEmitButtonsEnabled:YES];
        [self setStartClockButtonToPause:YES];

    } else {
        [self.activeTimer invalidate];
        self.activeTimer = nil;
        [self setEmitButtonsEnabled:NO];
        [self setStartClockButtonToPause:NO];
    }
}

- (void)putCarOnEdge:(StreetEdge *)edge andStartPoint:(IntersectionNode *)start withCar:(CarController*)car {
    [self.graph putCarOnEdge:edge startPoint:start andCar:car];
}

- (IBAction)startEFAutoEmitPressed:(UIButton *)sender {
    _autoEFEmit = !_autoEFEmit;
    NSString *routeName = [NSString stringWithFormat:@"%@-%@", self.startEmitNodename, self.endEmitNodename];
    if (_autoEFEmit)
        [sender setTitle:[NSString stringWithFormat:@"Stop %@ Emitting",routeName] forState:UIControlStateNormal];
    else
        [sender setTitle:[NSString stringWithFormat:@"Start Auto %@ Emit", routeName] forState:UIControlStateNormal];
}

- (IBAction)startSlowRandoEmit:(id)sender {
    _autorandoEmit = !_autorandoEmit;
    if (_autorandoEmit)
        [sender setTitle:@"Stop Rando Emit" forState:UIControlStateNormal];
    else
        [sender setTitle:@"Start Rando Emit" forState:UIControlStateNormal];
}

- (void)pruneCars:(NSTimeInterval)timeDiff {
    for (int i = (int)[_allCars count] - 1; i >= 0; i--) {
        CarController* element = _allCars[i];
        
        [element doTick:timeDiff];
        
        if ([element isReadyForRemoval]) {
            [self.graph removeCarFromGraph:element];
            [element.carView removeFromSuperview];
            [_allCars removeObjectAtIndex:i];
            if (!element.shadowRandomCar)
                _finishedCars++;
        }
    }
}

- (void)setStartClockButtonToPause:(BOOL)toPaused {
    if (!toPaused)
        [self.startClockButton setImage:[UIImage imageNamed:@"play1-150x150"] forState:UIControlStateNormal];
    else
        [self.startClockButton setImage:[UIImage imageNamed:@"pause1-150x150"] forState:UIControlStateNormal];
}

- (void)setEmitButtonsEnabled:(BOOL)enabled {
    self.startSlowRandoEmitLabel.enabled = enabled;
    self.startDFAutoEmitLabel.enabled = enabled;
    self.spawnStartEndCarButton.enabled = enabled;
    self.spawnSingleRandoCarButton.enabled = enabled;
}

- (void)updateSpawnButtons {
    NSString *startStop = _autoEFEmit ? @"Stop" : @"Start";
    NSString *routeName = [NSString stringWithFormat:@"%@-%@", self.startEmitNodename, self.endEmitNodename];
    [self.startDFAutoEmitLabel setTitle:[NSString stringWithFormat:@"%@ Auto %@ Emit",startStop, routeName] forState:UIControlStateNormal];
    [self.spawnStartEndCarButton setTitle:[NSString stringWithFormat:@"Spawn %@",routeName] forState:UIControlStateNormal];

}
- (IBAction)resetAll:(id)sender {

    [self.activeTimer invalidate];
    self.activeTimer = nil;
    
    _finishedCars = 0;
    _emittedCars = 0;
    _autorandoEmit = NO;
    _autoEFEmit = NO;
    _cumulativee2eDelay = 0;
    _numE2EReportedCars = 0;
    self.e2eDelayLabel.text = @"End-to-end delay:";

    self.routeLabel.text = @"Route";
    self.flowRateLabel.text = @"Flow Rate:";
    self.throughputLabel.text = @"Throughput:";
//    _frequentUIUpdates = YES;
    _drawAllPaths = YES;
    
    self.graph = [CityGraph new];
    [self establishGraph];
    [self updateSpawnButtons];
    [self setEmitButtonsEnabled:NO];
    

    self.masterTime = 0;
    self.clickableRenderView.graph = self.graph;
    _allCars = [NSMutableArray new];
        [self.startSlowRandoEmitLabel setTitle:@"Start Rando Emit" forState:UIControlStateNormal];
    [self setStartClockButtonToPause:NO];
    
    [self.clickableRenderView removeAllSubviews];
    [self.clickableRenderView setNeedsDisplay];

    
}


#pragma mark extra defines
#define TICKS_BETWEEN_EMITS 110.
#define TICKS_BETWEEN_RANDO_EMITS 40.

// How many timer cycles between traffic light adapations?
#define TICKS_BETWEEN_ADAPTATIONS 200.

// so that pedestrians don't get too antsy... assumes press button can preempt signals
#define IDEAL_TOTAL_CYCLE_TIME 60.

- (void)adaptTimerCycles {
    
    
    BOOL considerTimeSpentWaiting = YES;
    BOOL prescienceOn = YES;
    
    CityGraph *graph = self.graph;
    for (NSString *nodename in graph.nodes) {
        IntersectionNode *node = graph.nodes[nodename];
        
        double nsCars = [node countIncomingCarsQueued:considerTimeSpentWaiting andIsNS:YES andIntxn:node];
        double ewCars = [node countIncomingCarsQueued:considerTimeSpentWaiting andIsNS:NO andIntxn:node];
        
        double nsPrescientCars = 0;
        double ewPrescientCars = 0;
        if (prescienceOn) {
            nsPrescientCars = [node countPrescientCarsAndisNS:YES andIntxn:node];
            ewPrescientCars = [node countPrescientCarsAndisNS:NO andIntxn:node];
            nsCars += nsPrescientCars;
            ewCars += ewPrescientCars;
            
//            if ([nodename isEqualToString:@"K"] || [nodename isEqualToString:@"L"]) {
//                NSLog(@"%@'s NS Prescient :%.2f",nodename, NS_Prescient_Cars);
//                NSLog(@"%@'s EW Prescient: %.2f", nodename, EW_Prescient_Cars);
//            }
        }
        
        // Prevent div by 0 in a Laplaceian way...
        if (ewCars == 0) ewCars++;
        if (nsCars == 0) nsCars++;
        
        
        double NS_Scalar = nsCars / ewCars;
        double EW_Scalar = ewCars / nsCars;
        
        if (NS_Scalar > EW_Scalar) {
            if (NS_Scalar > 6)
                NS_Scalar = 6; // cap at 5 to 1. Make in increments of 10.
            
            double ewTime = IDEAL_TOTAL_CYCLE_TIME / (NS_Scalar + 1);
            double resultingNsTime = IDEAL_TOTAL_CYCLE_TIME - ewTime;
            [node.light_phase_machine setNextNSToDuration:resultingNsTime];
            [node.light_phase_machine setNextEWToDuration:ewTime];
        } else {
            if (EW_Scalar > 6)
                EW_Scalar = 6;
            double nsTime = IDEAL_TOTAL_CYCLE_TIME / (EW_Scalar + 1);
            double resultingEwTime = IDEAL_TOTAL_CYCLE_TIME - nsTime;
            [node.light_phase_machine setNextNSToDuration:nsTime];
            [node.light_phase_machine setNextEWToDuration:resultingEwTime];
        }
        
        
    }
    
    
}

- (void)timerTick:(id)something {
    NSTimeInterval timeDiff = 1.0/30.0 * _timeMultiplier;
    self.masterTime += timeDiff;
    
    
    static int E_F_Counts = 0;
    static int Rando_counts = 0;
    static int AdaptTimerCycles_Counts = 0;
    if (_autoEFEmit) {
        E_F_Counts++;
        
        double scaled_thirty = TICKS_BETWEEN_EMITS / _timeMultiplier;
        
        if (E_F_Counts % (int)scaled_thirty == 0) {
            [self placeCarOne:nil];
        }
    }
    
    if (_autorandoEmit) {
        Rando_counts++;
        
        double scaled_thirty = TICKS_BETWEEN_RANDO_EMITS / _timeMultiplier;
        
        if (Rando_counts % (int)scaled_thirty == 0) {
            [self emitRandomCar:nil];
        }
    }
    
    if (self.adaptiveCycleTimesSwitch.on) {
        self.rtPenaltySwitch.on = NO;
        self.rtPenaltySwitch.enabled = NO;
        AdaptTimerCycles_Counts++;
        
        double scaled_thirty = TICKS_BETWEEN_ADAPTATIONS / _timeMultiplier;
        
        if (AdaptTimerCycles_Counts % (int)scaled_thirty == 0) {
            [self adaptTimerCycles];
        }
    } else {
        self.rtPenaltySwitch.enabled = YES;
    }
    
    
    NSDictionary *nodes = self.graph.nodes;
    
    for (NSString * name in nodes) {
        IntersectionNode *node = nodes[name];
        LightPhaseMachine *phaseMachine = node.light_phase_machine;
        [phaseMachine setPhaseForMasterTimeInterval:self.masterTime];

    }
    
    [self pruneCars:timeDiff];
    
    self.clickableRenderView.drawAllPaths = _drawAllPaths;
    static int slowUpdate = 0;
    slowUpdate++;
    if (_frequentUIUpdates || slowUpdate % 4 == 0)
        [[self clickableRenderView] setNeedsDisplay];
    
    
    if (_numE2EReportedCars)
        self.e2eDelayLabel.text = [NSString stringWithFormat:@"End-to-end delay: %.2f for %d cars", _cumulativee2eDelay/_numE2EReportedCars, _numE2EReportedCars];
    self.flowRateLabel.text = [NSString stringWithFormat:@"Flow Rate: %.2f%% of %lu are moving", [self aggregateSpeed]/0.114504*100.0, (unsigned long)[_allCars count]];
    self.throughputLabel.text = [NSString stringWithFormat:@"Throughput: %d in %.2f sec", _finishedCars, self.masterTime];

    
    
}


// Returns true if node exists in the graph!
- (BOOL)validateNodeName:(NSString *)name {
    IntersectionNode *nd = [self.graph nodeInGraphWithIdentifier:name];
    return (nd != nil);
}


- (IBAction)placeCarOne:(id)sender {
    
    _emittedCars++;
    
    CarController *car = [[CarController alloc] init];
    car.secondVC = self;
    [car markStartTime:self.masterTime];
    [_allCars addObject:car];
    
    IntersectionNode *nodeStart = [self.graph nodeInGraphWithIdentifier:self.startEmitNodename];
    
    IntersectionNode *nodeEnd = [self.graph nodeInGraphWithIdentifier:self.endEmitNodename];
    
    if (nodeStart) {
        car.currentLongLat = CGPointMake(nodeStart.longitude, nodeStart.latitude);
        
        GraphRoute *route = [self.graph shortestRouteFromNode:nodeStart toNode:nodeEnd considerIntxnPenalty:self.considerLightSwitch.on realtimeTimings:self.rtPenaltySwitch.on andTime:self.masterTime andCurrentQueuePenalty:self.queingPenaltySwitch.on andIsAdaptiveTimedSystem:self.adaptiveCycleTimesSwitch.on];
        
        car.intendedRoute = route;
    }
    
    [[self clickableRenderView] setNeedsDisplay];
    
}

- (IBAction)emitRandomCar:(id)sender {
//    _emittedCars++;
    
    CarController *car = [[CarController alloc] init];
    car.secondVC = self;
    [car markStartTime:self.masterTime];

    [_allCars addObject:car];
    
    
    NSArray *allNodes = [self.graph.nodes allKeys];
    int rand1 = arc4random() % allNodes.count;
    int rand2 = arc4random() % allNodes.count;
    while (rand1 == rand2)
        rand2 = arc4random() % allNodes.count;
    
    IntersectionNode *nodeD = [self.graph nodeInGraphWithIdentifier:allNodes[rand1]];
    
    IntersectionNode *nodeF = [self.graph nodeInGraphWithIdentifier:allNodes[rand2]];
    
    if (nodeD && nodeF) {
        car.currentLongLat = CGPointMake(nodeD.longitude, nodeD.latitude);
        
        GraphRoute *route = [self.graph shortestRouteFromNode:nodeD toNode:nodeF considerIntxnPenalty:self.considerLightSwitch.on realtimeTimings:self.rtPenaltySwitch.on andTime:self.masterTime andCurrentQueuePenalty:self.queingPenaltySwitch.on andIsAdaptiveTimedSystem:self.adaptiveCycleTimesSwitch.on];
        
        car.intendedRoute = route;
        car.shadowRandomCar = YES;
    }
    
    [[self clickableRenderView] setNeedsDisplay];


}


- (IBAction)changedTimeRateSlider:(UISlider *)sender {
    _timeMultiplier = sender.value;
    self.timeRateLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}

- (void)reportE2EDelayForID:(NSUInteger)uniqueID andInterval:(NSTimeInterval)interval {
    [_e2eDelays setObject:@(interval) forKey:@(uniqueID)];
    _cumulativee2eDelay += interval;
    _numE2EReportedCars++;
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
