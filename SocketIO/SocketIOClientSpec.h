#import <Foundation/Foundation.h>

@protocol SocketIOClientSpec <NSObject>

@property (nonatomic, copy) NSString *nsp;

@optional
- (void) didConnect;
- (void) didDisconnect:(NSString*) reason;
- (void) didError:(NSString*) reason;
- (void) handleAck:(NSInteger) ack data:(NSArray *)data;
- (void) handleEvent:(NSString*) event data:(NSArray *)data
                        isInternalMessage:(Boolean)isInternalMessage withAck:(NSInteger)withAck;

- (void) joinNamespace:(NSString*) namespace;

@end

@interface SocketIOClientSpec : NSObject <SocketIOClientSpec>

@end
