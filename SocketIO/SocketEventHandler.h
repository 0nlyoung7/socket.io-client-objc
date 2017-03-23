#import <Foundation/Foundation.h>
#import "SocketTypes.h"
#import "SocketAckEmitter.h"
#import "SocketIOClient.h"

@interface SocketEventHandler: NSObject

@property (nonatomic, nullable) NSString *event;
@property (nonatomic, nullable) NSUUID *uuid;
@property (nonatomic, nullable) NormalCallback callback;

- (void)executeCallback:(NSArray *_Nonnull) items withAck:(int) ack withSocket:(SocketIOClient *_Nonnull) socket;

@end
