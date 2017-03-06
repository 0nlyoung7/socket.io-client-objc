#import <UIKit/UIKit.h>

#import "SocketIOClient.h"
#import "SocketPacket.h"


@implementation SocketIOClient
{
        
}

- (instancetype)initWithSocketURL:(NSURL *)url config:(NSMutableDictionary*)config
{
    self = [super init];
    if (self) {
        
        //set default value;
        self.nsp = @"/";
        self.reconnectWait = 10;
   
        self.currentAck = -1;
        self.reconnectAttempts = -1;
        
        self.socketURL = url;
        self.config = config;
        
        if( [[url absoluteString] hasPrefix:@"https://"] ){
            [self.config setObject:[NSNumber numberWithBool:YES] forKey:@"secure"];
        }
        
        for (NSString* key in config.allKeys) {
           if( [key isEqualToString:@"nsp"] ){
               self.nsp  = config[@"nsp"];
           } else if ( [key isEqualToString:@"forceNew"]  ){
               self.forceNew  = config[@"forceNew"];
           }
        }
        
        
        
        [self.config setObject:[NSNumber numberWithBool:YES] forKey:@"secure"];
    }
    return self;
}

- (void)emitAck:(int)ack with:(nullable NSArray*) items{
    
    dispatch_async(self.emitQueue,^{
        if(self.status == Connected){
            return;
        } else {
            SocketPacket *packet = [SocketPacket packetFromEmit:items id:ack nsp:self.nsp ack:TRUE];
            NSString *str = [packet packetString];
            
            [self.engine send:str withData:packet.binary];
        }
    });
}

-(void) engineDidClose:(NSString*)reason{
    [self.waitingPackets removeAllObjects];
    
    if( self.status != Disconnected ){
        [self setStatus:NotConnected];
    }
    
    if ( self.status != Disconnected || ! self.reconnects ) {
        [self didDisconnect:reason];
    } else if( !self.reconnecting ){
        [self setReconnecting:TRUE];
        [self tryReconnect:reason];
    }
}

-(void) didDisconnect:(NSString*)reason {
    if( self.status == Disconnected ){
        return;
    }
    
    [self setReconnecting:FALSE];
    [self setStatus:Disconnected];
    
    if( self.engine != NULL ){
        [self.engine disconnect:reason];
    }
    
    NSArray *data = @[reason];
    [self handleEvent:@"disconnect" data:data isInternalMessage:TRUE];
}

-(void) handleEvent:(NSString*)event data:(NSArray *)data isInternalMessage:(Boolean)isInternalMessage {
    [self handleEvent:event data:data isInternalMessage:isInternalMessage withAck:-1];
    
}

-(void) handleEvent:(NSString*)event data:(NSArray *)data isInternalMessage:(Boolean)isInternalMessage withAck:(NSInteger)withAck{
    if( self.status != Connected && !isInternalMessage ){
        return;
    }
    
    dispatch_async(self.handleQueue ,^{
        if( self.anyHandler ){
            SocketAnyEvent *socketAnyEvent = [[SocketAnyEvent alloc] init:event items:data];
            self.anyHandler(socketAnyEvent);
        }
        
        //TODO Handler
        
    });
}

-(void) tryReconnect:(NSString*) reason{
    if( !self.reconnecting ){
        return;
    }
    
    [self handleEvent:@"reconnect" data:@[reason] isInternalMessage:TRUE];
    [self _tryReconnect];
}

-(void) _tryReconnect{
    if( !self.reconnecting ){
        return;
    }
    
    if( (self.reconnectAttempts != -1 && self.currentReconnectAttempt + 1 > self.reconnectAttempts) || !self.reconnects ){
       [self didDisconnect:@"Reconnect Failed"];
       return;
    }
    
    
    NSArray *data = @[[NSString stringWithFormat:@"%d", (self.reconnectAttempts - self.currentReconnectAttempt)]];
    [self handleEvent:@"reconnectAttempt" data:data isInternalMessage:TRUE];
    
    self.currentReconnectAttempt += 1;
    
    //TODO connect
    
    CGFloat deadlinePlus = (CGFloat) (self.reconnectWait * NSEC_PER_SEC) / NSEC_PER_SEC;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, deadlinePlus), dispatch_get_main_queue(), ^{
        [self _tryReconnect];
    });
}

@end
