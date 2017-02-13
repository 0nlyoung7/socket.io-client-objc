#import "SocketEngineSpec.h"

@implementation SocketEngineSpec : NSObject 
{
    
}

- (NSURL*) urlPollingWithSid
{
    NSURLComponents *com = [[NSURLComponents alloc] initWithURL:self.urlPolling resolvingAgainstBaseURL:false];
    return com.url;
}

@end
