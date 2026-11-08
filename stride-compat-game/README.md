# Pocket Ridge Lite

A tiny original Java/Canvas game used only as a Stride single-DEX smoke test.

## Deliberately small compatibility surface

- One Java Activity and one custom View
- No third-party dependencies, AndroidX, Kotlin, JNI, native libraries, files, networking, audio, or game engine
- Canvas operations limited to clear color, rectangles, and circles
- Touch input uses basic MotionEvent coordinates and action values
- One DEX is required and verified by CI; the build fails if the APK contains anything other than exactly one DEX

This APK is a loader/launch/render/touch smoke test, not proof that Stride supports general Android games. Passing it would isolate the next compatibility step; it does not fix multi-DEX support.

## Build

```sh
gradle --no-daemon :app:assembleDebug
```

APK: `app/build/outputs/apk/debug/app-debug.apk`

## Verification

GitHub Actions compiles the APK, checks its ZIP and manifest, requires exactly one DEX, rejects packaged native libraries, and uploads the APK artifact. Actual execution still requires importing it into Stride and testing on-device.
