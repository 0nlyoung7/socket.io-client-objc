#import <UIKit/UIKit.h>

#import "SocketIOClient.h"

@implementation SocketIOClient
{
    dispatch_semaphore_t _semaphore;
}

- (instancetype)initWithSocketURL:(NSURL *)url config:(NSDictionary*)config
{
    self = [super init];
    if (self) {
        
        //set default value;
        self.nsp = @"/";
        self.reconnectWait = 10;
   
        self.currentAck = -1;
        self.reconnectAttempts = -1;
        
        self.socketURL = url;
        self.config = [config mutableCopy];
        
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
        
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (SocketEngine*) addEngine{
    SocketEngine *engine = [[SocketEngine alloc] initWithOption:self url:self.socketURL config:self.config];
    return engine;
}

- (void) connect{
    [self connect:0 withHandler:NULL];
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

-(int) nextAck {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER );
    self.currentAck += 1;
    dispatch_semaphore_signal( _semaphore );
    return self.currentAck;
}

- (OnAckCallback*) createOnAck:(NSArray*) items {
    int currentAck = [self nextAck];
    OnAckCallback *cb = [[OnAckCallback alloc] initWithSocket:currentAck items:items socket:self];
    return cb;
}

- (void) didConnect{
    self.status = Connected;
    
    [self handleEvent:@"connect" data:@[] isInternalMessage:false];
}

-(void) didDisconnect:(NSString*) reason{
    if ( self.status == Disconnected ){
        return;
    }
    
    NSLog(@"Disconnected: %@", reason);
    
    self.reconnecting = FALSE;
    self.status = Disconnected;
    
    if( self.engine ){
        [self.engine disconnect:reason];
    }
    
    [self handleEvent:@"disconnect" data:@[reason] isInternalMessage:TRUE];
}

-(void) disconnect{
    NSLog(@"Closing socket");
    [self didDisconnect:@"Disconnect"];
}

-(void) emit:(NSString*) event items:(NSArray*) items {
    if( self.status != Connected ){
        NSString *data = [@"" stringByAppendingFormat:@"Tried emitting %@ when not connected", event];
        [self handleEvent:@"error" data:@[data] isInternalMessage:TRUE];
        return;
    }
    
    NSMutableArray *dataArray = [[NSMutableArray alloc] initWithObjects:event, nil];
    [dataArray arrayByAddingObjectsFromArray:items];
    [self _emit:dataArray ack:-1];
}

-(OnAckCallback*) emitWithAck:(NSString*) event items:(NSArray*) items {
    NSMutableArray *dataArray = [[NSMutableArray alloc] initWithObjects:event, nil];
    [dataArray arrayByAddingObjectsFromArray:items];
    return [self createOnAck:dataArray];
}

-(void) _emit:(NSArray*) data ack:(NSInteger)ack {
    dispatch_async(self.emitQueue,^{
        if(self.status != Connected){
            [self handleEvent:@"error" data:@[@"Tried emitting when not connected"] isInternalMessage:TRUE];
            return;
        }
        
        SocketPacket *packet = [SocketPacket packetFromEmit:data id:ack nsp:self.nsp ack:FALSE];
        NSString *str = [packet packetString];
        
        NSLog(@"Emitting: %@", str);
        
        if( self.engine ){
            [self.engine send:str withData:packet.binary];
        }
        
    });
}

- (void)emitAck:(int)ack with:(nullable NSArray*) items{
    
    dispatch_async(self.emitQueue,^{
        if(self.status != Connected){
            return;
        }
        SocketPacket *packet = [SocketPacket packetFromEmit:items id:ack nsp:self.nsp ack:TRUE];
        NSString *str = [packet packetString];
            
        [self.engine send:str withData:packet.binary];
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

-(void) engineDidError:(NSString*)reason{
    [self handleEvent:@"error" data:@[reason] isInternalMessage:TRUE];
}

-(void) engineDidOpen:(NSString*)reason{
    NSLog(@"%@", reason);
}

-(void) handleAck:(int) ack data:(NSArray*) data{
    if( self.status != Connected ){
        return;
    }
    
    dispatch_async(self.handleQueue ,^{
        [self.ackHandlers executeAck:ack items:data onQueue:self.handleQueue];
    });
}

-(void) handleEvent:(NSString*)event data:(NSArray *)data isInternalMessage:(Boolean)isInternalMessage {
    [self handleEvent:event data:data isInternalMessage:isInternalMessage withAck:-1];
    
}

-(void) handleEvent:(NSString*)event data:(NSArray *)data isInternalMessage:(Boolean)isInternalMessage withAck:(int)withAck{
    if( self.status != Connected && !isInternalMessage ){
        return;
    }
    
    dispatch_async(self.handleQueue ,^{
        if( self.anyHandler ){
            SocketAnyEvent *socketAnyEvent = [[SocketAnyEvent alloc] initWithEvent:event items:data];
            self.anyHandler(socketAnyEvent);
            
            for( SocketEventHandler *handler in self.handlers ){
                if( handler.event == event ){
                    [handler executeCallback:data withAck:withAck withSocket:self];
                }
            }
        }
    });
}

-(void) leaveNamespace{
    if( ![self.nsp isEqualToString:@"/"] ){
        if( self.engine ){
            [self.engine send:[NSString stringWithFormat:@"1(%@)", self.nsp] withData:@[]];
        }
    }
}

-(void) joinNamespace:(NSString*) namespace{
    self.nsp = namespace;
    
    if( ![self.nsp isEqualToString:@"/"] ){
        if( self.engine ){
            [self.engine send:[NSString stringWithFormat:@"0(%@)", self.nsp] withData:@[]];
        }
    }
}

-(void) off:(NSString*) event{
    NSArray *filteredHandlers = [self.handlers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return ( ![[object event] isEqualToString:event] );
    }]];
    
    self.handlers = [[NSMutableArray alloc] initWithArray:filteredHandlers];
}

-(void) offById:(NSUUID*) uuid{
    NSArray *filteredHandlers = [self.handlers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return ( ![[object uuid] isEqual:uuid] );
    }]];
    
    self.handlers = [[NSMutableArray alloc] initWithArray:filteredHandlers];
}

-(NSUUID*) on:(NSString*) event callback:(NormalCallback) callback {
    
    SocketEventHandler *handler = [[SocketEventHandler alloc] init];
    handler.event = event;
    handler.uuid = [NSUUID UUID];
    handler.callback = callback;
    
    [self.handlers addObject:handler];
    return handler.uuid;
}

-(NSUUID*) once:(NSString*) event callback:(NormalCallback) callback {
    NSUUID *uuid = [NSUUID init];
    
    SocketEventHandler *handler = [[SocketEventHandler alloc] init];
    handler.event = event;
    handler.uuid = uuid;
    
    __weak typeof(self) weakSelf = self;
    
    NormalCallback onceCb = ^(NSData* data, SocketAckEmitter *ackEmitter) {
        [weakSelf offById:uuid];
        callback(data, ackEmitter);
    };
    
    handler.callback = onceCb;
    
    [self.handlers addObject:handler];
    return handler.uuid;
}

-(void) onAny:(void (^)(SocketAnyEvent*))handler {
    self.anyHandler = handler;
}

-(void) parseEngineMessage:(NSString*) msg{
    dispatch_async(self.parseQueue,^{
        [self parseSocketMessage:msg];
    });
}

-(void) parseEngineBinaryData:(NSData*) data{
    dispatch_async(self.parseQueue,^{
        [self parseBinaryData:data];
    });
}

-(void) reconnect{
    if( self.reconnecting ){
        return;
    }
    
    if( self.engine != NULL ){
        [self.engine disconnect:@"manual reconnect"];
    }
}

-(void) removeAllHandlers {
    [self.handlers removeAllObjects];
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
    [self connect];
    
    CGFloat deadlinePlus = (CGFloat) (self.reconnectWait * NSEC_PER_SEC) / NSEC_PER_SEC;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, deadlinePlus), dispatch_get_main_queue(), ^{
        [self _tryReconnect];
    });
}

@end
