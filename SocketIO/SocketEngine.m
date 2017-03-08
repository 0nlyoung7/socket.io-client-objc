#import <Foundation/Foundation.h>
#import "SocketEngine.h"

@implementation SocketEngine
{
    
}

-(instancetype) initWithOption:(SocketEngineClient*) client url:(NSURL*) url config:(NSMutableDictionary*) config {
    self = [[SocketEngine alloc] init];
    self.client = client;
    self.url = url;
    
    return self;
}

@end
