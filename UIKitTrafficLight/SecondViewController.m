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
#import "AATLightPhaseMachine.h"
#import "StopLightTimingOptionsPopoverViewController.h"
#import "CarAndView.h"

@interface SecondViewController ()

@property (nonatomic,strong) UIPopoverController *popover;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _timeMultiplier = 1.0;

    CityGraph *theGraph = [CityGraph new];
    self.graph = theGraph;
    [self establishGraph];
    
    _allCars = [NSMutableArray new];

    self.clickableRenderView.graph = theGraph;
    self.clickableRenderView.containingViewController = self;
    
    
    [self.clickableRenderView setNeedsDisplay];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (NSArray *)getCarsToDraw {
    return _allCars;
}

- (IBAction)considerPenaltyChanged:(UISwitch *)sender {
    if (!sender.on)
        [self.rtPenaltySwitch setOn:NO animated:YES];
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
    
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    vc.intxnnode = node;
    
    CGRect loc;
    loc.origin = point;
    loc.size = CGSizeMake(0, 0);
    
    [self.popover presentPopoverFromRect:loc inView:self.clickableRenderView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
}

- (void)setShortCycleTimes {
    CityGraph *graph = self.graph;
    NSDictionary *nodeNames = graph.nodes;
    for (NSString *name in nodeNames) {
        IntersectionNode *node = nodeNames[name];
        AATLightPhaseMachine *phaseMachine = node.light_phase_machine;
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
        AATLightPhaseMachine *phaseMachine = node.light_phase_machine;
        
        phaseMachine.phase_offset = randomFloat(-60.0, 60.0);
        
    }
    
    self.routeLabel.text = @"WARNING: TOTALLY RANDOM PHASES";
    
}

- (void)unselectAllCars {
    [_allCars makeObjectsPerformSelector:@selector(setUnselected)];
}


- (void)establishGraph {
//    [self establishBasicGraph];
//    [self establishGreenFlowGraph];
    [self establishRushhourGraph];
   
}
- (void)establishBasicGraph {
    
    
    CityGraph *graph = self.graph;
    
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
    lNode.light_phase_machine.phase_offset = 00.0;

    
    IntersectionNode *kNode = [IntersectionNode nodeWithIdentifier:@"K"]; [graph justAddNode:kNode];
    kNode.latitude = 45.15; kNode.longitude = 45.38;
    kNode.light_phase_machine.phase_offset = -26.0;
    
    //    IntersectionNode *hNode = [IntersectionNode nodeWithIdentifier:@"H"]; [graph justAddNode:hNode];
    //    hNode.latitude = 45.045; hNode.longitude = 45.24;
    //    hNode.light_phase_machine.nsPhase = 4.0;
    
    
    IntersectionNode *INode = [IntersectionNode nodeWithIdentifier:@"I"]; [graph justAddNode:INode];
    INode.latitude = 45.26; INode.longitude = 45.45;
    INode.light_phase_machine.phase_offset = 18.0;
    
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

    // DON'T NORMALLY USE THIS
    
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> B"] fromNode:cNode fromPort:NORTH_PORT toNode:bNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> G"] fromNode:cNode fromPort:EAST_PORT toNode:gNode toDir:WEST_PORT];
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"G <--> K"] fromNode:gNode fromPort:EAST_PORT toNode:kNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"J <--> G"] fromNode:JNode fromPort:NORTH_PORT toNode:gNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"K <--> F"] fromNode:kNode fromPort:NORTH_PORT toNode:fNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"F <--> I"] fromNode:fNode fromPort:EAST_PORT toNode:INode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"K <--> L"] fromNode:kNode fromPort:EAST_PORT toNode:lNode toDir:WEST_PORT];

    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"J <--> R"] fromNode:JNode fromPort:EAST_PORT toNode:RNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"R <--> S"] fromNode:RNode fromPort:EAST_PORT toNode:SNode toDir:WEST_PORT];
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"R <--> K"] fromNode:RNode fromPort:NORTH_PORT toNode:kNode toDir:SOUTH_PORT];

}

- (void)establishRushhourGraph {
    NSLog(@"Rush hour graph");
    CityGraph *graph = self.graph;
    
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
    eNode.light_phase_machine.ewPhase = 1.0;
    
    IntersectionNode *fNode = [IntersectionNode nodeWithIdentifier:@"F"];
    fNode.latitude = 45.26; fNode.longitude = 45.37; [graph justAddNode:fNode];
    
    
    IntersectionNode *lNode = [IntersectionNode nodeWithIdentifier:@"L"]; [graph justAddNode:lNode];
    lNode.latitude = 45.15; lNode.longitude = 45.46;
    if (withDecongestionOffset) lNode.light_phase_machine.ewPhase = 50;
    
    IntersectionNode *kNode = [IntersectionNode nodeWithIdentifier:@"K"]; [graph justAddNode:kNode];
    kNode.latitude = 45.15; kNode.longitude = 45.38;
    if (withDecongestionOffset)  kNode.light_phase_machine.phase_offset = 0.0;
    
    //    IntersectionNode *hNode = [IntersectionNode nodeWithIdentifier:@"H"]; [graph justAddNode:hNode];
    //    hNode.latitude = 45.045; hNode.longitude = 45.24;
    //    hNode.light_phase_machine.nsPhase = 4.0;
    
    
    
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
    
    // DON'T NORMALLY USE THIS
    
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> B"] fromNode:cNode fromPort:NORTH_PORT toNode:bNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> G"] fromNode:cNode fromPort:EAST_PORT toNode:gNode toDir:WEST_PORT];
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"G <--> K"] fromNode:gNode fromPort:EAST_PORT toNode:kNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"J <--> G"] fromNode:JNode fromPort:NORTH_PORT toNode:gNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"K <--> F"] fromNode:kNode fromPort:NORTH_PORT toNode:fNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"K <--> L"] fromNode:kNode fromPort:EAST_PORT toNode:lNode toDir:WEST_PORT];
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"J <--> R"] fromNode:JNode fromPort:EAST_PORT toNode:RNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"R <--> K"] fromNode:RNode fromPort:NORTH_PORT toNode:kNode toDir:SOUTH_PORT];

    
#warning RANDOM OFFSETS APPLIED
    [self setRandomOffsetTimes];
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

- (void)putCarOnEdge:(StreetEdge *)edge andStartPoint:(IntersectionNode *)start withCar:(CarAndView*)car {
    [self.graph putCarOnEdge:edge startPoint:start andCar:car];
}

- (IBAction)startEFAutoEmitPressed:(UIButton *)sender {
    _autoEFEmit = !_autoEFEmit;
    if (_autoEFEmit)
        [sender setTitle:@"Stop D-I Emitting" forState:UIControlStateNormal];
    else
        [sender setTitle:@"Start Auto D-I Emit" forState:UIControlStateNormal];
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
- (IBAction)resetAll:(id)sender {

    [self.activeTimer invalidate];
    self.activeTimer = nil;
    
    _finishedCars = 0;
    _emittedCars = 0;
    _autorandoEmit = NO;
    _autoEFEmit = NO;
    self.routeLabel.text = @"Route";
    self.flowRateLabel.text = @"Flow Rate:";
    self.throughputLabel.text = @"Throughput:";
    self.updateUISwitch.on = YES;
    [self.startDFAutoEmitLabel setTitle:@"Start Auto D-L Emit" forState:UIControlStateNormal];
    [self.startSlowRandoEmitLabel setTitle:@"Start Rando Emit" forState:UIControlStateNormal];
    [self.startClockButton setTitle:@"Start timer" forState:UIControlStateNormal];
    
    self.graph = [CityGraph new];
    [self establishGraph];
    self.masterTime = 0;
    self.clickableRenderView.graph = self.graph;
    _allCars = [NSMutableArray new];
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
        AATLightPhaseMachine *phaseMachine = node.light_phase_machine;
        [phaseMachine setPhaseForMasterTimeInterval:self.masterTime];

    }
    
    [self pruneCars:timeDiff];
    
    if (self.updateUISwitch.on)
        [[self clickableRenderView] setNeedsDisplay];
    
    self.flowRateLabel.text = [NSString stringWithFormat:@"Flow Rate: %.2f%%", [self aggregateSpeed]/0.11111*100.0];
    self.throughputLabel.text = [NSString stringWithFormat:@"Throughput: %d in %.2f sec", _finishedCars, self.masterTime];

    
    
}

- (IBAction)placeCarOne:(id)sender {
    
    _emittedCars++;
    
    CarAndView *car = [[CarAndView alloc] init];
    car.secondVC = self;
    [_allCars addObject:car];
    
    BOOL isGreenFlow = YES;
    
    IntersectionNode *nodeD = [self.graph nodeInGraphWithIdentifier:@"D"];
    
    IntersectionNode *nodeF = [self.graph nodeInGraphWithIdentifier:@"L"];
    
    if (nodeD) {
        car.currentLongLat = CGPointMake(nodeD.longitude, nodeD.latitude);
        
        AAGraphRoute *route = [self.graph shortestRouteFromNode:nodeD toNode:nodeF considerIntxnPenalty:self.considerLightSwitch.on realtimeTimings:self.rtPenaltySwitch.on andTime:self.masterTime andCurrentQueuePenalty:self.queingPenaltySwitch.on];
        
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
