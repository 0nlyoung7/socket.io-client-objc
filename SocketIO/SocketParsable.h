#import <Foundation/Foundation.h>
#import "SocketIOClientSpec.h"

@protocol SocketParsable <NSObject>

@optional
- (void) parseBinaryData:(NSData*) data;
- (void) parseSocketMessage:(NSString*) message;

@end

@interface SocketParsable : NSObject <SocketIOClientSpec, SocketParsable>

@end
