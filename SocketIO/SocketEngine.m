#import <Foundation/Foundation.h>
#import "SocketEngine.h"
#import "SocketEnginePacketType.h"
#import "SocketTypes.h"

@implementation SocketEngine
{
    
}

-(instancetype) initWithOption:(SocketEngineClient*) client url:(NSURL*) url config:(NSMutableDictionary*) config {
    self = [[SocketEngine alloc] init];
    self.client = client;
    self.url = url;
    
    for( NSString* key in config ){
        if(  [config[key] isEqual:@"ConnectParams"] ){
       
        }
    }
    
    return self;
}


- (void) dealloc {
    [self setClosed:TRUE];
    [self stopPolling];
}

- (void) checkAndHandleEngineError:(NSString*) str{
    NSDictionary  *dict = [self toNSDictionary:str];
    if( dict[@"message"] ){
        [self didError:dict[@"message"]];
    }
}

- (void) didError:(NSString*) reason {
    if( self.client ){
        [self.client engineDidError:reason];
        [self disconnect:reason];
    }
}

- (void) disconnect:(NSString*) reason {
    if( !self.connected ){
        [self closeOutEngine:reason];
        return;
    }
    
    if( self.closed ){
        [self closeOutEngine:reason];
        return;
    }
    
    if( self.websocket ){
        [self sendWebSocketMessage:@"" withType:Close withData:@[]];
        [self closeOutEngine:reason];
    } else {
        [self disconnectPolling:reason];
    }
}

- (void) disconnectPolling:(NSString*) reason {
    dispatch_async(self.emitQueue ,^{
        NSString *typeStr = [NSString stringWithFormat: @"%ld", (long)Close];
        [self.postWait addObject:typeStr];
        
        NSMutableURLRequest  *req = [self createRequestForPostWithPostWait];
        [self doRequest:req callbackWith:nil];
        [self closeOutEngine:reason];
    });
}

-(void) doFastUpgrade {
    if (self.waitingForPoll){
        NSLog(@"Outstanding poll when switched to WebSockets, we'll probably disconnect soon. You should report this");
    }
    
    [self sendWebSocketMessage:@"" withType:Upgrade withData:@[]];
    [self setWebsocket:TRUE];
    [self setPolling:FALSE];
    [self setFastUpgrade:FALSE];
    [self setProbing:FALSE];
    
    [self flushProbeWait];

}

-(void) flushProbeWait {
    dispatch_async(self.emitQueue ,^{
        for( Probe *waiter in self.probeWait ){
            [self write:waiter.msg withType:waiter.type withData:waiter.data];
        }
        
        [self.probeWait removeAllObjects];
        
        if( self.postWait.count != 0 ){
            [self flushWaitingForPostToWebSocket];
        }
    });
}

-(void)flushWaitingForPostToWebSocket {
    if( !self.ws ){
        return;
    }
    
    for( NSString *msg in self.postWait ){
        [self.ws writeString:msg];
    }
    
    [self.postWait removeAllObjects];
}

-(void)handleClose:(NSString*) reason {
    if( self.client ){
        [self.client engineDidClose:reason];
    }
}

-(void)handleMessage:(NSString*) message {
    if( self.client ){
        [self.client parseEngineMessage:message];
    }
}

- (void) closeOutEngine:(NSString*) reason{
    [self setSid:@""];
    [self setClosed:TRUE];
    [self setInvalidated:TRUE];
    [self setConnected:FALSE];
    
    if( self.ws ){
        [self.ws disconnect];
        [self stopPolling];
        if( self.client ){
            [self.client engineDidClose:reason];
        }
    }
}

- (NSDictionary*) toNSDictionary:(NSString*) str{
    
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    NSError *e = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];
    
    if (!json) {
        NSLog(@"Error parsing JSON: %@", e);
        return nil;;
    }
    
    return json;
}

- (void) write:(NSString*) msg withType:(SocketEnginePacketType)type withData:(NSArray<NSData *> * _Nonnull)data{
    // TODO Impl
}

@end
