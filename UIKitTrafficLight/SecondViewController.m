//
//  SecondViewController.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "SecondViewController.h"
#import "IntersectionNode.h"
#import "StreetEdge.h"
#import "AAGraphRoute.h"
#import "ClickableGraphRenderedView.h"
#import "LightPhaseMachine.h"
#import "StopLightTimingOptionsPopoverViewController.h"
#import "SimulationSettingsViewController.h"

#import "CarAndView.h"

@interface SecondViewController ()
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic,strong) UIPopoverController *timingsPopover;
@property (nonatomic,strong) UIPopoverController *simSettingsPopover;
#pragma clang diagnostic pop

@end

@implementation SecondViewController

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

- (IBAction)segmentControlChanged:(id)sender {
    [self.activeTimer invalidate];
    self.activeTimer = nil;
    [self resetAll:nil];
}

- (IBAction)openSimSettingsController:(UIButton *)sender {
    UIStoryboard *story = self.storyboard;
    SimulationSettingsViewController *vc = [story instantiateViewControllerWithIdentifier:@"simSettingsController"];
    vc.secondVC = self;
    
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
            self.endEmitNodename = @"K";
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
    
    self.routeLabel.text = @"TIMING: Timing cycles between 3 \"best\" flows for A->K .";

    
    self.clickableRenderView.min_long = 45.10;
    self.clickableRenderView.max_long = 45.50;
    //.7117
    self.clickableRenderView.min_lati = 45.00;
    self.clickableRenderView.max_lati = 45.285;
    
    IntersectionNode *aNode = [IntersectionNode nodeWithIdentifier:@"A"];
    aNode.latitude = 45.26; aNode.longitude = 45.16;
    
    IntersectionNode *ATNode = [IntersectionNode nodeWithIdentifier:@"AT"];
    ATNode.latitude = 45.26; ATNode.longitude = 45.01;
    
    IntersectionNode *bNode = [IntersectionNode nodeWithIdentifier:@"B"];
    bNode.latitude = 45.26; bNode.longitude = 45.24;[graph justAddNode:bNode];
//    fNode.light_phase_machine.ewPhase = 120.0; fNode.light_phase_machine.nsPhase = 4;
    bNode.light_phase_machine.phase_offset = 15.0;
    
    
    IntersectionNode *cNode = [IntersectionNode nodeWithIdentifier:@"C"];
    cNode.latitude = 45.15; cNode.longitude = 45.234; [graph justAddNode:cNode];
//#warning PUT THESE BACK!
    cNode.light_phase_machine.phase_offset = 30.0;
    cNode.light_phase_machine.ewPhase = 50.0;
    
    IntersectionNode *dNode = [IntersectionNode nodeWithIdentifier:@"D"];
    dNode.latitude = 45.14; dNode.longitude = 45.16;
    
    IntersectionNode *eNode = [IntersectionNode nodeWithIdentifier:@"E"]; [graph justAddNode:eNode];
    eNode.latitude = 45.07; eNode.longitude = 45.165;
    eNode.light_phase_machine.ewPhase = 4.0;

    IntersectionNode *fNode = [IntersectionNode nodeWithIdentifier:@"F"];
    fNode.latitude = 45.26; fNode.longitude = 45.37; [graph justAddNode:fNode];

    
    IntersectionNode *gNode = [IntersectionNode nodeWithIdentifier:@"G"];
    gNode.latitude = 45.15; gNode.longitude = 45.31;
    gNode.light_phase_machine.nsPhase = 10.0;
    
//    IntersectionNode *hNode = [IntersectionNode nodeWithIdentifier:@"H"]; [graph justAddNode:hNode];
//    hNode.latitude = 45.045; hNode.longitude = 45.24;
//    hNode.light_phase_machine.nsPhase = 4.0;

    
    IntersectionNode *INode = [IntersectionNode nodeWithIdentifier:@"I"]; [graph justAddNode:INode];
    INode.latitude = 45.26; INode.longitude = 45.45;
    INode.light_phase_machine.phase_offset = 18.0;
    
    IntersectionNode *JNode = [IntersectionNode nodeWithIdentifier:@"J"];    [graph justAddNode:JNode];
    JNode.latitude = 45.05; JNode.longitude = 45.315;
    JNode.light_phase_machine.phase_offset = 32.0;

    
    IntersectionNode *kNode = [IntersectionNode nodeWithIdentifier:@"K"];
    kNode.latitude = 45.15; kNode.longitude = 45.38;

    IntersectionNode *lNode = [IntersectionNode nodeWithIdentifier:@"L"]; [graph justAddNode:lNode];
    lNode.latitude = 45.15; lNode.longitude = 45.46;
    lNode.light_phase_machine.phase_offset = 15.0;

    
    IntersectionNode *RNode = [IntersectionNode nodeWithIdentifier:@"R"]; [graph justAddNode:RNode];
    RNode.latitude = 45.05; RNode.longitude = 45.38;
    RNode.light_phase_machine.phase_offset = 25.0;
    
    IntersectionNode *SNode = [IntersectionNode nodeWithIdentifier:@"S"];
    SNode.latitude = 45.05; SNode.longitude = 45.46;

    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> AT"] fromNode:aNode fromPort:WEST_PORT toNode:ATNode toDir:EAST_PORT];

    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> B"] fromNode:aNode fromPort:EAST_PORT toNode:bNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> D"] fromNode:aNode fromPort:SOUTH_PORT toNode:dNode toDir:NORTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <--> C"] fromNode:dNode fromPort:EAST_PORT toNode:cNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"B <--> F"] fromNode:bNode fromPort:EAST_PORT toNode:fNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <--> E"] fromNode:dNode fromPort:SOUTH_PORT toNode:eNode toDir:NORTH_PORT];

    BOOL EtoJ = YES;;
    if (EtoJ) {
        [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"E <--> J"] fromNode:eNode fromPort:EAST_PORT toNode:JNode toDir:WEST_PORT];

    } else {
//        [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"E <--> H"] fromNode:eNode fromPort:EAST_PORT toNode:hNode toDir:WEST_PORT];
//        [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"H <--> C"] fromNode:hNode fromPort:NORTH_PORT toNode:cNode toDir:SOUTH_PORT];
//        [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"H <--> J"] fromNode:hNode fromPort:EAST_PORT toNode:JNode toDir:WEST_PORT];
    }
    // DON'T NORMALLY USE THIS
    
    
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

    

//    [self setShortCycleTimes];
}

- (void)establishGreenFlowGraph {
    
    NSLog(@"Green flow graph");
    self.routeLabel.text = @"TIMING: D to L Green Flow";

    CityGraph *graph = self.graph;
    
    self.clickableRenderView.min_long = 45.10;
    self.clickableRenderView.max_long = 45.50;
    //.7117
    self.clickableRenderView.min_lati = 45.00;
    self.clickableRenderView.max_lati = 45.285;
    
    IntersectionNode *aNode = [IntersectionNode nodeWithIdentifier:@"A"];
    aNode.latitude = 45.26; aNode.longitude = 45.16;
    
    IntersectionNode *bNode = [IntersectionNode nodeWithIdentifier:@"B"];
    bNode.latitude = 45.26; bNode.longitude = 45.24;[graph justAddNode:bNode];
    //    fNode.light_phase_machine.ewPhase = 120.0; fNode.light_phase_machine.nsPhase = 4;
    bNode.light_phase_machine.phase_offset = 15.0;
    
    
    IntersectionNode *cNode = [IntersectionNode nodeWithIdentifier:@"C"];
    cNode.latitude = 45.15; cNode.longitude = 45.234; [graph justAddNode:cNode];
    //#warning PUT THESE BACK!
    cNode.light_phase_machine.phase_offset = 14.0;
    
    IntersectionNode *dNode = [IntersectionNode nodeWithIdentifier:@"D"];  [graph justAddNode:dNode];
    dNode.latitude = 45.14; dNode.longitude = 45.16;
    dNode.light_phase_machine.phase_offset = 30.0;
    
    
    IntersectionNode *gNode = [IntersectionNode nodeWithIdentifier:@"G"]; [graph justAddNode:gNode];
    gNode.latitude = 45.15; gNode.longitude = 45.31;
    gNode.light_phase_machine.phase_offset = -7.0;
    
    IntersectionNode *eNode = [IntersectionNode nodeWithIdentifier:@"E"]; [graph justAddNode:eNode];
    eNode.latitude = 45.07; eNode.longitude = 45.165;
    eNode.light_phase_machine.ewPhase = 4.0;
    
    IntersectionNode *fNode = [IntersectionNode nodeWithIdentifier:@"F"];
    fNode.latitude = 45.26; fNode.longitude = 45.37; [graph justAddNode:fNode];
    
    
    IntersectionNode *lNode = [IntersectionNode nodeWithIdentifier:@"L"]; [graph justAddNode:lNode];
    lNode.latitude = 45.15; lNode.longitude = 45.46;
    lNode.light_phase_machine.phase_offset = 16.0;
    lNode.light_phase_machine.ewPhase = 50;
    lNode.light_phase_machine.nsPhase = 10;

    
    IntersectionNode *kNode = [IntersectionNode nodeWithIdentifier:@"K"]; [graph justAddNode:kNode];
    kNode.latitude = 45.15; kNode.longitude = 45.38;
    kNode.light_phase_machine.phase_offset = -26.0;
    
    IntersectionNode *JNode = [IntersectionNode nodeWithIdentifier:@"J"];    [graph justAddNode:JNode];
    JNode.latitude = 45.05; JNode.longitude = 45.315;
    JNode.light_phase_machine.phase_offset = 32.0;
    
    
    IntersectionNode *RNode = [IntersectionNode nodeWithIdentifier:@"R"]; [graph justAddNode:RNode];
    RNode.latitude = 45.05; RNode.longitude = 45.38;
    RNode.light_phase_machine.phase_offset = 25.0;
    
    IntersectionNode *SNode = [IntersectionNode nodeWithIdentifier:@"S"];
    SNode.latitude = 45.05; SNode.longitude = 45.46;
    
    
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
    
    self.routeLabel.text = @"TIMING: D to L ALL GREEN. J->G is infinitely starved when C->L is fully loaded.";

    
    // Cross section starvation can result otherwise!
    BOOL withDecongestionOffset = NO;
    
    self.clickableRenderView.min_long = 45.10;
    self.clickableRenderView.max_long = 45.50;
    //.7117
    self.clickableRenderView.min_lati = 45.00;
    self.clickableRenderView.max_lati = 45.285;
    
    IntersectionNode *aNode = [IntersectionNode nodeWithIdentifier:@"A"];
    aNode.latitude = 45.26; aNode.longitude = 45.16;
    
    IntersectionNode *bNode = [IntersectionNode nodeWithIdentifier:@"B"];
    bNode.latitude = 45.26; bNode.longitude = 45.24;[graph justAddNode:bNode];
    //    fNode.light_phase_machine.ewPhase = 120.0; fNode.light_phase_machine.nsPhase = 4;
    bNode.light_phase_machine.phase_offset = 15.0;
    
    
    IntersectionNode *cNode = [IntersectionNode nodeWithIdentifier:@"C"];
    cNode.latitude = 45.15; cNode.longitude = 45.234; [graph justAddNode:cNode];
    if (withDecongestionOffset) cNode.light_phase_machine.phase_offset = -25.0;
    
    IntersectionNode *dNode = [IntersectionNode nodeWithIdentifier:@"D"];  [graph justAddNode:dNode];
    dNode.latitude = 45.14; dNode.longitude = 45.16;
    
    
    IntersectionNode *gNode = [IntersectionNode nodeWithIdentifier:@"G"]; [graph justAddNode:gNode];
    gNode.latitude = 45.15; gNode.longitude = 45.31;
    if (withDecongestionOffset)  gNode.light_phase_machine.phase_offset = -15.0;
    
    IntersectionNode *eNode = [IntersectionNode nodeWithIdentifier:@"E"]; [graph justAddNode:eNode];
    eNode.latitude = 45.07; eNode.longitude = 45.165;
    eNode.light_phase_machine.ewPhase = 5.0;
    
    IntersectionNode *fNode = [IntersectionNode nodeWithIdentifier:@"F"];
    fNode.latitude = 45.26; fNode.longitude = 45.37; [graph justAddNode:fNode];
    
    
    IntersectionNode *lNode = [IntersectionNode nodeWithIdentifier:@"L"]; [graph justAddNode:lNode];
    lNode.latitude = 45.15; lNode.longitude = 45.46;
    if (withDecongestionOffset) lNode.light_phase_machine.phase_offset = 15.0;
    lNode.light_phase_machine.ewPhase = 50;
    lNode.light_phase_machine.nsPhase = 10;
    
    IntersectionNode *kNode = [IntersectionNode nodeWithIdentifier:@"K"]; [graph justAddNode:kNode];
    kNode.latitude = 45.15; kNode.longitude = 45.38;
    if (withDecongestionOffset)  kNode.light_phase_machine.phase_offset = 0.0;
    
    
    IntersectionNode *JNode = [IntersectionNode nodeWithIdentifier:@"J"];    [graph justAddNode:JNode];
    JNode.latitude = 45.05; JNode.longitude = 45.315;
    JNode.light_phase_machine.phase_offset = 32.0;
    
    
    IntersectionNode *RNode = [IntersectionNode nodeWithIdentifier:@"R"]; [graph justAddNode:RNode];
    RNode.latitude = 45.05; RNode.longitude = 45.38;
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

    
#warning RANDOM OFFSETS APPLIED
//    [self setRandomOffsetTimes];
}

- (IBAction)startTimer:(id)sender {
    
    if (!self.activeTimer) {
        self.activeTimer = [NSTimer timerWithTimeInterval:2.0/60.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.activeTimer forMode:NSRunLoopCommonModes];
        [self setEmitButtonsEnabled:YES];
        [self setStartClockButtonToPause:YES];

//        [sender_as_label setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.activeTimer invalidate];
        self.activeTimer = nil;
        [self setEmitButtonsEnabled:NO];
        [self setStartClockButtonToPause:NO];

//        [sender_as_label setTitle:@"Start timer" forState:UIControlStateNormal];
    }
}

- (void)putCarOnEdge:(StreetEdge *)edge andStartPoint:(IntersectionNode *)start withCar:(CarAndView*)car {
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
    for (int i = [_allCars count] - 1; i >= 0; i--) {
        CarAndView* element = _allCars[i];
        
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
    NSString *routeName = [NSString stringWithFormat:@"%@-%@", self.startEmitNodename, self.endEmitNodename];
    [self.startDFAutoEmitLabel setTitle:[NSString stringWithFormat:@"Start Auto %@ Emit",routeName] forState:UIControlStateNormal];
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
    _frequentUIUpdates = YES;
    _drawAllPaths = YES;
    
    self.graph = [CityGraph new];
    [self establishGraph];
    [self updateSpawnButtons];
    [self setEmitButtonsEnabled:NO];
    

    self.masterTime = 0;
    self.clickableRenderView.graph = self.graph;
    _allCars = [NSMutableArray new];
        [self.startSlowRandoEmitLabel setTitle:@"Start Rando Emit" forState:UIControlStateNormal];
    //    [self.startClockButton setTitle:@"Start timer" forState:UIControlStateNormal];
    [self setStartClockButtonToPause:NO];
    
    [self.clickableRenderView removeAllSubviews];
    [self.clickableRenderView setNeedsDisplay];

    
}

#define TICKS_BETWEEN_EMITS 100

- (void)timerTick:(id)something {
    NSTimeInterval timeDiff = 1.0/30.0 * _timeMultiplier;
    self.masterTime += timeDiff;
    
    
    static int E_F_Counts = 0;
    static int Rando_counts = 0;
    if (_autoEFEmit) {
        E_F_Counts++;
        
        double scaled_thirty = TICKS_BETWEEN_EMITS / _timeMultiplier;
        
        if (E_F_Counts % (int)scaled_thirty == 0) {
//            NSLog(@"Emitted car %d", E_F_Counts);
            [self placeCarOne:nil];
        }
    }
    
    if (_autorandoEmit) {
        Rando_counts++;
        
        double scaled_thirty = 100.0 / _timeMultiplier;
        
        if (Rando_counts % (int)scaled_thirty == 0) {
//            NSLog(@"Emitted rando car %d", E_F_Counts);
            [self emitRandomCar:nil];
        }
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
    self.flowRateLabel.text = [NSString stringWithFormat:@"Flow Rate: %.2f%% of %lu are moving", [self aggregateSpeed]/0.11111*100.0, (unsigned long)[_allCars count]];
    self.throughputLabel.text = [NSString stringWithFormat:@"Throughput: %d in %.2f sec", _finishedCars, self.masterTime];

    
    
}


// Returns true if node exists in the graph!
- (BOOL)validateNodeName:(NSString *)name {
    IntersectionNode *nd = [self.graph nodeInGraphWithIdentifier:name];
    return (nd != nil);
}


- (IBAction)placeCarOne:(id)sender {
    
    _emittedCars++;
    
    CarAndView *car = [[CarAndView alloc] init];
    car.secondVC = self;
    [car markStartTime:self.masterTime];
    [_allCars addObject:car];
    
    IntersectionNode *nodeStart = [self.graph nodeInGraphWithIdentifier:self.startEmitNodename];
    
    IntersectionNode *nodeEnd = [self.graph nodeInGraphWithIdentifier:self.endEmitNodename];
    
    if (nodeStart) {
        car.currentLongLat = CGPointMake(nodeStart.longitude, nodeStart.latitude);
        
        AAGraphRoute *route = [self.graph shortestRouteFromNode:nodeStart toNode:nodeEnd considerIntxnPenalty:self.considerLightSwitch.on realtimeTimings:self.rtPenaltySwitch.on andTime:self.masterTime andCurrentQueuePenalty:self.queingPenaltySwitch.on];
        
        car.intendedRoute = route;
    }
    
    [[self clickableRenderView] setNeedsDisplay];
    
}

- (IBAction)emitRandomCar:(id)sender {
//    _emittedCars++;
    
    CarAndView *car = [[CarAndView alloc] init];
    car.secondVC = self;
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
        
        AAGraphRoute *route = [self.graph shortestRouteFromNode:nodeD toNode:nodeF considerIntxnPenalty:self.considerLightSwitch.on realtimeTimings:self.rtPenaltySwitch.on andTime:self.masterTime andCurrentQueuePenalty:self.queingPenaltySwitch.on];
        
        car.intendedRoute = route;
        car.shadowRandomCar = YES;
    }
    
    [[self clickableRenderView] setNeedsDisplay];


}


- (IBAction)calculateButton:(id)sender {
    
    IntersectionNode *startNode = [self.graph nodeInGraphWithIdentifier:[[self.startField.text uppercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    IntersectionNode *endNode = [self.graph nodeInGraphWithIdentifier:[[self.endField.text uppercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    
    if (startNode && endNode) {
        [self.clickableRenderView drawShortestPathFromNodeNamed:startNode.identifier toNodeNamed:endNode.identifier consider:self.considerLightSwitch.on inRealtime:self.rtPenaltySwitch.on withTime:self.masterTime andCurrentQueuePenalty:self.queingPenaltySwitch.on];
        self.routeLabel.text = self.clickableRenderView.curRouteText;
    } else {
        self.routeLabel.text = @"Invalid start/end node";
    }
    
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
