#import <Foundation/Foundation.h>
#import "SocketEnginePollable.h"
#import "SocketStringReader.h"

@implementation SocketEnginePollable : NSObject
{
    
}

-(void) addHeader:(NSMutableURLRequest*) req {
    if( self.cookies != NULL ){
        NSDictionary<NSString *, NSString *> *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:self.cookies];
        req.allHTTPHeaderFields = headers;
    }
    
    if( self.extraHeaders != NULL ){
        
        for (NSString* key in self.extraHeaders) {
            [req setValue:key forHTTPHeaderField:[self.extraHeaders objectForKey:key] ];
        }
        
    }
}

-(void) doRequest:(NSMutableURLRequest*) req callbackWith:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)) callback{
    
    if( !self.polling || self.closed || self.invalidated || self.fastUpgrade ) {
        
    } else {
        
        [ [self.session dataTaskWithRequest:req completionHandler:callback] resume ];
        
    }
    
}

-(void) doPoll {
    if (self.websocket || self.waitingForPoll || !self.connected || self.closed ){
        
    } else {
        self.waitingForPoll = true;
        
        NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:self.urlPollingWithSid];
        [self addHeader:req];
        
        [self doLongPoll:req];
    }
}

-(void) doLongPoll:(NSMutableURLRequest*) req {
    //TODO
    __weak typeof(self) weakSelf = self;
    
    [self doRequest:req
       callbackWith:^(NSData *data, NSURLResponse *res, NSError *err) {
           if( !weakSelf.polling ){
               return;
           }

           if( err != NULL || data == NULL ){
               if( weakSelf.polling ){
                   NSString *errorMsg = @"Error";
                   if( err.localizedDescription != NULL ){
                       errorMsg = err.localizedDescription;
                   }
                   
                   [self didError:errorMsg];
               }
               
               return;
           }
           
           NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
           
           dispatch_async(weakSelf.parseQueue ,^{
               [self parsePollingMessage:str];
           });
           
           
           weakSelf.waitingForPoll = false;
           
           if( weakSelf.fastUpgrade ){
               [self doFastUpgrade];
           } else if( !weakSelf.closed && weakSelf.polling ){
               [self doPoll];
           }
       }
    ];
}

-(void) parsePollingMessage:(NSString*) str{
    if( str.length == 1 ){
        SocketStringReader *reader = [[SocketStringReader alloc] init:str];
        while( reader.hasNext ){
            NSString *str = [reader readUntilOccurence:@":"];
            int n = [reader indexOf:@":"];
            
            if( n >= 0 ){
                dispatch_async(self.handleQueue ,^{
                    [self parseEngineMessage:str fromPolling: true];
                });
            } else {
                dispatch_async(self.handleQueue ,^{
                    [self parseEngineMessage:str fromPolling: true];
                });
                break;
            }
        }
    }
}

-(void) sendPollMessage:(NSString*) message type:(SocketEnginePacketType)type withData:(NSArray<NSData*> *) datas{
    NSString *fixedMessage = @"";
    
    if( self.doubleEncodeUTF8 ){
        // TODO
        //fixedMessage = [self doubleEncodeUTF8:message];
    } else {
        fixedMessage = message;
    }
    
   NSString *typeStr = [NSString stringWithFormat: @"%ld", (long)type];
   [self.postWait addObject:[typeStr stringByAppendingString:fixedMessage] ];
    
    for (id data in datas) {
        //TODO
    }
}

-(void) stopPolling {
    self.waitingForPoll = FALSE;
    self.waitingForPost = FALSE;
    if( self.session != NULL ){
        [self.session finishTasksAndInvalidate];
    }
}

@end
