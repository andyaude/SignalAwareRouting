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

@property (strong, nonatomic) NSTimer *activeTimer;
@property (weak, nonatomic) IBOutlet UILabel *timeRateLabel;

- (NSArray *)getCarsToDraw;

-(void)editNode:(IntersectionNode *)node atPoint:(CGPoint)point;
- (void)putCarOnEdge:(StreetEdge *)edge andStartPoint:(IntersectionNode *)start withCar:(CarAndView*)car;

@end

