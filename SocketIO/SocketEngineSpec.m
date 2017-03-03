#import "SocketEngineSpec.h"
#import "SocketTypes.h"

@implementation SocketEngineSpec : NSObject 
{
    }

- (NSURL*) urlPollingWithSid
{
    NSURLComponents *com = [[NSURLComponents alloc] initWithURL:self.urlPolling resolvingAgainstBaseURL:false];
    return com.URL;
}

- (NSURL*) urlWebSocketWithSid
{
    NSURLComponents *com = [[NSURLComponents alloc] initWithURL:self.urlWebSocket resolvingAgainstBaseURL:false];
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    NSString *urlEncoded = [self.sid stringByAddingPercentEncodingWithAllowedCharacters:set];
    
    NSString *percentEncodedQuery;
    if ( [self.sid isEqualToString:@""]){
        percentEncodedQuery = @"";
    } else {
        percentEncodedQuery = [[self.sid stringByAppendingString:@"&sid="] stringByAppendingString:urlEncoded];
    }
    com.percentEncodedQuery = percentEncodedQuery;
    return com.URL;
}

-(BinaryContainer) createBinaryDataForSend:(NSData*) data{
    //TODO impl this
    struct BinaryContainer binaryContainer;
    if( self.websocket ){
        
        NSMutableData *mutableData = [[NSMutableData alloc]init];
        [mutableData appendData:data];
        
        binaryContainer.data = mutableData;
        
    } else {
        NSString *str = [@"b4" stringByAppendingString:[data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
        
        binaryContainer.string = str;
    }
    
    return binaryContainer;
}

-(void) send:(NSString*) msg withData:(NSData*) datas{
    NSArray *dataArray = [[NSArray alloc] initWithObjects:datas, nil];
    [self write:msg withType:Message withData:dataArray];
}

@end
