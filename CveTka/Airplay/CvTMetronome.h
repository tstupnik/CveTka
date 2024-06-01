//
//  CvTMetronome.h
//  CveTka
//
//  Created by tomaz stupnik on 8/24/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioPlayer.h>

@interface CvTMetronome : NSObject
{
    AVAudioPlayer *StafPlayer, *NotePlayer;
    NSThread *Thread;
}

@property (nonatomic, strong) NSDate *StartTime;
@property (assign) int Nominator;
@property (assign) int Denominator;
@property (assign) int Tempo;

-(float)Duration:(NSDate*)time;
-(float)Duration:(NSDate *)time startTime:(NSDate*)startTime;
-(float)Duration;

-(void)CountIn:(int)measures;
-(BOOL)CountToEvent:(MusicTimeStamp)eventTime;

-(void)TrimBeginning:(NSDate *)time;

@end
