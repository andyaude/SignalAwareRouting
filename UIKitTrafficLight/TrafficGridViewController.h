//
//  SecondViewController.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClickableGraphRenderedView.h"

@interface TrafficGridViewController : UIViewController <UIScrollViewDelegate> {
    double _timeMultiplier;
    NSMutableArray *_allCars;
    int _finishedCars;
    int _emittedCars;

    BOOL _autoEFEmit;
    BOOL _autorandoEmit;
    
    // Calculated E2E delays
    NSMutableDictionary *_e2eDelays;
    NSTimeInterval _cumulativee2eDelay;
    int _numE2EReportedCars;
    
    BOOL _frequentUIUpdates;
    BOOL _drawAllPaths;

}

@property (weak, nonatomic) IBOutlet ClickableGraphRenderedView *clickableRenderView;


@property (nonatomic) NSTimeInterval masterTime;
@property (weak, nonatomic) IBOutlet UISegmentedControl *scenarioSegment;

@property (nonatomic) CityGraph *graph;
@property (weak, nonatomic) IBOutlet UISwitch *considerLightSwitch;
@property (weak, nonatomic) IBOutlet UITextField *startField;
@property (weak, nonatomic) IBOutlet UITextField *endField;
@property (weak, nonatomic) IBOutlet UISwitch *rtPenaltySwitch;
@property (weak, nonatomic) IBOutlet UILabel *routeLabel;
@property (weak, nonatomic) IBOutlet UILabel *flowRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *throughputLabel;
@property (weak, nonatomic) IBOutlet UISwitch *queingPenaltySwitch;

@property (strong, nonatomic) NSTimer *activeTimer;
@property (weak, nonatomic) IBOutlet UILabel *timeRateLabel;
@property (weak, nonatomic) IBOutlet UIButton *startDFAutoEmitLabel;
@property (weak, nonatomic) IBOutlet UIButton *startSlowRandoEmitLabel;
@property (weak, nonatomic) IBOutlet UILabel *e2eDelayLabel;
@property (weak, nonatomic) IBOutlet UIButton *startClockButton;
@property (weak, nonatomic) IBOutlet UIButton *spawnStartEndCarButton;
@property (weak, nonatomic) IBOutlet UIButton *spawnSingleRandoCarButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UISwitch *adaptiveCycleTimesSwitch;

@property (copy, nonatomic) NSString *startEmitNodename;
@property (copy, nonatomic) NSString *endEmitNodename;

- (NSArray *)getCarsToDraw;
- (IBAction)considerPenaltyChanged:(id)sender;
- (IBAction)segmentControlChanged:(id)sender;

- (IBAction)openSimSettingsController:(id)sender;
- (void)unselectAllCars;
- (void)editNode:(IntersectionNode *)node atPoint:(CGPoint)point;
- (void)putCarOnEdge:(StreetEdge *)edge andStartPoint:(IntersectionNode *)start withCar:(CarController*)car;
- (IBAction)startEFAutoEmitPressed:(id)sender;


// For CarAndView's use
- (void)reportE2EDelayForID:(NSUInteger)uniqueID andInterval:(NSTimeInterval)interval;

// For SimulationSettingsViewController's use
- (BOOL)validateNodeName:(NSString *)name;
- (void)updateSpawnButtons;


@end

