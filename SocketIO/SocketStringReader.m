#import "SocketStringReader.h"

#import <Foundation/Foundation.h>

@implementation SocketStringReader
{
    
}

- (Boolean) hasNext
{
    return ( self.currentIndex != [self.message length] - 1 );
}

- (unichar) currentCharacter
{
    return [self.message characterAtIndex:self.currentIndex];
}

- (void) init:(NSString*) message{
    self.message = message;
    self.currentIndex = 0;
}

- (NSUInteger) advance:(NSUInteger) by __attribute__((warn_unused_result)){
    self.currentIndex = self.currentIndex + by;
    return self.currentIndex;
}

- (NSString*) read:(NSUInteger) count{
    
    NSString* readString = [self.message substringWithRange:NSMakeRange(8, 6)];
    [self advance:count];
    
    return readString;
}

@end
