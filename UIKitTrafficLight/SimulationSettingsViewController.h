//
//  SimulationSettingsViewController.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 3/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TrafficGridViewController;
@interface SimulationSettingsViewController : UIViewController

@property (nonatomic) BOOL *parentFrequentUIUpdates;
@property (nonatomic) BOOL *parentDrawAllPaths;
@property (nonatomic, weak) TrafficGridViewController *trafficVC;
@property (weak, nonatomic) IBOutlet UITextField *startField;
@property (weak, nonatomic) IBOutlet UITextField *endField;
- (IBAction)confirmSetButtonTouched:(id)sender;

@end
