#import <Foundation/Foundation.h>
#import "SocketEngine.h"
#import "SocketEnginePacketType.h"
#import "SocketTypes.h"
#import "SocketStringReader.h"

@implementation SocketEngine
{
    
}

-(void) setPingTimeout:(double)pingTimeout{
    self.pingTimeout = pingTimeout;
    
    if( self.pingInterval == 0 ){
        self.pingInterval = 25;
    }
    
    self.pongsMissedMax = (int) ( pingTimeout / self.pingInterval );
}

-(instancetype) initWithOption:(SocketEngineClient*) client url:(NSURL*) url config:(NSMutableDictionary*) config {
    
    self = [[SocketEngine alloc] init];
    _socketPath = @"/engine.io/";
    
    self.client = client;
    self.url = url;
    
    for( NSString* key in config ){
        if( [key isEqual:@"connectParams"] ){
            _connectParams = config[key];
        } else if( [key isEqual:@"cookies"] ){
            _cookies = config[key];
        } else if( [key isEqual:@"doubleEncodeUTF8"] ){
            _doubleEncodeUTF8 = config[key];
        } else if( [key isEqual:@"extraHeaders"] ){
            _extraHeaders = config[key];
        } else if( [key isEqual:@"sessionDelegate"] ){
            _sessionDelegate = config[key];
        } else if( [key isEqual:@"forcePolling"] ){
            _forcePolling = config[key];
        } else if( [key isEqual:@"forceWebsockets"] ){
            _forceWebsockets = config[key];
        } else if( [key isEqual:@"path"] ){
            _socketPath = config[key];
            
            if( [_socketPath hasSuffix:@"/"] ){
                [_socketPath stringByAppendingString:@"/"];
            }
        } else if( [key isEqual:@"voipEnabled"] ){
            _voipEnabled = config[key];
        } else if( [key isEqual:@"secure"] ){
            _secure = config[key];
        } else if( [key isEqual:@"selfSigned"] ){
            _selfSigned = config[key];
        } else if( [key isEqual:@"security"] ){
            _security = config[key];
        }
    }
    
    self.sessionDelegate = self;
    
    [self createURLs];
    
    return self;
}


- (void) dealloc {
    [self setClosed:TRUE];
    [self stopPolling];
}

- (void) checkAndHandleEngineError:(NSString*) str{
    NSDictionary  *dict = [self toNSDictionary:str];
    if( dict[@"message"] ){
        [self didError:dict[@"message"]];
    }
}


- (void) handleBase64:(NSString*) message{
    //썌얘
    // binary in base64 string
    /**
    let noPrefix = message[message.index(message.startIndex, offsetBy: 2)..<message.endIndex]
    
    if let data = NSData(base64Encoded: noPrefix, options: .ignoreUnknownCharacters) {
        client?.parseEngineBinaryData(data as Data)
    }
    */
}

- (void) closeOutEngine:(NSString*) reason{
    [self setSid:@""];
    [self setClosed:TRUE];
    [self setInvalidated:TRUE];
    [self setConnected:FALSE];
    
    if( self.ws ){
        [self.ws disconnect];
        [self stopPolling];
        if( self.client ){
            [self.client engineDidClose:reason];
        }
    }
}

-(void) connect{
    if( self.connected ){
        [self disconnect:@"reconnet"];
    }
    
    [self resetEngine];
    
    if( self.forceWebsockets ){
        [self setPolling:FALSE];
        [self setWebsocket:TRUE];
        
        [self createWebsocketAndConnect];
        return;
    }
    
    NSMutableURLRequest *reqPolling = [[NSMutableURLRequest alloc] initWithURL:self.urlPollingWithSid];
    
    if( self.cookies != NULL ){
        NSDictionary<NSString *, NSString *> *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:self.cookies];
        reqPolling.allHTTPHeaderFields = headers;
    }
    
    if( self.extraHeaders ){
        for( NSString *headerName in self.extraHeaders ){
            [reqPolling setValue:self.extraHeaders[headerName] forHTTPHeaderField:headerName];
        }
    }
    
    [self doLongPoll:reqPolling];
    
}

- (void) createURLs {
    if( self.client == NULL ){
        self.urlPolling = [NSURL URLWithString:@"http://localhost/"];
        self.urlWebSocket = [NSURL URLWithString:@"http://localhost/"];
        return;
    }

    NSURLComponents *urlPolling = [[NSURLComponents alloc] initWithURL:self.url resolvingAgainstBaseURL:false];
    NSURLComponents *urlWebSocket = [[NSURLComponents alloc] initWithURL:self.url resolvingAgainstBaseURL:false];
    
    NSString *queryString = @"";
    
    urlWebSocket.path = _socketPath;
    urlPolling.path = _socketPath;
    
    if( _secure ){
        urlPolling.scheme = @"https";
        urlWebSocket.scheme = @"wss";
    } else {
        urlPolling.scheme = @"http";
        urlWebSocket.scheme = @"ws";
    }
    
    if( _connectParams != NULL ){
        for( NSString* key in _connectParams ){
            NSString *keyEsc = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            
            NSString *tmp = [NSString stringWithFormat:@"(%@)",_connectParams[key] ];
            NSString *valueEsc = [tmp stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            
            queryString = [NSString stringWithFormat:@"&(%@)=(%@)", keyEsc, valueEsc];
        }
    }
    
    urlWebSocket.percentEncodedQuery = [@"transport=websocket" stringByAppendingString:queryString];
    urlPolling.percentEncodedQuery = [@"transport=polling&b64=1" stringByAppendingString:queryString];
    
    self.urlPolling = urlPolling.URL;
    self.urlWebSocket = urlWebSocket.URL;
}

-(void) createWebsocketAndConnect {
    self.ws = [[WebSocket alloc] initWithURL:self.urlPollingWithSid protocols:NULL];
    
    if( self.cookies != NULL ){
        NSDictionary<NSString *, NSString *> *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:self.cookies];
        for( NSString *key in headers ){
            [self.ws setValue:headers[key] forKey:key];
        }
    }
    
    if( self.extraHeaders ){
        for( NSString *key in self.extraHeaders ){
            [self.ws setValue:self.extraHeaders[key] forKey:key];
        }
    }
    
    self.ws.callbackQueue = self.handleQueue;
    self.ws.voipEnabled = self.voipEnabled;
    self.ws.delegate = self;
    self.ws.disableSSLCertValidation = self.selfSigned;
    self.ws.security = self.security;
    
    [self.ws connect];
}

- (void) didError:(NSString*) reason {
    if( self.client ){
        [self.client engineDidError:reason];
        [self disconnect:reason];
    }
}

- (void) disconnect:(NSString*) reason {
    if( !self.connected ){
        [self closeOutEngine:reason];
        return;
    }
    
    if( self.closed ){
        [self closeOutEngine:reason];
        return;
    }
    
    if( self.websocket ){
        [self sendWebSocketMessage:@"" withType:Close withData:@[]];
        [self closeOutEngine:reason];
    } else {
        [self disconnectPolling:reason];
    }
}

- (void) disconnectPolling:(NSString*) reason {
    dispatch_async(self.emitQueue ,^{
        NSString *typeStr = [NSString stringWithFormat: @"%ld", (long)Close];
        [self.postWait addObject:typeStr];
        
        NSMutableURLRequest  *req = [self createRequestForPostWithPostWait];
        [self doRequest:req callbackWith:nil];
        [self closeOutEngine:reason];
    });
}

-(void) doFastUpgrade {
    if (self.waitingForPoll){
        NSLog(@"Outstanding poll when switched to WebSockets, we'll probably disconnect soon. You should report this");
    }
    
    [self sendWebSocketMessage:@"" withType:Upgrade withData:@[]];
    [self setWebsocket:TRUE];
    [self setPolling:FALSE];
    [self setFastUpgrade:FALSE];
    [self setProbing:FALSE];
    
    [self flushProbeWait];

}

-(void) flushProbeWait {
    dispatch_async(self.emitQueue ,^{
        for( Probe *waiter in self.probeWait ){
            [self write:waiter.msg withType:waiter.type withData:waiter.data];
        }
        
        [self.probeWait removeAllObjects];
        
        if( self.postWait.count != 0 ){
            [self flushWaitingForPostToWebSocket];
        }
    });
}

-(void)flushWaitingForPostToWebSocket {
    if( !self.ws ){
        return;
    }
    
    for( NSString *msg in self.postWait ){
        [self.ws writeString:msg];
    }
    
    [self.postWait removeAllObjects];
}

-(void)handleClose:(NSString*) reason {
    if( self.client ){
        [self.client engineDidClose:reason];
    }
}

-(void)handleMessage:(NSString*) message {
    if( self.client ){
        [self.client parseEngineMessage:message];
    }
}

-(void)handleNOOP {
    [self doPoll];
}

-(void)handleOpen:(NSString*) openData{
    NSDictionary  *json = [self toNSDictionary:openData];
    if( !json ){
        [self didError:@"Error parsing open packet"];
        return;
    }
    
    NSString *sid = json[@"sid"];
    if( sid != NULL ){
        [self didError:@"Open packet contained no sid"];
        return;
    }
    
    BOOL upgradeWs;
    
    self.sid = sid;
    self.connected = true;
    
    NSString *upgrades = json[@"upgrades"];
    if( json[@"upgrades"] != NULL ){
        upgradeWs = [upgrades containsString:@"websocket"];
    } else {
        upgradeWs = FALSE;
    }
    
    double pingInterval = [json[@"pingInterval"] doubleValue];
    double pingTimeout = [json[@"pingTimeout"] doubleValue];
    
    if( pingInterval && pingTimeout ) {
        self.pingInterval = pingInterval / 1000.0;
        self.pingTimeout = pingTimeout / 1000.0;
    }
    
    if( !self.forcePolling && !self.forceWebsockets && upgradeWs ){
        [self createWebsocketAndConnect];
    }
    
    [self sendPing];
    
    if( !self.forceWebsockets ){
        [self doPoll];
    }
    
    [self.client engineDidOpen:@"Connect"];
}

- (void) handlePong:(NSString*) message{
    self.pongsMissed = 0;
    
    if( [message isEqualToString:@"3probe"] ){
        [self upgradeTransport];
    }
}

- (void) parseEngineData:(NSData*) data {
    if( self.client ){
        NSData *newData = [data subdataWithRange:NSMakeRange(1, [data length])];
        [self.client parseEngineBinaryData:newData];
    }
}

- (void) parseEngineMessage:(NSString*) message fromPolling:(BOOL) fromPolling {
    SocketStringReader *reader = [[SocketStringReader alloc] init:message];
    NSString *fixedString;
    
    if( [message hasPrefix:@"b4"] ){
        return [self handleBase64:message];
    }
    
    SocketEnginePacketType type = reader.currentCharacter;
    if( !type ){
        [self checkAndHandleEngineError:message];
        return;
    }
    
    if( fromPolling && type != Noop && self.doubleEncodeUTF8 ){
        //fixedString = [self fixDoubleUTF8:message];
    } else {
        fixedString = message;
    }
    
    switch (type) {
        case Message:
            [self handleMessage:[fixedString substringFromIndex:1]];
            break;
        case Noop:
            [self handleNOOP];
            break;
            
        case Pong:
            [self handlePong:fixedString];
            break;
            
        case Open:
            [self handleOpen:[fixedString substringFromIndex:1]];
            break;
            
        case Close:
            [self handleClose:fixedString];
            break;
            
        default:
            break;
    }
}

- (void) resetEngine{
    
    self.closed = FALSE;
    self.connected = FALSE;
    self.fastUpgrade = FALSE;
    self.polling = TRUE;
    self.probing = FALSE;
    self.invalidated = FALSE;
    
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    self.session  = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self.sessionDelegate delegateQueue:mainQueue];
    
    self.sid = @"";
    self.waitingForPoll = FALSE;
    self.waitingForPost = FALSE;
    self.websocket = FALSE;
}

- (void) sendPing{
    if( !self.connected ) {
        return;
    }
    
    if( self.pongsMissed > self.pongsMissedMax ){
        if( self.client ){
            [self.client engineDidClose:@"Ping timeout"];
            return;
        }
    }
    
    if( !self.pingInterval ){
        return;
    }
    
    self.pongsMissed += 1;
    [self write:@"" withType:Ping withData:@[]];
    
    __weak typeof(self) weakSelf = self;
    
    CGFloat deadlinePlus = (CGFloat) (self.pingInterval * NSEC_PER_SEC) / NSEC_PER_SEC;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, deadlinePlus), dispatch_get_main_queue(), ^{
        [weakSelf sendPing];
    });
}

- (void) upgradeTransport{
    if( self.ws && self.ws.isConnected ){
        self.fastUpgrade = true;
        [self sendPollMessage:@"" type:Noop withData:@[]];
    }
}

- (void) write:(NSString*) msg withType:(SocketEnginePacketType)type withData:(NSArray<NSData *> * _Nonnull)data{
    
    dispatch_async(self.emitQueue ,^{
        if( !self.connected ){
            return;
        }
        
        if( self.websocket ){
            [self sendWebSocketMessage:msg withType:type withData:data];
        } else if( !self.probing ){
            [self sendPollMessage:msg type:type withData:data];
        } else {
            Probe *probe = [Probe init];
            probe.msg = msg;
            probe.type = type;
            probe.data = data;
            [self.probeWait addObject:probe];
        }
    });
}


-(void)websocketDidConnect:(WebSocket*) socket{
    if( !self.forceWebsockets ){
        self.probing = true;
        [self probeWebSocket];
    } else {
        self.connected = true;
        self.probing = false;
        self.polling = false;
    }
}

-(void)websocketDidDisconnect:(WebSocket*) socket error:(NSError*) error{
    self.probing = false;
    
    if( self.closed ){
        [self.client engineDidClose:@"Socket Disconnected"];
        return;
    } else {
        [self flushProbeWait];
    }
}

-(void) URLSession:(NSURLSession*)session error:(NSError*) error{
    
    [self didError:@"Engine URLSession became invalid"];
}


- (NSDictionary*) toNSDictionary:(NSString*) str{
    
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    NSError *e = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];
    
    if (!json) {
        NSLog(@"Error parsing JSON: %@", e);
        return nil;;
    }
    
    return json;
}


@end
