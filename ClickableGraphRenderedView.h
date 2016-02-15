//
//  ClickableGraphRenderedView.h
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/18/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CityGraph.h"
#import "AAGraphRoute.h"

@interface ClickableGraphRenderedView : UIView {
    AAGraphRoute *drawThisRoute;
    NSMutableDictionary *_intxn_lights;
}

@property (nonatomic, weak) CityGraph *graph;



@property (nonatomic) float min_long;
@property (nonatomic) float max_long;

@property (nonatomic) float min_lati;
@property (nonatomic) float max_lati;

- (void)drawShortestPathFromNodeNamed:(NSString *)first toNodeNamed:(NSString *)second consider:(BOOL)considerPenalty;
@property (nonatomic) NSString *curRouteText;

#warning sloppy delegate
@property (nonatomic, weak) id containingViewController;


+ (double)distance:(CGPoint)latLongOne andPoint:(CGPoint)latLongTwo;

@end
