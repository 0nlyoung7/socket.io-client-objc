
#import "SocketPacket.h"
#import "SocketAckEmitter.h"

typedef void(^AckCallback)(id args);

typedef void(^NormalCallback)(id args, SocketAckEmitter* ackEmitter);

typedef void(^OnAckCallback)(int timeoutAfter, AckCallback callback);

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

