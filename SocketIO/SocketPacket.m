#import "SocketPacket.h"

#import <Foundation/Foundation.h>

@implementation SocketPacket
{
    
}
    
- (void) init:(PacketType)type data:(NSArray *)data id:(NSInteger)id nsp:(NSString *)nsp
    placeholders:(NSInteger)placeholders binary:(NSData *) binary
{
    self.type = type;
    self.data = data;
    self.id = id;
    self.nsp = nsp;
    self.placeholders = placeholders;
    self.binary = binary;
}

- (NSString*) completeMessage:(NSString*)message
{
    if ( self.data.count == 0 )
    {
        return [message stringByAppendingString:@"[]"];
    }
    
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.data options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    if( error != nil )
    {
        return [message stringByAppendingString:@"[]"];
    }

    return [message stringByAppendingString:jsonString];
}


- (NSString*) createPacketString {
    NSString *typeString = [self packeyTypeEnumToString:self.type];
    // Binary count?

    
    NSString *tmpString = @"";
    
    switch (self.type){
        case BinaryAck:
            tmpString = @"\(String(binary.count))-";
            break;
        case BinaryEvent:
            tmpString = @"\(String(binary.count))-";
            break;
        default:
            break;
    }
    
    NSString *binaryCountString = [typeString stringByAppendingString:tmpString];
    
    
    NSString *tmpString1 = @"";
    if( ![self.nsp isEqual: @"/"] ){
        tmpString1 = @"\(nsp),";
    }
    
    NSString *tmpString2 = @"";
    if( !(self.id != -1) ){
        tmpString2 = [NSString stringWithFormat: @"%ld", (long)self.id];
    }


    // Namespace?
    NSString *nspString = [binaryCountString stringByAppendingString:tmpString1];
    // Ack number?
    NSString *idString = [nspString stringByAppendingString:tmpString2];
    
    return [self completeMessage:idString];
}


-(NSString*) packeyTypeEnumToString:(PacketType)enumVal
{
    NSArray *packetTypeArray = [[NSArray alloc] initWithObjects:kPacketTypeArray];
    return [packetTypeArray objectAtIndex:enumVal];
}

@end
