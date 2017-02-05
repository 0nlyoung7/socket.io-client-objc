#import "SocketIOClientSpec.h"

@implementation SocketIOClientSpec
{

}

- (void) didError:(NSString*) reason {
    
    NSMutableArray *arrayout = [NSMutableArray array];
    [arrayout addObject:reason];
    
    //DefaultSocketLogger.Logger.error("%@", type: "SocketIOClient", args: reason)
    [self handleEvent:@"error" data:arrayout isInternalMessage:true withAck:-1];
}

@end
