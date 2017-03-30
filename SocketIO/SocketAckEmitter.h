#import <Foundation/Foundation.h>
#import "SocketIOClient.h"

@class SocketIOClient;

@interface SocketAckEmitter : NSObject

@property (nonatomic, copy) SocketIOClient *socket;
@property (nonatomic, assign) int ackNum;

- (instancetype)initWithAckNum:(SocketIOClient*) socket ackNum:(int)ackNum;
- (void)with:(NSArray*) items;

@end


@interface OnAckCallback : NSObject

@property (nonatomic, assign) int ackNumber;
@property (nonatomic, copy) NSArray *items;
@property (nonatomic, copy) SocketIOClient *socket;

- (instancetype)initWithSocket:(int)ackNumber items:(NSArray*)items socket:(SocketIOClient*) socket;

- (void) timingOut:(int) seconds callback:(AckCallback) callback;

@end
