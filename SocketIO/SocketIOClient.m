#import <UIKit/UIKit.h>

#import "SocketIOClient.h"
#import "SocketPacket.h"
#import "SocketEngine.h"


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

- (SocketEngine*) addEngine{
    SocketEngine *engine = [[SocketEngine alloc] init];
    return engine;
}

- (void) connect {
   // [self connect:0 withHandler:NULL];
}

- (void) connect:(int) timeoutAfter withHandler:(void (^)(void))handler {
    
    if( self.status == Connected ){
        NSLog(@"Tried connecting on an already connected socket");
        return;
    }
    
    self.status = Connecting;
    
    if( self.engine == NULL || self.forceNew ){
        [[self addEngine] connect];
    } else {
        if( self.engine ){
            [self.engine connect];
        }
    }
    
    if (timeoutAfter == 0 ){
        return;
    }
    
    
    CGFloat deadlinePlus = (CGFloat) (timeoutAfter * NSEC_PER_SEC) / NSEC_PER_SEC;
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, deadlinePlus), self.handleQueue, ^{
        if( weakSelf.status == Connected || weakSelf.status == Disconnected ){
            return;
        }
        
        weakSelf.status = Disconnected;
        if( weakSelf ){
            [weakSelf.engine disconnect:@"Connect timeout"];
        }
        
        if( handler ){
            handler();
        }
        
    });

}

- (OnAckCallback) createOnAck:(NSArray*) items {
    self.currentAck += 1;

    __weak typeof(self) weakSelf = self;
    
    OnAckCallback cb = ^(int timeoutAfter, AckCallback callback) {
        dispatch_sync(weakSelf.ackQueue, ^{
            //TODO
            //[weakSelf.ackHandlers addAck:ack callback:callback];
        });
        
    };
    
    
    return cb;
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
