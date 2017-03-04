#import <Foundation/Foundation.h>
#import "SocketTypes.h"

@interface SocketAck : NSObject

@property (nonatomic, assign) int ack;
@property (nonatomic, copy, nullable) AckCallback callback;

@end

@interface SocketAckManager : NSObject

@property (nonatomic, copy, nullable) NSMutableDictionary* acks ;

@end
