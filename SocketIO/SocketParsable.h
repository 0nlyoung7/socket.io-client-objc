#import <Foundation/Foundation.h>
#import "SocketIOClientSpec.h"

@protocol SocketParsable <NSObject>

- (BOOL) isStringEmpty:(NSString *)string;

@optional
- (void) parseBinaryData:(NSData*) data;
- (void) parseSocketMessage:(NSString*) message;

@end

@interface SocketParsable : NSObject <SocketIOClientSpec, SocketParsable>

@end
