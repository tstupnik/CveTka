//
//  CvTViewController.h
//  CveTka
//
//  Created by tomaz stupnik on 5/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Airplay/CvTBluetooth.h"
#import "Airplay/CvTWiFi.h"

#import "CvTSpiralView.h"
#import "CvTSpiralView.h"
#import "Left/CvTDemoSetupViewController.h"

@interface CvTViewController : UIViewController
{
@public
    CvTDemoSetupViewController *DemoController;
}

-(void)initialize;
-(void)applicationDidBecomeActive;

@end
