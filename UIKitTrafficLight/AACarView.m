//
//  AACarView.m
//  UIKitTrafficLight
//
//  Created by Andrew Aude on 1/2/16.
//  Copyright © 2016 Andrew Aude. All rights reserved.
//

#import "AACarView.h"

@interface AACarView () {
    AApproachDirs _approachDir;
}

@end

@implementation AACarView

-(void)moveInApproachDir:(CGFloat)units {
    CGRect oldFrame = self.frame;
    
    if (_approachDir == NORTH_APPROACH) {
        // subtract Y to go north
        oldFrame.origin.y -= units;
        

    } else if (_approachDir == SOUTH_APPROACH) {
        // add Y to go south
        oldFrame.origin.y += units;
    } else if (_approachDir == EASTWARD_APPROACH) {
        // add Y to go south
        oldFrame.origin.x += units;
    } else if (_approachDir == WESTWARD_APPROACH) {
        // add Y to go south
        oldFrame.origin.x -= units;
    }
    
    self.frame = oldFrame;
}

-(void)setApproachDir:(AApproachDirs)approach {
    
    _approachDir = approach;
    
    if (approach == NORTH_APPROACH) {
        self.transform = CGAffineTransformIdentity;
    }
    
    else if (approach == SOUTH_APPROACH) {
        self.transform = CGAffineTransformMakeRotation(M_PI);
    }
    
    else if (approach == EASTWARD_APPROACH) {
        self.transform = CGAffineTransformMakeRotation(M_PI/2.);
    }
    else if (approach == WESTWARD_APPROACH) {
        self.transform = CGAffineTransformMakeRotation(-M_PI/2.);
    }
}
-(AApproachDirs)approachDir {
    return _approachDir;
}

-(void)drawRect:(CGRect)rect {
    
    [super drawRect:rect];
    

    CGFloat TRI_SIDE_LEN = self.bounds.size.width;
    CGFloat X_OFFSET = TRI_SIDE_LEN/2.0;
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(cgcontext);
    
    UIBezierPath *bezier = [UIBezierPath bezierPath];
    
    [bezier moveToPoint:CGPointMake(X_OFFSET, 0)];
    
    //  4.33
    float coordX = X_OFFSET + cosf(60.0 * M_PI / 180.0) * TRI_SIDE_LEN;
    float coordY = sinf(60.0 * M_PI / 180.0) * TRI_SIDE_LEN;
    
    CGPoint coord = { coordX, coordY };
    
    [bezier addLineToPoint:coord];
    
    coord.x -= TRI_SIDE_LEN;
    [bezier addLineToPoint:coord];
    
    [bezier closePath];
    bezier.lineWidth = 1.0;
    
    [[UIColor blackColor] setStroke];
    [[UIColor greenColor] setFill];
    [bezier fill];
    [bezier stroke];
    
    CGContextRestoreGState(cgcontext);
    
}

@end
