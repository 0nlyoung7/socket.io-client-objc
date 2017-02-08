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

- (SocketStringReader*) init:(NSString*) message{
    
    self = [super init];
    if (self) {
        self.message = message;
        self.currentIndex = 0;
    }
    return self;
}

- (NSUInteger) advance:(NSUInteger) by __attribute__((warn_unused_result)){
    self.currentIndex = self.currentIndex + by;
    return self.currentIndex;
}

- (NSString*) read:(NSUInteger) count{
    
    NSString* readString = [self.message substringWithRange:NSMakeRange(_currentIndex, count)];
    [self advance:count];
    
    return readString;
}

- (NSString*) readUntilOccurence:(NSString *) keyword {
    
    
    NSString* substring = [self.message substringFromIndex:_currentIndex];

    
    NSRange range = [substring rangeOfString:keyword];
    
    NSLog(@"range: %@", NSStringFromRange(range));
    
    if (range.location == NSNotFound) {
        NSLog(@"string was not found");
        return substring;
    } else {
        NSLog(@"position %lu", (unsigned long)range.location);
    }
    
    [self advance:( range.location + [keyword length] -1 )];
    return [substring substringToIndex:range.location];
}

@end
