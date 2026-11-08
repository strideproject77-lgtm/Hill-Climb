# Pocket Ridge

An original small 2D hill-driving game built as a compatibility test for Stride.

## Compatibility-first design
- One Java Activity and one custom View
- Android Canvas, Paint, Path, and touch input only
- No Kotlin, AndroidX, external libraries, native shared libraries, JNI, OpenGL, or runtime JIT
- Offline landscape gameplay

## Build
From this directory, run: gradle --no-daemon :app:assembleDebug

APK output: app/build/outputs/apk/debug/app-debug.apk

GitHub Actions verifies the APK archive, DEX bytecode, manifest, package ID, and absence of packaged native libraries. These are build/package checks, not proof Stride can launch it; that requires an on-device import and gameplay test.
