//
//  CvTAppDelegate.h
//  CveTka
//
//  Created by tomaz stupnik on 5/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Audiobus.h"

#import "Synth/CvTSynth.h"

@interface CvTAppDelegate : UIResponder<UIApplicationDelegate, ABAudiobusControllerStateIODelegate>

@property (strong, nonatomic) UIWindow *window;

@end
