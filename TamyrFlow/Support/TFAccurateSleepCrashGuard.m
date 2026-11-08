#import "TFAccurateSleepCrashGuard.h"

#import <objc/runtime.h>
#import <VeepooBleSDK/VPAccurateSleepModel.h>
#import <VeepooBleSDK/VPPeripheralManage.h>

/*
 Build 5 tried @try/@catch around Veepoo sleep parsers. That only catches NSException.
 Client build 5 then died with EXC_BAD_ACCESS (objc_retain of 0x1) inside the BLE
 characteristic callback — a hard fault that ObjC exceptions cannot catch.

 Fix: never enter Veepoo accurate-sleep / all-sleep handlers. Drop the packets.
 Sleep UI stays on HealthKit / ordinary local DB only.
*/

#pragma mark - Drop replacements (do not call originals)

static id TFDropAccurateSleepModelFactory(id self, SEL _cmd, NSData *data, NSInteger day, NSInteger type) {
    (void)self; (void)_cmd; (void)data; (void)day; (void)type;
    NSLog(@"[TamyrFlow] dropped VPAccurateSleepModel factory call");
    return nil;
}

static void TFDropOneArg(id self, SEL _cmd, id arg) {
    (void)self; (void)_cmd; (void)arg;
    NSLog(@"[TamyrFlow] dropped Veepoo sleep BLE handler (%@)", NSStringFromSelector(_cmd));
}

static void TFDropAccurateSleepData(id self, SEL _cmd, id data, id times, NSInteger day, id mac, NSInteger type) {
    (void)self; (void)_cmd; (void)data; (void)times; (void)day; (void)mac; (void)type;
    NSLog(@"[TamyrFlow] dropped handleAccurateSleepData");
}

static void TFDropAccurateModel(id self, SEL _cmd, id model, NSInteger day) {
    (void)self; (void)_cmd; (void)model; (void)day;
    NSLog(@"[TamyrFlow] dropped handleAccurateModle");
}

static void TFDropHRV(id self, SEL _cmd, id hrvData) {
    (void)self; (void)_cmd; (void)hrvData;
    NSLog(@"[TamyrFlow] dropped handleOneDayHRVData (connect stability)");
}

#pragma mark - Install helpers

static BOOL TFReplaceInstanceIMP(Class cls, SEL sel, IMP newIMP) {
    if (cls == Nil || newIMP == NULL) { return NO; }
    Method method = class_getInstanceMethod(cls, sel);
    if (method == NULL) {
        NSLog(@"[TamyrFlow] instance method missing %@ / %@", NSStringFromSelector(sel), NSStringFromClass(cls));
        return NO;
    }
    method_setImplementation(method, newIMP);
    return YES;
}

/// Class methods live on the metaclass — replace via `object_getClass`.
static BOOL TFReplaceClassIMP(Class cls, SEL sel, IMP newIMP) {
    if (cls == Nil || newIMP == NULL) { return NO; }
    Class meta = object_getClass(cls);
    Method method = class_getInstanceMethod(meta, sel);
    if (method == NULL) {
        // Fallback for odd SDK layouts.
        method = class_getClassMethod(cls, sel);
    }
    if (method == NULL) {
        NSLog(@"[TamyrFlow] class method missing %@ / %@", NSStringFromSelector(sel), NSStringFromClass(cls));
        return NO;
    }
    method_setImplementation(method, newIMP);
    return YES;
}

void TFInstallAccurateSleepCrashGuard(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL ok = YES;

        ok = TFReplaceClassIMP(
                [VPAccurateSleepModel class],
                @selector(modelWithAccurateSleepData:dayNumber:sleepType:),
                (IMP)TFDropAccurateSleepModelFactory
            ) && ok;

        ok = TFReplaceInstanceIMP(
                [VPPeripheralManage class],
                NSSelectorFromString(@"handleOneDayAllSleepData:"),
                (IMP)TFDropOneArg
            ) && ok;

        ok = TFReplaceInstanceIMP(
                [VPPeripheralManage class],
                NSSelectorFromString(@"handleOneDayHRVData:"),
                (IMP)TFDropHRV
            ) && ok;

        Class addManageClass = NSClassFromString(@"VPPeripheralAddManage");
        ok = TFReplaceInstanceIMP(
                addManageClass,
                NSSelectorFromString(@"sdk_handleOneDayAllSleepData:"),
                (IMP)TFDropOneArg
            ) && ok;

        Class handlerClass = NSClassFromString(@"VPHandleDeviceAccurateSleepData");
        ok = TFReplaceClassIMP(
                handlerClass,
                NSSelectorFromString(@"handleAccurateSleepData:sleepTimes:dayNumber:deviceMac:sleepType:"),
                (IMP)TFDropAccurateSleepData
            ) && ok;
        ok = TFReplaceClassIMP(
                handlerClass,
                NSSelectorFromString(@"handleAccurateModle:dayNumber:"),
                (IMP)TFDropAccurateModel
            ) && ok;

        NSLog(@"[TamyrFlow] VPAccurateSleep crash guard installed (drop-mode)%@", ok ? @"" : @" — some hooks missing");
    });
}
