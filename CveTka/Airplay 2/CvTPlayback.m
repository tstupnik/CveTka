//
//  CvTMidiThread.m
//  CveTka
//
//  Created by tomaz stupnik on 8/10/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTRecorder.h"
#import "CvTPlayback.h"
#import "../Spiral/CvTSpiralView.h"


@implementation CvTMidiTuneInfo

-(id)initWithArray:(NSArray*)array
{
    _Name = array[0];
    _File = array[1];
    _RootTone = [array[2] intValue];
    _RootOctave = [array[3] intValue];
    _TonalCentre = [array[4] intValue];
    _Scale = array[5];
    return self;
}

-(id)initWithFile:(NSString*)file
{
    _File = file;
    return self;
}

-(id)initWithSharps:(int)sharps minor:(BOOL)minor
{
    _RootOctave = 57;
    _RootTone = [CvTScale RootFromNumberOfSharps:sharps];
    _TonalCentre = minor ? 9 : 0;
    _Scale = @"101011010101";
 
    return self;
}

@end


@implementation CvTPlaybackTune

-(id)init:(CvTMidiTuneInfo*)tuneInfo
{
    NewMusicSequence(&Sequence);
    NSString *dirPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, TRUE) objectAtIndex:0] stringByAppendingPathComponent:tuneInfo.File];
    if (MusicSequenceFileLoad(Sequence, (__bridge CFURLRef)[NSURL fileURLWithPath:dirPath], 0, 0) == noErr)
        tuneInfo = [self LoadTuneInfo:Sequence];
    else
        MusicSequenceFileLoad(Sequence, (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:tuneInfo.File ofType:@"mid"]], 0, 0);
    
    CAShow(Sequence);
    
    _RootOctave = tuneInfo.RootOctave;
    _RootTone = tuneInfo.RootTone;
    _TonalCentre = tuneInfo.TonalCentre;
    _Scale = tuneInfo.Scale;
    
    [self Rewind];
    return self;
}

-(CvTMidiTuneInfo*)LoadTuneInfo:(MusicSequence)sequence
{
    [self Rewind];

    MusicTimeStamp timestamp;
    MusicEventType eventType;
    const Byte *eventData;
    UInt32 eventDataSize;
    int track;
    
    while ([self GetNextEvent:&track timestamp:&timestamp eventType:&eventType eventData:&eventData eventDataSize:&eventDataSize])
        if (eventType == kMusicEventType_Meta)
        {
            MIDIMetaEvent *metaMessage = (MIDIMetaEvent*)eventData;
            if (metaMessage->metaEventType == 0x59)
                return [[CvTMidiTuneInfo alloc] initWithSharps:(char)metaMessage->data[0] minor:metaMessage->data[1]];
        }
    return [[CvTMidiTuneInfo alloc] initWithSharps:0 minor:FALSE];
}

-(void)SetupMetronome:(CvTMetronome*)metronome
{
    MusicTrack track;
    MusicEventIterator iterator;
    MusicSequenceGetTempoTrack(Sequence, &track);
    NewMusicEventIterator(track, &iterator);

    for (Boolean hasEvent = TRUE; hasEvent; MusicEventIteratorNextEvent(iterator))
    {
        MusicEventIteratorHasCurrentEvent(iterator, &hasEvent);
        if (hasEvent)
        {
            MusicTimeStamp cTimeStamp;
            MusicEventType cEventType;
            const Byte *cEventData;
            UInt32 cEventDataSize;
            MusicEventIteratorGetEventInfo(iterator, &cTimeStamp, &cEventType, (const void**)&cEventData, &cEventDataSize);
            
            if (cEventType == kMusicEventType_Meta)
            {
                MIDIMetaEvent *metaMessage = (MIDIMetaEvent*)cEventData;
                if (metaMessage->metaEventType == 0x58)
                {
                    metronome.Nominator = metaMessage->data[0];
                    metronome.Denominator = pow(2, metaMessage->data[1]);
                    break;
                }
            }
        }
    }
}

-(void)Rewind
{
    MusicSequenceGetTrackCount(Sequence, &NumberOfTracks);
    NumberOfTracks = MIN(NumberOfTracks, 2);
    
    for (int i = 0; i < NumberOfTracks; i++)
    {
        MusicTrack track;
        MusicSequenceGetIndTrack(Sequence, i, &track);
        NewMusicEventIterator(track, &(Iterators[i]));
    }
}

-(BOOL)GetNextEvent:(int*)track timestamp:(MusicTimeStamp*)timestamp eventType:(MusicEventType*)eventType eventData:(const Byte**)eventData eventDataSize:(UInt32*)eventDataSize
{
    MusicTimeStamp cTimeStamp;
    MusicEventType cEventType;
    const Byte *cEventData;
    UInt32 cEventDataSize;
    
    track[0] = -1;
    for (int i = 0; i < NumberOfTracks; i++)
    {
        Boolean hasEvent;
        MusicEventIteratorHasCurrentEvent(Iterators[i], &hasEvent);
        
        if (hasEvent)
        {
            MusicEventIteratorGetEventInfo(Iterators[i], &cTimeStamp, &cEventType, (const void**)&cEventData, &cEventDataSize);
 
            if ((track[0] < 0) || (timestamp[0] > cTimeStamp))
            {
                track[0] = i;
                timestamp[0] = cTimeStamp;
                eventType[0] = cEventType;
                eventData[0] = cEventData;
                eventDataSize[0] = cEventDataSize;
            }
        }
    }
    
    if (track[0] >= 0)
    {
        MusicEventIteratorNextEvent(Iterators[track[0]]);
        return TRUE;
    }
    return FALSE;
}

@end


@implementation CvTPlaybackThread

+(CvTPlaybackThread*)Playback
{
    static CvTPlaybackThread* _Playback = NULL;
    if (_Playback == NULL)
        _Playback = [[CvTPlaybackThread alloc] init];
    return _Playback;
}

-(void)setSelectedFile:(CvTMidiTuneInfo*)tuneInfo
{
    [self Stop];
    
    _SelectedFile = tuneInfo;
    _Tune = tuneInfo ? [[CvTPlaybackTune alloc] init:tuneInfo] : NULL;
    if (_Delegate)
        [_Delegate didSelectTune:tuneInfo];
}

-(void)Play:(BOOL)record
{
    Recording = record;
    if (Thread == NULL)
    {
        if (_Tune)
        {
            [_Tune Rewind];
            
            [CvTAppSettings Current].RootTone = _Tune.RootTone;
            [CvTAppSettings Current].RootOctave = _Tune.RootOctave;
            [CvTAppSettings Current].TonalCentre = _Tune.TonalCentre;
            [CvTAppSettings Current].Scale = _Tune.Scale;
            [[CvTSpiralView Spiral] Initialize];
        }
        
        Thread = [[NSThread alloc] initWithTarget:self selector:@selector(ThreadLoop) object:NULL];
        [Thread start];
    }
}

-(void)Stop
{
    if (Thread != NULL)
    {
        [Thread cancel];
        Thread = NULL;
    }
}

-(void)ThreadLoop
{
    MusicTimeStamp noteTimestamp;
    MusicEventType eventType;
    const Byte *eventData;
    UInt32 eventDataSize;
    int track;
    
    _Metronome = [[CvTMetronome alloc] init];
    if (_Tune)
        [_Tune SetupMetronome:_Metronome];
    if (Recording)
        [[CvTRecorder Recorder] Start:_Metronome];
    [_Metronome CountIn:2];
    
    if (_Tune)
        while ([_Tune GetNextEvent:&track timestamp:&noteTimestamp eventType:&eventType eventData:&eventData eventDataSize:&eventDataSize])
        {
            if (![_Metronome CountToEvent:noteTimestamp])
            {
                Thread = NULL;
                break;
            }
            
            if (eventType == kMusicEventType_MIDINoteMessage)
            {
                MIDINoteMessage *noteMessage = (MIDINoteMessage*)eventData;
                
                dispatch_queue_t queue = dispatch_queue_create("queue", NULL);
                dispatch_async(queue, ^{
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CvTSynthChord *chord = [[CvTSynthChord alloc] init:noteMessage->note chordMode:kChordMode_Root duration:noteMessage->duration * _Metronome.Duration source:[NSString stringWithFormat:@"%d", track]];
                        chord.Symbol = track % 3;
                        
                        [[CvTSpiralView Spiral] Play:chord];
                    });
                });
            }
        }
    
    if (Recording)
    {
        if (Thread)
            [_Metronome CountToEvent:MAXFLOAT];
        
        NSString *filePath;
        [[CvTRecorder Recorder] Save:&filePath];
        [CvTPlaybackThread Playback].SelectedFile = [[CvTMidiTuneInfo alloc] initWithFile:filePath];
    }
    
    Thread = NULL;
    if (_Delegate)
        [_Delegate didFinishPlayback];
}

@end
