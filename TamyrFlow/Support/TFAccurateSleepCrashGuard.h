#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Installs a runtime swizzle so Veepoo `VPAccurateSleepModel` parse crashes
/// (`-[__NSCFString year]`) are caught instead of killing the app on connect.
void TFInstallAccurateSleepCrashGuard(void);

NS_ASSUME_NONNULL_END
