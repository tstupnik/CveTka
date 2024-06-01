//
//  CvtScale.m
//  CveTest
//
//  Created by tomaz stupnik on 4/27/14.
//  Copyright (c) 2014 tomaz stupnik. All rights reserved.
//

#import "CvTScale.h"

@implementation CvTScaleTone

- (float)Radius {
     return self.Angle / 2 / M_PI;
}

@end

@implementation CvTScale

- (id)initWithScale:(int)midiRoot tonalCentre:(int)tonalCentre scale:(NSString*)scale
{
    _MidiRootTone = midiRoot;
    _TonalCentre = tonalCentre;
    
    for (int tone = 0; tone < 12; tone++)
        if ([scale characterAtIndex:(tone%12)] == '1')
            [self ToggleTone:tone];
    
    return self;
}

-(NSString*)string
{
    NSMutableString *s = [[NSMutableString alloc] initWithString:@""];
    for (int i = 0; i < 12; i++)
        [s appendString: (Tones[i] == NULL) ? @"0" : @"1"];
    return s;
}

-(void)ToggleTone:(int)tone
{
    if (Tones[tone] == NULL)
    {
        CvTScaleTone *t =[CvTScaleTone new];
        t.Tone = tone + _MidiRootTone;
        t.Angle = ((float)tone) / 12 * 2 * M_PI;
        Tones[tone] = t;
    }
    else
    {
        Tones[tone] = NULL;
    }
}

-(float)Interval:(float)midiTone {
    return fmodf(12.f * 12.f + midiTone - _MidiRootTone, 12.f);
}

-(int)Root:(float)midiTone {
    return midiTone - [self Interval:midiTone];
}

-(void)ToggleMidiTone:(float)midiTone
{
    int tone = (12 * 12 + (int)roundf(midiTone) - _MidiRootTone) % 12;
    if (tone > 0)
        [self ToggleTone:tone];
}

-(BOOL)ContainsMidiTone:(float)midiTone
{
    int tone = (12 * 12 + (int)roundf(midiTone) - _MidiRootTone) % 12;
    return (Tones[tone] != NULL);
}

-(int)MidiSolNumber:(float)midiTone{
    return (12 * 12 + (int)roundf(midiTone) - _MidiRootTone) % 12;
}

-(NSString*)MidiSolName:(float)midiTone
{
    NSString *tonenames[12] = {@"DO", @"di", @"RE", @"ri", @"MI", @"FA", @"fi", @"SO", @"si", @"LA", @"li", @"TI"};
    return tonenames[[self MidiSolNumber:midiTone]];
}

+(NSString*)MidiToneName:(float)midiTone
{
    NSString *tonenames[12] = {@"A", @"B\u266D", @"B", @"C", @"D\u266D", @"D", @"E\u266D", @"E", @"F", @"F\u266F", @"G", @"A\u266D" };
    return tonenames[((int)roundf(midiTone) - 9 + 12) % 12];
}

-(float)SnapMidiTone:(float)midiTone
{
    int roundedMidiTone = (int)lroundf(midiTone);
    int tone = (12 * 12 + roundedMidiTone - _MidiRootTone) % 12;
    if (Tones[tone] != NULL)
        return roundedMidiTone;
        
    for (int i = 0; i < 6; i++)
    {
        int hitone = (12 * 12 + roundedMidiTone - _MidiRootTone + i) % 12;
        int lotone = (12 * 12 + roundedMidiTone - _MidiRootTone - i) % 12;
    
        if (Tones[hitone] != NULL)
            if (Tones[lotone] != NULL)
                return roundedMidiTone + (((midiTone - roundedMidiTone) > 0) ? i : -i);
            else
                return roundedMidiTone + i;
        else
            if (Tones[lotone] != NULL)
                return roundedMidiTone - i;
    }
    return roundedMidiTone;
}

-(int)MidiIntervalTone:(int)midiTone interval:(int)interval
{
    midiTone += interval;
    for (int i = 0; i < 12; i++)
    {
        midiTone += ((interval > 0) ? 1 : -1);
        if (Tones[(12 * 12 + midiTone - _MidiRootTone) % 12] != NULL)
            return midiTone;
    }
    return midiTone;
}

-(int)MidiChordTone:(int)midiTone chordInterval:(int)chordInterval
{
    int root = [self MidiSolNumber:midiTone];
    int interval;
    for (interval = 0; interval < 12; interval++)
        if (Tones[(interval + root) % 12] != NULL)
            if(--chordInterval <= 0)
                break;

    return midiTone + interval;
    
    
    //Doremi    faso    latido
    //Doremi    fasi    latido
    //Doremi    fisi    latido
}

-(int)getMidiNumberOfSharps
{
    int scaleRoots[15][2] = {
        {0, 0}, //C
        {1, -5}, //Db
        {2, 2}, //D
        {3, -3}, //Eb
        {4, 4}, //E
        {5, -1}, //F
        {6, 6}, //F#
        {7, 1}, //G
        {8, -4}, //Ab
        {9, 3}, //A
        {10, -2}, //Bb
        {11, 5}, //B
    };
    int majorScale[12] = { 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1 };
    
    int bestScale = 0;
    int bestMisses = 12;
    for (int i = 0; i < 12; i++)
    {
        int misses = 0, root = _MidiRootTone % 12;
        for (int j = 0; j < 12; j++)
        {
            if (Tones[(j + root) % 12])
                if (!majorScale[(j + i) % 12])
                    misses++;
        }
        if (misses < bestMisses)
        {
            bestScale = i;
            bestMisses = misses;
        }
    }

    return scaleRoots[bestScale][1];
}

+(int)RootFromNumberOfSharps:(int)sharps
{
    int scaleRoots[15][2] = {
        {3, 0}, //C
        {4, -5}, //Db
        {5, 2}, //D
        {6, -3}, //Eb
        {7, 4}, //E
        {8, -1}, //F
        {9, 6}, //F#
        {10, 1}, //G
        {11, -4}, //Ab
        {0, 3}, //A
        {1, -2}, //Bb
        {2, 5}, //B
    };
    
    sharps = MAX(MIN(sharps, 6), -6);
    if (sharps == -6)
        sharps = 6;
    
    for (int i = 0; i < 12; i++)
        if (scaleRoots[i][1] == sharps)
            return scaleRoots[i][0];
    return 0;
}

@end