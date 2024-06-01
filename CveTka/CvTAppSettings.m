//
//  CvTAppSettings.m
//  CveTka
//
//  Created by tomaz stupnik on 8/15/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTAppSettings.h"

@implementation CvTAppSettings

+(CvTAppSettings*)Current
{
    static CvTAppSettings* CurrentSettings = NULL;
    @synchronized(self)
    {
        if(CurrentSettings == NULL)
            CurrentSettings = [[CvTAppSettings alloc] init];
    }
    return CurrentSettings;
}

-(id)init
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *defaultsDict = [@{@"autotune":@"1", @"autotunetime":@"0", @"tone":@"10", @"octave":@"57", @"scale":@"101011010101", @"tonalcentre":@"0", @"span":@"24", @"modulator":@"2", @"operator":@"0.5", @"gain":@"0.35", @"env_A":@"0.01", @"env_D":@"0.01", @"env_S":@"0.7", @"env_R":@"0.5", @"sound":@"1", @"tempo":@"120", @"personality":@"2", @"airplay":@"0", @"airplaysymbol":@"0", @"timesignature":@"2", @"concertpitch":@"442", @"intonation":@"1" } mutableCopy];
    [standardDefaults registerDefaults:defaultsDict];
    [standardDefaults synchronize];
    
    Defaults = [NSUserDefaults standardUserDefaults];
    return self;
}

-(void)SetString:(NSString*)value key:(NSString*)key
{
    [Defaults setObject:value forKey:key];
    [Defaults synchronize];
}

-(void)SetNumber:(float)value key:(NSString*)key {
    [self SetString:[NSString stringWithFormat:@"%g", value] key:key];
    [Defaults synchronize];
}

-(NSString*)GetString:(NSString*)key {
    return [Defaults objectForKey:key];
}

-(int)GetNumber:(NSString*)key {
    return [[Defaults objectForKey:key] intValue];
}

-(BOOL)GetAdvanced { return [[Defaults objectForKey:@"Advanced"] boolValue]; }

-(AutoTuneType)GetAutoTune { return [self GetNumber:@"autotune"]; }
-(void)SetAutoTune:(AutoTuneType)autoTune { [self SetNumber:autoTune key:@"autotune"]; }
-(AutoTuneSpeed)GetAutoTuneTime { return [self GetNumber:@"autotunetime"]; }
-(void)SetAutoTuneTime:(AutoTuneSpeed)autoTune { [self SetNumber:autoTune key:@"autotunetime"]; }

-(AirplayMode)GetAirplay { return [self GetNumber:@"airplay"]; }
-(void)SetAirplay:(AirplayMode)airplay { [self SetNumber:airplay key:@"airplay"]; }
-(AirplaySymbol)GetAirplaySymbol { return [self GetNumber:@"airplaysymbol"]; }
-(void)SetAirplaySymbol:(AirplaySymbol)airplaySymbol { [self SetNumber:airplaySymbol key:@"airplaysymbol"]; }

-(int)GetTempo { return [self GetNumber:@"tempo"]; }
-(void)SetTempo:(int)span { [self SetNumber:span key:@"tempo"]; }
-(MetronomeTimeSignature)GetTimeSignature { return [self GetNumber:@"timesignature"]; }
-(void)SetTimeSignature:(MetronomeTimeSignature)timeSignature { [self SetNumber:timeSignature key:@"timesignature"]; }

-(NSString*)GetScale { return [self GetString:@"scale"]; }
-(void)SetScale:(NSString *)scale { [self SetString:scale key:@"scale"]; }

-(int)GetTonalSpan { return [self GetNumber:@"span"]; }
-(void)SetTonalSpan:(int)span { [self SetNumber:span key:@"span"]; }
-(int)GetTonalCentre { return [self GetNumber:@"tonalcentre"]; }
-(void)SetTonalCentre:(int)centre { [self SetNumber:centre key:@"tonalcentre"]; }
-(int)GetRootTone { return [self GetNumber:@"tone"]; }
-(void)SetRootTone:(int)root { [self SetNumber:root key:@"tone"]; }
-(SynthRootOctave)GetRootOctave { return [self GetNumber:@"octave"]; }
-(void)SetRootOctave:(SynthRootOctave)root { [self SetNumber:root key:@"octave"]; }

-(SynthSoundPreset)GetSound { return [self GetNumber:@"sound"]; }
-(void)SetSound:(SynthSoundPreset)sound { [self SetNumber:sound key:@"sound"]; }

-(AppPersonality)GetPersonality { return [self GetNumber:@"personality"]; }
-(void)SetPersonality:(AppPersonality)personality { [self SetNumber:personality key:@"personality"]; }

-(float)GetConcertPitch { return [self GetNumber:@"concertpitch"]; }
-(void)SetConcertPitch:(float)pitch { [self SetNumber:pitch key:@"concertpitch"]; }

-(SynthIntonation)GetIntonation { return [self GetNumber:@"intonation"]; }
-(void)SetIntonation:(SynthIntonation)intonation { [self SetNumber:intonation key:@"intonation"]; }
@end
