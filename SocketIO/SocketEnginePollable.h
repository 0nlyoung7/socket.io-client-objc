#import <Foundation/Foundation.h>
#import "SocketEngineSpec.h"

@protocol SocketEnginePollable <NSObject>

@property (nonatomic, readonly) BOOL invalidated;

@property (nonatomic, copy, nullable) NSMutableArray<NSString *> *postWait;
@property (nonatomic, copy, readonly, nullable) NSURLSession *session;

@property (nonatomic) BOOL waitingForPoll;
@property (nonatomic) BOOL waitingForPost;

@optional

-(void) doPoll;
-(void) sendPollMessage:(NSString* _Nullable) message type:(SocketEnginePacketType)type withData:(NSArray<NSData*> * _Nullable) datas;
-(void) stopPolling;

-(NSMutableURLRequest* _Nonnull) createRequestForPostWithPostWait;

-(void) doRequest:(NSMutableURLRequest* _Nullable) req callbackWith:(void ( ^ _Nullable )(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)) callback;

-(void) doLongPoll:(NSMutableURLRequest* _Nonnull) req;

@end

@interface SocketEnginePollable : NSObject <SocketEngineSpec, SocketEnginePollable>
@end
