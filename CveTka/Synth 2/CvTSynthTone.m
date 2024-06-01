//
//  CvTSynthTone.m
//  CveTka
//
//  Created by tomaz stupnik on 8/2/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTSynthTone.h"
#import "CvTSynth.h"

@implementation CvTOscillator

-(id)init{
    return [self init:1];
}

-(id)init:(float)frequencyRatio
{
    self = [super init];
    Phase = 0;
    FrequencyRatio = frequencyRatio;
    return self;
}

-(void)Render:(float*)frequencyBuffer buffer:(float*)buffer length:(int)length
{
    for (int i = 0; i < length; ++i)
    {
        buffer[i] = sin(Phase);
        Phase += 2.0f * frequencyBuffer[i] * FrequencyRatio * M_PI / SAMPLERATE;
    }
    Phase = fmodf(Phase, 2 * M_PI);
}

@end

@implementation CvTADSREnvelope

-(id)initWithADSR:(float)A D:(float)D S:(float)S R:(float)R;
{
    self = [super init];
    AttackTime = A;
    DecayTime = D;
    Sustain = S;
    ReleaseTime = R;
    Time = - AttackTime - DecayTime;
    
    return self;
}

-(void)Release
{
    if (TimeReleased == 0)
        TimeReleased = fmaxf(Time, 0.001f);
}

-(BOOL)Finished
{
    return (TimeReleased > 0) && (Time >= (TimeReleased + ReleaseTime));
}

-(BOOL)Released
{
    return (TimeReleased > 0);
}

-(void)Render:(float*)buffer length:(int)length
{
    for (int i = 0; i < length; ++i)
    {
        if (Time < -DecayTime)
            buffer[i] = (AttackTime + DecayTime + Time) / AttackTime;
        else
            if (Time < 0)
                buffer[i] = 1.0f - (1.0f - Sustain) * (DecayTime + Time) / DecayTime;
            else
                if (TimeReleased > 0)
                    buffer[i] = Sustain * (1.0f - fminf(Time - TimeReleased, ReleaseTime) / ReleaseTime);
                else
                    buffer[i] = Sustain;
        
        Time += 1.0f / SAMPLERATE;
    }
}

@end

@implementation CvTSynthFMTone

-(id)init:(float)midiTone disableAutotune:(BOOL)disableAutotune
{
    self = [super init];
    _MidiTone = midiTone;
    Tuning = disableAutotune ? [[CvTTuning alloc] init:midiTone] : [[CvTAutoTuning alloc] init:midiTone];
    
    Gain = [CvTSynth Synth]->Gain;
    Operator = [CvTSynth Synth]->Operator;
    
    Carrier = [[CvTOscillator alloc] init];
    Modulator = [[CvTOscillator alloc] init:[CvTSynth Synth]->Modulator];
    Envelope = [[CvTADSREnvelope alloc] initWithADSR:([CvTSynth Synth]->A + 0.01) D:([CvTSynth Synth]->D + 0.01) S:[CvTSynth Synth]->S R:[CvTSynth Synth]->R];

    return self;
}

-(void)Slide:(float)midiTone
{
    _MidiTone = midiTone;
    [Tuning Slide:midiTone];
}

-(void)Release {
    [Envelope Release];
}

-(BOOL)Finished {
    return [Envelope Finished];
}

-(BOOL)Released {
    return [Envelope Released];
}

-(void)Render:(float*)Buffer envelopeBuffer:(float*)envelopeBuffer length:(int)length
{
    if (_Duration > 0)
    {
        _Duration -= (float)length / SAMPLERATE;
        if (_Duration <= 0)
            [self Release];
    }
    
    float oscillatorBuffer[length];
    float modulatorBuffer[length];
    float frequencyBuffer[length];
    [Tuning FrequencyBuffer:frequencyBuffer length:length];
    
    [Carrier Render:frequencyBuffer buffer:oscillatorBuffer length:length];
    [Modulator Render:frequencyBuffer buffer:modulatorBuffer length:length];
    [Envelope Render:envelopeBuffer length:length];
    
    for (int i = 0; i < length; i++)
    {
        float f = Operator * modulatorBuffer[i] + oscillatorBuffer[i];
        f = fminf(1, fmaxf(-1, f));
        Buffer[i] = f * Gain * envelopeBuffer[i];
    }
}

@end

@implementation CvTMuteTone

-(id)init:(float)midiTone
{
    self.MidiTone = midiTone;
    return self;
}

-(void)Render:(float*)Buffer envelopeBuffer:(float*)envelopeBuffer length:(int)length
{
    for (int i = 0; i < length; i++)
        Buffer[i] = envelopeBuffer[i] = 0;
    
    if (_Duration > 0)
    {
        _Duration -= (float)length / SAMPLERATE;
        if (_Duration <= 0)
            [self Release];
    }
}

-(BOOL)Finished {
    return (_MidiTone == 0);
}

-(BOOL)Released {
    return [self Finished];
}

-(void)Slide:(float)midiTone {
    self.MidiTone = midiTone;
}

-(void)Release {
    self.MidiTone = 0;
}

@end

@implementation CvTSynthMidiTone

-(id)init:(float)midiTone channel:(int)channel
{
    _MidiChannel = channel;
    self = [super init:roundf([[CvTSynth Synth] SnapTone:midiTone])];
    [self ToneOn];
    return self;
}

-(void)ToneOn
{
    Byte message[] = {  0x90 + (_MidiChannel & 0x0f), (Byte)self.MidiTone & 0x7f, 127 };
    
    MIDIPacketList packetList;
    MIDIPacket *packet = MIDIPacketListInit(&packetList);
    MIDIPacketListAdd(&packetList, sizeof(MIDIPacketList), packet, 0, sizeof(message), message);
    MIDIReceived([CvTSynth Synth].VirtualSendEndpoint, &packetList);
}

-(void)Slide:(float)midiTone
{
    int newMidiTone = roundf([[CvTSynth Synth] SnapTone:midiTone]);
    if (self.MidiTone != newMidiTone)
    {
        [self ToneOff];
        
        self.MidiTone = newMidiTone;
        [self ToneOn];
    }
}

-(void)ToneOff
{
    Byte message[] = { 0x80 + (_MidiChannel & 0x0f), (Byte)self.MidiTone & 0x7f, 127 };
    MIDIPacketList packetList;
    MIDIPacket *packet = MIDIPacketListInit(&packetList);
    MIDIPacketListAdd(&packetList, sizeof(MIDIPacketList), packet, 0, sizeof(message), message);
    MIDIReceived([CvTSynth Synth].VirtualSendEndpoint, &packetList);
}

-(void)Release
{
    [self ToneOff];
    self.MidiTone = 0;
}

@end