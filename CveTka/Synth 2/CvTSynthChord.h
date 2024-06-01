//
//  CvTSynthChord.h
//  CveTka
//
//  Created by tomaz stupnik on 8/12/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CvTSynthTone.h"
#import "../CvTAppSettings.h"

@class CvTAnimation;
@protocol CvTAnimationDelegate;

@interface CvTChordMaker : NSObject

+(NSString*)Name:(NSArray*)Chords;
+(NSArray*)DiatonicChordTones:(float)midiTone scale:(CvTScale*)scale chordMode:(AutoChordMode)chordMode;
+(NSArray*)ChordTones:(float)midiTone chordMode:(AutoChordMode)chordMode;

@end


@interface CvTSynthChord : NSObject<NSCoding>
{
    NSArray *Tones;
    
    float MidiFingerPosition;
    AutoChordMode ChordMode;
}
@property (readonly) long Ident;
@property (readonly) NSString *Source;
@property (readonly) NSDate *TimeStamp;
@property (assign) AirplaySymbol Symbol;
@property (nonatomic, readwrite) id<CvTAnimationDelegate> Animation;

-(id)initWithCoder:(NSCoder*)decoder;
-(id)init:(float)midiTone chordMode:(AutoChordMode)chordMode duration:(float)duration source:(NSString*)source;
-(void)Play;

-(void)encodeWithCoder:(NSCoder *)aCoder;

-(void)SlideChord:(NSArray*)chordTones;
-(void)Slide:(float)midiTone;
-(void)Release;
-(void)Render:(float*)buffer envelopeBuffer:(float*)envelopeBuffer length:(int)length;
-(BOOL)Finished;
-(BOOL)Released;
-(float)Duration;

-(float)FingeredMidiTone;
-(NSArray*)ChordMidiTones;
-(NSArray*)ChordIntMidiTones;
-(NSArray*)ChordSnappedMidiTones;

@end