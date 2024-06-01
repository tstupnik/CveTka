//
//  CvTRecorder.h
//  CveTka
//
//  Created by tomaz stupnik on 8/24/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreMIDI/CoreMIDI.h>

#import "CvTMetronome.h"

@class CvTAirplayMessage;
@class CvTSynth;

@interface CvTRecorderTrack : NSObject
{
    MusicTrack Track;
}

-(id)init:(MusicSequence)sequence name:(NSString*)name;
-(void)MetaEvent:(MIDIMetaEvent*)event;
-(void)NoteMessage:(MIDINoteMessage*)message timestamp:(MusicTimeStamp)timestamp;

@end

@interface CvTRecorder : NSObject
{
    CvTMetronome *Metronome;
    
    MusicSequence Sequence;
    MusicTrack TempoTrack;
    NSLock *RecorderLock;
    
    BOOL IsEmpty;
    NSMutableDictionary *Tracks;
    NSMutableDictionary *MessageBuffer;
}

@property (readonly) int RootTone;
@property (readonly) int RootOctave;
@property (readonly) int TonalCentre;
@property (readonly) NSString *Scale;

+(CvTRecorder*)Recorder;
-(id)init;
-(void)Start:(CvTMetronome*)metronome;
-(void)Feed:(CvTAirplayMessage*)message;
-(NSData*)Save:(NSString**)filePath;

@end
