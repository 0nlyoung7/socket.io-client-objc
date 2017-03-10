
#import "SocketPacket.h"
#import "SocketAckEmitter.h"
#import "SocketEnginePacketType.h"

typedef void(^AckCallback)(id args);

typedef void(^NormalCallback)(id args, SocketAckEmitter* ackEmitter);

typedef void(^OnAckCallback)(int timeoutAfter, AckCallback callback);


@interface Probe : NSObject

@property (nonatomic, copy) NSString* msg;
@property (nonatomic, assign) SocketEnginePacketType type;
@property (nonatomic, readonly) NSArray* data;

@end

typedef NSMutableArray<Probe*> ProbeWaitQueue;

typedef struct ParseResult {
    __unsafe_unretained NSString *message;
    __unsafe_unretained SocketPacket *socketPacket;
} ParseResult;

typedef struct ParseArrayResult {
    __unsafe_unretained NSString *message;
    __unsafe_unretained NSArray *array;
} ParseArrayResult;

typedef struct BinaryContainer {
    __unsafe_unretained NSData *data;
    __unsafe_unretained NSString *string;

} BinaryContainer;
