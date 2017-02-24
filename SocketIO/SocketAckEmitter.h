#import <Foundation/Foundation.h>

#import "SocketIOClient.h"

@interface SocketAckEmitter : NSObject

@property (nonatomic, copy) SocketIOClient *socket;
@property (nonatomic, assign) NSInteger ackNum;

- (instancetype)initWithSocket:(SocketIOClient*) socket ackNum:(NSInteger)ackNum;

- (void)with:(NSArray*) items;

@end
