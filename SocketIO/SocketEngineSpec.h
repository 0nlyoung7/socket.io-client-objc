#import <Foundation/Foundation.h>
#import "SocketEngineClient.h"
#import "SocketEnginePacketType.h"


@protocol SocketEngineSpec <NSObject>

@property (nonatomic, weak) SocketEngineClient *client;
@property (nonatomic) BOOL closed;
@property (nonatomic) BOOL connected;
@property (nonatomic) NSDictionary *connectParams;
@property (nonatomic) BOOL doubleEncodeUTF8;
@property (nonatomic) NSArray<NSHTTPCookie *> *cookies;
@property (nonatomic) NSDictionary *extraHeaders;

@property (nonatomic) BOOL fastUpgrade;
@property (nonatomic) BOOL forcePolling;
@property (nonatomic) BOOL forceWebsockets;
@property (nonatomic, strong, nullable) dispatch_queue_t parseQueue;


@property (nonatomic) BOOL polling;
@property (nonatomic) BOOL probing;

@property (nonatomic, strong, nullable) dispatch_queue_t emitQueue;
@property (nonatomic, strong, nullable) dispatch_queue_t handleQueue;

@property (nonatomic, nullable) NSString *sid;
@property (nonatomic, nullable) NSString *socketPath;
@property (nonatomic, nullable) NSURL *urlPolling;
@property (nonatomic, nullable) NSURL *urlWebSocket;

@property (nonatomic, readonly, nullable) NSURL *urlPollingWithSid;

@property (nonatomic) BOOL websocket;

-(void) send:(NSString *_Nullable) msg withData:(NSData *_Nullable) datas;


@optional
- (void) connect;
- (void) didError:(NSString *_Nullable) reason;
- (void) disconnect:(NSString *_Nullable) reason;
- (void) doFastUpgrade;
- (void) flushWaitingForPostToWebSocket;
- (void) parseEngineData:(NSData *_Nonnull) data;
- (void) parseEngineMessage:(NSString *_Nonnull) message fromPolling:(BOOL)fromPolling;
- (void) write:(NSString *_Nonnull) msg withType:(enum SocketEnginePacketType)type withData:(NSArray<NSData*> *_Nonnull) data;
@end

@interface SocketEngineSpec : NSObject <SocketEngineSpec>

@end
