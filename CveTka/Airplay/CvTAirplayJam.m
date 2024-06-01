//
//  CvTAirplayJam.m
//  CveTka
//
//  Created by tomaz stupnik on 8/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTAirplayJam.h"
#import "../Spiral/CvTSpiralView.h"

@implementation CvTAirplayJam

+(CvTAirplayJam*)AirplayJam
{
    static CvTAirplayJam *airplay = nil;
    @synchronized(self)
    {
        if (airplay == nil)
            airplay = [[self alloc] init];
    }
    return airplay;
}

-(id)init
{
    Server = NULL;
    Client = NULL;
    self.Mode = [CvTAppSettings Current].Airplay;
    return self;
}

-(AirplayMode)GetMode
{
    if (Server != NULL)
        return kAirplay_Server;
    if (Client != NULL)
        return kAirplay_Client;
    return kAirplay_Off;
}

-(void)SetMode:(AirplayMode)mode
{
    if (self.Mode != mode)
    {
        if (Server != NULL)
        {
            [Server stop];
            Server = NULL;
        }
        if (Client != NULL)
        {
            [Client stop];
            Client = NULL;
        }
        if (mode == kAirplay_Server)
        {
            Server = [[CvTWiFiServer alloc] initWithDelegate:self];
            [Server start];
        }
        if (mode == kAirplay_Client)
        {
            Client = [[CvTWiFiClient alloc] initWithDelegate:self];
            [Client start];
        }
    }
}

-(void)Receive:(id)object ident:(NSString*)ident {
    if ([object isKindOfClass:[CvTAirplayMessage class]])
    {
        [[CvTRecorder Recorder] Feed:(CvTAirplayMessage*)object];
        [_Delegate Receive:(CvTAirplayMessage*)object];
    }
}

-(void)ServersUpdate{
}

-(void)NewConnection:(CvTWiFiConnection *)connection {
    [connection Send:[[CvTAirplayMessage alloc] init]];
}

-(void)ChordOn:(CvTSynthChord*)chord  {
    [self Send:[[CvTAirplayMessage alloc] initWithChord:chord type:kAirplayMessage_ChordOn]];
}

-(void)ChordSlide:(CvTSynthChord*)chord {
    [self Send:[[CvTAirplayMessage alloc] initWithChord:chord type:kAirplayMessage_ChordSlide]];
}

-(void)ChordOff:(CvTSynthChord*)chord {
    [self Send:[[CvTAirplayMessage alloc] initWithChord:chord type:kAirplayMessage_ChordOff]];
}

-(void)ChordNone {
    if (Server)
        [self Send:[[CvTAirplayMessage alloc] initWithType:kAirplayMessage_ChordNone]];
}

-(void)Setup {
    if (Server)
        [self Send:[[CvTAirplayMessage alloc] initWithType:kAirplayMessage_Setup]];
}

-(void)Send:(CvTAirplayMessage*)message
{
    [[CvTRecorder Recorder] Feed:message];
    if (Server)
        [Server Send:message];
    if (Client)
        [Client Send:message];
}

@end


@implementation CvTAirplayMessage

-(id)initWithType:(AirplayMessageType)type
{
    _Ident = [[UIDevice currentDevice] name];
    _Type = type;
    _Timestamp = [NSDate date];
    return self;
}

-(id)initWithChord:(CvTSynthChord *)chord type:(AirplayMessageType)type
{
    _Ident = [[UIDevice currentDevice] name];
    _Type = type;
    _Chord = chord;
    _Timestamp = [NSDate date];
    return self;
}

-(NSString*)Source {
    if (([_Ident isEqualToString:[[UIDevice currentDevice] name]]) && (_Chord))
        return _Chord.Source;
    else
        return _Chord ? [NSString stringWithFormat:@"%@.%@", _Ident, _Chord.Source] : _Ident;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    _Ident = [aDecoder decodeObjectForKey:@"name"];
    _Timestamp = [aDecoder decodeObjectForKey:@"time"];
    _Type = [aDecoder decodeIntegerForKey:@"type"];
    switch (_Type)
    {
        case kAirplayMessage_ChordOn:
        case kAirplayMessage_ChordSlide:
        case kAirplayMessage_ChordOff:
            _Chord = [[CvTSynthChord alloc] initWithCoder:aDecoder];
            break;
            
        case kAirplayMessage_Setup:
            [CvTAppSettings Current].TonalCentre = (int)[aDecoder decodeIntegerForKey:@"centre"];
            [CvTAppSettings Current].RootTone = (int)[aDecoder decodeIntegerForKey:@"root"];
            [CvTAppSettings Current].Scale = [aDecoder decodeObjectForKey:@"scale"];
            break;
            
        case kAirplayMessage_ChordNone:
            break;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_Ident forKey:@"name"];
    [aCoder encodeObject:_Timestamp forKey:@"time"];
    [aCoder encodeInteger:_Type forKey:@"type"];
    switch (_Type)
    {
        case kAirplayMessage_ChordOn:
        case kAirplayMessage_ChordSlide:
        case kAirplayMessage_ChordOff:
            [_Chord encodeWithCoder:aCoder];
            break;
            
        case kAirplayMessage_Setup:
            [aCoder encodeInteger:[CvTAppSettings Current].TonalCentre forKey:@"centre"];
            [aCoder encodeInteger:[CvTAppSettings Current].RootTone forKey:@"root"];
            [aCoder encodeObject:[CvTAppSettings Current].Scale forKey:@"scale"];
            break;
            
        case kAirplayMessage_ChordNone:
            break;
    }
}

@end