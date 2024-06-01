//
//  CvTDemoSetupViewController.m
//  CveTka
//
//  Created by tomaz stupnik on 7/17/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTDemoSetupViewController.h"
#import "../Popovers/CvTSettingsViewController.h"
#import "../Popovers/CvTMIDITuneViewController.h"
#import "../Airplay/CvTPlayback.h"
#import "../CvTAppSettings.h"
#import "../CvTPersonality.h"


@implementation CvTDemoSetupViewController

-(AutoChordMode)ChordMode
{
    AutoChordMode modes[3][5] = {
        { kChordMode_Root, kChordMode_Root, kChordMode_Root, kChordMode_Root, kChordMode_Root },
        { kChordMode_Diatonic, kChordMode_Major, kChordMode_Minor, kChordMode_Diminished, kChordMode_Augmented },
        { kChordMode_Diatonic7, kChordMode_Major7, kChordMode_Minor7, kChordMode_Diminished7, kChordMode_Dominant7 }
    };
    
    int index = 0;
    if (_AugmentedChord.highlighted)
        index = 4;
    if (_DiminishedChord.highlighted)
        index = 3;
    if (_MinorChord.highlighted)
        index = 2;
    if (_MajorChord.highlighted)
        index = 1;
    
    return modes[[_ChordType selectedSegmentIndex]][index];
}

- (IBAction)ChordModeChange:(UISegmentedControl *)sender
{
    [_AugmentedChord setHidden:([sender selectedSegmentIndex] == 0)];
    [_DiminishedChord setHidden:([sender selectedSegmentIndex] == 0)];
    [_MinorChord setHidden:([sender selectedSegmentIndex] == 0)];
    [_MajorChord setHidden:([sender selectedSegmentIndex] == 0)];
    
    [_AugmentedChord setTitle:([sender selectedSegmentIndex] == 2) ? @"dom" : @"aug" forState:UIControlStateNormal];
}

- (IBAction)PlaybackChange:(id)sender
{
    if ([CvTAppSettings Current].Airplay == kAirplay_Client)
        [sender setSelectedSegmentIndex:2];
    else
        switch ([sender selectedSegmentIndex])
    {
        case 0: [[CvTPlaybackThread Playback] Play:FALSE];
            break;
        case 1: [[CvTPlaybackThread Playback] Stop];
            break;
        case 2: [[CvTPlaybackThread Playback] Play:TRUE];
            break;
    }
}

-(void)viewDidLoad
{
    [CvTAppSettings Current].Scale = @"101011010101";
    [CvTAppSettings Current].TonalSpan = 24;
    [CvTAppSettings Current].TonalCentre = 0;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self ChordModeChange:_ChordType];

    [self.Playback setSelectedSegmentIndex:1];
    
    if (![CvTAppSettings Current].Advanced)
    {
        [self.Playback setHidden:TRUE];
        [self.TuneSelect setHidden:TRUE];
    }
}

-(void)didFinishPlayback;
{
    [self.Playback setSelectedSegmentIndex:1];
}

-(void)didSelectTune:(CvTMidiTuneInfo*)tuneInfo
{
    _TuneName.text = tuneInfo.File;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    for (id controller in ((UINavigationController*)segue.destinationViewController).viewControllers)
    {
        if ([controller isKindOfClass:[CvTMIDITuneViewController class]])
        {
            [_Playback setSelectedSegmentIndex:1];
            [self PlaybackChange:_Playback];
        }
    }
}

@end