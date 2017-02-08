
#import "SocketPacket.h"

typedef struct ParseResult {
    __unsafe_unretained NSString *message;
    __unsafe_unretained SocketPacket *socketPacket;
} ParseResult;

typedef struct ParseArrayResult {
    __unsafe_unretained NSString *message;
    __unsafe_unretained NSArray *array;
} ParseArrayResult;
