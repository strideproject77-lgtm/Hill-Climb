# Cross-platform builds

INFINITE HORIZONS uses one shared Godot project and gameplay/source tree for Android and iOS.

- Android: `.github/workflows/hill-climb-android.yml` on Ubuntu; the existing ARM64 APK pipeline remains unchanged.
- iOS: `.github/workflows/infinite-horizons-ios.yml` on a GitHub-hosted macOS runner.
- The iOS pipeline exports a Godot Xcode project, compiles an ARM64 iPhone app with Xcode code signing disabled, then packages the app as an unsigned IPA.
- No Apple Developer account, certificate, provisioning profile, or signing secrets are required to produce the unsigned build artifact.
- The unsigned IPA must still be signed by a compatible sideloading tool (for example, SideStore/AltStore) before installation on a physical iPhone.
- Manual workflow dispatch is explicitly gated by `authorize_ipa_export=true`; the repository sentinel file can also trigger a build on `hill-climb-game`.
- Build verification checks the bundle identifier, app executable, ARM64 architecture, IPA ZIP integrity, and SHA-256 digest.
- Never commit certificates, provisioning profiles, passwords, or private keys.

A successful CI export verifies packaging and architecture, not runtime compatibility on every iPhone. Device installation and gameplay still require a separate on-device check.
