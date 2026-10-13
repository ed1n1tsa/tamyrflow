#import "TFObjCExceptionCatcher.h"

BOOL TFTryObjC(NS_NOESCAPE void (^block)(void)) {
    @try {
        if (block) {
            block();
        }
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"[TamyrFlow] Caught ObjC exception: %@ — %@", exception.name, exception.reason ?: @"");
        return NO;
    }
}
