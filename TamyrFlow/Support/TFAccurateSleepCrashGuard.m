#import "TFAccurateSleepCrashGuard.h"

#import <objc/runtime.h>
#import <VeepooBleSDK/VPAccurateSleepModel.h>
#import <VeepooBleSDK/VPPeripheralManage.h>

/*
 Client crashes after connect while Veepoo parses inbound BLE day dumps:

 - build 3/4: -[__NSCFString year] in VPAccurateSleepModel
 - build 5:   EXC_BAD_ACCESS inside characteristic callback
 - build 6:   -[NSTaggedPointerString hour] (same BLE path — sleep drop was not enough)

 Strategy:
 1) Drop all known one-day dump handlers (sleep / HRV / oxygen / daily / 5-min / temperature).
 2) Wrap peripheral:didUpdateValueForCharacteristic:error: in @try/@catch so any remaining
    NSException from Veepoo parsers is swallowed instead of aborting the app.

 Live tests (heart / SpO2 / temp / BP) and realtime GetStepData stay intact — they use
 other SDK entry points, not these day-dump handlers.
*/

typedef void (*TFDidUpdateValueIMP)(id, SEL, id, id, id);

static TFDidUpdateValueIMP TFOriginalDidUpdateManage = NULL;
static TFDidUpdateValueIMP TFOriginalDidUpdateAdd = NULL;
static TFDidUpdateValueIMP TFOriginalDidUpdateBase = NULL;

#pragma mark - Drop stubs

static id TFDropAccurateSleepModelFactory(id self, SEL _cmd, NSData *data, NSInteger day, NSInteger type) {
    (void)self; (void)_cmd; (void)data; (void)day; (void)type;
    return nil;
}

static void TFDropPacket(id self, SEL _cmd, id arg) {
    (void)self; (void)arg;
    NSLog(@"[TamyrFlow] dropped Veepoo day-dump (%@)", NSStringFromSelector(_cmd));
}

static void TFDropAccurateSleepData(id self, SEL _cmd, id data, id times, NSInteger day, id mac, NSInteger type) {
    (void)self; (void)_cmd; (void)data; (void)times; (void)day; (void)mac; (void)type;
}

static void TFDropAccurateModel(id self, SEL _cmd, id model, NSInteger day) {
    (void)self; (void)_cmd; (void)model; (void)day;
}

#pragma mark - didUpdateValue wrappers

static void TFSafeDidUpdateManage(id self, SEL _cmd, id peripheral, id characteristic, id error) {
    @try {
        if (TFOriginalDidUpdateManage) {
            TFOriginalDidUpdateManage(self, _cmd, peripheral, characteristic, error);
        }
    } @catch (NSException *exception) {
        NSLog(
            @"[TamyrFlow] swallowed VPPeripheralManage characteristic exception: %@ — %@",
            exception.name,
            exception.reason ?: @""
        );
    }
}

static void TFSafeDidUpdateAdd(id self, SEL _cmd, id peripheral, id characteristic, id error) {
    @try {
        if (TFOriginalDidUpdateAdd) {
            TFOriginalDidUpdateAdd(self, _cmd, peripheral, characteristic, error);
        }
    } @catch (NSException *exception) {
        NSLog(
            @"[TamyrFlow] swallowed VPPeripheralAddManage characteristic exception: %@ — %@",
            exception.name,
            exception.reason ?: @""
        );
    }
}

static void TFSafeDidUpdateBase(id self, SEL _cmd, id peripheral, id characteristic, id error) {
    @try {
        if (TFOriginalDidUpdateBase) {
            TFOriginalDidUpdateBase(self, _cmd, peripheral, characteristic, error);
        }
    } @catch (NSException *exception) {
        NSLog(
            @"[TamyrFlow] swallowed VPPeripheralBaseManage characteristic exception: %@ — %@",
            exception.name,
            exception.reason ?: @""
        );
    }
}

#pragma mark - Install helpers

static BOOL TFReplaceInstanceIMP(Class cls, SEL sel, IMP newIMP, IMP *outOriginal) {
    if (cls == Nil || newIMP == NULL) { return NO; }
    Method method = class_getInstanceMethod(cls, sel);
    if (method == NULL) {
        NSLog(@"[TamyrFlow] instance method missing %@ / %@", NSStringFromSelector(sel), NSStringFromClass(cls));
        return NO;
    }
    IMP previous = method_setImplementation(method, newIMP);
    if (outOriginal) {
        *outOriginal = previous;
    }
    return YES;
}

static BOOL TFReplaceClassIMP(Class cls, SEL sel, IMP newIMP) {
    if (cls == Nil || newIMP == NULL) { return NO; }
    Class meta = object_getClass(cls);
    Method method = class_getInstanceMethod(meta, sel);
    if (method == NULL) {
        method = class_getClassMethod(cls, sel);
    }
    if (method == NULL) {
        NSLog(@"[TamyrFlow] class method missing %@ / %@", NSStringFromSelector(sel), NSStringFromClass(cls));
        return NO;
    }
    method_setImplementation(method, newIMP);
    return YES;
}

static void TFDropInstanceSelector(Class cls, SEL sel) {
    TFReplaceInstanceIMP(cls, sel, (IMP)TFDropPacket, NULL);
}

void TFInstallAccurateSleepCrashGuard(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 1) Factory / private accurate-sleep handlers
        TFReplaceClassIMP(
            [VPAccurateSleepModel class],
            @selector(modelWithAccurateSleepData:dayNumber:sleepType:),
            (IMP)TFDropAccurateSleepModelFactory
        );

        Class accurateHandler = NSClassFromString(@"VPHandleDeviceAccurateSleepData");
        TFReplaceClassIMP(
            accurateHandler,
            NSSelectorFromString(@"handleAccurateSleepData:sleepTimes:dayNumber:deviceMac:sleepType:"),
            (IMP)TFDropAccurateSleepData
        );
        TFReplaceClassIMP(
            accurateHandler,
            NSSelectorFromString(@"handleAccurateModle:dayNumber:"),
            (IMP)TFDropAccurateModel
        );

        // 2) All known one-day dump entry points on VPPeripheralManage
        Class manageClass = [VPPeripheralManage class];
        TFDropInstanceSelector(manageClass, NSSelectorFromString(@"handleOneDayAllSleepData:"));
        TFDropInstanceSelector(manageClass, NSSelectorFromString(@"handleOneDayHRVData:"));
        TFDropInstanceSelector(manageClass, NSSelectorFromString(@"handleOneDayOxygenData:"));
        TFDropInstanceSelector(manageClass, NSSelectorFromString(@"handleOneDayDailyData:"));
        TFDropInstanceSelector(manageClass, NSSelectorFromString(@"handleOneDayAllFiveMinuteData:"));
        TFDropInstanceSelector(manageClass, NSSelectorFromString(@"handleOneDayTemperatureData:"));

        Class addManageClass = NSClassFromString(@"VPPeripheralAddManage");
        TFDropInstanceSelector(addManageClass, NSSelectorFromString(@"sdk_handleOneDayAllSleepData:"));

        // 3) Top-level characteristic callback — last line of defense for NSException
        SEL didUpdateSEL = @selector(peripheral:didUpdateValueForCharacteristic:error:);
        IMP previous = NULL;

        if (TFReplaceInstanceIMP(manageClass, didUpdateSEL, (IMP)TFSafeDidUpdateManage, &previous)) {
            TFOriginalDidUpdateManage = (TFDidUpdateValueIMP)previous;
        }
        if (TFReplaceInstanceIMP(addManageClass, didUpdateSEL, (IMP)TFSafeDidUpdateAdd, &previous)) {
            TFOriginalDidUpdateAdd = (TFDidUpdateValueIMP)previous;
        }

        Class baseManageClass = NSClassFromString(@"VPPeripheralBaseManage");
        if (TFReplaceInstanceIMP(baseManageClass, didUpdateSEL, (IMP)TFSafeDidUpdateBase, &previous)) {
            TFOriginalDidUpdateBase = (TFDidUpdateValueIMP)previous;
        }

        NSLog(@"[TamyrFlow] Veepoo BLE crash guard installed (drop day-dumps + catch didUpdateValue)");
    });
}
