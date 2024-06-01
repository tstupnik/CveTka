//
//  CvTSynthTone.h
//  CveTka
//
//  Created by tomaz stupnik on 8/2/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#define SAMPLERATE  44100
//#define SAMPLETIME  (1.0f)
//#define SAMPLESIZE  (SAMPLERATE * SAMPLETIME)

#import <Foundation/Foundation.h>
#import "CvTTuning.h"
#import "CvTScale.h"
#import "../Spiral/CvTAnimation.h"

@interface CvTOscillator : NSObject
{
    float Phase;
    float FrequencyRatio;
}

-(id)init:(float)frequencyRatio;
-(void)Render:(float*)frequencyBuffer buffer:(float*)Buffer length:(int)length;

@end


@protocol CvTEnvelope<NSObject>
-(void)Release;
-(void)Render:(float*)Buffer length:(int)length;
-(BOOL)Finished;
-(BOOL)Released;
@end


@interface CvTADSREnvelope : NSObject<CvTEnvelope>
{
    float Time, TimeReleased;
    float AttackTime;
    float DecayTime;
    float Sustain;
    float ReleaseTime;
}

-(id)initWithADSR:(float)A D:(float)D S:(float)S R:(float)R;
-(void)Release;
-(void)Render:(float*)Buffer length:(int)length;
-(BOOL)Finished;
-(BOOL)Released;

@end


@protocol CvTSynthTone<NSObject>
-(void)Slide:(float)midiTone;
-(void)Release;
-(void)Render:(float*)Buffer envelopeBuffer:(float*)envelopeBuffer length:(int)length;
-(BOOL)Finished;
-(BOOL)Released;
@property (readonly) float MidiTone;
@property float Duration;
@end


@interface CvTSynthFMTone : NSObject<CvTSynthTone>
{
    id<CvTEnvelope> Envelope;
    CvTOscillator *Carrier;
    CvTOscillator *Modulator;
    CvTTuning *Tuning;
    
    float Gain;
    float Operator;
}
@property (readonly) float MidiTone;
@property float Duration;

-(id)init:(float)midiTone disableAutotune:(BOOL)disableAutotune;
-(void)Slide:(float)midiTone;
-(void)Release;
-(void)Render:(float*)Buffer envelopeBuffer:(float*)envelopeBuffer length:(int)length;
-(BOOL)Finished;
-(BOOL)Released;

@end


@interface CvTMuteTone : NSObject<CvTSynthTone>

@property (readwrite) float MidiTone;
@property float Duration;

-(id)init:(float)midiTone;
-(void)Slide:(float)midiTone;
-(void)Release;
-(void)Render:(float*)Buffer envelopeBuffer:(float*)envelopeBuffer length:(int)length;
-(BOOL)Finished;
-(BOOL)Released;

@end


@interface CvTSynthMidiTone : CvTMuteTone

@property (assign, nonatomic, readonly) int MidiChannel;

-(id)init:(float)midiTone channel:(int)channel;
-(void)Slide:(float)midiTone;
-(void)Release;

@end


