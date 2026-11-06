# Ridgeline: Offroad Championship

An original 2D off-road driving game built with Godot 4.4 for Android ARM64.

## Current systems

- Suspension-based two-wheel vehicle simulation with spring response, traction, braking, weight transfer and airborne lean
- Four selectable vehicle classes with different mass, engine power, grip and suspension profiles
- Garage with unlockable vehicles and persistent career progress
- Four upgrade tracks: engine, suspension, tires and fuel capacity
- Three procedural environments: Green Highlands, Desert Dunes and Frost Ridge, each with its own terrain profile and surface grip
- Fuel consumption, collectible fuel cans, coins, distance rewards and saved best distance
- Touch controls designed for landscape mobile play
- Reproducible Android ARM64 APK workflow

## Build

Open this folder in Godot 4.4. Install the matching Android export templates and configure the Android SDK/JDK in Editor Settings. Then export using the **Android** preset.

GitHub Actions builds and validates the Android ARM64 APK. The artifact is a development build and still requires hands-on gameplay testing on a physical device.

## Husk JIT-less readiness

The Android export targets **ARM64 only** and uses Godot 4 GDScript (not a runtime JIT or a C#/.NET build). The APK workflow checks that every packaged native shared library is an ELF64 AArch64 library and rejects other native ABI directories.

These checks establish a JIT-less-friendly package profile; they do **not** prove Husk can convert or launch this build. Husk performs its own first-launch library conversion and signing, which must be tested on-device with the matching sideloading certificate. Actual JIT-less launch and gameplay remain a separate compatibility test.
