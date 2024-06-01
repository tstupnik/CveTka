//
//  CvTMidiThread.h
//  CveTka
//
//  Created by tomaz stupnik on 8/10/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreMIDI/CoreMIDI.h>

#import "../Synth/CvTSynth.h"

@interface CvTMidiTuneInfo : NSObject

@property (readonly) NSString *Name;
@property (readonly) NSString *File;
@property (readonly) int RootTone;
@property (readonly) int RootOctave;
@property (readonly) int TonalCentre;
@property (readonly) NSString *Scale;

-(id)initWithArray:(NSArray*)array;
-(id)initWithFile:(NSString*)file;

@end


@class CvTRecorder;

@interface CvTPlaybackTune : NSObject
{
    MusicSequence Sequence;
    MusicEventIterator Iterators[2];
    UInt32 NumberOfTracks;
}

@property (readonly) int RootTone;
@property (readonly) int RootOctave;
@property (readonly) int TonalCentre;
@property (readonly) NSString *Scale;

-(id)init:(CvTMidiTuneInfo*)tuneInfo;
-(BOOL)GetNextEvent:(int*)track timestamp:(MusicTimeStamp*)timestamp eventType:(MusicEventType*)eventType eventData:(const Byte**)eventData eventDataSize:(UInt32*)eventDataSize;
@end

@protocol CvTPlaybackDelegate

-(void)didFinishPlayback;
-(void)didSelectTune:(CvTMidiTuneInfo*)tuneInfo;

@end

@interface CvTPlaybackThread : NSObject
{
    BOOL Recording;
    NSThread *Thread;
}

@property (nonatomic, readwrite, setter = setSelectedFile:) CvTMidiTuneInfo *SelectedFile;
@property (nonatomic, readwrite) CvTPlaybackTune *Tune;
@property (nonatomic) id<CvTPlaybackDelegate> Delegate;
@property (nonatomic, readonly) CvTMetronome *Metronome;

+(CvTPlaybackThread*)Playback;

-(void)Play:(BOOL)record;
-(void)Stop;

@end
