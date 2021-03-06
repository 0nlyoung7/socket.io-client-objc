#import <Foundation/Foundation.h>
#import "SocketEnginePollable.h"
#import "SocketStringReader.h"
#import "SocketTypes.h"

@implementation SocketEnginePollable : NSObject
{
    
}

-(void) addHeader:(NSMutableURLRequest*) req
{
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

-(NSMutableURLRequest*) createRequestForPostWithPostWait
{
    NSString *postStr = @"";
    
    for( NSString* key in self.postWait){
        NSString *dataItem = [NSString stringWithFormat:@"%d:%@", (int)[key length], key];
        [postStr stringByAppendingString:dataItem];
    }
    
    NSData *postData = [postStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
    
    
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:self.urlPollingWithSid];
    [self addHeader:req];
    
    [req setHTTPMethod:@"POST"];
    
    [req setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    
    [req setHTTPBody:postData];
    [req setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [self.postWait removeAllObjects];
    
    return req;
    
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

#pragma mark SocketEnginePollable
-(void) doRequest:(NSMutableURLRequest*) req callbackWith:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)) callback{
    
    if( !self.polling || self.closed || self.invalidated || self.fastUpgrade ) {
        
    } else {
        
        [ [self.session dataTaskWithRequest:req completionHandler:callback] resume ];
        
    }
    
}

#pragma mark SocketEnginePollable
-(void) doLongPoll:(NSMutableURLRequest*) req {
    
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
           
           [weakSelf setWaitingForPoll:FALSE];
           
           if( weakSelf.fastUpgrade ){
               [self doFastUpgrade];
           } else if( !weakSelf.closed && weakSelf.polling ){
               [self doPoll];
           }
       }
    ];
}

-(void) flushWaitingForPost{
    if ( self.websocket ){
        [self flushWaitingForPostToWebSocket];
    } else if( self.postWait.count != 0 && self.connected  ){
        NSMutableURLRequest* req = [self createRequestForPostWithPostWait];
        
        [self setWaitingForPost:TRUE];
        
        __weak typeof(self) weakSelf = self;
        
        [self doRequest:req
           callbackWith:^(NSData *data, NSURLResponse *res, NSError *err) {
               
               if( weakSelf == NULL ){
                   return;
               }
               
               if( err != NULL ){
                   
                   if( weakSelf.polling ){
                       NSString *errorMsg = @"Error";
                       if( err.localizedDescription != NULL ){
                           errorMsg = err.localizedDescription;
                       }
                       
                       [self didError:errorMsg];
                   }
                   
                   return;
               }
               
               
               [weakSelf setWaitingForPost:FALSE];
               
               dispatch_async(weakSelf.emitQueue ,^{
                   if( ! weakSelf.fastUpgrade ){
                       [self flushWaitingForPost];
                       [self doPoll];
                   }
               });
           }
         ];
    }
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
    
    for (NSData *data in datas) {
        
        BinaryContainer bc = [self createBinaryDataForSend:data];
        if( !bc.string ){
            [self.postWait addObject:bc.string];
        }

    }
    
    if( !self.waitingForPost){
        [self flushWaitingForPost];
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
