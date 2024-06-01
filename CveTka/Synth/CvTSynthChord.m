//
//  CvTSynthChord.m
//  CveTka
//
//  Created by tomaz stupnik on 8/12/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTSynth.h"
#import "CvTSynthChord.h"
#import "CvTMidiPacketList.h"

@implementation CvTChordMaker

struct ChordTableEntry
{
    char *Name;
    int Pattern;
    AutoChordMode Mode;
} AllChords[] = {
    {   "sus2",     0b10101001000000  },      //1,3,5,8
    {   "sus2",     0b10101001000100  },      //1,3,5,8,12
    
    {   "7,9,sus4", 0b10100101001000  },      //1,3,6,8,11
    {   "M7,9,sus4",0b10100101000100  },      //1,3,6,8,12
    
    {   "m6,9",     0b10110001010000  },      //1,3,4,8,10
    {   "6,9",      0b10101001011000  },      //1,3,5,8,10,11
    {   "7,9",      0b10101001010100  },      //1,3,5,8,10,12
    {   "M9",       0b10101001001000  },      //1,3,5,8,11
    {   "7,+9",     0b10011001001000  },      //1,4,5,8,11
    {   "7,b9",     0b11001001001000  },      //1,2,5,8,11
    
    {   "M",        0b10001001000000,   kChordMode_Major        },      //1,5,8
    {   "6",        0b10001001010000  },      //1,5,8,10
    {   "7",        0b10001001001000,   kChordMode_Dominant7    },      //1,5,8,11
    {   "M7",       0b10001001000100,   kChordMode_Major7       },      //1,5,8,12
    {   "add9",     0b10001001000001  },      //1,5,8,14
    
    {   "+",        0b10001000100000,   kChordMode_Augmented    },      //1,5,9
    {   "+7",       0b10001000101000,   kChordMode_Augmented7   },      //1,5,9,11
    {   "Maj7 #5",  0b10001000100100  },      //1,5,9,12
    
    {   "sus4",     0b10000101000000  },      //1,6,8
    {   "6,sus4",   0b10000101010000  },      //1,6,8,10
    {   "7,sus4",   0b10000101001000  },      //1,6,8,11
    {   "Maj7,sus4",0b10000101000100  },      //1,6,8,12
    
    {   "o",        0b10010010000000,   kChordMode_Diminished   },      //1,4,7
    {   "o7",       0b10010010010000,   kChordMode_Diminished7  },      //1,4,7,10
    {   "7 (b5)",   0b10010010001000  },      //1,4,7,11
    
    {   "m",        0b10010001000000,   kChordMode_Minor        },      //1,4,8
    {   "mb6",      0b10010001100000  },      //1,4,8,9
    {   "m+6",      0b10010001010000  },      //1,4,8,10
    {   "m7",       0b10010001001000,   kChordMode_Minor7       },      //1,4,8,11
    {   "m Maj7",   0b10010001000100  },      //1,4,8,12
    {   "madd9",    0b10010001000001  },      //1,4,8,14
    
    {   "m7,6",     0b10010001011000  }       //1,4,8,10,11
};

+(NSString*)Name:(NSArray*)Chords
{
    NSMutableArray *midiTones =[[NSMutableArray alloc]init];
    for (CvTSynthChord *chord in Chords)
        if (!chord.Released)
            for (NSNumber *midiTone in chord.ChordSnappedMidiTones)
                [midiTones addObject:midiTone];

    NSArray *sortedMidiTones = [midiTones sortedArrayUsingSelector:@selector(compare:)];
    
    NSString *chordName = @"";
    if (sortedMidiTones.count > 0)
    {
        chordName = [CvTScale MidiToneName:[sortedMidiTones[0] intValue]];
        
        int chord = 0;
        for (int i = 0; i < sortedMidiTones.count; i++)
        {
            int interval = [sortedMidiTones[i] intValue] - [sortedMidiTones[0] intValue];
            if (interval < 14)
                chord |= 1 << (13 - interval);
        }

        for (int i = 0; i < sizeof(AllChords)/sizeof(struct ChordTableEntry); i++)
        {
            int pattern = AllChords[i].Pattern;
            if (chord == pattern)
                chordName = [NSString stringWithFormat:@"%@%@", chordName, [NSString stringWithUTF8String:AllChords[i].Name]];
        }
    }
    
    chordName = [chordName stringByReplacingOccurrencesOfString:@"o" withString:@"\u00B0"];
    chordName = [chordName stringByReplacingOccurrencesOfString:@"M" withString:@"\u0394"];
    return chordName;
}

+(NSArray*)DiatonicChordTones:(float)midiTone scale:(CvTScale*)scale chordMode:(AutoChordMode)chordMode
{
    NSNumber *tones[8] = { [NSNumber numberWithFloat:midiTone] };
    NSArray *diatonicTones = @[@0, @2, @4, @5, @7, @9, @11, @12, @14, @16, @17, @19, @21, @23];
    
    midiTone = roundf(midiTone);
    int root = midiTone - fmod(12 * 12 + midiTone - scale.MidiRootTone, 12);
    int solNumber = [scale MidiSolNumber:midiTone];
    long diatonicIndex = [diatonicTones indexOfObject:[NSNumber numberWithInt:solNumber]];
    if (diatonicIndex != NSNotFound)
    {
        tones[0] = @([diatonicTones[diatonicIndex] integerValue] + root);
        tones[1] = @([diatonicTones[diatonicIndex + 2] integerValue] + root);
        tones[2] = @([diatonicTones[diatonicIndex + 4] integerValue] + root);
        
        if (chordMode == kChordMode_Diatonic7)
        {
            tones[3] = @([diatonicTones[diatonicIndex + 6] integerValue] + root);
            return [[NSArray alloc] initWithObjects:tones count:4];
        }
        return [[NSArray alloc] initWithObjects:tones count:3];
    }
    return [[NSArray alloc] initWithObjects:tones count:1];
}

+(NSArray*)ChordTones:(float)midiTone chordMode:(AutoChordMode)chordMode
{
    NSNumber *tones[8] = { [NSNumber numberWithFloat:midiTone] };
    
    for (int i = 0; i < sizeof(AllChords)/sizeof(struct ChordTableEntry); i++)
        if (AllChords[i].Mode == chordMode)
        {
            int root = round(midiTone);
            int toneCount = 0;
            for (int interval = 0; interval < 14; interval++)
                if ((AllChords[i].Pattern >> (13 - interval)) & 1)
                    tones[toneCount++] = @(root + interval);
            return [[NSArray alloc] initWithObjects:tones count:toneCount];
        }
    
    return [[NSArray alloc] initWithObjects:tones count:1];
}

@end


@implementation CvTSynthChord

-(NSArray*)GetChordTones:(float)midiTone
{
    NSNumber *tones[8] = { [NSNumber numberWithFloat:midiTone] };
    switch (ChordMode)
    {
        case kChordMode_Root:
            return [[NSArray alloc] initWithObjects:tones count:1];
        case kChordMode_Diatonic:
        case kChordMode_Diatonic7:
            return [CvTChordMaker DiatonicChordTones:midiTone scale:[CvTSynth Synth].Scale chordMode:ChordMode];
        default:
            return [CvTChordMaker ChordTones:midiTone chordMode:ChordMode];
    }
}

-(NSArray*)tonesFromMidiTones:(NSArray*)midiTones duration:(float)duration
{
    id<CvTSynthTone> tones[32];
    for (int i = 0; i < [midiTones count]; i++)
    {
        if (ChordMode == kChordMode_Mute)
            tones[i] = [[CvTMuteTone alloc] init:[[midiTones objectAtIndex:i] floatValue]];
        else
            if ([CvTAppSettings Current].Sound != kSynthSound_Midi)
                tones[i] = [[CvTSynthFMTone alloc] init:[[midiTones objectAtIndex:i] floatValue] disableAutotune:(duration > 0)];
            else
                tones[i] = [[CvTSynthMidiTone alloc] init:[[midiTones objectAtIndex:i] floatValue] channel:0];
        tones[i].Duration = duration;
    }
    return [[NSArray alloc] initWithObjects:tones count:[midiTones count]];
}

-(id)init:(float)midiTone chordMode:(AutoChordMode)chordMode duration:(float)duration source:(NSString*)source
{
    _Source = source;
    _Ident = random();
    _Symbol = [CvTAppSettings Current].AirplaySymbol;
    _TimeStamp = [NSDate date];
    
    ChordMode = chordMode;
    Tones = [self tonesFromMidiTones:[self GetChordTones:midiTone] duration:duration];
    
    return self;
}

-(id)initWithCoder:(NSCoder*)decoder
{
    _Source = [decoder decodeObjectForKey:@"source"];
    _Ident = [[decoder decodeObjectForKey:@"ident"] longValue];
    _Symbol = [[decoder decodeObjectForKey:@"symbol"] intValue];
    _TimeStamp = [decoder decodeObjectForKey:@"timestamp"];
    
    ChordMode = kChordMode_Mute;
    Tones = [self tonesFromMidiTones:[decoder decodeObjectForKey:@"tones"] duration:[[decoder decodeObjectForKey:@"duration"] floatValue]];

    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_Source forKey:@"source"];
    [aCoder encodeObject:[NSNumber numberWithLong:_Ident] forKey:@"ident"];
    [aCoder encodeObject:[NSNumber numberWithInt:_Symbol] forKey:@"symbol"];
    [aCoder encodeObject:_TimeStamp forKey:@"timestamp"];
    [aCoder encodeObject:self.ChordSnappedMidiTones forKey:@"tones"];
    [aCoder encodeObject:[NSNumber numberWithFloat:self.Duration] forKey:@"duration"];
}

-(void)Play
{
    if (ChordMode != kChordMode_Mute)
        [[CvTAirplayJam AirplayJam] ChordOn:self];
}

-(float)FingeredMidiTone {
    return [(NSObject<CvTSynthTone> *)Tones[0] MidiTone];
}

-(NSArray*)ChordMidiTones
{
    NSNumber *tones[32];
    for (int i = 0; i < [Tones count]; i++)
        tones[i] = [NSNumber numberWithFloat:[(NSObject<CvTSynthTone> *)Tones[i] MidiTone]];
    return [[NSArray alloc] initWithObjects:tones count:[Tones count]];
}

-(NSArray*)ChordIntMidiTones
{
    NSNumber *tones[32];
    NSArray *midiTones = self.ChordMidiTones;
    for (int i = 0; i < midiTones.count; i++)
        tones[i] = [NSNumber numberWithInt:roundf(((NSNumber*)midiTones[i]).floatValue)];
    return [[NSArray alloc] initWithObjects:tones count:[midiTones count]];
}

-(NSArray*)ChordSnappedMidiTones
{
    NSNumber *tones[32];
    NSArray *midiTones = self.ChordMidiTones;
    for (int i = 0; i < midiTones.count; i++)
        if (/*Synth && */(self.Duration == 0))
            tones[i] = [NSNumber numberWithFloat:[[CvTSynth Synth] SnapTone:(((NSNumber*)midiTones[i]).floatValue)]];
        else
            tones[i] = [NSNumber numberWithFloat:((NSNumber*)midiTones[i]).floatValue];
    return [[NSArray alloc] initWithObjects:tones count:[midiTones count]];
}

-(void)SlideChord:(NSArray*)chordTones
{
    if (chordTones.count == Tones.count)
        for (int i = 0; i < Tones.count; i++)
            [(NSObject<CvTSynthTone> *)Tones[i] Slide:[[chordTones objectAtIndex:i] floatValue]];
}

-(void)Slide:(float)midiTone
{
    //if (Synth != NULL)
    {
        [self SlideChord:[self GetChordTones:midiTone]];
        [[CvTAirplayJam AirplayJam] ChordSlide:self];
    }
}

-(void)Release
{
    if (ChordMode != kChordMode_Mute)
        [[CvTAirplayJam AirplayJam] ChordOff:self];
    
    for (int i = 0; i < Tones.count; i++)
        [Tones[i] Release];
    
    if (_Animation != NULL)
    {
        [_Animation Release];
        _Animation = NULL;
    }
}

-(void)Render:(float*)buffer envelopeBuffer:(float*)envelopeBuffer length:(int)length
{
    [Tones[0] Render:buffer envelopeBuffer:envelopeBuffer length:length];
    for (int i = 1; i < Tones.count; i++)
    {
        float exbuffer[length];
        [Tones[i] Render:exbuffer envelopeBuffer:envelopeBuffer length:length];
        for (int j = 0; j < length; j++)
            buffer[j] += exbuffer[j];
    }
    if (Tones.count > 1)
        for (int j = 0; j < length; j++)
            buffer[j] /= Tones.count;
    
    if (self.Finished)
        if (_Animation)
        {
            [_Animation Release];
            _Animation = NULL;
        }
}

-(BOOL)Finished {
    return [Tones[0] Finished];
}

-(BOOL)Released {
    return [Tones[0] Released];
}

-(float)Duration {
    return ((id<CvTSynthTone>)Tones[0]).Duration;
}

@end