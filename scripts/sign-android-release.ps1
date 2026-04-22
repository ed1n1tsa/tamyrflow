# Signs TamyrFlow release APK with a local keystore. Run in PowerShell from any cwd.
# Usage: .\scripts\sign-android-release.ps1
# Requires: Android SDK build-tools (zipalign, apksigner) under %LOCALAPPDATA%\Android\Sdk

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $root "Android\app\build.gradle.kts"))) {
  throw "Expected repo root with Android\app\build.gradle.kts; got: $root"
}

$unsigned = Join-Path $root "Android\app\build\outputs\apk\release\app-release-unsigned.apk"
$aligned = Join-Path $root "app-release-aligned.apk"
$signed = Join-Path $root "app-release-signed.apk"
$ks = Join-Path $root "tamyrflow-release.jks"
$alias = "tamyrflow"

$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk\build-tools"
if (-not (Test-Path $sdkRoot)) {
  throw "Android SDK build-tools not found at $sdkRoot"
}
$bt = (Get-ChildItem $sdkRoot -Directory | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1).FullName
$zipalign = Join-Path $bt "zipalign.exe"
$apksigner = Join-Path $bt "apksigner.bat"
if (-not (Test-Path $zipalign) -or -not (Test-Path $apksigner)) {
  throw "zipalign/apksigner missing in $bt"
}

if (-not (Test-Path $unsigned)) {
  throw "Unsigned APK not found. Build first: Android\gradlew.bat assembleRelease ($unsigned)"
}
if (-not (Test-Path $ks)) {
  throw "Keystore not found: $ks"
}

Write-Host "Using build-tools: $bt"
& $zipalign -p -f 4 $unsigned $aligned
if ($LASTEXITCODE -ne 0) { throw "zipalign failed with exit $LASTEXITCODE" }

$sec = Read-Host "Keystore password" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try {
  $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  $plain | & $apksigner sign --ks $ks --ks-key-alias $alias --ks-pass stdin --out $signed $aligned
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}
if ($LASTEXITCODE -ne 0) { throw "apksigner failed with exit $LASTEXITCODE" }

& $apksigner verify --verbose $signed
if ($LASTEXITCODE -ne 0) { throw "apksigner verify failed with exit $LASTEXITCODE" }

Write-Host "Signed APK: $signed"
