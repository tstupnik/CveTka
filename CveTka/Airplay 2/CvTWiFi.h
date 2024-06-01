//
//  CvTWiFiServer.h
//  CveTka
//
//  Created by tomaz stupnik on 8/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CvTWiFiConnection;
@protocol CvTWiFiConnectionDelegate <NSObject>

-(void)Receive:(id)object viaConnection:(CvTWiFiConnection *)viaConnection;
-(void)ConnectionTerminated:(CvTWiFiConnection *)connection;

@end

@interface CvTWiFiConnection : NSObject<NSNetServiceDelegate>
{
    NSString *Host;
    int Port;
    CFSocketNativeHandle Socket;
    NSNetService* Service;
    
    CFReadStreamRef ReadStream;
    BOOL ReadStreamOpen;
    NSMutableData *IncomingDataBuffer;
    int PacketBodySize;
    
    CFWriteStreamRef WriteStream;
    BOOL WriteStreamOpen;
    NSMutableData *OutgoingDataBuffer;

    id<CvTWiFiConnectionDelegate> Delegate;
}

@property (nonatomic, readonly, getter = getName) NSString *Name;

-(id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle;
-(id)initWithNetService:(NSNetService*)netService;
-(BOOL)connect:(id<CvTWiFiConnectionDelegate>)delegate;
-(void)close;
-(void)Send:(id)object;

@end

@protocol CvTWiFiServerDelegate <NSObject>

-(void)Receive:(NSDictionary*)packet ident:(NSString*)ident;
-(void)NewConnection:(CvTWiFiConnection*)connection;

@end

@interface CvTWiFiServer : NSObject<NSNetServiceDelegate, CvTWiFiConnectionDelegate>
{
    uint16_t Port;
    CFSocketRef Socket;
    NSNetService *Service;
    NSMutableArray *Connections;
    id<CvTWiFiServerDelegate> Delegate;
}

-(id)initWithDelegate:(id<CvTWiFiServerDelegate>)delegate;
-(BOOL)start;
-(void)stop;
-(void)Send:(id)object;

@end

@protocol CvTWiFiClientDelegate <NSObject>

-(void)Receive:(NSDictionary*)packet ident:(NSString*)ident;
-(void)ServersUpdate;

@end

@interface CvTWiFiClient : NSObject<NSNetServiceBrowserDelegate, CvTWiFiConnectionDelegate>
{
    NSNetServiceBrowser *Browser;
    NSMutableArray *Servers;
    CvTWiFiConnection *Connection;
    id<CvTWiFiClientDelegate> Delegate;
}

-(id)initWithDelegate:(id<CvTWiFiClientDelegate>)delegate;
-(BOOL)start;
-(void)stop;
-(void)Send:(id)object;

@end

