#import "SocketParsable.h"
#import "SocketPacket.h"
#import "SocketTypes.h"

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

@end
