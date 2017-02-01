#import <Foundation/Foundation.h>

typedef NS_ENUM(unsigned int, PacketType) {
    Connect = 0,
    Disconnect = 1,
    Event =2,
    Ack = 3,
    Error = 4,
    BinaryEvent = 5,
    BinaryAck = 6
};

@interface SocketPacket : NSObject

@property (nonatomic, assign) NSInteger placeholders;

@property (nonatomic, copy) NSString *nsp;
@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) PacketType *type;

@property (nonatomic, copy) NSData *binary;
@property (nonatomic, copy) NSArray *data;
@property (nonatomic, copy) NSArray *args;

-(void) init:(PacketType)type data:(NSArray *)data id:(NSInteger)id nsp:(NSString *)nsp
    placeholders:(NSInteger)placeholders binary:(NSData *) binary;

@end
