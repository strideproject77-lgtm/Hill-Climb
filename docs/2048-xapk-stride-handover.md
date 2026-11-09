# Stride APK Handover — 2048 (APKPure XAPK 1.7.0)

## Intake and integrity

- Source filename: `2048_1.7.0_APKPure.xapk`
- Package: `com.tpcstld.twozerogame`
- App name: `2048`
- Version: `1.7.0` (version code `1013`)
- XAPK format version: `2`
- Archive size: `3,453,701 bytes` (about 3.29 MiB)
- SHA-256: `e3a9c160ea34bfa916e0022dcacb3da07732042c1f2912f52b7bbdc4485ec3a7`
- Source: user-provided APKPure XAPK, inspected locally on 2026-11-09.
- This report records static inspection only. No APK was installed or executed on Android or Stride.

## Package layout

The XAPK contains 21 entries:
- One base APK: `com.tpcstld.twozerogame.apk` (2,990,995 bytes).
- Eighteen configuration split APKs: language splits `ko, es, fr, hi, pt, zh, ar, in, my, tr, de, it, th, vi, en, ja, ru`, plus `config.xxhdpi.apk`.
- `icon.png` (11,431 bytes).
- `manifest.json` (1,357 bytes).

The XAPK manifest declares:
- `min_sdk_version = 23` (Android 6.0).
- `target_sdk_version = 37`.
- One declared XAPK-level permission: `com.tpcstld.twozerogame.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.
- Split delivery is part of the package. A correct installer/loader must treat the base APK and applicable config splits as one install set, not as unrelated APKs.

Base APK contents relevant to execution:
- Exactly one DEX file: `classes.dex`.
- DEX magic/version: `dex\n035\0`.
- DEX file size: 7,059,288 bytes.
- 45,835 string IDs; 7,882 type IDs; 12,059 proto IDs; 17,860 field IDs; 51,183 method IDs; 6,502 class definitions.
- No `classes2.dex` was found.
- No `lib/**/*.so` native libraries were found in the base APK or any configuration split.
- App asset: `assets/ClearSans-Bold.ttf` (269,792 bytes).
- Baseline profile files: `assets/dexopt/baseline.prof` and `baseline.profm`.

## Execution model — important finding

This is a strong early Stride DEX/framework test candidate, not a native game-engine test.

The app-specific DEX class inventory includes:
- `MainActivity`
- `MainGame`
- `MainView`
- `Grid`, `Tile`, `Cell`
- `AnimationGrid`, `AnimationCell`
- `InputListener`
- `SnapshotManager`, `SnapshotData`
- `DebugTools`

The app's own `MainView` contains methods such as `onDraw`, `onSizeChanged`, `drawBackground`, `drawBackgroundGrid`, `drawCells`, `drawCellText`, `drawScoreText`, `drawUndoButton`, `drawNewGameButton`, and `tick`. DEX references `android.graphics.Canvas`. `InputListener` exposes `onTouch`, `isTap`, and `pathMoved`.

Static evidence therefore points to a custom Android View/Canvas 2D game loop with Java/Dalvik bytecode and touch input. No native ABI or native symbol-loading requirement was detected in this XAPK. This is not evidence that every code path is pure Java; it means the inspected package contains no packaged ELF shared libraries.

## Stride requirements and likely compatibility blockers

### P0 — required for a meaningful real launch
1. Parse the XAPK manifest and build a split-install plan. Select base plus compatible density/language splits; do not try to launch a config split by itself.
2. Parse the base APK's binary AndroidManifest.xml and resolve the actual launcher Activity, application class, orientation, theme, exported state, and component declarations.
3. Load the single DEX and resolve all app classes, fields, constructors, and methods, including framework/library references.
4. Execute the real `MainActivity` lifecycle: at minimum attach/create, resume, pause, save/restore state, and back/key handling.
5. Implement or bridge the Android View APIs used by `MainView`: View construction, sizing, invalidation, `onDraw(Canvas)`, touch listener registration and event dispatch.
6. Implement the Canvas 2D calls actually used by `MainView`: drawing colors/rectangles/text/bitmaps, text measurement/alignment, clipping, and density-aware coordinate conversion. Confirm exact method inventory from disassembly before coding.
7. Support touch event delivery for swipe gestures and button taps. Preserve pointer coordinates, action type, and event ordering.
8. Support app state persistence used by `MainActivity` / `SnapshotManager`, including save/load and high-score state.
9. Load packaged resources and the font asset; resolve strings, drawables, colors, dimensions, and styles from the base/config splits.
10. Correctly handle the app's target SDK 37 behavior where it affects permission, component, receiver, and edge-to-edge/window APIs.

### P1 — likely needed for full feature coverage
- AndroidX Activity, AppCompat/Core, Lifecycle, SavedState, Startup, and ProfileInstaller references are present in DEX inventory; provide compatible implementations or safe stubs only where semantically valid.
- Google Play Services Auth and Games/leaderboard-related classes are present. Determine whether sign-in/leaderboards are optional. Offline core gameplay should be tested separately from Play Games functionality.
- Kotlin/coroutines-related references exist in the DEX string/type inventory. Resolve only the classes/methods reached by the actual app paths; do not assume the whole app requires a full coroutine scheduler before proving it.
- Handle system bar/window inset behavior and configuration changes.
- Verify animation timing and frame scheduling so `MainView.tick` and invalidation do not stall or consume excessive CPU.

### P2 — not detected as a package requirement
- JNI/native method bridge: no app-packaged `.so` library detected.
- ELF/ARM64 native loader and Bionic symbol resolver: no app-packaged native library detected.
- OpenGL ES/Vulkan/SurfaceView game renderer: no evidence in the inspected base package; the app references Canvas.
- Audio engine: no clear app-specific audio requirement identified in the static inventory.

Do not build native-engine support just for this sample unless runtime logs show a dynamically supplied native dependency.

## Recommended Stride test sequence

1. Register this as a real third-party APK fixture: package `com.tpcstld.twozerogame`, version `1.7.0`.
2. Test XAPK parsing and split selection independently from execution.
3. Test DEX load/class inventory and confirm the real launcher Activity is found.
4. Launch the real Activity and verify the app's own screen is shown (not a Stride demo or substitute calculator/game screen).
5. Verify first-run board creation and rendering through `MainView.onDraw(Canvas)`.
6. Verify all four swipe directions, tile movement/merge, score updates, new game, undo, win/lose overlays, and animation progression.
7. Pause/resume and force-close/relaunch; verify board and high score restore correctly.
8. Test offline gameplay first. Test Google Play Games sign-in/leaderboards separately and mark unavailable integrations explicitly rather than blocking core gameplay.
9. Capture launch-to-exit logs, missing API/method reports, unsupported opcodes, Canvas call coverage, frame time/FPS, and memory use.
10. Add every fixed failure as a regression test. Only mark compatibility successful after the real APK's own code executes end-to-end on device.

## Compatibility assessment

- APK structure: straightforward base + configuration split package; XAPK split handling is required.
- Native execution burden: low based on packaged contents (no ELF libraries found).
- DEX/framework burden: moderate to high because the APK has a sizeable DEX and uses AndroidX/Google Play Services references.
- Graphics burden: Canvas 2D and custom View lifecycle/input are central.
- Best role in the Stride roadmap: early real-APK integration/regression target for DEX execution, Activity lifecycle, View/Canvas rendering, touch input, resources, and persistence. It is a better first real-game milestone than a Unity/IL2CPP or Cocos2d-x title.
- Current status: statically inspected only; **not yet confirmed runnable in Stride**.

## Verification limitations

This was a ZIP/DEX-level static scan. The binary AndroidManifest.xml was not fully decoded with aapt/apktool, and no full JADX/Androguard decompilation was performed. Therefore the exact launcher component, complete permission list, exact AndroidX/Google API call paths, and exact Canvas method signatures remain to be extracted in a deeper disassembly pass. Do not treat package metadata strings alone as proof that every listed SDK feature is mandatory.
