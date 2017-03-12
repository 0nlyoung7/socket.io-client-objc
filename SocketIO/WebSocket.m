#import "WebSocket.h"

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
static NSString *const WebsocketDidConnectNotification = @"WebsocketDidConnectNotification";
static NSString *const WebsocketDidDisconnectNotification = @"WebsocketDidDisconnectNotification";
static NSString *const WebsocketDisconnectionErrorKeyName = @"WebsocketDisconnectionErrorKeyName";

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

#define kHttpSwitchProtocolCode 101

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
        self.origin = [url absoluteString];
        
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

- (void)disconnect:(NSTimeInterval) forceTimeout closeCode:(UInt16) closeCode  {
    
    if( forceTimeout > 0 ){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, forceTimeout * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self disconnectStream:nil];
        });
    } else if ( forceTimeout == 0 ){
         [self writeError:Normal];
    }
    [self disconnectStream:nil];
}

- (void)writeString:(NSString*)string {
    if(string) {
        [self dequeueWrite:[string dataUsingEncoding:NSUTF8StringEncoding]
                  code:TextFrame];
    }
}

- (void)writePing:(NSData*)data {
    [self dequeueWrite:data code:OpPing];
}

- (void)writeData:(NSData*)data {
    [self dequeueWrite:data code:BinaryFrame];
}

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
    
    NSData *serializedRequest = (__bridge_transfer NSData *)(CFHTTPMessageCopySerializedMessage(urlRequest));
    [self initStreamsWithData:serializedRequest port:port];
    CFRelease(urlRequest);
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

/////////////////////////////////////////////////////////////////////////////
//Sets up our reader/writer for the TCP stream.
- (void)initStreamsWithData:(NSData*)data port:(NSNumber*)port {
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.url.host, [port intValue], &readStream, &writeStream);
    
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.inputStream.delegate = self;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    self.outputStream.delegate = self;
    if([self.url.scheme isEqualToString:@"wss"] || [self.url.scheme isEqualToString:@"https"]) {
        [self.inputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
        [self.outputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
    
        if(self.disableSSLCertValidation) {
            NSString *chain = (__bridge_transfer NSString *)kCFStreamSSLValidatesCertificateChain;
            NSString *peerName = (__bridge_transfer NSString *)kCFStreamSSLPeerName;
            NSString *key = (__bridge_transfer NSString *)kCFStreamPropertySSLSettings;
            NSDictionary *settings = @{chain: [[NSNumber alloc] initWithBool:NO],
                                       peerName: [NSNull null]};
            [self.inputStream setProperty:settings forKey:key];
            [self.outputStream setProperty:settings forKey:key];
        }
        
    } else {
        self.certValidated = YES; //not a https session, so no need to check SSL pinning
    }

    if(self.voipEnabled) {
        [self.inputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
        [self.outputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    }
    
    self.isRunLoop = YES;
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.inputStream open];
    [self.outputStream open];
    
    size_t dataLen = [data length];
    [self.outputStream write:[data bytes] maxLength:dataLen];
    while (self.isRunLoop) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if(self.security && !self.certValidated && (eventCode == NSStreamEventHasBytesAvailable || eventCode == NSStreamEventHasSpaceAvailable)) {
        SecTrustRef trust = (__bridge SecTrustRef)([aStream propertyForKey:(__bridge_transfer NSString *)kCFStreamPropertySSLPeerTrust]);
        NSString *domain = [aStream propertyForKey:(__bridge_transfer NSString *)kCFStreamSSLPeerName];
        if([self.security isValid:trust domain:domain]) {
            self.certValidated = YES;
        } else {
            [self disconnectStream:[self errorWithDetail:@"Invalid SSL certificate" code:1]];
            return;
        }
    }
    switch (eventCode) {
        case NSStreamEventNone:
            break;
            
        case NSStreamEventOpenCompleted:
            break;
            
        case NSStreamEventHasBytesAvailable:
            if(aStream == self.inputStream) {
                [self processInputStream];
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            break;
            
        case NSStreamEventErrorOccurred:
            [self disconnectStream:[aStream streamError]];
            break;
            
        case NSStreamEventEndEncountered:
            [self disconnectStream:nil];
            break;
            
        default:
            break;
    }
}

- (void)disconnectStream:(NSError*)error {
    if ( error == nil ) {
        [self.writeQueue waitUntilAllOperationsAreFinished];
    } else {
        [self.writeQueue cancelAllOperations];
    }

    [self cleanupStream];
    [self doDisconnect:error];
}

- (void)cleanupStream {
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.outputStream close];
    [self.inputStream close];
    self.outputStream = nil;
    self.inputStream = nil;
    self.isRunLoop = NO;
    _isConnected = NO;
    self.certValidated = NO;
}

- (void)processInputStream {
    @autoreleasepool {
        uint8_t buffer[BUFFER_MAX];
        NSInteger length = [self.inputStream read:buffer maxLength:BUFFER_MAX];
        if(length > 0) {
            BOOL process = NO;
            if(self.inputQueue.count == 0) {
                process = YES;
            }
            [self.inputQueue addObject:[NSData dataWithBytes:buffer length:length]];
            if  (process) {
                [self dequeueInput];
            }
        }
    }
}

- (void)dequeueInput {
    while(self.inputQueue.count > 0) {
        NSData *data = [self.inputQueue objectAtIndex:0];
        NSData *work = data;
        if(self.fragBuffer) {
            NSMutableData *combine = [NSMutableData dataWithData:self.fragBuffer];
            [combine appendData:data];
            work = combine;
            self.fragBuffer = nil;
        }
        if(!self.isConnected) {
            CFIndex responseStatusCode;
             // TODO
            //[self processTCPHandshake:(uint8_t*)work.bytes length:work.length responseStatusCode:&responseStatusCode];
        } else {
             // TODO
            //[self processRawMessage:(uint8_t*)work.bytes length:work.length];
        }
        [self.inputQueue removeObject:data];
    }
}

- (void) processTCPHandshake:(uint8_t*)buffer length:(NSInteger)bufferLen {
    BOOL code = [self processHTTP:buffer length:bufferLen];
    if ( code == YES ){
        _isConnected = YES;
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.queue,^{
            if([self.delegate respondsToSelector:@selector(websocketDidConnect:)]) {
                [weakSelf.delegate websocketDidConnect:self];
            }
            if(weakSelf.onConnect) {
                weakSelf.onConnect();
            }
        });
        
    } else if ( code == NO ){
        [self disconnectStream:[self errorWithDetail:@"Invalid HTTP upgrade" code:(uint64_t)code]];
    }
}

/////////////////////////////////////////////////////////////////////////////
//Finds the HTTP Packet in the TCP stream, by looking for the CRLF.
- (BOOL)processHTTP:(uint8_t*)buffer length:(NSInteger)bufferLen {
    int k = 0;
    NSInteger totalSize = 0;
    for(int i = 0; i < bufferLen; i++) {
        if(buffer[i] == CRLFBytes[k]) {
            k++;
            if(k == 3) {
                totalSize = i + 1;
                break;
            }
        } else {
            k = 0;
        }
    }
    if(totalSize > 0) {
        BOOL status = [self validateResponse:buffer length:totalSize];
        if (status == YES) {
            totalSize += 1; //skip the last \n
            NSInteger  restSize = bufferLen-totalSize;
            if(restSize > 0) {
                // TODO
                // [self processRawMessage:(buffer+totalSize) length:restSize];
            }
        }
        return status;
    }
    return NO;
}



//Validate the HTTP is a 101, as per the RFC spec.
- (BOOL)validateResponse:(uint8_t *)buffer length:(NSInteger)bufferLen {
    CFHTTPMessageRef response = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, NO);
    CFHTTPMessageAppendBytes(response, buffer, bufferLen);
    CFIndex responseStatusCode = CFHTTPMessageGetResponseStatusCode(response);
    BOOL status = ((responseStatusCode) == kHttpSwitchProtocolCode)?(YES):(NO);
    if(status == NO) {
        CFRelease(response);
        return NO;
    }
    NSDictionary *headers = (__bridge_transfer NSDictionary *)(CFHTTPMessageCopyAllHeaderFields(response));
    NSString *acceptKey = headers[headerWSAcceptName];
    CFRelease(response);
    if(acceptKey.length > 0) {
        return YES;
    }
    return NO;
}

-(void)dequeueWrite:(NSData*)data code:(OpCode)code {
    if(!self.isConnected) {
        return;
    }
    if(!self.writeQueue) {
        self.writeQueue = [[NSOperationQueue alloc] init];
        self.writeQueue.maxConcurrentOperationCount = 1;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.writeQueue addOperationWithBlock:^{
        if(!weakSelf || !weakSelf.isConnected) {
            return;
        }
        typeof(weakSelf) strongSelf = weakSelf;
        uint64_t offset = 2; //how many bytes do we need to skip for the header
        uint8_t *bytes = (uint8_t*)[data bytes];
        uint64_t dataLength = data.length;
        NSMutableData *frame = [[NSMutableData alloc] initWithLength:(NSInteger)(dataLength + MaxFrameSize)];
        uint8_t *buffer = (uint8_t*)[frame mutableBytes];
        buffer[0] = FinMask | code;
        if(dataLength < 126) {
            buffer[1] |= dataLength;
        } else if(dataLength <= UINT16_MAX) {
            buffer[1] |= 126;
            *((uint16_t *)(buffer + offset)) = CFSwapInt16BigToHost((uint16_t)dataLength);
            offset += sizeof(uint16_t);
        } else {
            buffer[1] |= 127;
            *((uint64_t *)(buffer + offset)) = CFSwapInt64BigToHost((uint64_t)dataLength);
            offset += sizeof(uint64_t);
        }
        BOOL isMask = YES;
        if(isMask) {
            buffer[1] |= MaskMask;
            uint8_t *maskKey = (buffer + offset);
            int secRan = SecRandomCopyBytes(kSecRandomDefault, sizeof(uint32_t), (uint8_t *)maskKey);
            offset += sizeof(uint32_t);
            
            for (size_t i = 0; i < dataLength; i++) {
                buffer[offset] = bytes[i] ^ maskKey[i % sizeof(uint32_t)];
                offset += 1;
            }
        } else {
            for(size_t i = 0; i < dataLength; i++) {
                buffer[offset] = bytes[i];
                offset += 1;
            }
        }
        uint64_t total = 0;
        while (true) {
            if(!strongSelf.isConnected || !strongSelf.outputStream) {
                break;
            }
            NSInteger len = [strongSelf.outputStream write:([frame bytes]+total) maxLength:(NSInteger)(offset-total)];
            if(len < 0 || len == NSNotFound) {
                NSError *error = strongSelf.outputStream.streamError;
                if(!error) {
                    error = [strongSelf errorWithDetail:@"output stream error during write" code:OutputStreamWriteError];
                }
                [strongSelf doDisconnect:error];
                break;
            } else {
                total += len;
            }
            if(total >= offset) {
                break;
            }
        }
    }];
}

- (void)doDisconnect:(NSError*)error {
    if(!self.didDisconnect) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.queue, ^{
            weakSelf.didDisconnect = YES;
            [weakSelf disconnect];
            if([weakSelf.delegate respondsToSelector:@selector(websocketDidDisconnect:error:)]) {
                [weakSelf.delegate websocketDidDisconnect:weakSelf error:error];
            }
            if(weakSelf.onDisconnect) {
                weakSelf.onDisconnect(error);
            }
        });
    }
}

- (NSError*)errorWithDetail:(NSString*)detail code:(NSInteger)code
{
    return [self errorWithDetail:detail code:code userInfo:nil];
}

- (NSError*)errorWithDetail:(NSString*)detail code:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    details[detail] = NSLocalizedDescriptionKey;
    if (userInfo) {
        [details addEntriesFromDictionary:userInfo];
    }
    return [[NSError alloc] initWithDomain:ErrorDomain code:code userInfo:details];
}

- (void)writeError:(uint16_t)code {
    uint16_t buffer[1];
    buffer[0] = CFSwapInt16BigToHost(code);
    [self dequeueWrite:[NSData dataWithBytes:buffer length:sizeof(uint16_t)] code:ConnectionClose];
}

- (void)dealloc {
    if(self.isConnected) {
        [self disconnect];
    }
}

@end
