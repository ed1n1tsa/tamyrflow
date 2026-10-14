#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Runs `block` inside `@try/@catch`. Returns YES on success, NO if an NSException was thrown.
/// Does not catch faults that happen later on another runloop callback.
BOOL TFTryObjC(NS_NOESCAPE void (^block)(void));

NS_ASSUME_NONNULL_END
