#import <Foundation/Foundation.h>

@interface SocketIOClientOption : NSObject

@property (nonatomic, assign) NSInteger placeholders;

@property (nonatomic, copy)   NSMutableDictionary *connectParams;
@property (nonatomic, copy)    NSMutableDictionary *cookies;
@property (nonatomic, assign) BOOL doubleEncodeUTF8;

@end
