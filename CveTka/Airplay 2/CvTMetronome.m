//
//  CvTMetronome.m
//  CveTka
//
//  Created by tomaz stupnik on 8/24/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTMetronome.h"
#import "../CvTAppSettings.h"

@implementation CvTMetronome

-(id)init
{
    self = [super init];
    StafPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Clave" ofType:@"wav"]] error:NULL];
    NotePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Clave@" ofType:@"wav"]] error:NULL];
    [self reset];
    return self;
}

-(void)reset
{
    _Tempo = [CvTAppSettings Current].Tempo;
    _Nominator = 2 + [CvTAppSettings Current].TimeSignature;
    _Denominator = 4;
}

-(void)TrimBeginning:(NSDate *)time {
    float trim = [time timeIntervalSinceDate:_StartTime];
    if (trim > 0)
    {
        trim -= fmodf(trim, _Nominator * self.Duration);
        _StartTime = [_StartTime dateByAddingTimeInterval:trim];
    }
}

-(float)Duration{
    return 60.0f / (float)_Tempo;
}

-(float)Duration:(NSDate*)time {
    return [self Duration:time startTime:_StartTime];
}

-(float)Duration:(NSDate *)time startTime:(NSDate*)startTime {
    return [time timeIntervalSinceDate:startTime] / self.Duration;
}

-(void)CountIn:(int)measures
{
    NSDate *nextTick = _StartTime = [NSDate date];
    for(int noteCount = 0; noteCount < _Nominator * measures; noteCount++)
    {
        [(((noteCount % _Nominator) == 0) ? StafPlayer : NotePlayer) play];
        
        NSDate *date = [NSDate date];
        while ([nextTick timeIntervalSinceDate:date] < 0)
            nextTick = [nextTick dateByAddingTimeInterval:self.Duration];
        [NSThread sleepForTimeInterval:[nextTick timeIntervalSinceDate:date]];
        
        if ([[NSThread currentThread] isCancelled])
            return;
    }
    [StafPlayer play];
    _StartTime = [_StartTime dateByAddingTimeInterval:self.Duration * _Nominator * measures];
}

-(NSDate*)NextTick:(NSDate*)currentDate {
    return [_StartTime dateByAddingTimeInterval:(floor([currentDate timeIntervalSinceDate:_StartTime] / self.Duration) + 1) * self.Duration];
}

-(BOOL)CountToEvent:(MusicTimeStamp)eventTime
{
    NSDate *date = [NSDate date];
    NSDate *eventDate = [_StartTime dateByAddingTimeInterval:self.Duration * eventTime];
    for (NSDate *tickDate = [self NextTick:date]; [eventDate timeIntervalSinceDate:tickDate] >= 0; tickDate = [self NextTick:date])
    {
        [NSThread sleepForTimeInterval:[tickDate timeIntervalSinceDate:date]];

        [((fmod([tickDate timeIntervalSinceDate:_StartTime] / self.Duration, _Nominator) == 0) ? StafPlayer : NotePlayer) play];
        
        if ([[NSThread currentThread] isCancelled])
            return FALSE;
        
        date = [NSDate date];
    }
    [NSThread sleepForTimeInterval:[eventDate timeIntervalSinceDate:date]];
    return TRUE;
}

@end
