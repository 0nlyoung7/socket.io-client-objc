#import "SocketAckEmitter.h"

@implementation SocketAckEmitter
{
    
}

- (instancetype)initWithSocket:(SocketIOClient*) socket ackNum:(NSInteger)ackNum{
    if(self = [super init]) {
        self.socket = socket;
        self.ackNum = ackNum;
    }
    return self;
}

-(void) with:(NSArray*) items{
    //[self.socket emitAck:self.ackNum with:items]
}

@end
