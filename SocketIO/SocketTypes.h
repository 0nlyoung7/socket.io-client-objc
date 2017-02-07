
#import "SocketPacket.h"

typedef struct ParseResult {
    __unsafe_unretained NSString *message;
    __unsafe_unretained SocketPacket *socketPackets;
} ParseResult;
