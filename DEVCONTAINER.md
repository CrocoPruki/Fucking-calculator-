Devcontainer for Trading Watch Flutter app

Steps to use:

1. Install Docker and VS Code Remote - Containers extension.
2. Open this repository in VS Code.
3. From the command palette choose: Remote-Containers: Reopen in Container.
4. The container uses the `ghcr.io/cirrusci/flutter:stable` image and will run `flutter pub get` for you.
5. Once container opens, to run the app:

```bash
cd trading_watch_app
flutter devices
flutter run
```

Notes:
- If you need Android emulator support, ensure Docker has nested virtualization and the image has AVD tools (you might prefer to run the emulator on the host).
- The container provides Flutter tooling; building signed APKs or iOS builds may require extra setup.
