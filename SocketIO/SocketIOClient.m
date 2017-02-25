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

@end
