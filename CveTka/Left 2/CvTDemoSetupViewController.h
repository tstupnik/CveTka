//
//  CvTDemoSetupViewController.h
//  CveTka
//
//  Created by tomaz stupnik on 7/17/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "../Spiral/CvTSpiralView.h"
#import "../Airplay/CvTPlayback.h"
#import "../CvTAppSettings.h"

@interface CvTDemoSetupViewController : UIViewController<CvTPlaybackDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *ChordType;
@property (weak, nonatomic) IBOutlet UIButton *MajorChord;
@property (weak, nonatomic) IBOutlet UIButton *DiminishedChord;
@property (weak, nonatomic) IBOutlet UIButton *MinorChord;
@property (weak, nonatomic) IBOutlet UIButton *AugmentedChord;

@property (weak, nonatomic) IBOutlet UISegmentedControl *Playback;
@property (weak, nonatomic) IBOutlet UIButton *TuneSelect;
@property (weak, nonatomic) IBOutlet UILabel *TuneName;

-(void)didFinishPlayback;
-(void)didSelectTune:(CvTMidiTuneInfo*)tuneInfo;

-(AutoChordMode)ChordMode;

@end
