# Stride Open World

An original 3D open-world driving/action game for Android ARM64, built with Godot 4.4.1.

## Direction

The project is moving from its previous 2D off-road game into a third-person, realistic 3D open-world experience. The visual and gameplay target is commercial open-world quality: detailed environments, believable vehicles, character animation, traffic, pedestrians, missions, weather, and a polished mobile interface.

This is an original game inspired by the broad genre and production values of modern open-world games. It does not reuse GTA assets, maps, characters, branding, or proprietary content.

## Current implementation

- Phase 1: 3D rendering and procedural world foundation.
- Procedural rolling terrain with layered noise.
- Procedural asphalt road with curvature and center markings.
- Procedural vegetation and distant ridge silhouettes.
- Filmic sky, late-afternoon directional lighting, and mobile-compatible rendering.
- Android ARM64 APK export remains automated through GitHub Actions.

## Build

The GitHub Actions workflow in `.github/workflows/hill-climb-android.yml` imports the Godot project, runs a headless startup/parse smoke test, exports an Android ARM64 APK, validates the archive and native ABI, and uploads the APK as a workflow artifact.

No local PC build is required for the normal development workflow. Download the APK artifact from the completed GitHub Actions run.

## Honest status

The current phase establishes the 3D world foundation. It is not yet a complete open-world game: player controller, drivable vehicle physics, camera follow, world streaming, districts, NPCs, missions, and final art assets are subsequent implementation phases. No compatibility or visual-quality claim should be made without a real APK/device review.
