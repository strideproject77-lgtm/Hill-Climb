# Pocket Ridge

Pocket Ridge is a small original 2D hill-driving APK maintained separately from the Stride app repository. It is intended as a narrow Java/DEX + Android framework compatibility workload.

## Compatibility-first implementation

- One Java Activity and one custom View
- Java source only; no Kotlin, AndroidX, game engine, external runtime library, JNI, or packaged native `.so`
- 2D rendering restricted to basic Canvas operations: clear color, scale, rectangles, circles, lines, and paths
- Paint usage restricted to color, fill/stroke style, stroke width, and anti-alias setting
- Touch input uses MotionEvent action and pointer coordinates
- No text rendering, shaders/gradients, rounded-rectangle drawing, rotation, audio, networking, or storage
- Offline landscape gameplay

The game source intentionally avoids APIs that are not represented by the current Stride Canvas primitive tests. This is a conservative source-level profile, **not a claim that the Android Java API bridge or continuous View rendering is already verified end-to-end**.

## Build

From this directory:

```sh
gradle --no-daemon :app:assembleDebug
```

APK output:

`app/build/outputs/apk/debug/app-debug.apk`

## Verification

GitHub Actions compiles the APK and checks its ZIP structure, DEX presence, manifest, package ID, and absence of packaged native libraries. Those checks prove that the APK is built and packaged correctly; they do not prove that Stride can launch it or sustain gameplay.

The remaining compatibility gate is importing this APK into a current Stride IPA and verifying launch, drawing, touch controls, repeated frames, and clean exit on-device.