#import "SocketAckEmitter.h"

@implementation SocketAckEmitter
{
    
}

- (instancetype)initWithAckNum:(SocketIOClient*) socket ackNum:(int)ackNum{
    if(self = [super init]) {
        self.socket = socket;
        self.ackNum = ackNum;
    }
    return self;
}

-(void) with:(NSArray*) items{
    if( _ackNum == -1 ){
        return;
    }
    [self.socket emitAck:self.ackNum with:items];
}
@end

@implementation OnAckCallback
{

}

- (instancetype) initWithSocket:(int)ackNumber items:(NSArray*)items socket:(SocketIOClient*) socket{
    if(self = [super init]) {
        self.ackNumber = ackNumber;
        self.items = items;
        self.socket = socket;
    }
    return self;
}

- (void) timingOut:(int) seconds callback:(AckCallback) callback{
    if( self.socket == NULL ){
        return;
    }
    
    dispatch_sync(self.socket.ackQueue, ^{
        [self.socket.ackHandlers addAck:self.ackNumber callback:callback];
    });
    
    [self.socket _emit:self.items ack:self.ackNumber];
    
    if( seconds == 0 ){
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), self.socket.handleQueue, ^{
        [self.socket.ackHandlers timeoutAck:self.ackNumber onQueue:self.socket.handleQueue];
    });
    
}

@end
