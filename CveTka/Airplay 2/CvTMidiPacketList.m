//
//  CvTMidiPacketList.m
//  CveTka
//
//  Created by tomaz stupnik on 8/21/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTMidiPacketList.h"

@implementation CvTMidiPacketList

/*-----------------
MIDI extension using xA aftertouch message
 - follows every 9, 8, E message
 
 
 ------------------*/


-(int)WriteHeader:(Byte*)buffer message:(int)message size:(int)size
{
    buffer[0] = (message << 4) | (Channel & 0x0f);
    buffer[1] = MidiTone & 0x7f;
    buffer[2] = 0x7f;
    buffer[3] = (0xa << 4) | (Channel & 0x0f);
    buffer[4] = buffer[1];
    buffer[5] = ExtensionLength = (1 + 10 + size) & 0x7f;
    
    return [self Write10Long:buffer value:Ident offset:6];
}

-(int)Write1Int:(Byte*)buffer value:(int)value offset:(int)offset
{
    buffer[offset++] = 0xa0 | (Channel & 0xf);
    buffer[offset++] = MidiTone & 0x7f;
    buffer[offset++] = value & 0x7f;
    return offset;
}

-(int)Write2Float:(Byte*)buffer value:(float)value offset:(int)offset
{
    int A = floor(value);
    int B = (value - A) * 127;
    
    offset = [self Write1Int:buffer value:(A & 0x7f) offset:offset];
    return [self Write1Int:buffer value:(B & 0x7f) offset:offset];
}

-(int)Write10Long:(Byte*)buffer value:(long)value offset:(int)offset
{
    for (int i = 0; i < 10; i++)
    {
        offset = [self Write1Int:buffer value:(value & 0x7f) offset:offset];
        value >>= 7;
    }
    return offset;
}

-(id)initNoteOn:(int)channel ident:(long)ident tones:(NSArray*)tones
{
    Channel = channel;
    Ident = ident;
    MidiTone = (int)lround([tones[0] floatValue]);
    Message = 9;

    Byte messages[256];
    int offset = [self WriteHeader:messages message:9 size:((int)tones.count * 2)];
    
    for (int i = 0; i < tones.count; i++)
        offset = [self Write2Float:messages value:[tones[i] floatValue] offset:offset];
    
    Byte buffer[sizeof(messages)];
    MIDIPacket* packet = MIDIPacketListInit(&PacketList);
    packet->timeStamp = 0;
    MIDIPacketListAdd(&PacketList, sizeof(buffer), packet, 0, offset, messages);
    return self;
}

-(id)initNoteSlide:(int)channel ident:(long)ident tones:(NSArray*)tones
{
    self = [self initNoteOn:channel ident:ident tones:tones];
    PacketList.packet[0].data[0] = 0xe0 | (PacketList.packet[0].data[0] & 0x0f);
    PacketList.packet[0].data[2] = 0;
    Message = 0xe;
    return self;
}

-(id)initNoteOff:(int)channel ident:(long)ident tones:(NSArray*)tones
{
    Channel = channel;
    Ident = ident;
    MidiTone = (int)lround([tones[0] floatValue]);
    Message = 8;
    
    Byte messages[256];
    int offset = [self WriteHeader:messages message:8 size:0];
    
    Byte buffer[sizeof(messages)];
    MIDIPacket* packet = MIDIPacketListInit(&PacketList);
    MIDIPacketListAdd(&PacketList, sizeof(buffer), packet, 0, offset, messages);
    return self;
}

-(float)Read2Float:(const Byte*)data length:(int)length offset:(int)offset
{
    float value = 0;
    if (length >= (offset + 3))
        if ((data[offset] >> 4) == 0xa)
            value = data[offset + 2];
    if (length >= (offset + 6))
        if ((data[offset + 3] >> 4) == 0xa)
        {
            float f =data[offset + 5];
            value += f / 127;
        }
    return value;
}

-(int)Read1Int:(const Byte*)data length:(int)length offset:(int)offset
{
    int value = 0;
    if (length >= (offset + 3))
        if ((data[offset] >> 4) == 0xa)
            value = data[offset + 2];
    return value;
}

-(long)Read10Long:(const Byte*)data length:(int)length offset:(int)offset
{
    long value = 0;
    for (int i = 0; i < 10; i++, offset += 3)
        value |= [self Read1Int:data length:length offset:offset] << (i * 7);
    return value;
}

-(id)init:(const Byte*)data length:(int)length
{
    self = [super init];
    Message = data[0] >> 4;
    Channel = data[0] & 0x0f;
    MidiTone = data[1];
    ExtensionLength = 0;

    NSNumber *chordTones[32];
    chordTones[0] = [NSNumber numberWithInt:MidiTone];
    ChordTones = [[NSArray alloc] initWithObjects:chordTones count:1];

    if (length > 6)
    {
        Byte aMessage = (data[0] & 0x0f) | 0xa0;
        if ((data[3] == aMessage) && (data[4] == data[1]))
        {
            int size = data[5];
            if ((length >= size * 3 + 3) && (size > 0))
            {
                for (int i = 1; i < size; i++)
                    if ((data[4 + i * 3] != data[1]) || (data[3 + i * 3] != aMessage))
                        return self;
                
                Ident = [self Read10Long:data length:length offset:6];
                if (size > 11)
                {
                    MidiTone = [self Read2Float:data length:length offset:36];
                    
                    NSNumber *chordTones[32];
                    int chordToneCount = 0;
                    if ((Message == 8) || (Message == 9) || (Message == 0xe))
                        for (int i = 36; i < (size * 3 + 3); i += 6)
                            chordTones[chordToneCount++] = [NSNumber numberWithFloat:[self Read2Float:data length:length offset:(i)]];
                    ChordTones = [[NSArray alloc] initWithObjects:chordTones count:chordToneCount];
                }
                ExtensionLength = size;
            }
        }
    }
    return self;
}

-(MIDIPacketList*)getData{
    return &PacketList;
}

-(int)getSize{
    return 3 + ExtensionLength * 3;
}

@end
