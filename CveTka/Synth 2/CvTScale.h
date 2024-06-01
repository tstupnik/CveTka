//
//  CvtScale.h
//  CveTest
//
//  Created by tomaz stupnik on 4/27/14.
//  Copyright (c) 2014 tomaz stupnik. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CvTScaleTone : NSObject

@property (nonatomic, assign) int Tone;
@property (nonatomic, assign) float Angle;
@property (readonly) float Radius;

@end

@interface CvTScale : NSObject
{
    CvTScaleTone *Tones[12];
}

@property (readonly) int MidiRootTone;
@property (readonly) int TonalCentre;
@property (nonatomic, getter = getMidiNumberOfSharps) int MidiNumberOfSharps;

- (id)initWithScale:(int)root tonalCentre:(int)tonalCentre scale:(NSString*)scale;
-(NSString*)string;

-(float)Interval:(float)midiTone;
-(int)Root:(float)midiTone;
    
-(void)ToggleTone:(int)tone;
-(void)ToggleMidiTone:(float)midiTone;
-(BOOL)ContainsMidiTone:(float)midiTone;

-(float)SnapMidiTone:(float)midiTone;
-(int)MidiChordTone:(int)midiTone chordInterval:(int)chordInterval;
-(int)MidiIntervalTone:(int)midiTone interval:(int)interval;

-(NSString*)MidiSolName:(float)midiTone;
-(int)MidiSolNumber:(float)midiTone;
+(NSString*)MidiToneName:(float)midiTone;
+(int)RootFromNumberOfSharps:(int)sharps;
@end