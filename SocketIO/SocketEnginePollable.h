#import <Foundation/Foundation.h>
#import "SocketEngineSpec.h"

@interface SocketEnginePollable : NSObject<SocketEngineSpec>

@property (nonatomic, readonly) BOOL invalidated;

@property (nonatomic, copy) NSMutableArray<NSString *> *postWait;
@property (nonatomic, copy, readonly) NSURLSession *session;

@property (nonatomic) BOOL waitingForPoll;
@property (nonatomic) BOOL waitingForPost;

-(void) doPoll;

-(void) sendPollMessage:(NSString*) message type:(SocketEnginePacketType)type withData:(NSArray<NSData*> *) datas;

-(void) stopPolling;

@end
