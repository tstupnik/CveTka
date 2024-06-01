//
//  CvTMidiPacketList.h
//  CveTka
//
//  Created by tomaz stupnik on 8/21/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@interface CvTMidiPacketList : NSObject
{
    int ExtensionLength;
    MIDIPacketList PacketList;
@public
    int MidiTone;
    NSArray *ChordTones;
    
    int Channel;
    int Message;
    long Ident;
}

@property (nonatomic, getter = getData, readonly) MIDIPacketList *Data;
@property (getter = getSize, readonly) int Size;

-(id)initNoteOn:(int)channel ident:(long)ident tones:(NSArray*)tones;
-(id)initNoteSlide:(int)channel ident:(long)ident tones:(NSArray*)tones;
-(id)initNoteOff:(int)channel ident:(long)ident tones:(NSArray*)tones;
-(id)init:(const Byte*)data length:(int)length;

@end
