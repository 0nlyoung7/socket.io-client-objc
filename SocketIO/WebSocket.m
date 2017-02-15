#import "WebSocket.h"

NSString *const WebsocketDidConnectNotification = @"WebsocketDidConnectNotification";
NSString *const WebsocketDidDisconnectNotification = @"WebsocketDidDisconnectNotification";
NSString *const WebsocketDisconnectionErrorKeyName = @"WebsocketDisconnectionErrorKeyName";

static NSString *const ErrorDomain = @"WebSocket";

@interface WSResponse : NSObject

@property(nonatomic, assign)BOOL isFin;
@property(nonatomic, assign)OpCode code;
@property(nonatomic, assign)NSInteger bytesLeft;
@property(nonatomic, assign)NSInteger frameCount;
@property(nonatomic, strong)NSMutableData *buffer;

@end

@interface WebSocket () <NSStreamDelegate>

@property(nonatomic, strong, nonnull)NSURL *url;
@property(nonatomic, strong, null_unspecified)NSInputStream *inputStream;
@property(nonatomic, strong, null_unspecified)NSOutputStream *outputStream;
@property(nonatomic, strong, null_unspecified)NSOperationQueue *writeQueue;
@property(nonatomic, assign)BOOL isRunLoop;
@property(nonatomic, strong, nonnull)NSMutableArray *readStack;
@property(nonatomic, strong, nonnull)NSMutableArray *inputQueue;
@property(nonatomic, strong, nullable)NSData *fragBuffer;
@property(nonatomic, strong, nullable)NSMutableDictionary *headers;
@property(nonatomic, strong, nullable)NSArray *optProtocols;
@property(nonatomic, assign)BOOL isCreated;
@property(nonatomic, assign)BOOL didDisconnect;
@property(nonatomic, assign)BOOL certValidated;

@end

//Constant Header Values.
NS_ASSUME_NONNULL_BEGIN
static NSString *const headerWSUpgradeName     = @"Upgrade";
static NSString *const headerWSUpgradeValue    = @"websocket";
static NSString *const headerWSHostName        = @"Host";
static NSString *const headerWSConnectionName  = @"Connection";
static NSString *const headerWSConnectionValue = @"Upgrade";
static NSString *const headerWSProtocolName    = @"Sec-WebSocket-Protocol";
static NSString *const headerWSVersionName     = @"Sec-Websocket-Version";
static NSString *const headerWSVersionValue    = @"13";
static NSString *const headerWSKeyName         = @"Sec-WebSocket-Key";
static NSString *const headerOriginName        = @"Origin";
static NSString *const headerWSAcceptName      = @"Sec-WebSocket-Accept";
NS_ASSUME_NONNULL_END

//Class Constants
static char CRLFBytes[] = {'\r', '\n', '\r', '\n'};
static int BUFFER_MAX = 4096;

// This get the correct bits out by masking the bytes of the buffer.
static const uint8_t FinMask             = 0x80;
static const uint8_t OpCodeMask          = 0x0F;
static const uint8_t RSVMask             = 0x70;
static const uint8_t MaskMask            = 0x80;
static const uint8_t PayloadLenMask      = 0x7F;
static const size_t  MaxFrameSize        = 32;

#define HttpSwitchProtocolCode 101

@implementation WebSocket
{
}

- (instancetype)initWithURL:(NSURL *)url protocols:(NSArray*)protocols
{
    if(self = [super init]) {
        self.certValidated = NO;
        self.voipEnabled = NO;
        self.selfSignedSSL = NO;
        self.queue = dispatch_get_main_queue();
        self.url = url;
        self.readStack = [NSMutableArray new];
        self.inputQueue = [NSMutableArray new];
        self.optProtocols = protocols;
    }
    
    return self;
}

@end
