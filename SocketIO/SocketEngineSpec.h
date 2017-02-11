#import <Foundation/Foundation.h>
#import "SocketEngineClient.h"
#import "SocketEnginePacketType.h"


@protocol SocketEngineSpec <NSObject>

@property (nonatomic, copy) NSString *nsp;
@property (nonatomic, copy) NSMutableArray *waitingPackets;

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
