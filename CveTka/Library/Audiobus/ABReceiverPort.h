//
//  ABReceiverPort.h
//  Audiobus
//
//  Created by Michael Tyson on 03/03/2012.
//  Copyright (c) 2011-2014 Audiobus. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ABCommon.h"
#import "ABPort.h"

/*!
 * Receiver port connections changed
 *
 *  Sent when the port's connections have changed, caused by connections
 *  or disconnections from within the Audiobus app.
 */
extern NSString * const ABReceiverPortConnectionsChangedNotification;
    
/*!
 * Port added notification
 *
 *  Sent when a new source is added to this port
 */
extern NSString * const ABReceiverPortPortAddedNotification;

/*!
 * Port removed notification
 *
 *  Sent when a source is removed from this port
 */
extern NSString * const ABReceiverPortPortRemovedNotification;

/*!
 * Port audio unit will initialize notification
 *
 *  Sent just before a port's audio unit is initialized; use this to set host callbacks, etc.
 */
extern NSString * const ABReceiverPortPortInterAppAudioUnitWillInitializeNotification;
    
/*!
 * Port audio unit connected notification
 *
 *  Sent when a port's audio unit has been connected successfully
 */
extern NSString * const ABReceiverPortPortInterAppAudioUnitConnectedNotification;

/*!
 * Port audio unit disconnected notification
 *
 *  Sent when a port's audio unit was disconnected, either through a port removal, or an error
 */
extern NSString * const ABReceiverPortPortInterAppAudioUnitDisconnectedNotification;

/*!
 * Port key for the userInfo dictionary of port added/remove notifications
 */
extern NSString * const ABReceiverPortPortKey;

@class ABReceiverPort;

/*!
 * Receiver port
 *
 *  This class is used to receive audio sent by other Audiobus-compatible apps.
 *
 *  See the integration guide's section on using the [Receiver Port](@ref Create-Receiver-Port),
 *  and the [Receiver Port](@ref Receiver-Port) section in the documentation for details.
 */
@interface ABReceiverPort : ABPort

/*!
 * Initialize
 *
 *  Initializes a new receiver port
 *
 * @param name Name of port, for internal use
 * @param title Title of port, show to the user
 */
- (id)initWithName:(NSString *)name title:(NSString*)title;

/*!
 * Receive audio
 *
 *  Use this C function to receive audio from Audiobus.
 *  It's suitable for use from within a realtime Core Audio context.
 *
 *  Please note that if you are receiving separate streams (@link receiveMixedAudio @endlink is NO), then this function will
 *  provide synchronized streams for each connected source port. The following procedures must be followed:
 *
 *  - All calls to ABReceiverPortReceive must be performed on the same thread.
 *  - You must call @link ABReceiverPortEndReceiveTimeInterval @endlink at the end of each time interval (such as for each render
 *    of your audio system, or each input notification), to tell Audiobus that you are finished with all audio for that interval.
 *    Audio for any sources that you did not receive audio for will be discarded.
 *
 * @param receiverPort         The receiver port.
 * @param sourcePortOrNil   If you are receiving separate streams (@link receiveMixedAudio @endlink is NO), this must be a valid source port - one of the ports from the
 *                          @link sources @endlink array. Otherwise, if you are receiving a mixed stream, pass nil.
 * @param audio             The audio buffer list to receive audio into, in the format specified by @link clientFormat @endlink. Must not be NULL.
 *                          If 'mData' pointers are NULL, then an internal buffer will be provided.
 * @param lengthInFrames    The number of frames requested. This method will never return less than the requested frames.
 * @param ioTimestamp       On input, the current audio timestamp. On output, the timestamp of the returned audio (may differ due to latency).
 */
void ABReceiverPortReceive(ABReceiverPort *receiverPort, ABPort *sourcePortOrNil, AudioBufferList *audio, UInt32 lengthInFrames, AudioTimeStamp *ioTimestamp);

/*!
 * When receiving separate streams, mark the end of the current time interval
 *
 *  When you are receiving separate streams (@link receiveMixedAudio @endlink is NO), this function must be called
 *  at the end of each time interval to signal to Audiobus that you have finished receiving the incoming audio 
 *  for the given interval.
 *
 * @param receiverPort         The receiver port.
 */
void ABReceiverPortEndReceiveTimeInterval(ABReceiverPort *receiverPort);

/*!
 * Audio Queue version of ABReceiverPortReceive
 *
 *  You can use this function to pull audio from Audiobus into an Audio Queue buffer. This may be used
 *  inside an AudioQueueInputCallback to replace the audio received from the microphone with audio
 *  from Audiobus, for instance.
 *
 *  See discussion for @link ABReceiverPortReceive @endlink.
 *
 * @param receiverPort         The receiver port.
 * @param sourcePortOrNil   If you are receiving separate streams (@link receiveMixedAudio @endlink is NO), this must be nil. Otherwise, pass the port to receive audio from.
 * @param bufferList        The buffer list to receive audio into, in the format specified by @link clientFormat @endlink. If NULL, then audio will simply be discarded.
 * @param lengthInFrames    The number of frames requested. This method will never return less than the requested frames.
 * @param ioTimestamp       On input, the current audio timestamp. On output, the timestamp of the returned audio (may differ due to latency).
 */
void ABReceiverPortReceiveAQ(ABReceiverPort *receiverPort, ABPort *sourcePortOrNil, AudioQueueBufferRef bufferList, UInt32 lengthInFrames, AudioTimeStamp *ioTimestamp);

/*!
 * Determine if the receiver port is currently connected to any sources
 *
 *  This function is suitable for use from within a realtime Core Audio context.
 *
 * @param receiverPort The receiver port.
 * @return YES if there are currently sources connected; NO otherwise.
 */
BOOL ABReceiverPortIsConnected(ABReceiverPort *receiverPort);

/*
 * Whether the port is connected to another port from the same app
 *
 *  This returns YES when the receiver port is connected to a sender port also belonging to your app.
 *
 *  If your app supports connections to self (ABAudiobusController's
 *  @link ABAudiobusController::allowsConnectionsToSelf allowsConnectionsToSelf @endlink
 *  is set to YES), then you should take care to avoid feedback issues when the app's input is being fed from
 *  its own output.
 *
 *  Primarily, this means not sending output derived from the input through the sender port.
 *
 *  You can use @link ABReceiverPortIsConnectedToSelf @endlink and the equivalent ABSenderPort function,
 *  @link ABSenderPortIsConnectedToSelf @endlink to determine this state from the Core Audio realtime
 *  thread, and perform muting/etc as appropriate.
 *
 * @param receiverPort The receiver port.
 * @return YES if one of this port's sources belongs to this app
 */
BOOL ABReceiverPortIsConnectedToSelf(ABReceiverPort *receiverPort);

/*!
 * Set the volume level for a particular source
 *
 *  Note that this only applies to the mixed stream as accessed via
 *  ABReceiverPortReceive when the receiveMixedAudio property is YES.
 *
 *  It does not affect separate streams accessed via ABReceiverPortReceive
 *  when receiveMixedAudio is NO.
 *
 * @param volume            Volume level (0 - 1); default 1
 * @param port              Source port
 */
- (void)setVolume:(float)volume forSourcePort:(ABPort*)port;

/*!
 * Get the volume level for a source
 *
 * @param port              Source port
 * @return Volume for the given port (0 - 1)
 */
- (float)volumeForSourcePort:(ABPort*)port;

/*!
 * Set the pan for a particular source
 *
 *  Note that this only applies to the mixed stream as accessed via
 *  ABReceiverPortReceive when the receiveMixedAudio property is YES.
 *
 *  It does not affect separate streams accessed via ABReceiverPortReceive
 *  when receiveMixedAudio is NO.
 *
 * @param pan               Pan (-1.0 - 1.0); default 0.0
 * @param port              Source port
 */
- (void)setPan:(float)pan forSourcePort:(ABPort*)port;

/*!
 * Get the pan level for a source
 *
 * @param port              Source port
 * @return Pan for the given port (-1.0 - 1.0)
 */
- (float)panForSourcePort:(ABPort*)port;

/*!
 * Get access to the Inter-App Audio audio unit for a particular source
 *
 *  You may use this method to gain direct access to the audio unit for a source
 *  in order to perform custom Inter-App Audio interactions, such as MIDI exchange.
 *
 *  Watch the @link ABReceiverPortPortInterAppAudioUnitWillInitializeNotification @endlink notification
 *  to be informed when an audio unit for a port that is being connected is about to be
 *  initialised. You can use this to set IAA host transport callbacks.
 *  Watch @link ABReceiverPortPortInterAppAudioUnitConnectedNotification @endlink notification
 *  to be informed when an audio unit for a connected port has been connected.
 *  Watch @link ABReceiverPortPortInterAppAudioUnitDisconnectedNotification @endlink to be notified
 *  when an audio unit has been disconnected, after which you should not access the
 *  audio unit again.
 *  
 *  You must never add this audio unit to a graph, call AudioUnitRender upon it, or
 *  change the client formats.
 *
 *  Note that once this audio unit has been disconnected, either due to an Audiobus
 *  disconnection, or an error like the source app crashing, the audio unit will be
 *  invalidated. If you retain references to audio units returned from this method,
 *  it's very important that you observe the 
 *  @link ABReceiverPortPortInterAppAudioUnitDisconnectedNotification @endlink notification, and 
 *  unset your references.
 *
 * @param port              Source port
 * @return The audio unit connected to the source, if Inter-App Audio in use. Otherwise, NULL.
 */
- (AudioUnit)audioUnitForSourcePort:(ABPort*)port;

/*!
 * Currently-connected sources
 *
 *  This is an array of @link ABPort ABPorts @endlink.
 */
@property (nonatomic, strong, readonly) NSArray *sources;

/*!
 * Whether the port is connected
 */
@property (nonatomic, readonly) BOOL connected;

/*!
 * Whether to receive audio as a mixed stream
 *
 *  If YES (default), then all incoming audio across all sources will be mixed to a single audio stream.
 *  Otherwise, you will receive separate audio streams for each connected port.
 *
 *  See documentation for ABReceiverPortReceive and ABReceiverPortEndReceiveTimeInterval.
 */
@property (nonatomic, assign) BOOL receiveMixedAudio;

/*!
 * Client format
 *
 *  Use this to specify what audio format your app uses. Audio will be automatically
 *  converted from the Audiobus line format.
 *
 *  The default value is non-interleaved stereo floating-point PCM.
 */
@property (nonatomic, assign) AudioStreamBasicDescription clientFormat;

/*!
 * The title of the port, for display to the user
 */
@property (nonatomic, strong, readwrite) NSString *title;

/*!
 * The port icon (a 32x32 image)
 *
 *  This is optional if your app only has one receiver port, but if your app
 *  defines multiple receiver ports, it is highly recommended that you provide icons
 *  for each, for easy identification by the user.
 */
@property (nonatomic, strong, readwrite) UIImage *icon;

/*!
 * Whether the port should perform monitoring itself
 *
 *  If your app does not do audio monitoring - such as a guitar tuner app without a
 *  passthrough feature - you should set this property to YES, which will cause the
 *  receiver port to do its own monitoring, so input apps can still be heard.
 *
 *  If, on the other hand, your app *does* do its own audio monitoring, leave this
 *  property at its default value, NO, to disable internal monitoring.
 *
 *  The default value is NO.
 */
@property (nonatomic, assign) BOOL automaticMonitoring;

/*!
 * Whether the port is connected to another port from the same app
 *
 *  This is a key-value-observable property equivalent of ABReceiverPortIsConnectedToSelf. See
 *  the documentation for ABReceiverPortIsConnectedToSelf for details.
 */
@property (nonatomic, readonly) BOOL connectedToSelf;

/*!
 * The current latency
 *
 *  This reports the total latency of the audio chain ending at this receiver.
 *  Note that this latency is already represented in the AudioTimeStamp value
 *  returned from the receive methods.
 */
@property (nonatomic, readonly) NSTimeInterval latency;

@end

#ifdef __cplusplus
}
#endif