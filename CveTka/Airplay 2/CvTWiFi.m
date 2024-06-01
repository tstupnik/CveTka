//
//  CvTWiFiServer.m
//  CveTka
//
//  Created by tomaz stupnik on 8/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <CFNetwork/CFSocketStream.h>

#import "CvTWiFi.h"

@implementation CvTWiFiServer

-(id)init
{
    self = [super init];
    Connections = [[NSMutableArray alloc] init];
    return self;
}

-(id)initWithDelegate:(id<CvTWiFiServerDelegate>)delegate
{
    self = [self init];
    Delegate = delegate;
    return self;
}

-(BOOL)start
{
    if ([self createServer])
        if ([self publishService])
            return TRUE;

    [self terminateServer];
    return FALSE;
}

-(void)stop
{
    [self terminateServer];
    [self unpublishService];
    for (CvTWiFiConnection *connection in Connections)
        [connection close];
    Connections = [[NSMutableArray alloc] init];
}

static void serverAcceptCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    CvTWiFiServer *server = (__bridge CvTWiFiServer *)info;
    
    if (type == kCFSocketAcceptCallBack)
    {
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle*)data;
        
        CvTWiFiConnection *connection = [[CvTWiFiConnection alloc] initWithNativeSocketHandle:nativeSocketHandle];
        if (connection == NULL)
            close(nativeSocketHandle);
        else
            if (![connection connect:server])
            {
                [connection close];
            }
            else
            {
                [server->Connections addObject:connection];
                [server->Delegate NewConnection:connection];
            }
    }
}

-(BOOL)createServer
{
    CFSocketContext socketCtxt = {0, (__bridge void *)(self), NULL, NULL, NULL};
    Socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&serverAcceptCallback, &socketCtxt );
    if (socket == NULL)
        return FALSE;
    
    int existingValue = 1;
    setsockopt(CFSocketGetNative(Socket), SOL_SOCKET, SO_REUSEADDR, (void *)&existingValue, sizeof(existingValue));
    
    struct sockaddr_in socketAddress = {
        .sin_len = sizeof(socketAddress),
        .sin_family = AF_INET,
        .sin_port = 0,
        .sin_addr.s_addr = htonl(INADDR_ANY)
    };
    NSData *socketAddressData = [NSData dataWithBytes:&socketAddress length:sizeof(socketAddress)];
    
    if (CFSocketSetAddress(Socket, (__bridge CFDataRef)(socketAddressData)) != kCFSocketSuccess )
    {
        CFRelease(socket);
        Socket = NULL;
        return FALSE;
    }
    
    NSData *socketAddressActualData = (__bridge NSData *)CFSocketCopyAddress(Socket);
    struct sockaddr_in socketAddressActual;
    memcpy(&socketAddressActual, [socketAddressActualData bytes], [socketAddressActualData length]);
    Port = ntohs(socketAddressActual.sin_port);
    
    CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
    CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, Socket, 0);
    CFRunLoopAddSource(currentRunLoop, runLoopSource, kCFRunLoopCommonModes);
    CFRelease(runLoopSource);
    return TRUE;
}

-(BOOL)publishService
{
  	Service = [[NSNetService alloc] initWithDomain:@"" type:@"_cvetka._tcp." name:@"ZixJam" port:Port];
	if (Service == NULL)
		return FALSE;
    
	[Service scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[Service setDelegate:self];
	[Service publish];
    return TRUE;
}

-(void)terminateServer
{
    if (Socket != NULL)
    {
        CFSocketInvalidate(Socket);
		CFRelease(Socket);
		Socket = NULL;
    }
}

-(void)unpublishService
{
    if (Service )
    {
		[Service stop];
		[Service removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		Service = NULL;
	}
}

-(void)Send:(id)object
{
    for (CvTWiFiConnection *connection in Connections)
        [connection Send:object];
}

-(void)Receive:(id)object viaConnection:(CvTWiFiConnection*)viaConnection
{
    for (CvTWiFiConnection *connection in Connections)
        if (connection != viaConnection)
            [connection Send:object];
    [Delegate Receive:object ident:viaConnection.Name];
}

-(void)ConnectionTerminated:(CvTWiFiConnection *)connection{
    [Connections removeObject:connection];
}

@end


@implementation CvTWiFiClient

-(id)initWithDelegate:(id<CvTWiFiClientDelegate>)delegate
{
    self = [self init];
    Delegate = delegate;
    return self;
}

-(BOOL)start
{
    if (Browser != NULL)
        [self stop];
    
	Browser = [[NSNetServiceBrowser alloc] init];
	if(!Browser)
        return FALSE;
    
	Browser.delegate = self;
	[Browser searchForServicesOfType:@"_cvetka._tcp." inDomain:@""];
    return TRUE;
}

- (void)stop
{
    if (Browser)
    {
        [Browser stop];
        Browser = NULL;
        [Servers removeAllObjects];
    }
    [Connection close];
    Connection = NULL;
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
    if (![Servers containsObject:netService])
    {
        [Servers addObject:netService];
        if (Connection == NULL)
        {
            Connection = [[CvTWiFiConnection alloc] initWithNetService:netService];
            [Connection connect:self];
        }
    }
    
    if (!moreServicesComing)
        [Delegate ServersUpdate];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
    [Servers removeObject:netService];
    
    if (!moreServicesComing)
        [Delegate ServersUpdate];
}

-(void)Send:(id)object {
    [Connection Send:object];
}

-(void)Receive:(NSDictionary*)packet viaConnection:(CvTWiFiConnection*)viaConnection {
    [Delegate Receive:packet ident:viaConnection.Name];
}

-(void)ConnectionTerminated:(CvTWiFiConnection *)connection{
    Connection = NULL;
}

@end


@implementation CvTWiFiConnection

-(NSString*)getName{
    return Host;
}

-(void)clean
{
    ReadStream = NULL;
    WriteStream = NULL;
    ReadStreamOpen = WriteStreamOpen = FALSE;
    IncomingDataBuffer = OutgoingDataBuffer = NULL;
    
    Service = NULL;
    Host = NULL;
    Socket = -1;
    PacketBodySize = -1;
}

-(id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle
{
    [self clean];
    Socket = nativeSocketHandle;
    return self;
}

-(id)initWithNetService:(NSNetService*)netService
{
    [self clean];
    Service = netService;
    if (Service.hostName != NULL)
    {
        Host = Service.hostName;
        Port = (int)Service.port;
    }
    return self;
}

-(BOOL)connect:(id<CvTWiFiConnectionDelegate>)delegate
{
    Delegate = delegate;
    if (Host != NULL)
    {
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)Host, Port, &ReadStream, &WriteStream);
        return [self setupSocketStreams];
    }
    else
        if (Socket != -1)
        {
            CFStreamCreatePairWithSocket(kCFAllocatorDefault, Socket, &ReadStream, &WriteStream);
            return [self setupSocketStreams];
        }
        else
            if (Service != NULL)
            {
                if (Service.hostName != NULL)
                {
                    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)Service.hostName, (int)Service.port, &ReadStream, &WriteStream);
                    return [self setupSocketStreams];
                }
                
                Service.delegate = self;
                [Service resolveWithTimeout:5.0];
                return TRUE;
            }
    return FALSE;
}

-(void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    if (sender == Service)
    {
        [self close];
        [Delegate ConnectionTerminated:self];
    }
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender
{
    if (sender == Service)
    {
        Host = Service.hostName;
        Port = (int)Service.port;
        Service = NULL;
        if (![self connect:Delegate])
        {
            [self close];
            [Delegate ConnectionTerminated:self];
        }
    }
}

-(BOOL)setupSocketStreams
{
    if (ReadStream == NULL || WriteStream == NULL)
    {
        [self close];
        return FALSE;
    }
    
    IncomingDataBuffer = [[NSMutableData alloc] init];
    OutgoingDataBuffer = [[NSMutableData alloc] init];
    
    CFReadStreamSetProperty(ReadStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(WriteStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    CFOptionFlags registeredEvents = kCFStreamEventOpenCompleted | kCFStreamEventHasBytesAvailable | kCFStreamEventCanAcceptBytes | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred;
    CFStreamClientContext ctx = {0, (__bridge void *)(self), NULL, NULL, NULL};
    CFReadStreamSetClient(ReadStream, registeredEvents, ReadStreamEventHandler, &ctx);
    CFWriteStreamSetClient(WriteStream, registeredEvents, WriteStreamEventHandler, &ctx);
    CFReadStreamScheduleWithRunLoop(ReadStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFWriteStreamScheduleWithRunLoop(WriteStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    if (!CFReadStreamOpen(ReadStream) || !CFWriteStreamOpen(WriteStream))
    {
        [self close];
        return FALSE;
    }
    return TRUE;
}

- (void)close
{
    if (ReadStream != NULL)
    {
        CFReadStreamUnscheduleFromRunLoop(ReadStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFReadStreamClose(ReadStream);
        CFRelease(ReadStream);
        ReadStream = NULL;
    }
    if (WriteStream != NULL)
    {
        CFWriteStreamUnscheduleFromRunLoop(WriteStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFWriteStreamClose(WriteStream);
        CFRelease(WriteStream);
        WriteStream = NULL;
    }
    IncomingDataBuffer = OutgoingDataBuffer = NULL;

    if (Service != NULL)
    {
        [Service stop];
        Service = NULL;
    }
    [self clean];
}

void ReadStreamEventHandler(CFReadStreamRef stream, CFStreamEventType eventType, void *info)
{
    @autoreleasepool {
        CvTWiFiConnection* connection = (__bridge CvTWiFiConnection*)info;
        
        switch (eventType)
        {
            case kCFStreamEventOpenCompleted:
                connection->ReadStreamOpen = TRUE;
                break;
            case kCFStreamEventHasBytesAvailable:
                [connection ReadFromStreamIntoIncomingBuffer];
                break;
            case kCFStreamEventEndEncountered:
            case kCFStreamEventErrorOccurred:
                [connection close];
                [connection->Delegate ConnectionTerminated:connection];
                break;
            case kCFStreamEventCanAcceptBytes:
            case kCFStreamEventNone:
                break;
        }
    }
}

void WriteStreamEventHandler(CFWriteStreamRef stream, CFStreamEventType eventType, void *info)
{
    @autoreleasepool {
        CvTWiFiConnection* connection = (__bridge CvTWiFiConnection*)info;
        
        switch (eventType)
        {
            case kCFStreamEventOpenCompleted:
                connection->WriteStreamOpen = YES;
                break;
            case kCFStreamEventCanAcceptBytes:
                [connection writeOutgoingBufferToStream];
                break;
            case kCFStreamEventEndEncountered:
            case kCFStreamEventErrorOccurred:
                [connection close];
                [connection->Delegate ConnectionTerminated:connection];
                break;
            case kCFStreamEventNone:
            case kCFStreamEventHasBytesAvailable:
                break;
        }
    }
}

-(void)ReadFromStreamIntoIncomingBuffer
{
    UInt8 buf[1024];
    
    while(CFReadStreamHasBytesAvailable(ReadStream))
    {
        CFIndex len = CFReadStreamRead(ReadStream, buf, sizeof(buf));
        if (len <= 0)
        {
            [self close];
            [Delegate ConnectionTerminated:self];
            return;
        }
        [IncomingDataBuffer appendBytes:buf length:len];
    }
    
    while(1)
    {
        if (PacketBodySize == -1)
        {
            if ( [IncomingDataBuffer length] >= sizeof(int) )
            {
                memcpy(&PacketBodySize, [IncomingDataBuffer bytes], sizeof(int));
                NSRange rangeToDelete = {0, sizeof(int)};
                [IncomingDataBuffer replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
            }
            else
            {
                break;
            }
        }
        
        if ([IncomingDataBuffer length] >= PacketBodySize )
        {
            NSData* raw = [NSData dataWithBytes:[IncomingDataBuffer bytes] length:PacketBodySize];
            NSDictionary* packet = [NSKeyedUnarchiver unarchiveObjectWithData:raw];
            [Delegate Receive:packet viaConnection:self];

            NSRange rangeToDelete = {0, PacketBodySize};
            [IncomingDataBuffer replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
            PacketBodySize = -1;
        }
        else
        {
            break;
        }
    }
}

-(void)Send:(id)object
{
    NSData* rawPacket = [NSKeyedArchiver archivedDataWithRootObject:object];
    
    long packetLength = [rawPacket length];
    [OutgoingDataBuffer appendBytes:&packetLength length:sizeof(int)];
    [OutgoingDataBuffer appendData:rawPacket];
    [self writeOutgoingBufferToStream];
}

-(void)writeOutgoingBufferToStream
{
    if (!ReadStreamOpen || !WriteStreamOpen || ([OutgoingDataBuffer length] == 0))
        return;
    
    if (CFWriteStreamCanAcceptBytes(WriteStream))
    {
        CFIndex writtenBytes = CFWriteStreamWrite(WriteStream, [OutgoingDataBuffer bytes], [OutgoingDataBuffer length]);
        if (writtenBytes == -1)
        {
            [self close];
            [Delegate ConnectionTerminated:self];
            return;
        }
        NSRange range = {0, writtenBytes};
        [OutgoingDataBuffer replaceBytesInRange:range withBytes:NULL length:0];
    }
}

@end