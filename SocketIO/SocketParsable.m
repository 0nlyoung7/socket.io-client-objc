#import "SocketParsable.h"
#import "SocketPacket.h"
#import "SocketTypes.h"
#import "SocketStringReader.h"

@implementation SocketParsable
{
    
}

@synthesize nsp = _nsp;

- (Boolean) isCorrectNamespace:(NSString*) nsp {
    return [_nsp isEqual: nsp];
}

- (void) handleConnect:(NSString*) packetNamespace {
    if( [packetNamespace isEqual:@"/"] && ![_nsp isEqual: @"/"] ){
        [self joinNamespace:_nsp];
    } else {
        [self didConnect];
    }
}

- (void) handlePacket:(SocketPacket*) pack {
    switch ( pack.type ) {
        case Event:
            if( [self isCorrectNamespace:pack.nsp] ) {
                [self handleEvent:pack.event data:pack.args isInternalMessage:true withAck:pack.id];
                break;
            }
        case Ack:
            if( [self isCorrectNamespace:pack.nsp] ) {
                [self handleAck:pack.id data:pack.data];
                break;
            }
        case BinaryEvent:
            if( [self isCorrectNamespace:pack.nsp] ) {
                // TODO : waitingPackets.append(pack)
                break;
            }
        case BinaryAck:
            if( [self isCorrectNamespace:pack.nsp] ) {
                // TODO : waitingPackets.append(pack)
                break;
            }
        case Connect:
            if( [self isCorrectNamespace:pack.nsp] ) {
                [self handleConnect:pack.nsp];
                break;
            }
        case Disconnect:
            if( [self isCorrectNamespace:pack.nsp] ) {
                [self didDisconnect:@"Got disconnect"];
                break;
            }
        case Error:
            if( [self isCorrectNamespace:pack.nsp] ) {
                [self handleEvent:@"error" data:pack.data isInternalMessage:true withAck:pack.id];
                break;
            }
        default:
            // DefaultSocketLogger.Logger.log("Got invalid packet: %@", type: "SocketParser", args: pack.description)
            break;
            
    }
}

- (ParseResult) parseString:(NSString*) message {
    SocketStringReader *reader = [[SocketStringReader alloc] init:message];
    struct ParseResult parseResult;
    
    NSInteger type = [[reader read:1] integerValue];

    if ( !(type >= Connect && type <= BinaryAck) ){
        parseResult.message = @"Invalid packet type";
        return parseResult;
    }
    
    if( ![reader hasNext] ){
        SocketPacket *socketPacket = [[SocketPacket alloc] init:type nsp:@"/" ];
        parseResult.socketPacket = socketPacket;
        return parseResult;
    }
    
    NSString *namespace = @"/";
    NSInteger placeholders = -1;
    
    
    /** TODO : Impl this;
    if ( type == BinaryEvent || type == BinaryAck ) {
        if let holders = Int(reader.readUntilOccurence(of: "-")) {
            placeholders = holders
        } else {
            parseResult.message = @"Invalid packet type";
            return parseResult;
        }
    }
     */
    
    if ( reader.currentCharacter == '/' ) {
        namespace = [reader readUntilOccurence:@","];
    }

    if( ![reader hasNext] ){
        SocketPacket *socketPacket = [[SocketPacket alloc] init:type nsp:namespace placeholders:placeholders];
        parseResult.socketPacket = socketPacket;
        return parseResult;
    }
    
    NSString* idString = @"";
    
    NSString *dataArray = [message substringFromIndex:reader.currentIndex+1];
    
    if (type == Error && ![dataArray hasPrefix:@"["] && ![dataArray hasSuffix:@"]"] ) {
        dataArray = [ [@"[" stringByAppendingString:dataArray ] stringByAppendingString:@"]" ];
    }
    
    ParseArrayResult parseArrayResult = [self parseData:dataArray];
    if( parseArrayResult.array ){
        SocketPacket *socketPacket = [[SocketPacket alloc] initWithData:type data:parseArrayResult.array id:-1 nsp:namespace placeholders:placeholders binary:nil];
        parseResult.socketPacket = socketPacket;
    } else {
        parseResult.message = parseArrayResult.message;
    }
    
    return parseResult;
}

- (ParseArrayResult) parseData:(NSString*) str {
    
    struct ParseArrayResult parseArrayResult;

    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *e = nil;
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &e];
    
    if (!jsonArray) {
        parseArrayResult.message = @"Error parsing data for packet";
    } else {
        parseArrayResult.array = jsonArray;
    }
        
    return parseArrayResult;
}

- (void) parseSocketMessage:(NSString*)message{
    if ( ![self isStringEmpty:message] ) {
        //      DefaultSocketLogger.Logger.log("Parsing %@", type: "SocketParser", args: message)
        struct ParseResult parseResult;
        
        parseResult = [self parseString:message];
        if( parseResult.socketPacket ){
            [self handlePacket:parseResult.socketPacket];
        } else {
            // DefaultSocketLogger.Logger.log("Decoded packet as: %@", type: "SocketParser", args: pack.description)
        }
    }
}

// TODO : impl this;
- (void) parseBinaryData:(NSData*) data{
    if ( self.waitingPackets == nil || self.waitingPackets.count == 0) {
         self.waitingPackets = [[NSMutableArray alloc]init];
    }
    
    [self.waitingPackets addObject:data];
}

- (BOOL)isStringEmpty:(NSString *)string {
    if([string length] == 0) { //string is empty or nil
        return YES;
    }
    
    if(![[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        //string is all whitespace
        return YES;
    }
    
    return NO;
}

@end
