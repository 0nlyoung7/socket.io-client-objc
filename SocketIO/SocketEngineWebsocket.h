#import <Foundation/Foundation.h>
#import "SocketEngineSpec.h"
#import "WebSocket.h"

@protocol SocketEngineWebsocket <SocketEngineSpec, WebSocketDelegate>

- (void)sendWebSocketMessage:(NSString*) str withType:(SocketEnginePacketType)type withData:(NSArray*) datas;

- (void)probeWebSocket;

@end

@interface SocketEngineWebsocket : NSObject <SocketEngineSpec, WebSocketDelegate>

@end
