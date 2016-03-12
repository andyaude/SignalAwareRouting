//
//  StopLightTimingOptionsPopoverViewController.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 2/12/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "StopLightTimingOptionsPopoverViewController.h"
#import "LightPhaseMachine.h"

@interface StopLightTimingOptionsPopoverViewController ()
@property (weak, nonatomic) IBOutlet UILabel *NWPhaseLbl;
@property (weak, nonatomic) IBOutlet UILabel *EWPhaseLbl;
@property (weak, nonatomic) IBOutlet UILabel *PhaseOffsetLabel;
@property (weak, nonatomic) IBOutlet UISlider *NSPhaseSlider;
@property (weak, nonatomic) IBOutlet UISlider *EWPhaseSlider;
@property (weak, nonatomic) IBOutlet UISlider *phaseOffsetSlider;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *ewWaitLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressIndicator;

@property (nonatomic, strong) NSTimer *updateTimer;

@end

@implementation StopLightTimingOptionsPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleLabel.text = self.intxnnode.identifier;
    
    [self updateTimerProg];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateTimerProg) userInfo:nil repeats:YES];
    // Do any additional setup after loading the view.
}

- (void)updateTimerProg {
    LightPhaseMachine *phase = self.intxnnode.light_phase_machine;

    [self.progressIndicator setProgress:[phase getCurrentPhaseProgress] animated:NO];
    
    self.ewWaitLabel.text = [NSString stringWithFormat:@"NS: %.1f", [phase predictWaitTimeForMasterInterval:[phase getMasterInterval] andTrafficDir:NS_DIRECTION]];
}

- (void)viewWillAppear:(BOOL)animated {
    LightPhaseMachine *phase = self.intxnnode.light_phase_machine;
    
    
    self.NWPhaseLbl.text = [NSString stringWithFormat:@"%.2f", phase.nsPhase];
    self.EWPhaseLbl.text = [NSString stringWithFormat:@"%.2f", phase.ewPhase];
    self.PhaseOffsetLabel.text = [NSString stringWithFormat:@"%.2f", phase.phase_offset];
    
    self.NSPhaseSlider.value = phase.nsPhase;
    self.EWPhaseSlider.value = phase.ewPhase;
    self.phaseOffsetSlider.value = phase.phase_offset;

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.updateTimer) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
}
- (IBAction)offsetChanged:(UISlider *)sender {
    LightPhaseMachine *phase = self.intxnnode.light_phase_machine;
    phase.phase_offset = sender.value;
    [self viewWillAppear:NO];
}
- (IBAction)EWChanged:(UISlider *)sender {
    LightPhaseMachine *phase = self.intxnnode.light_phase_machine;
    phase.ewPhase = sender.value;
    [self viewWillAppear:NO];
}
- (IBAction)NSChanged:(UISlider *)sender {
    LightPhaseMachine *phase = self.intxnnode.light_phase_machine;
    phase.nsPhase = sender.value;
    [self viewWillAppear:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    if (self.updateTimer) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
