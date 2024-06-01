//
//  CvTTemperament.h
//  CveTka
//
//  Created by tomaz stupnik on 5/28/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../CvTAppSettings.h"

@interface CvTTuning : NSObject
{
    float Frequency;
}

-(id)init:(float)midiTone;
-(void)Slide:(float)midiTone;
- (void)FrequencyBuffer:(float*)frequencyBuffer length:(int)length;

@end


@interface CvTAutoTuning : CvTTuning
{
    float MidiCurrentTone;
    float MidiAutoTuneTone;
    float MidiHigherTone;
    float MidiLowerTone;
    
    int DriftSteps;
    float FrequencyDrift;
    
    AutoTuneType AutoTune;
    AutoTuneSpeed AutoTuneTime;
}

-(id)init:(float)midiTone;
-(void)Slide:(float)midiTone;
- (void)FrequencyBuffer:(float*)frequencyBuffer length:(int)length;

@end
