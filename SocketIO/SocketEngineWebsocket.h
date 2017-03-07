#import <Foundation/Foundation.h>
#import "SocketEngineSpec.h"
#import "WebSocket.h"

@protocol SocketEngineWebsocket <NSObject>

- (void)sendWebSocketMessage:(NSString*) str withType:(SocketEnginePacketType)type withData:(NSArray*) datas;

@end

@interface SocketEngineWebsocket : NSObject <SocketEngineSpec, WebSocketDelegate>

@end
