#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SocketEnginePollable.h"
#import "SocketEngineWebsocket.h"
#import "SocketTypes.h"

@interface SocketEngine: NSObject<NSURLSessionDelegate, SocketEnginePollable, SocketEngineWebsocket>

@property (nonatomic, strong, nullable) dispatch_queue_t emitQueue;
@property (nonatomic, strong, nullable) dispatch_queue_t handleQueue;
@property (nonatomic, strong, nullable) dispatch_queue_t parseQueue;


@property (nonatomic, nullable) NSDictionary *connectParams;

@property (nonatomic, copy, nullable) NSMutableArray<NSString*> *postWait;
@property (nonatomic) BOOL waitingForPoll;
@property (nonatomic) BOOL waitingForPost;

@property (nonatomic) BOOL closed;
@property (nonatomic) BOOL connected;
@property (nonatomic, nullable) NSArray<NSHTTPCookie *> *cookies;
@property (nonatomic) BOOL doubleEncodeUTF8;
@property (nonatomic, nullable) NSDictionary *extraHeaders;
@property (nonatomic) BOOL fastUpgrade;
@property (nonatomic) BOOL forcePolling;
@property (nonatomic) BOOL forceWebsockets;
@property (nonatomic) BOOL invalidated;
@property (nonatomic) BOOL polling;
@property (nonatomic) BOOL probing;
@property (nonatomic, copy, readonly, nullable) NSURLSession *session;
@property (nonatomic, nullable) NSString *sid;
@property (nonatomic, nullable) NSString *socketPath;
@property (nonatomic, nullable) NSURL *urlPolling;
@property (nonatomic, nullable) NSURL *urlWebSocket;
@property (nonatomic) BOOL websocket;
@property (nonatomic, copy, nullable) WebSocket *ws;

@property (nonatomic, weak, nullable) SocketEngineClient *client;
//@property (nonatomic, weak, nullable) NSURLSessionDelegate *client;


@property (nonatomic, nullable) NSURL *url;

@property (nonatomic, nullable) ProbeWaitQueue* probeWait;

@property (nonatomic, readonly, nullable) NSURL *urlPollingWithSid;

@end
