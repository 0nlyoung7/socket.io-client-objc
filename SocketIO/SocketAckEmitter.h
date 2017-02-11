#import <Foundation/Foundation.h>

#import "SocketIOClient.h"

@interface SocketAckEmitter : NSObject

@property (nonatomic, assign) SocketIOClient socket;
@property (nonatomic, assign) NSInteger ackNum;

- (instancetype)init:(SocketIOClient) socket ackNum:(NSInteger)ackNum;

@end
