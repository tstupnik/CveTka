//
//  CvTAppSettings.h
//  CveTka
//
//  Created by tomaz stupnik on 8/15/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum AutoTuneType : NSUInteger {
    kAutoTune_Chromatic = 0,
    kAutoTune_Scale = 1
} AutoTuneType;

typedef enum AutoTuneSpeed : NSUInteger {
    kAutoTuneSpeed_Snap = 0,
    kAutoTuneSpeed_Fast = 1,
    kAutoTuneSpeed_Slow = 2,
    kAutoTuneSpeed_None = 3
} AutoTuneSpeed;

typedef enum AutoChordMode : NSUInteger {
    kChordMode_Mute = 0,
    kChordMode_Root = 1,
    
    kChordMode_Diatonic = 2,
    kChordMode_Major = 3,
    kChordMode_Minor = 4,
    kChordMode_Diminished = 5,
    kChordMode_Augmented = 6,
    
    kChordMode_Diatonic7 = 100,
    kChordMode_Major7 = 101,
    kChordMode_Minor7 = 102,
    kChordMode_Dominant7 = 103,
    kChordMode_Diminished7 = 104,
    kChordMode_Augmented7 = 105
} AutoChordMode;

typedef enum AirplayMode : NSUInteger {
    kAirplay_Off = 0,
    kAirplay_Client = 1,
    kAirplay_Server = 2
} AirplayMode;

typedef enum AirplaySymbol : NSUInteger {
    kAirplaySymbol_Circle = 0,
    kAirplaySymbol_Square = 1,
    kAirplaySymbol_Triangle = 2
} AirplaySymbol;

typedef enum MetronomeTimeSignature : NSUInteger {
    kMetronomeTimeSignature_2_4 = 0,
    kMetronomeTimeSignature_3_4 = 1,
    kMetronomeTimeSignature_4_4 = 2,
    kMetronomeTimeSignature_5_4 = 3
} MetronomeTimeSignature;

typedef enum SynthSoundPreset : NSUInteger {
    kSynthSound_Midi = 0,
    kSynthSound_Pluck = 1,
    kSynthSound_Ping = 2,
    kSynthSound_Pong = 3
} SynthSoundPreset;

typedef enum SynthRootOctave : NSUInteger {
    kSynthRootOctave_Bass = 45,
    kSynthRootOctave_Alt = 57,
    kSynthRootOctave_Soprano = 69
} SynthRootOctave;

typedef enum AppPersonality : NSUInteger {
    kAppPersonality_Bach = 0,
    kAppPersonality_Sibelius = 1,
    kAppPersonality_Dvorak = 2,
    kAppPersonality_Mercury = 3
} AppPersonality;

typedef enum SynthIntonation : NSUInteger {
    kSynthEqualTemperament = 0,
    kSynthJustTemperament = 1,
    kSyntPythagoreanTemperament = 2
} SynthIntonation;

@interface CvTAppSettings : NSObject
{
    NSUserDefaults *Defaults;
}

+(CvTAppSettings*)Current;

@property(readonly, getter = GetAdvanced) BOOL Advanced;

@property(setter = SetAutoTune:, getter = GetAutoTune) AutoTuneType AutoTune;
@property(setter = SetAutoTuneTime:, getter = GetAutoTuneTime) AutoTuneSpeed AutoTuneTime;

@property(setter = SetScale:, getter = GetScale) NSString* Scale;
@property(setter = SetTonalSpan:, getter = GetTonalSpan) int TonalSpan;
@property(setter = SetRootTone:, getter = GetRootTone) int RootTone;
@property(setter = SetRootOctave:, getter = GetRootOctave) SynthRootOctave RootOctave;
@property(setter = SetTonalCentre:, getter = GetTonalCentre) int TonalCentre;

@property(setter = SetAirplay:, getter = GetAirplay) AirplayMode Airplay;
@property(setter = SetAirplaySymbol:, getter = GetAirplaySymbol) AirplaySymbol AirplaySymbol;

@property(setter = SetTempo:, getter = GetTempo) int Tempo;
@property(setter = SetTimeSignature:, getter = GetTimeSignature) MetronomeTimeSignature TimeSignature;

@property(setter = SetSound:, getter = GetSound) SynthSoundPreset Sound;

@property(setter = SetPersonality:, getter = GetPersonality) AppPersonality Personality;
@property(setter = SetConcertPitch:, getter = GetConcertPitch) float ConcertPitch;
@property(setter = SetIntonation:, getter = GetIntonation) SynthIntonation Intonation;

@end
