//
//  SecondViewController.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClickableGraphRenderedView.h"

@interface SecondViewController : UIViewController {
    double _timeMultiplier;
    NSMutableArray *_allCars;
    int _finishedCars;
    int _emittedCars;

    BOOL _autoEFEmit;
    BOOL _autorandoEmit;

}

@property (weak, nonatomic) IBOutlet ClickableGraphRenderedView *clickableRenderView;


@property (nonatomic) NSTimeInterval masterTime;

@property (nonatomic) CityGraph *graph;
@property (weak, nonatomic) IBOutlet UISwitch *considerLightSwitch;
@property (weak, nonatomic) IBOutlet UISlider *timePhaseSlider;
@property (weak, nonatomic) IBOutlet UILabel *timePhaseLabel;
@property (weak, nonatomic) IBOutlet UITextField *startField;
@property (weak, nonatomic) IBOutlet UITextField *endField;
@property (weak, nonatomic) IBOutlet UISwitch *rtPenaltySwitch;
@property (weak, nonatomic) IBOutlet UILabel *routeLabel;
@property (weak, nonatomic) IBOutlet UILabel *flowRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *throughputLabel;
@property (weak, nonatomic) IBOutlet UISwitch *queingPenaltySwitch;

@property (strong, nonatomic) NSTimer *activeTimer;
@property (weak, nonatomic) IBOutlet UILabel *timeRateLabel;
@property (weak, nonatomic) IBOutlet UISwitch *updateUISwitch;
@property (weak, nonatomic) IBOutlet UIButton *startDFAutoEmitLabel;
@property (weak, nonatomic) IBOutlet UIButton *startSlowRandoEmitLabel;
@property (weak, nonatomic) IBOutlet UIButton *startClockButton;

- (NSArray *)getCarsToDraw;
- (IBAction)considerPenaltyChanged:(id)sender;

- (void)unselectAllCars;
- (void)editNode:(IntersectionNode *)node atPoint:(CGPoint)point;
- (void)putCarOnEdge:(StreetEdge *)edge andStartPoint:(IntersectionNode *)start withCar:(CarAndView*)car;
- (IBAction)startEFAutoEmitPressed:(id)sender;

@end

