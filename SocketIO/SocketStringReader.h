#import <Foundation/Foundation.h>

@interface SocketStringReader : NSObject

@property (nonatomic, copy) NSString* message;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, readonly) Boolean hasNext;
@property (nonatomic, readonly) unichar currentCharacter;


@end
