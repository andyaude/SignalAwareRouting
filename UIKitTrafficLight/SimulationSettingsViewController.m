//
//  SimulationSettingsViewController.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 3/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "SimulationSettingsViewController.h"
#import "SecondViewController.h"

@interface SimulationSettingsViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *freqUIUpdatesSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *drawAllPathsSwitch;

@end

@implementation SimulationSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.freqUIUpdatesSwitch.on = *self.parentFrequentUIUpdates;
    self.drawAllPathsSwitch.on = *self.parentDrawAllPaths;
    self.startField.text = self.secondVC.startEmitNodename;
    self.endField.text = self.secondVC.endEmitNodename;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)frequentUIUpdatesChanged:(UISwitch*)sender {
    *self.parentFrequentUIUpdates = sender.on;
}
- (IBAction)drawAllPathsChanged:(UISwitch*)sender {
    *self.parentDrawAllPaths = sender.on;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
    
    BOOL startValid = [self.secondVC validateNodeName:candidateStart];
    BOOL endValid = [self.secondVC validateNodeName:candidateEnd];
    if (!startValid) {
        [self displayGenericAlert:@"You must enter a VALID start nodename!" andField:self.startField];
        return;
    }
    if (!endValid) {
        [self displayGenericAlert:@"You must enter a VALID end nodename!" andField:self.endField];
        return;
    }
    
    [self.secondVC setStartEmitNodename:candidateStart];
    [self.secondVC setEndEmitNodename:candidateEnd];
    [self.secondVC updateSpawnButtons];
    
}
@end
