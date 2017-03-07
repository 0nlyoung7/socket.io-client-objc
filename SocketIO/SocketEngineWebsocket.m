#import "SocketEngineWebsocket.h"
#import "SocketTypes.h"

@implementation SocketEngineWebsocket : NSObject
{
}

- (void)probeWebSocket {
    if( self.ws && self.ws.isConnected ){
        [self sendWebSocketMessage:@"probe" withType:Ping withData:@[]];
    }
}

- (void)sendWebSocketMessage:(NSString*) str withType:(SocketEnginePacketType)type withData:(NSArray*) datas{
    
    if( self.ws ){
        NSString *typeStr = [NSString stringWithFormat: @"%ld", (long)type];
        [self.ws writeString:typeStr];
    }
    
    for(NSData *data in datas){
        BinaryContainer bc = [self createBinaryDataForSend:data];
        if( bc.data ){
            [self.ws writeData:data];
        }
    }
}

- (void)websocketDidReceiveMessage:(WebSocket*) socket text:(NSString*) text{
    [self parseEngineMessage:text fromPolling:FALSE];
}

- (void)websocketDidReceiveData:(WebSocket*) socket data:(NSData*) data{
    [self parseEngineData:data];
}

@end
