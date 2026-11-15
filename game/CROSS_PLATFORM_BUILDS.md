# Cross-platform build notes

INFINITE HORIZONS uses one Godot project and one shared gameplay/source tree for Android and iOS.

- Android: `.github/workflows/hill-climb-android.yml` on Ubuntu; existing ARM64 APK pipeline remains the default.
- iOS: `.github/workflows/infinite-horizons-ios.yml` on a GitHub-hosted macOS runner; manual dispatch only and explicitly gated.
- iOS signing assets are supplied only through repository Actions secrets. Never commit certificates, provisioning profiles, passwords or private keys.
- Required iOS secrets: `IOS_CERTIFICATE_P12_BASE64`, `IOS_CERTIFICATE_PASSWORD`, `IOS_PROVISION_PROFILE_BASE64`, and `IOS_TEAM_ID`.
- The iOS workflow's authorization input defaults to false. A run without explicit authorization performs no export.
- Platform capability checks belong in `IHPlatformProfile`; keep gameplay shared and isolate platform-specific settings/input at the edges.

The iOS workflow is prepared but requires a valid Apple Distribution certificate and matching App Store provisioning profile, plus validation of the Godot iOS export preset against the configured Apple account. A successful Android build does not prove iOS signing or device compatibility.
