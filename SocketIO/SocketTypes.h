#import <Foundation/Foundation.h>

#import "SocketEnginePacketType.h"

@class SocketIOClient;
@class SocketAckEmitter;
@class SocketPacket;

typedef void(^AckCallback)(id _Nullable args );

typedef void(^NormalCallback)(id _Nullable args, SocketAckEmitter *_Nullable ackEmitter);

typedef void(^OnAckCallback)(int timeoutAfter, AckCallback _Nullable callback);


@interface Probe : NSObject

@property (nonatomic, copy, nullable) NSString* msg;
@property (nonatomic, assign) SocketEnginePacketType type;
@property (nonatomic, copy, nullable) NSArray* data;

@end

typedef NSMutableArray<Probe*> ProbeWaitQueue;

typedef struct ParseResult {
    __unsafe_unretained NSString *_Nullable message;
    __unsafe_unretained SocketPacket *_Nullable socketPacket;
} ParseResult;

typedef struct ParseArrayResult {
    __unsafe_unretained NSString *_Nullable message;
    __unsafe_unretained NSArray *_Nullable array;
} ParseArrayResult;

typedef struct BinaryContainer {
    __unsafe_unretained NSData *_Nullable data;
    __unsafe_unretained NSString *_Nullable string;

} BinaryContainer;
