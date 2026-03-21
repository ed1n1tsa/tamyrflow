# Vendor build notes

## `JL_BLEKit_NoDup.a` (duplicate ObjC classes vs `JLDialUnit`)

The stock `JL_BLEKit.framework` is a **static** archive: it merges `JL_Tools`, `JL_Timer`, `JLModel_File`, etc. into the app binary.  
`JLDialUnit.framework` is **dynamic** and **also** contains those same classes → runtime warning *“Class … is implemented in both …”*.

We link **`Vendor/JL_BLEKit_NoDup.a`** instead: same JL_BLEKit objects **minus** `JL_Tools.o` and `JLModel_File.o`, so those classes resolve from **JLDialUnit** only.

After replacing `JL_BLEKit.framework` from the vendor, regenerate:

```bash
./Scripts/build_jl_blekit_nodup.sh
```

Keep the original `JL_BLEKit.framework` in the repo for that script (it is no longer linked in the Xcode target).

---

## ZipZap (required by `JLDialUnit.framework`)

`JLDialUnit` loads `@rpath/ZipZap.framework/ZipZap` at runtime. The prebuilt **`ZipZap.framework`** at the project root was produced from [pixelglow/zipzap](https://github.com/pixelglow/zipzap) tag **8.1** with a raised deployment target (modern Xcode no longer ships `libarclite` for iOS 8).

Rebuild (from repo root):

```bash
cd Vendor/zipzap-source
xcodebuild -scheme "ZipZap (iOS Framework)" -configuration Release \
  -sdk iphoneos -derivedDataPath ./dd-build ONLY_ACTIVE_ARCH=NO \
  IPHONEOS_DEPLOYMENT_TARGET=12.0 clean build
cp -R dd-build/Build/Products/Release-iphoneos/ZipZap.framework ../../
```

You can remove `Vendor/zipzap-source` and `dd-build` after copying if you want a smaller tree; keep **`ZipZap.framework`** next to the other `.framework` folders.
