#import <Foundation/Foundation.h>
#import "SocketEngineClient.h"
#import "SocketEnginePacketType.h"


@protocol SocketEngineSpec <NSObject>

@property (nonatomic, weak) SocketEngineClient *client;
@property (nonatomic) BOOL closed;
@property (nonatomic) BOOL connected;
@property (nonatomic) NSDictionary *connectParams;
@property (nonatomic) BOOL doubleEncodeUTF8;
@property (nonatomic) NSDictionary *cookies;
@property (nonatomic) NSDictionary *extraHeaders;

@property (nonatomic) BOOL fastUpgrade;
@property (nonatomic) BOOL forcePolling;
@property (nonatomic) BOOL forceWebsockets;

@property (nonatomic) BOOL polling;
@property (nonatomic) BOOL probing;

@property (nonatomic) NSString *sid;
@property (nonatomic) NSString *socketPath;
@property (nonatomic) NSUrl *urlPolling;
@property (nonatomic) NSUrl *urlWebSocket

@property (nonatomic) BOOL websocket;


@optional
- (void) connect;
- (void) didError:(NSString*) reason;
- (void) disconnect:(NSString*) reason;
- (void) doFastUpgrade;
- (void) flushWaitingForPostToWebSocket;
- (void) parseEngineData:(NSData*) data;
- (void) parseEngineMessage:(NSString*) message fromPolling:(BOOL)fromPolling;
- (void) write:(NSString*) msg withType:(SocketEnginePacketType)type withData:(NSArray*) data;

@end

@interface SocketIOClientSpec : NSObject <SocketIOClientSpec>

@end
