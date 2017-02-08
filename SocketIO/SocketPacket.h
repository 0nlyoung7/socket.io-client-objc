#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PacketType) {
    Connect = 0,
    Disconnect = 1,
    Event =2,
    Ack = 3,
    Error = 4,
    BinaryEvent = 5,
    BinaryAck = 6
};

#define kPacketTypeArray @"connect", @"disconnect", @"event", @"ack", @"error", @"binaryEvent", @"binaryAck", nil

@interface SocketPacket : NSObject

@property (nonatomic, assign) NSInteger placeholders;

@property (nonatomic, copy) NSString *nsp;
@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) PacketType type;

@property (nonatomic, copy) NSData *binary;
@property (nonatomic, copy) NSArray *data;
@property (nonatomic, copy) NSArray *args;

@property (nonatomic, copy) NSString* event;
@property (nonatomic, readonly) NSString* description;

+ (void)findType:(NSInteger)binCount ack:(Boolean)ack;

- (SocketPacket*) init:(PacketType)type nsp:(NSString *)nsp;

- (SocketPacket*) init:(PacketType)type nsp:(NSString *)nsp placeholders:(NSInteger)placeholders;

- (SocketPacket*) init:(PacketType)type data:(NSArray *)data id:(NSInteger)id nsp:(NSString *)nsp
    placeholders:(NSInteger)placeholders binary:(NSData *) binary;

@end
