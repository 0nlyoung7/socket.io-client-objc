#import <Foundation/Foundation.h>

#import "SocketEngineClient.h"
#import "SocketParsable.h"

@interface SocketIOClient : NSObject<SocketEngineClient, SocketParsable>

@end
