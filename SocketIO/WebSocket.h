#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import "SSLSecurity.h"

@protocol WebSocketDelegate <NSObject>

@end

FOUNDATION_EXPORT NSString *const WebsocketDidConnectNotification;
FOUNDATION_EXPORT NSString *const WebsocketDidDisconnectNotification;
FOUNDATION_EXPORT NSString *const WebsocketDisconnectionErrorKeyName;

@interface WebSocket : NSObject <NSStreamDelegate>
    
typedef NS_ENUM(uint8_t, OpCode) {
    ContinueFrame = 0x0,
    TextFrame = 0x1,
    BinaryFrame = 0x2,
    ConnectionClose = 0x8,
    Ping = 0x8,
    Pong = 0xA
};

typedef NS_ENUM(uint16_t, CloseCode) {
    Normal = 1000,
    GoingAway = 1001,
    ProtocolError = 1002,
    ProtocolUnhandledType = 1003,
    NoStatusReceived = 1005,
    Encoding = 1007,
    PolicyViolated = 1008,
    MessageTooBig = 1009
};

typedef NS_ENUM(uint16_t, InternalErrorCode) {
    OutputStreamWriteError = 1
};

@property(nonatomic,weak, nullable)id<WebSocketDelegate>delegate;
@property(nonatomic, readonly, nonnull) NSURL *url;

- (nonnull instancetype)initWithURL:(nonnull NSURL *)url protocols:(nullable NSArray*)protocols;

- (void)connect;

- (void)disconnect;

- (void)writeData:(nonnull NSData*)data;

- (void)writeString:(nonnull NSString*)string;

- (void)writePing:(nonnull NSData*)data;

- (void)addHeader:(nonnull CFHTTPMessageRef)urlRequset key:(nonnull NSString*)key value:(nonnull NSString*)val;

@property(nonatomic, strong, nullable)void (^onConnect)(void);

@property(nonatomic, strong, nullable)void (^onDisconnect)(NSError*_Nullable);

@property(nonatomic, strong, nullable)void (^onText)(NSString*_Nullable);

@property(nonatomic, strong, nullable)void (^onData)(NSData*_Nullable);

@property(nonatomic, strong, nullable)void (^onPong)(NSData*_Nullable);

@property(nonatomic, strong, nullable)NSMutableDictionary *headers;
@property(nonatomic, assign) BOOL voipEnabled;
@property(nonatomic, assign) BOOL disableSSLCertValidation;
@property(nonatomic, strong, nullable)SSLSecurity *security;

@property(nonatomic, strong, nullable)NSString *origin;
@property(nonatomic, assign, readonly)BOOL isConnected;

@property(nonatomic, strong, nullable)dispatch_queue_t queue;

@end
