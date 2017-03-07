#import <Foundation/Foundation.h>
#import "SocketEnginePollable.h"
#import "SocketEngineWebsocket.h"

@interface SocketEngine: NSObject<NSURLSessionDelegate, SocketEnginePollable, SocketEngineWebsocket>

@end
