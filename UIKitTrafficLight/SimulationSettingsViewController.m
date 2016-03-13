//
//  SimulationSettingsViewController.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 3/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "SimulationSettingsViewController.h"
#import "TrafficGridViewController.h"

@interface SimulationSettingsViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *freqUIUpdatesSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *drawAllPathsSwitch;

@end

@implementation SimulationSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.freqUIUpdatesSwitch.on = *self.parentFrequentUIUpdates;
    self.drawAllPathsSwitch.on = *self.parentDrawAllPaths;
    self.startField.text = self.trafficVC.startEmitNodename;
    self.endField.text = self.trafficVC.endEmitNodename;

}

- (IBAction)frequentUIUpdatesChanged:(UISwitch*)sender {
    *self.parentFrequentUIUpdates = sender.on;
}
- (IBAction)drawAllPathsChanged:(UISwitch*)sender {
    *self.parentDrawAllPaths = sender.on;
}

- (void)displayGenericAlert:(NSString *)text andField:(UITextField *)field {
    UIAlertController *cont = [UIAlertController alertControllerWithTitle:@"Error" message:text preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                       [field becomeFirstResponder];
                                   }];
    [cont addAction:cancelAction];
    [self presentViewController:cont animated:YES completion:nil];
}

- (IBAction)confirmSetButtonTouched:(id)sender {
    NSString *candidateStart = self.startField.text;
    NSString *candidateEnd = self.endField.text;
    if (!candidateStart || candidateStart.length == 0) {
        
        [self displayGenericAlert:@"You must enter a start nodename!" andField:self.startField];
        return;
    }
    
    if (! candidateEnd|| candidateEnd.length == 0) {
        [self displayGenericAlert:@"You must enter a end nodename!" andField:self.endField];
        return;
    }
    
    BOOL startValid = [self.trafficVC validateNodeName:candidateStart];
    BOOL endValid = [self.trafficVC validateNodeName:candidateEnd];
    if (!startValid) {
        [self displayGenericAlert:@"You must enter a VALID start nodename!" andField:self.startField];
        return;
    }
    if (!endValid) {
        [self displayGenericAlert:@"You must enter a VALID end nodename!" andField:self.endField];
        return;
    }
    
    [self.trafficVC setStartEmitNodename:candidateStart];
    [self.trafficVC setEndEmitNodename:candidateEnd];
    [self.trafficVC updateSpawnButtons];
    
}
@end
