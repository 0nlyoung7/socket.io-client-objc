#import "SocketIOClient.h"

@implementation SocketIOClient
{
        
}

- (instancetype)initWithURL:(NSURL *)url protocols:(NSArray*)protocols
{
    return self;
}

- (void)emitAck:(int)ack with:(nullable NSArray*) items{
    
    dispatch_async(self.emitQueue,^{
        if(self.status == Connected){
            return;
        } else {
            
        }
    });
}

@end
