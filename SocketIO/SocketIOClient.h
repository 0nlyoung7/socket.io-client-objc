#import <Foundation/Foundation.h>

#import "SocketEngineClient.h"
#import "SocketIOClientStatus.h"
#import "SocketParsable.h"

@interface SocketIOClient : NSObject<SocketEngineClient, SocketParsable>

@property (nonatomic, copy, nonnull) NSURL *socketURL;
@property (nonatomic)  SocketIOClientStatus status;

@property (nonatomic) BOOL forceNew;
@property (nonatomic, copy, nullable) NSString *nsp;
@property (nonatomic) BOOL reconnects;

@property (nonatomic) int reconnectWait;

@property(nonatomic, strong, nullable) dispatch_queue_t parseQueue;


@property (nonatomic) int currentReconnectAttempt;
@property (nonatomic) BOOL reconnecting;

@property(nonatomic, strong, nullable)dispatch_queue_t handleQueue;
@property(nonatomic) BOOL reconnectAttempts;

@property(nonatomic, strong, nullable) dispatch_queue_t ackQueue;
@property(nonatomic, strong, nullable) dispatch_queue_t emitQueue;

- (void)emitAck:(int)ack with:(nullable NSArray*) items;

@end
