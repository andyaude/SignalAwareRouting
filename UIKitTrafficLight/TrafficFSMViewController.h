//
//  FirstViewController.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <UIKit/UIKit.h>


// This is the "Signal FSM" controller. 
@interface TrafficFSMViewController : UIViewController

@property (nonatomic) NSTimeInterval masterTime;

@property (weak, nonatomic) IBOutlet UISlider *mySlider;

@end

