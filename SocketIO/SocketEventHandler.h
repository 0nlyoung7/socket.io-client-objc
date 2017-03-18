#import <Foundation/Foundation.h>
#import "SocketTypes.h"

@interface SocketEventHandler: NSObject
{
}

@property (nonatomic, nullable) NSString *event;
@property (nonatomic, nullable) NSUUID *id;
@property (nonatomic, nullable) NormalCallback callback;

- (void)executeCallback:(NSArray*) items withAck:(int) ack withSocket:(SocketIOClient *_Nonnull) socket;
@end
