//
//  CvTSynth.m
//  SynthTest
//
//  Created by tomaz stupnik on 7/7/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTSynth.h"

OSStatus AudioCallBack(void *synth, AudioUnitRenderActionFlags 	*ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *data)
{
    [((__bridge CvTSynth*)synth) RenderSound:((float*)data->mBuffers[0].mData) numFrames:inNumberFrames];
    for (int i = 1; i < data->mNumberBuffers; i++)
        memcpy(data->mBuffers[i].mData, data->mBuffers[0].mData, inNumberFrames * sizeof(float));
    return noErr;
}

static void *kAudiobusRunningOrConnectedChanged = &kAudiobusRunningOrConnectedChanged;

@interface CvTSynth ()
{
    AUGraph Graph;
    AudioUnit OutputUnit;
    AudioUnit SamplerUnit;
    AudioUnit MixerUnit;
    
    NSMutableDictionary *Chords;
    
    NSLock *ArrayLock;
}
@property (retain) ABSenderPort *AudiobusSender;
@property (assign) id ObserverToken;

@end

@implementation CvTSynth

+(CvTSynth*)Synth
{
    static CvTSynth *synth = nil;
    @synchronized(self)
    {
        if (synth == nil)
            synth = [[self alloc] init];
    }
    return synth;
}

-(id)init
{
    if ( !(self = [super init]) ) return nil;
 
    [self setup];

    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
    {
        _AudiobusController = [[ABAudiobusController alloc] initWithApiKey:@"MTQxMDk3MDEwOSoqKkN2ZVRrYSoqKkN2ZVRrYS0wLjEuYXVkaW9idXM6Ly8=:lM0kcpC1xVBJO20KxTw94k7wVbNzC/Qm29zCXw5Hg8Tdcj+ZL5z3Plh46gVUuw+8vlbZ6/DkpfLw8MTUmkzz8x6lHgndYvNhAvttS+DpHu5NeFJbljns3nETedDBY0Ld"];
        
        _AudiobusSender = [[ABSenderPort alloc] initWithName:@"CveTka" title:@"CveTka" audioComponentDescription:(AudioComponentDescription) {
            .componentType = kAudioUnitType_RemoteGenerator,
            .componentSubType = 'aout',
            .componentManufacturer = 'gdlk' } audioUnit:OutputUnit];
        [_AudiobusController addSenderPort:_AudiobusSender];
        
        [_AudiobusController addObserver:self forKeyPath:@"connected" options:0 context:kAudiobusRunningOrConnectedChanged];
        [_AudiobusController addObserver:self forKeyPath:@"audiobusAppRunning" options:0 context:kAudiobusRunningOrConnectedChanged];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }

    MIDIClientRef client;
    MIDIClientCreate(CFSTR("CveTka"), NULL, (__bridge void *)self, &client);
    MIDISourceCreate(client, CFSTR("CveTka"), &_VirtualSendEndpoint);
    
    if (ArrayLock == NULL)
        ArrayLock = [[NSLock alloc] init];

    return self;
}

-(void)dealloc
{
    [_AudiobusController removeObserver:self forKeyPath:@"connected"];
    [_AudiobusController removeObserver:self forKeyPath:@"audiobusAppRunning"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self teardown];
}

- (BOOL)start
{
    OSStatus err = AUGraphStart(Graph);
    return (err == noErr);
}

- (BOOL)running
{
    Boolean isRunning = false;
    AUGraphIsRunning(Graph, &isRunning);
    return (BOOL)isRunning;
}

- (void)stop
{
    if ([self running])
        AUGraphStop(Graph);
}

-(void)setup
{
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    
    NewAUGraph(&Graph);
    
    AUNode outputNode;
    AUNode samplerNode;
    AUNode mixerNode;
    
    AudioComponentDescription output_desc = {
        .componentType = kAudioUnitType_Output,
        .componentSubType = kAudioUnitSubType_RemoteIO,
        .componentFlags = 0,
        .componentFlagsMask = 0,
        .componentManufacturer = kAudioUnitManufacturer_Apple
    };
    AudioComponentDescription mixer_desc = { kAudioUnitType_Mixer, kAudioUnitSubType_MultiChannelMixer, kAudioUnitManufacturer_Apple, 0, 0 };
    AudioComponentDescription sampler_desc = { kAudioUnitType_MusicDevice, kAudioUnitSubType_Sampler, kAudioUnitManufacturer_Apple, 0, 0 };
    
    AUGraphOpen(Graph);
    AUGraphAddNode(Graph, &output_desc, &outputNode);
    AUGraphAddNode(Graph, &mixer_desc, &mixerNode);
    AUGraphAddNode(Graph, &sampler_desc, &samplerNode);
    
    AUGraphNodeInfo(Graph, samplerNode, NULL, &SamplerUnit);
    AUGraphNodeInfo(Graph, mixerNode, NULL, &MixerUnit);
    AUGraphNodeInfo(Graph, outputNode, NULL, &OutputUnit);
 
    UInt32 busCount = 1;
    AudioUnitSetProperty(MixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof(busCount));
    
    AudioStreamBasicDescription audioFormat = {
        .mFormatID          = kAudioFormatLinearPCM,
        .mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved,
        .mChannelsPerFrame  = 2,
        .mBytesPerPacket    = sizeof(float),
        .mFramesPerPacket   = 1,
        .mBytesPerFrame     = sizeof(float),
        .mBitsPerChannel    = 8 * sizeof(float),
        .mSampleRate        = SAMPLERATE
    };
	AudioUnitSetProperty(MixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &audioFormat, sizeof(audioFormat));
	AudioUnitSetProperty(MixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioFormat, sizeof(audioFormat));
    AUGraphConnectNodeInput(Graph, samplerNode, 0, mixerNode, 1);
    AUGraphConnectNodeInput(Graph, mixerNode, 0, outputNode, 0);
    AUGraphOpen(Graph);
    
    AURenderCallbackStruct renderCallbackStruct = {
        .inputProc = AudioCallBack,
        .inputProcRefCon = (__bridge void *)self,
    };
    AUGraphSetNodeInputCallback(Graph, mixerNode, 0, &renderCallbackStruct);
    
    AUGraphInitialize(Graph);
    CAShow(Graph);
    
    Chords = [[NSMutableDictionary alloc] init];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    Modulator = [[defaults objectForKey:@"modulator"] floatValue];
    Operator = [[defaults objectForKey:@"operator"] floatValue];
    Gain = [[defaults objectForKey:@"gain"] floatValue];
    A = [[defaults objectForKey:@"env_A"] floatValue];
    D = [[defaults objectForKey:@"env_D"] floatValue];
    S = [[defaults objectForKey:@"env_S"] floatValue];
    R = [[defaults objectForKey:@"env_R"] floatValue];
    
    [self LoadPreset:[CvTAppSettings Current].Sound];
}

- (void)teardown
{
    if (self.running)
        [self stop];
}


-(void)applicationDidEnterBackground:(NSNotification *)notification
{
    if (!_AudiobusController.connected && !_AudiobusController.audiobusAppRunning)
        [self stop];
}

-(void)applicationWillEnterForeground:(NSNotification *)notification
{
    if (!self.running)
        [self start];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kAudiobusRunningOrConnectedChanged)
    {
        if (self.running && [UIApplication sharedApplication].applicationState == UIApplicationStateBackground && !_AudiobusController.connected && !_AudiobusController.audiobusAppRunning)
            [self stop];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(float)SnapTone:(float)midiTone
{
    if ([CvTAppSettings Current].AutoTuneTime == kAutoTuneSpeed_None)
        return midiTone;
    if ([CvTAppSettings Current].AutoTune == kAutoTune_Scale)
            return [_Scale SnapMidiTone:midiTone];
    return lroundf(midiTone);
}

-(BOOL)Play:(CvTSynthChord*)chord
{
    [ArrayLock lock];
    
    BOOL bSuccess = FALSE;
    NSNumber *key = [NSNumber numberWithLong:chord.Ident];
    if ([Chords objectForKey:key] == NULL)
    {
        [Chords setObject:chord forKey:key];
        [chord Play];
        bSuccess = TRUE;
    }
    
    [ArrayLock unlock];
    
    return bSuccess;
}

-(id<CvTAnimationDelegate>)Animation:(long)ident {
    return ((CvTSynthChord*)Chords[[NSNumber numberWithLong:ident]]).Animation;
}

-(NSString*)CurrentChord
{
    [ArrayLock lock];
    
    NSString *chordName = [CvTChordMaker Name:[Chords allValues]];
    
    [ArrayLock unlock];
    
    return chordName;
}

-(void)Slide:(float)midiTone ident:(long)ident
{
    [ArrayLock lock];
    
    CvTSynthChord *chord = Chords[[NSNumber numberWithLong:ident]];
    if (chord != NULL)
    {
        float chordMidiTone = chord.FingeredMidiTone;
        float dTone = fabs(midiTone - chordMidiTone);
        if (dTone > 6)
        {
            midiTone = fmodf(midiTone, 12);
            for (int i = 0; i < 10; i++)
            {
                if (fabs(midiTone - chordMidiTone) <= 6)
                    break;
                midiTone += 12;
            }
        }
        
        //only if angle < 45 or > 135 degrees
        [chord Slide:midiTone];
    }
    
    [ArrayLock unlock];
}

-(void)Release:(long)ident
{
    [ArrayLock lock];
    
    NSNumber *key = [NSNumber numberWithLong:ident];
    CvTSynthChord *chord = Chords[key];
    if (chord != NULL)
    {
        [chord Release];
        if ([chord Finished])
            [Chords removeObjectForKey:key];
        
        if (Chords.count == 0)
            [[CvTAirplayJam AirplayJam] ChordNone];
        
        //chord history...
    }
    
    [ArrayLock unlock];
}

-(void)reset
{
    for (id key in [Chords allKeys])
        [Chords removeObjectForKey:key];
    [[CvTAirplayJam AirplayJam] ChordNone];
}

-(void)RenderSound:(float*)buffer numFrames:(int)numFrames
{
    float commonEnvelope[numFrames];
    for (int i = 0; i < numFrames; ++i)
    {
        buffer[i] = 0.0f;
        commonEnvelope[i] = 0.0f;
    }
    
    [ArrayLock lock];
    
    for (id key in [Chords allKeys])
    {
        CvTSynthChord *chord = Chords[key];
        
        float toneBuffer[numFrames];
        float envelopeBuffer[numFrames];
        [chord Render:toneBuffer envelopeBuffer:envelopeBuffer length:numFrames];
        
        for (int i = 0; i < numFrames; ++i)
        {
            buffer[i] += toneBuffer[i];
            commonEnvelope[i] += envelopeBuffer[i];
        }
        
        if ([chord Finished])
            [Chords removeObjectForKey:key];
   }

    [ArrayLock unlock];
    
    for (int i = 0; i < numFrames; ++i)
    {
        float compression = 0.70f * pow(0.85f, fmaxf(commonEnvelope[i], 1.0f) - 1.0f);
        buffer[i] = buffer[i] * compression;
        
        if (buffer[i] > 1.25f)
            buffer[i] = 0.984375f;
        else
            if (buffer[i] < -1.25)
                buffer[i] = -0.984375;
            else
                buffer[i] = 1.1f * buffer[i] - 0.2 * buffer[i] * buffer[i] * buffer[i];
        
        if (buffer[i] < -0.984375f)
            buffer[i] = -0.984375f;
        else
            if (buffer[i] > 0.984375f)
                buffer[i] = 0.984375f;
    }
}

-(void)LoadPreset:(SynthSoundPreset)preset
{
    float voiceSettings[3][7] = {
        {0.001f, 0.15f, 0.0f, 0.001f, 6.00f, 0.25f, 0.80f},
        {0.001f, 0.15f, 0.8f, 0.500f, 2.00f, 0.40f, 0.71f},
        {0.250f, 0.01f, 1.0f, 1.100f, 0.50f, 0.65f, 0.60f}};
    
    int i = preset - kSynthSound_Pluck;
    i = MIN(MAX(0, i), 2);
    A = voiceSettings[i][0];
    D = voiceSettings[i][1];
    S = voiceSettings[i][2];
    R = voiceSettings[i][3];
    Modulator = voiceSettings[i][4];
    Operator = voiceSettings[i][5];
    Gain = voiceSettings[i][6];
}

@end
