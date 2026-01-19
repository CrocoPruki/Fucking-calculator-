# trading_watch_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

## CI: Stable APK signing (recommended)

If you install APKs on your watch/phone via ADB, you want a consistent signing key.
Otherwise Android will reject updates with:
`INSTALL_FAILED_UPDATE_INCOMPATIBLE (signatures do not match)`.

The GitHub Actions workflow supports stable signing via secrets. Create an **upload keystore** once and store it in GitHub Secrets:

Secrets to add in your repo:
- `ANDROID_KEYSTORE_BASE64` (base64 of the `.jks`)
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Example (Windows PowerShell) to create + base64 the keystore:
- Create keystore:
	`keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- Base64:
	`[Convert]::ToBase64String([IO.File]::ReadAllBytes('upload-keystore.jks'))`

After setting secrets, CI builds a consistently-signed `app-release.apk`, and updates work with:
`adb install -r app-release.apk`.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
