# Hill Climb Adventure

An original, lightweight 2D off-road driving game built with Godot 4.4. The game uses procedural vector art and has no external asset downloads.

## Current prototype

- Landscape 960×540 game view
- Procedural rolling terrain and parallax sky
- Arcade driving, gravity, slope alignment and in-air lean controls
- Touch controls and keyboard controls for desktop testing
- Coins, fuel, distance, run summary and retry loop
- Android ARM64 export preset

## Build

Open this folder in Godot 4.4. Install the matching Android export templates and configure the Android SDK/JDK in Editor Settings. Then export using the **Android** preset.

The GitHub Actions workflow also attempts a reproducible Android APK export. The APK is a development build and has not yet been tested on a physical device or inside Husk.

## Controls

- Gas: right side
- Brake: left side
- Lean: two middle touch zones
- Desktop: A/D or arrow keys
