//
//  CvTTemperament.m
//  CveTka
//
//  Created by tomaz stupnik on 5/28/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTTuning.h"
#import "CvTSynthTone.h"
#import "CvTSynth.h"

@implementation CvTTuning

+(float)Frequency:(float)midiTone
{
    float rTable[2][13] =
    {
        {   1.f,            25.f / 24.f,    9.f / 8.f,      6.f / 5.f,
            5.f / 4.f,      4.f / 3.f,      45.f / 32.f,    3.f / 2.f,
            8.f / 5.f,      5.f / 3.f,      9.f / 5.f,      15.f / 8.f,     2.f },
        {   1.f,            256.f / 243.f,  9.f / 8.f,      32.f / 27.f,
            81.f / 64.f,    4.f / 3.f,      729.f/512.f,    3.f / 2.f,
            128.f / 81.f,   27.f / 16.f,    16.f / 9.f,     243.f / 128.f,  2.f }
    };
    
    if ([CvTAppSettings Current].Intonation == kSynthEqualTemperament)
        return [CvTAppSettings Current].ConcertPitch * pow(exp(log(2.0f) / 12.0f), (midiTone - 69));
    
    int table = ([CvTAppSettings Current].Intonation == kSyntPythagoreanTemperament) ? 1 : 0;
    int rootA4 = [[CvTSynth Synth].Scale Root:69];
    float intervalA4 = [[CvTSynth Synth].Scale Interval:69];
    float rootA4Frequency = [CvTAppSettings Current].ConcertPitch / rTable[table][(int)intervalA4];
    
    int root = [[CvTSynth Synth].Scale Root:midiTone];
    float rootFrequency = rootA4Frequency * pow(2, (root - rootA4) / 12);
    
    float interval = [[CvTSynth Synth].Scale Interval:midiTone];
    float loTone = rootFrequency * rTable[table][(int)floor(interval)];
    float hiTone = rootFrequency * rTable[table][(int)ceil(interval)];
    
    return loTone + (hiTone - loTone) * (interval - floor(interval));
}

-(id)init:(float)midiTone {
    Frequency = [CvTTuning Frequency:midiTone];
    return self;
}

-(void)Slide:(float)midiTone {
    Frequency = [CvTTuning Frequency:midiTone];
}

-(void)FrequencyBuffer:(float*)frequencyBuffer length:(int)length
{
    for (int i = 0; i < length; i++)
        frequencyBuffer[i] = Frequency;
}

@end


@implementation CvTAutoTuning

-(void)SetupDriftTo:(float)TargetFrequency
{
    if (AutoTuneTime == kAutoTuneSpeed_Snap)
    {
        Frequency = TargetFrequency;
        DriftSteps = 0;
    }
    else
    {
        float autoTuneTimes[3] = { 0, 0.5f, 1.5f } ;
        
        FrequencyDrift = TargetFrequency * (exp(log(2) / 12) - 1) / autoTuneTimes[(long)AutoTuneTime] / SAMPLERATE;
        DriftSteps = (TargetFrequency - Frequency) / FrequencyDrift;
        if (DriftSteps < 0)
        {
            DriftSteps = -DriftSteps;
            FrequencyDrift = -FrequencyDrift;
        }
    }
}

-(id)init:(float)midiTone
{
    AutoTune = [CvTAppSettings Current].AutoTune;
    AutoTuneTime = [CvTAppSettings Current].AutoTuneTime;
    
    MidiCurrentTone = 0;
    MidiHigherTone = 0;
    Frequency = [CvTTuning Frequency:midiTone];
    [self Slide:midiTone];

    return self;
}

-(void)Slide:(float)midiTone
{
    if (AutoTuneTime == kAutoTuneSpeed_None)
    {
        Frequency = [CvTTuning Frequency:midiTone];
    }
    else
    {
        MidiAutoTuneTone = (AutoTune == kAutoTune_Scale) ? [[CvTSynth Synth].Scale SnapMidiTone:midiTone] : round(midiTone);
        
        if (AutoTuneTime == kAutoTuneSpeed_Snap)
        {
            Frequency = [CvTTuning Frequency:MidiAutoTuneTone];
        }
        else
        {
            if (midiTone < MidiCurrentTone)
            {
                if (midiTone > MidiLowerTone)
                {
                    float LowFrequency = [CvTTuning Frequency:MidiLowerTone];
                    Frequency = LowFrequency + (Frequency - LowFrequency) * (midiTone - MidiLowerTone) / (MidiCurrentTone - MidiLowerTone);
                    [self SetupDriftTo:[CvTTuning Frequency:MidiAutoTuneTone]];
                }
                else
                {
                    [self SetupDriftTo:[CvTTuning Frequency:MidiAutoTuneTone]];
                }
            }
            else
                if (midiTone > MidiCurrentTone)
                {
                    if (midiTone < MidiHigherTone)
                    {
                        float HighFrequency = [CvTTuning Frequency:MidiHigherTone];
                        Frequency = Frequency + (HighFrequency - Frequency) * (midiTone - MidiCurrentTone) / (MidiHigherTone - MidiCurrentTone);
                        [self SetupDriftTo:[CvTTuning Frequency:MidiAutoTuneTone]];
                    }
                    else
                    {
                        [self SetupDriftTo:[CvTTuning Frequency:MidiAutoTuneTone]];
                    }
                }
        }
    }
    
    MidiCurrentTone = midiTone;
    if (AutoTune == kAutoTune_Chromatic)
    {
        MidiHigherTone = MidiAutoTuneTone + 1;
        MidiLowerTone = MidiAutoTuneTone - 1;
    }
    if (AutoTune == kAutoTune_Scale)
    {
        MidiHigherTone = [[CvTSynth Synth].Scale MidiIntervalTone:MidiAutoTuneTone interval:1];
        MidiLowerTone = [[CvTSynth Synth].Scale MidiIntervalTone:MidiAutoTuneTone interval:-1];
    }
}

-(void)FrequencyBuffer:(float*)frequencyBuffer length:(int)length
{
    for (int i = 0; i < length; i++)
    {
        frequencyBuffer[i] = Frequency;
        if (DriftSteps > 0)
        {
            Frequency += FrequencyDrift;
            DriftSteps--;
        }
    }
}

@end