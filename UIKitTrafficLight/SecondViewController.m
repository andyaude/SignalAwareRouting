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

- (void)establishGraph {
    CityGraph *graph = self.graph;
    
    self.clickableRenderView.min_long = 45.10;
    self.clickableRenderView.max_long = 45.50;
    //.7117
    self.clickableRenderView.min_lati = 45.00;
    self.clickableRenderView.max_lati = 45.285;
    
    IntersectionNode *aNode = [IntersectionNode nodeWithIdentifier:@"A"];
    aNode.latitude = 45.26; aNode.longitude = 45.16;
    
    IntersectionNode *bNode = [IntersectionNode nodeWithIdentifier:@"B"];
    bNode.latitude = 45.26; bNode.longitude = 45.24;
    
    IntersectionNode *cNode = [IntersectionNode nodeWithIdentifier:@"C"];
    cNode.latitude = 45.15; cNode.longitude = 45.234;
    
    IntersectionNode *dNode = [IntersectionNode nodeWithIdentifier:@"D"];
    dNode.latitude = 45.14; dNode.longitude = 45.16;
    
    IntersectionNode *eNode = [IntersectionNode nodeWithIdentifier:@"E"];
    eNode.latitude = 45.04; eNode.longitude = 45.165;

    IntersectionNode *fNode = [IntersectionNode nodeWithIdentifier:@"F"];
    fNode.latitude = 45.26; fNode.longitude = 45.37; [graph justAddNode:fNode];
    fNode.light_phase_machine.ewPhase = 120.0; fNode.light_phase_machine.nsPhase = 4;

    
    IntersectionNode *gNode = [IntersectionNode nodeWithIdentifier:@"G"];
    gNode.latitude = 45.15; gNode.longitude = 45.31;
    
    IntersectionNode *hNode = [IntersectionNode nodeWithIdentifier:@"H"];
    hNode.latitude = 45.045; hNode.longitude = 45.24;
    
    
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> B"] fromNode:aNode fromPort:EAST_PORT toNode:bNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <--> D"] fromNode:aNode fromPort:SOUTH_PORT toNode:dNode toDir:NORTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <--> C"] fromNode:dNode fromPort:EAST_PORT toNode:cNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"B <--> F"] fromNode:bNode fromPort:EAST_PORT toNode:fNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <--> E"] fromNode:dNode fromPort:SOUTH_PORT toNode:eNode toDir:NORTH_PORT];

    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"E <--> H"] fromNode:eNode fromPort:EAST_PORT toNode:hNode toDir:WEST_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"H <--> C"] fromNode:hNode fromPort:NORTH_PORT toNode:cNode toDir:SOUTH_PORT];

    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> B"] fromNode:cNode fromPort:NORTH_PORT toNode:bNode toDir:SOUTH_PORT];
    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <--> G"] fromNode:cNode fromPort:EAST_PORT toNode:gNode toDir:WEST_PORT];

    
//    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <-> B" andDistance:7.0] fromNode:aNode toNode:bNode];
//    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <-> C" andDistance:9.0] fromNode:aNode toNode:cNode];
//    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"A <-> F" andDistance:14.0] fromNode:aNode toNode:fNode];
//    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"B <-> C" andDistance:10.0] fromNode:bNode toNode:cNode];
//    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"B <-> D" andDistance:15.0] fromNode:bNode toNode:dNode];
//    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <-> F" andDistance:2.0] fromNode:cNode toNode:fNode];
//    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"C <-> D" andDistance:11.0] fromNode:cNode toNode:dNode];
//    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"D <-> E" andDistance:6.0] fromNode:dNode toNode:eNode];
//    [graph addBiDirectionalEdge:[StreetEdge edgeWithName:@"E <-> F" andDistance:9.0] fromNode:eNode toNode:fNode];
    
//    AAGraphRoute *route = [graph shortestRouteFromNode:aNode toNode:eNode];
    
//    NSLog(@"Route steps : %@", [route steps]);
    
//    // There should be three steps in the route, from A -> C -> F -> E
//    XCTAssertTrue(4 == [route count], @"Invald number of steps in route, should be 4, not %lu", (unsigned long)[route count]);
//    XCTAssertEqual(aNode, [route startingNode], @"Invald starting point for route, should be node A, not %@", [[route startingNode] identifier]);
//    XCTAssertEqual(eNode, [route endingNode], @"Invald starting point for route, should be node E, not %@", [[route endingNode] identifier]);
//    XCTAssertTrue(20 == [route length], @"Invalid distance for route, should be 23, not %f.0", [route length]);

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

- (void)pruneCars:(NSTimeInterval)timeDiff {
    for (int i = [_allCars count] - 1; i >= 0; i--) {
        CarAndView* element = _allCars[i];
        
        [element doTick:timeDiff];
        
        if ([element isReadyForRemoval]) {
            [self.graph removeCarFromGraph:element];
            [element.carView removeFromSuperview];
            [_allCars removeObjectAtIndex:i];
        }
    }
}

- (void)timerTick:(id)something {
    NSTimeInterval timeDiff = 1.0/30.0 * _timeMultiplier;
    self.masterTime += timeDiff;
    
    
    NSDictionary *nodes = self.graph.nodes;
    
    for (NSString * name in nodes) {
        IntersectionNode *node = nodes[name];
        AATLightPhaseMachine *phaseMachine = node.light_phase_machine;
        [phaseMachine setPhaseForMasterTimeInterval:self.masterTime];

    }
    
    [self pruneCars:timeDiff];
    
    [[self clickableRenderView] setNeedsDisplay];
    
}

- (IBAction)placeCarOne:(id)sender {
    
    CarAndView *car = [[CarAndView alloc] init];
    car.secondVC = self;
    [_allCars addObject:car];
    
    IntersectionNode *nodeD = [self.graph nodeInGraphWithIdentifier:@"D"];
    
    IntersectionNode *nodeF = [self.graph nodeInGraphWithIdentifier:@"F"];
    
    if (nodeD) {
        car.currentLongLat = CGPointMake(nodeD.longitude, nodeD.latitude);
        
        AAGraphRoute *route = [self.graph shortestRouteFromNode:nodeD toNode:nodeF considerIntxnPenalty:YES andTime:self.masterTime];
        
        car.intendedRoute = route;
    }
    
    [[self clickableRenderView] setNeedsDisplay];
    
}

- (IBAction)calculateButton:(id)sender {
    
    IntersectionNode *startNode = [self.graph nodeInGraphWithIdentifier:[[self.startField.text uppercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    IntersectionNode *endNode = [self.graph nodeInGraphWithIdentifier:[[self.endField.text uppercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    
    if (startNode && endNode) {
        [self.clickableRenderView drawShortestPathFromNodeNamed:startNode.identifier toNodeNamed:endNode.identifier consider:self.considerLightSwitch.on];
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

@end
