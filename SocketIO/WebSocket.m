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
        //self.selfSignedSSL = NO;
        self.queue = dispatch_get_main_queue();
        self.url = url;
        self.readStack = [NSMutableArray new];
        self.inputQueue = [NSMutableArray new];
        self.optProtocols = protocols;
    }
    
    return self;
}

- (void)connect {
    if(self.isCreated) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.queue, ^{
        weakSelf.didDisconnect = NO;
    });
    
    //everything is on a background thread.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        weakSelf.isCreated = YES;
        [weakSelf createHTTPRequest];
        weakSelf.isCreated = NO;
    });
}

/**
- (void)disconnect {
    [self writeError:JFRCloseCodeNormal];
}
 */

- (void) createHTTPRequest {
    CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)self.url.absoluteString, NULL);
    CFStringRef requestMethod = CFSTR("GET");
    CFHTTPMessageRef urlRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault,
                                                             requestMethod,
                                                             url,
                                                             kCFHTTPVersion1_1);
    CFRelease(url);
    
    NSNumber *port = _url.port;
    if (!port) {
        if([self.url.scheme isEqualToString:@"wss"] || [self.url.scheme isEqualToString:@"https"]){
            port = @(443);
        } else {
            port = @(80);
        }
    }
    NSString *protocols = nil;
    if([self.optProtocols count] > 0) {
        protocols = [self.optProtocols componentsJoinedByString:@","];
    }
    [self addHeader:urlRequest key:headerWSHostName val:headerWSUpgradeValue];
    [self addHeader:urlRequest key:headerWSConnectionName val:headerWSConnectionValue];
    if (protocols.length > 0) {
        [self addHeader:urlRequest key:headerWSProtocolName val:protocols];
    }
    [self addHeader:urlRequest key:headerWSVersionName val:headerWSVersionValue];
    [self addHeader:urlRequest key:headerWSKeyName val:[self generateWebSocketKey]];
    
    if( self.origin != nil ){
        [self addHeader:urlRequest key:headerOriginName val:[self origin]];
    }
    
    [self addHeader:urlRequest key:headerWSHostName val:[NSString stringWithFormat:@"%@:%@",self.url.host,port]];
    for(NSString *key in self.headers) {
        [self addHeader:urlRequest key:key val:self.headers[key]];
    }
}

-(void) addHeader:(CFHTTPMessageRef) urlRequset key:(NSString *)key val:(NSString *)val {
    CFHTTPMessageSetHeaderFieldValue(urlRequset, (__bridge CFStringRef)key, (__bridge CFStringRef)val);
}

/////////////////////////////////////////////////////////////////////////////
//Random String of 16 lowercase chars, SHA1 and base64 encoded.
- (NSString*)generateWebSocketKey {
    NSInteger seed = 16;
    NSMutableString *string = [NSMutableString stringWithCapacity:seed];
    for (int i = 0; i < seed; i++) {
        [string appendFormat:@"%C", (unichar)('a' + arc4random_uniform(25))];
    }
    return [[string dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}

@end
