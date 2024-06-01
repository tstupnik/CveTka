//
//  CvTRecorder.m
//  CveTka
//
//  Created by tomaz stupnik on 8/24/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTRecorder.h"
#import "CvTAirplayJam.h"
#import "../Synth/CvTSynth.h"

@implementation CvTRecorderTrack

-(id)init:(MusicSequence)sequence name:(NSString*)name
{
    MusicSequenceNewTrack(sequence, &Track);
    return self;
}

-(void)MetaEvent:(MIDIMetaEvent*)event
{
    MusicTrackNewMetaEvent(Track, 0, event);
}

-(void)NoteMessage:(MIDINoteMessage*)message timestamp:(MusicTimeStamp)timestamp
{
    MusicTrackNewMIDINoteEvent(Track, timestamp, message);
}

@end

@implementation CvTRecorder

+(CvTRecorder*)Recorder
{
    static CvTRecorder *recorder = nil;
    @synchronized(self)
    {
        if (recorder == nil)
            recorder = [[self alloc] init];
    }
    return recorder;
}

-(id)init
{
    self = [super init];
    MessageBuffer = [[NSMutableDictionary alloc] init];
    Tracks = [[NSMutableDictionary alloc] init];
    RecorderLock = [[NSLock alloc] init];
    return self;
}

-(CvTRecorderTrack*)Track:(NSString*)name
{
    CvTRecorderTrack *track = [Tracks objectForKey:name];
    if (!track)
    {
        track = [[CvTRecorderTrack alloc] init:Sequence name:name];
        [Tracks setObject:track forKey:name];

        if (Tracks.count == 1)
        {
            NSString *name = @"mytune";
            Byte buffer[256];
            MIDIMetaEvent *nameEvent = (MIDIMetaEvent*)buffer;
            nameEvent->metaEventType = 0x08;
            nameEvent->dataLength = (int)name.length;
            memcpy(&nameEvent->data, [name cStringUsingEncoding:NSASCIIStringEncoding], nameEvent->dataLength);
            
            MIDIMetaEvent keyEvent;
            keyEvent.metaEventType = 0x59;
            keyEvent.dataLength = 2;
            keyEvent.data[0] = [CvTSynth Synth].Scale.MidiNumberOfSharps;
            keyEvent.data[1] = 0;
            
            [track MetaEvent:&keyEvent];
            [track MetaEvent:nameEvent];
        }
    }
    return track;
}

-(void)Start:(CvTMetronome*)metronome
{
    [RecorderLock lock];
    
    Metronome = metronome;
    
    NewMusicSequence(&Sequence);
    MusicSequenceGetTempoTrack(Sequence, &TempoTrack);
    [MessageBuffer removeAllObjects];
    [Tracks removeAllObjects];
    
    _RootTone = ([CvTSynth Synth].Scale.MidiRootTone - 9 + 12) % 12;
    _RootOctave = [CvTSynth Synth].Scale.MidiRootTone - _RootTone;
    _TonalCentre = [CvTSynth Synth].Scale.TonalCentre;
    _Scale = [CvTSynth Synth].Scale.string;

    MIDIMetaEvent timeEvent;
    timeEvent.metaEventType = 0x58;
    timeEvent.dataLength = 4;
    timeEvent.data[0] = Metronome.Nominator;
    timeEvent.data[1] = log2(Metronome.Denominator);
    timeEvent.data[2] = 0x18;
    timeEvent.data[3] = 9;

    MIDIMetaEvent tempoEvent;
    tempoEvent.metaEventType = 0x51;
    tempoEvent.dataLength = 3;
    
    int quarterNote = 60 * 1000000 / Metronome.Tempo;
    for (int i = 0; i < 3; i++, quarterNote >>= 8)
        tempoEvent.data[2 - i] = quarterNote & 0xff;
    
    MusicTrackNewMetaEvent(TempoTrack, 0, &timeEvent);
    MusicTrackNewMetaEvent(TempoTrack, 0, &tempoEvent);
    
    IsEmpty = TRUE;
    
    [RecorderLock unlock];
}

-(void)RecordMessage:(NSArray*)midiTones time:(float)time duration:(float)duration source:(NSString*)source
{
    if (time < 0)
    {
        duration += time;
        time = 0;
    }
    if (duration > 0)
        for (NSNumber *tone in midiTones)
        {
            MusicTimeStamp timestamp = time;
            MIDINoteMessage noteMessage = {
                .channel = 0,
                .note = tone.intValue & 0x7f,
                .velocity = 0x7f,
                .releaseVelocity = 0x7f,
                .duration = duration
            };
            [[self Track:source] NoteMessage:&noteMessage timestamp:timestamp];
        }
}

-(void)Feed:(CvTAirplayMessage*)message
{
    [RecorderLock lock];
    
    NSNumber *key = [NSNumber numberWithLong:message.Chord.Ident];
    switch (message.Type)
    {
        case kAirplayMessage_ChordOn:
            [MessageBuffer setObject:message forKey:key];
            if (message.Chord.Duration > 0)
                [self RecordMessage:message.Chord.ChordIntMidiTones time:[Metronome Duration:message.Timestamp] duration:message.Chord.Duration / Metronome.Duration source:message.Source];
            break;
        case kAirplayMessage_ChordSlide:
            break;
        case kAirplayMessage_ChordOff: {
            CvTAirplayMessage *oldMessage = [MessageBuffer objectForKey:key];
            if (oldMessage)
                [self RecordMessage:oldMessage.Chord.ChordIntMidiTones time:[Metronome Duration:oldMessage.Timestamp] duration:[Metronome Duration:message.Timestamp startTime:oldMessage.Timestamp] source:message.Source];
            if (message.Type == kAirplayMessage_ChordOff)
                [MessageBuffer removeObjectForKey:key];
        } break;
        case kAirplayMessage_Setup:
        case kAirplayMessage_ChordNone:
            break;
    }
    
    [RecorderLock unlock];
}

-(NSData*)Save:(NSString**)file
{
    [RecorderLock lock];
    
    CAShow(Sequence);
    
    CFDataRef cfData;
    MusicSequenceFileCreateData(Sequence, kMusicSequenceFile_MIDIType, kMusicSequenceFileFlags_EraseFile, 0, &cfData);

    NSString *filePrefix = @"CveTka-tune-";
    NSString *dirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, TRUE) objectAtIndex:0];
    
    int lastFile = 0;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:NULL];
    for (NSString *file in files)
    {
        NSInteger index;
        NSScanner *scanner = [NSScanner scannerWithString:file];
        if ([scanner scanString:filePrefix intoString:NULL])
            if([scanner scanInteger:&index])
                lastFile = MAX(lastFile, (int)index);
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@%04d.mid", filePrefix, lastFile + 1];
    NSString *filePath = [dirPath stringByAppendingFormat:@"/%@", fileName];
    [(__bridge NSData *)cfData writeToFile:filePath atomically:TRUE];
    
    if (file)
        file[0] = fileName;

    [RecorderLock unlock];

    return (__bridge NSData *)cfData;
}

@end
