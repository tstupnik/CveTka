//
//  CvTNetworkMidi.m
//  CveTka
//
//  Created by tomaz stupnik on 8/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTNetworkMidi.h"

@implementation CvTNetworkMidi


@end

//connect
/*MIDINetworkHost *host = [MIDINetworkHost hostWithName:@"CveTka" address:@"192.168.2.108" port:5004];
 MIDINetworkConnection *connection = [MIDINetworkConnection connectionWithHost:host];
 MIDINetworkSession *session = [MIDINetworkSession defaultSession];
 [session addConnection:connection];
 session.enabled = TRUE;
 _NetworkSendEndpoint = [session destinationEndpoint];
 MIDIOutputPortCreate(client, CFSTR("CveTka out"), &_NetworkOutPort);*/


/*MIDIDestinationCreate(client, CFSTR("CveTka"), MidiInputCallback, NULL, &_NetworkReceiveEndpoint);
 MIDIInputPortCreate(client, CFSTR("Input"), MidiInputCallback, (__bridge void *)(self), &_NetworkInPort);
 
 ItemCount numOfDevices = MIDIGetNumberOfDevices();
 for (int i = 0; i < numOfDevices; i++)
 {
 MIDIDeviceRef midiDevice = MIDIGetDevice(i);
 CFPropertyListRef midiProperties;
 MIDIObjectGetProperties(midiDevice, &midiProperties, YES);
 MIDIEndpointRef src = MIDIGetSource(i);
 MIDIPortConnectSource(_NetworkInPort, src, NULL);
 }*/


/*
 void MidiInputCallback (const MIDIPacketList *list, void *procRef, void *srcRef)
 {
 dispatch_queue_t queue = dispatch_queue_create("queue", NULL);
 dispatch_async(queue, ^{
 dispatch_async(dispatch_get_main_queue(), ^{
 CvTSpiralView *spiral = (__bridge CvTSpiralView*)procRef;
 [spiral ReceiveMidiPacket:list];
 });
 });
 }*/


/*
 -(void)ReceiveMidiPacket:(const MIDIPacketList *)packetList
 {
 int airplay = [CvTAppSettings Current].Airplay;
 if (airplay >= 0)
 {
 int length = 0;
 Byte midiData[10240];
 const MIDIPacket *packet = packetList->packet;
 for (int i = 0; i < packetList->numPackets; i++)
 {
 memcpy(&midiData[length], packet->data, packet->length);
 length += packet->length;
 packet = MIDIPacketNext(packet);
 }
 
 for (Byte *data = midiData; length > 0;)
 {
 CvTMidiPacketList *midi = [[CvTMidiPacketList alloc] init:data length:length];
 data += midi.Size;
 length -= midi.Size;
 
 if (midi->Channel != airplay)
 {
 if (midi->Message != 0xe)
 {
 NSString *tones = @"";
 for (NSNumber *t in midi->ChordTones)
 tones = [NSString stringWithFormat:@"%@ %@", tones, [t stringValue]];
 NSLog(@"MIDI IN %x %lx, tones: %@", midi->Message, midi->Ident, tones);
 }
 
 if (midi.Size > 3)//midi->ChordTones.count > 0)
 switch (midi->Message)
 {
 case 9: {
 CvTSynthChord *chord = [[CvTSynthChord alloc] initMute:midi->ChordTones ident:midi->Ident synth:_Synth];
 CvTAnimation *animation = [[CvTAnimation alloc] init:[self ToneToPoint:[midi->ChordTones[0] floatValue]]];// chord:chord spiral:self];
 
 if ([_Synth Play:chord])
 {
 [self addSubview:animation];
 chord.Animation = animation;
 animation->SpotTime = SpotTime;
 ChordName.text = [_Synth CurrentChord];
 }
 break;
 }
 case 8:
 [_Synth Release:midi->Ident];
 break;
 case 0xa:
 [_Synth SlideChord:midi->ChordTones ident:midi->Ident];
 CGPoint p = [self ToneToPoint:[midi->ChordTones[0] floatValue]];
 [[_Synth Animation:midi->Ident] Slide:p];
 break;
 }
 }
 }
 }
 }
 

*/

/*
 -(void)MIDISend:(CvTMidiPacketList*)midi
 {
 NSString *tones = @"";
 for (NSNumber *t in midi->ChordTones)
 tones = [NSString stringWithFormat:@"%@ %@", tones, [t stringValue]];
 //NSLog(@"MIDI OUT %x %lx, tones: %@", midi->Message, midi->Ident, tones);
 
 //MIDISend(Synth.NetworkOutPort, Synth.NetworkSendEndpoint, midi.Data);
 }*/

//    int airplay = [CvTAppSettings Current].Airplay;
//    if (airplay >= 0)
//        [self MIDISend:[[CvTMidiPacketList alloc] initNoteOn:airplay ident:_Ident tones:[self MidiTones]]];



///    int airplay = [CvTAppSettings Current].Airplay;
//    if ((airplay >= 0) && (ChordMode != kChordMode_Mute))
//        [self MIDISend:[[CvTMidiPacketList alloc] initNoteSlide:airplay ident:_Ident tones:[self MidiTones]]];



//   int airplay = [CvTAppSettings Current].Airplay;
//    if ((airplay >= 0) && (ChordMode != kChordMode_Mute))
//        [self MIDISend:[[CvTMidiPacketList alloc] initNoteOff:airplay ident:_Ident tones:[self MidiTones]]];



