//
//  CvTAirplayJam.h
//  CveTka
//
//  Created by tomaz stupnik on 8/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CvTWiFi.h"
#import "../Synth/CvTSynthChord.h"
#import "CvTRecorder.h"

typedef enum AirplayMessageType : NSUInteger {
    kAirplayMessage_Setup = 0,
    kAirplayMessage_ChordOn = 1,
    kAirplayMessage_ChordSlide = 2,
    kAirplayMessage_ChordOff = 3,
    kAirplayMessage_ChordNone = 4
} AirplayMessageType;



@interface CvTAirplayMessage : NSObject<NSCoding>

@property(nonatomic, readonly) enum AirplayMessageType Type;
@property(nonatomic, readonly) CvTSynthChord* Chord;
@property(nonatomic, readonly) NSDate* Timestamp;
@property(nonatomic, readonly) NSString* Ident;

-(id)initWithType:(AirplayMessageType)type;
-(id)initWithChord:(CvTSynthChord*)chord type:(AirplayMessageType)type;

-(NSString*)Source;

@end


@protocol CvTAirplayJamDelegate <NSObject>

-(void)Receive:(CvTAirplayMessage*)message;

@end


@interface CvTAirplayJam : NSObject<CvTWiFiClientDelegate, CvTWiFiServerDelegate>
{
    CvTWiFiServer *Server;
    CvTWiFiClient *Client;
}

@property (nonatomic, retain) id<CvTAirplayJamDelegate> Delegate;
@property(nonatomic, getter = GetMode, setter = SetMode:) AirplayMode Mode;

+(CvTAirplayJam*)AirplayJam;
-(id)init;
-(void)ChordOn:(CvTSynthChord*)chord;
-(void)ChordSlide:(CvTSynthChord*)chord;
-(void)ChordOff:(CvTSynthChord*)chord;
-(void)Setup;
-(void)ChordNone;

@end