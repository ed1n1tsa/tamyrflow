#import "TFAccurateSleepCrashGuard.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <VeepooBleSDK/VPAccurateSleepModel.h>
#import <VeepooBleSDK/VPPeripheralManage.h>

typedef id (*TFModelFactoryIMP)(id, SEL, NSData *, NSInteger, NSInteger);
typedef void (*TFVoidIdIMP)(id, SEL, id);
typedef void (*TFHandleSleepIMP)(id, SEL, id, id, NSInteger, id, NSInteger);
typedef void (*TFHandleModelIMP)(id, SEL, id, NSInteger);

static TFModelFactoryIMP TFOriginalModelFactory = NULL;
static TFVoidIdIMP TFOriginalHandleOneDayAllSleep = NULL;
static TFVoidIdIMP TFOriginalSdkHandleOneDayAllSleep = NULL;
static TFHandleSleepIMP TFOriginalHandleAccurateSleep = NULL;
static TFHandleModelIMP TFOriginalHandleAccurateModel = NULL;

static id TFSafeModelWithAccurateSleepData(id self, SEL _cmd, NSData *data, NSInteger day, NSInteger type) {
    @try {
        if (TFOriginalModelFactory) {
            return TFOriginalModelFactory(self, _cmd, data, day, type);
        }
    } @catch (NSException *exception) {
        NSLog(
            @"[TamyrFlow] VPAccurateSleepModel parse crashed (swallowed): %@ — %@",
            exception.name,
            exception.reason ?: @""
        );
    }
    return nil;
}

static void TFSafeHandleOneDayAllSleepData(id self, SEL _cmd, id sleepData) {
    @try {
        if (TFOriginalHandleOneDayAllSleep) {
            TFOriginalHandleOneDayAllSleep(self, _cmd, sleepData);
        }
    } @catch (NSException *exception) {
        NSLog(
            @"[TamyrFlow] handleOneDayAllSleepData crashed (swallowed): %@ — %@",
            exception.name,
            exception.reason ?: @""
        );
    }
}

static void TFSafeSdkHandleOneDayAllSleepData(id self, SEL _cmd, id sleepData) {
    @try {
        if (TFOriginalSdkHandleOneDayAllSleep) {
            TFOriginalSdkHandleOneDayAllSleep(self, _cmd, sleepData);
        }
    } @catch (NSException *exception) {
        NSLog(
            @"[TamyrFlow] sdk_handleOneDayAllSleepData crashed (swallowed): %@ — %@",
            exception.name,
            exception.reason ?: @""
        );
    }
}

static void TFSafeHandleAccurateSleepData(id self, SEL _cmd, id data, id times, NSInteger day, id mac, NSInteger type) {
    @try {
        if (TFOriginalHandleAccurateSleep) {
            TFOriginalHandleAccurateSleep(self, _cmd, data, times, day, mac, type);
        }
    } @catch (NSException *exception) {
        NSLog(
            @"[TamyrFlow] handleAccurateSleepData crashed (swallowed): %@ — %@",
            exception.name,
            exception.reason ?: @""
        );
    }
}

static void TFSafeHandleAccurateModel(id self, SEL _cmd, id model, NSInteger day) {
    @try {
        if (TFOriginalHandleAccurateModel) {
            TFOriginalHandleAccurateModel(self, _cmd, model, day);
        }
    } @catch (NSException *exception) {
        NSLog(
            @"[TamyrFlow] handleAccurateModle crashed (swallowed): %@ — %@",
            exception.name,
            exception.reason ?: @""
        );
    }
}

static BOOL TFReplaceClassMethod(Class cls, SEL sel, IMP newIMP, IMP *outOriginal) {
    if (cls == Nil || newIMP == NULL || outOriginal == NULL) { return NO; }
    Method method = class_getClassMethod(cls, sel);
    if (method == NULL) {
        NSLog(@"[TamyrFlow] class method missing %@ / %@", NSStringFromSelector(sel), NSStringFromClass(cls));
        return NO;
    }
    *outOriginal = method_setImplementation(method, newIMP);
    return *outOriginal != NULL;
}

static BOOL TFReplaceInstanceMethod(Class cls, SEL sel, IMP newIMP, IMP *outOriginal) {
    if (cls == Nil || newIMP == NULL || outOriginal == NULL) { return NO; }
    Method method = class_getInstanceMethod(cls, sel);
    if (method == NULL) {
        NSLog(@"[TamyrFlow] instance method missing %@ / %@", NSStringFromSelector(sel), NSStringFromClass(cls));
        return NO;
    }
    *outOriginal = method_setImplementation(method, newIMP);
    return *outOriginal != NULL;
}

void TFInstallAccurateSleepCrashGuard(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IMP original = NULL;

        if (TFReplaceClassMethod(
                [VPAccurateSleepModel class],
                @selector(modelWithAccurateSleepData:dayNumber:sleepType:),
                (IMP)TFSafeModelWithAccurateSleepData,
                &original
            )) {
            TFOriginalModelFactory = (TFModelFactoryIMP)original;
        }

        if (TFReplaceInstanceMethod(
                [VPPeripheralManage class],
                NSSelectorFromString(@"handleOneDayAllSleepData:"),
                (IMP)TFSafeHandleOneDayAllSleepData,
                &original
            )) {
            TFOriginalHandleOneDayAllSleep = (TFVoidIdIMP)original;
        }

        Class addManageClass = NSClassFromString(@"VPPeripheralAddManage");
        if (TFReplaceInstanceMethod(
                addManageClass,
                NSSelectorFromString(@"sdk_handleOneDayAllSleepData:"),
                (IMP)TFSafeSdkHandleOneDayAllSleepData,
                &original
            )) {
            TFOriginalSdkHandleOneDayAllSleep = (TFVoidIdIMP)original;
        }

        Class handlerClass = NSClassFromString(@"VPHandleDeviceAccurateSleepData");
        if (TFReplaceClassMethod(
                handlerClass,
                NSSelectorFromString(@"handleAccurateSleepData:sleepTimes:dayNumber:deviceMac:sleepType:"),
                (IMP)TFSafeHandleAccurateSleepData,
                &original
            )) {
            TFOriginalHandleAccurateSleep = (TFHandleSleepIMP)original;
        }
        if (TFReplaceClassMethod(
                handlerClass,
                NSSelectorFromString(@"handleAccurateModle:dayNumber:"),
                (IMP)TFSafeHandleAccurateModel,
                &original
            )) {
            TFOriginalHandleAccurateModel = (TFHandleModelIMP)original;
        }

        NSLog(@"[TamyrFlow] VPAccurateSleep crash guard installed");
    });
}

__attribute__((constructor))
static void TFAccurateSleepCrashGuardConstructor(void) {
    TFInstallAccurateSleepCrashGuard();
}
