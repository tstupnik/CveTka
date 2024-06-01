//
//  CvTSynth.h
//  SynthTest
//
//  Created by tomaz stupnik on 7/7/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreMIDI/CoreMIDI.h>

#import "Audiobus.h"
#import "CvTScale.h"
#import "CvTSynthTone.h"
#import "CvTSynthChord.h"
#import "../CvTAppSettings.h"
#import "../Airplay/CvTAirplayJam.h"

@interface CvTSynth : NSObject
{
@public
    float Gain;
    float Operator;
    float ExOperator;
    float Modulator;
    float A, D, S, R;
}

@property (retain, readwrite) CvTScale *Scale;
@property (retain, readonly) ABAudiobusController *AudiobusController;
@property (assign) MIDIEndpointRef VirtualSendEndpoint;

+(CvTSynth*)Synth;

-(id)init;
-(BOOL)start;
-(void)stop;
-(void)reset;

-(void)LoadPreset:(SynthSoundPreset)preset;

-(float)SnapTone:(float)midiTone;
-(BOOL)Play:(CvTSynthChord*)chord;
-(void)Slide:(float)midiTone ident:(long)ident;
-(void)Release:(long)ident;
-(void)RenderSound:(float*)buffer numFrames:(int)numFrames;

-(id<CvTAnimationDelegate>)Animation:(long)ident;
-(NSString*)CurrentChord;

@end
