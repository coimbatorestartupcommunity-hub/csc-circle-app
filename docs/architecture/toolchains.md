# Toolchains and platform support

Checked 2026-10-25 on macOS arm64.

| Tool | Local state | Evidence / limit |
|---|---|---|
| macOS host | Apple Silicon, Darwin 27.2 | `uname -a` |
| Flutter | 3.47.8 stable, framework revision `737ba8f885`, installed under `/private/tmp/csc-circle-flutter-sdk` | `flutter --version`; SDK is outside the repository |
| Dart | 3.13.7 stable, macOS arm64 | Bundled with Flutter |
| Xcode | 27.1 (27A9275) | `xcodebuild -version` |
| Apple SDKs | iOS 27.1, iOS Simulator 27.1, macOS 27.0 | `xcodebuild -showsdks`; SDK presence does not mean a simulator runtime is installed |
| iOS Simulator | iOS 26.1 and 26.4.1 runtimes installed; iPhone 17 simulator boots, runs the app, and passes the integration smoke test. Xcode 27.1 runtime download was attempted but remained at 0 bytes; 26.4.1 is used for verification. | `xcrun simctl list runtimes`; `flutter devices` |
| Android Studio | Not installed | Android command-line tooling is installed directly; Studio is optional for this CLI build setup |
| Android SDK | Installed at `/Users/vikash/Library/Android/sdk`; Flutter is configured to use it | Flutter doctor recognizes API 36; Build Tools 36.0.0 and 36.1.0, NDK 28.2.13676358, and CMake 3.22.1 installed |
| Android emulator / system image | API 36.1 Google APIs ARM64 image installed; `csc-circle-api-36` AVD created manually because `avdmanager` reported no valid system-image paths for this image; emulator boots and runs integration tests | `sdkmanager`, emulator, `adb`, Flutter integration test |
| Android platform tools | Installed | `adb` 37.0.1; SDK cmdline tools exposed at `cmdline-tools/latest` |
| Java | OpenJDK 25.0.2 | Installed; Android Gradle compatibility unverified |
| CocoaPods | 1.17.0 | `pod --version` |
| Windows build host / Visual Studio C++ / Windows SDK | Not present on this Mac | Windows builds and MSIX validation require a Windows runner |
| Chrome | Version 156.0.8078.47 | Recognized by Flutter; not a requested store platform |
| ffmpeg | Installed | Available for local video production |
| GitHub CLI | Authenticated as `coimbatorestartupcommunity-hub`; repo permission is ADMIN | `gh auth status`; initial push to `main` succeeded |

The Flutter project targets iOS, Android, macOS, and Windows. Apple bundle ID `dev.cscircle.csc-circle-app` and Android package `dev.cscircle.csc_circle_app` are temporary and do not claim publisher ownership. macOS debug/integration builds, unsigned iOS device/simulator builds, an iPhone 17 integration test, and an Android API 36 integration test pass. Android debug APK compilation passes (159 MB). Windows `flutter analyze`, widget tests, release build, and artifact upload passed on the GitHub Windows host in [run 40220477021](https://github.com/coimbatorestartupcommunity-hub/csc-circle-app/actions/runs/40220477021). Its unsigned artifact was downloaded and inspected; interactive Windows launch and MSIX remain unverified. Xcode 27.1's iOS 27.1 simulator runtime download stalled at 0 bytes; iOS 26.4.1 is the tested runtime. Flutter's selected SDK lives at `/private/tmp/csc-circle-flutter-sdk`; this host's PATH also contains a separate Homebrew Flutter install, so commands should use the selected SDK's absolute path.
