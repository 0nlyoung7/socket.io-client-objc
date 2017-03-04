#import <Foundation/Foundation.h>

#import "SocketIOClient.h"

@interface SocketAckEmitter : NSObject

@property (nonatomic, copy) SocketIOClient *socket;
@property (nonatomic, assign) int ackNum;

- (instancetype)initWithAckNum:(SocketIOClient*) socket ackNum:(int)ackNum;

- (void)with:(NSArray*) items;

@end
