#import <Foundation/Foundation.h>
#import "SocketEngine.h"
#import "SocketEnginePacketType.h"

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
        // sendWebSocketMessage
        [self closeOutEngine:reason];
    } else {
        // disconnectPolling
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

@end
