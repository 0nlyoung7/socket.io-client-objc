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
        //
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

@end
