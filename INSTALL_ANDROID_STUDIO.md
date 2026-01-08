# Jak zainstalować potrzebne narzędzia na Windows

## SZYBKA OPCJA - Użyj Android Studio (REKOMENDOWANE)

### 1. Pobierz i zainstaluj Android Studio
🔗 https://developer.android.com/studio

- Pobierz najnowszą wersję (2026.x)
- Uruchom instalator
- Podczas instalacji zaznacz:
  - ✅ Android SDK
  - ✅ Android SDK Platform
  - ✅ Android Virtual Device

### 2. Zainstaluj wymagane SDK
Po uruchomieniu Android Studio:
1. `File` → `Settings` → `Appearance & Behavior` → `System Settings` → `Android SDK`
2. Zakładka **SDK Platforms**:
   - ✅ Zaznacz **Android 16.0 (V)** (API Level 36)
   - ✅ Zaznacz **Android 15.0 (V)** (API Level 35) - dla kompatybilności
3. Zakładka **SDK Tools**:
   - ✅ Android SDK Build-Tools 35
   - ✅ Android SDK Platform-Tools
   - ✅ Android SDK Command-line Tools
4. Kliknij **Apply** i poczekaj na instalację

### 3. Dla ZEGARKA - Zainstaluj Flutter
🔗 https://docs.flutter.dev/get-started/install/windows

**Najłatwiejsza metoda:**
```bash
# Pobierz Flutter SDK:
# https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_stable.zip

# Rozpakuj do C:\flutter
# Dodaj do PATH: C:\flutter\bin
```

Sprawdź instalację:
```bash
flutter doctor
```

### 4. Włącz ADB w Windows
ADB jest już częścią Android Studio Platform Tools.

Dodaj do PATH:
- Ustawienia → System → Informacje → Zaawansowane ustawienia systemu
- Zmienne środowiskowe → Path → Edytuj → Dodaj:
  ```
  C:\Users\TwojaNazwa\AppData\Local\Android\Sdk\platform-tools
  ```

Sprawdź:
```bash
adb version
```

---

## ALTERNATYWNA OPCJA - Tylko narzędzia CLI (bez Android Studio)

Jeśli nie chcesz instalować całego Android Studio, możesz użyć tylko narzędzi:

### 1. Zainstaluj Java JDK 17
🔗 https://adoptium.net/ (wybierz JDK 17)

### 2. Pobierz Android Command Line Tools
🔗 https://developer.android.com/studio#command-line-tools-only

Pobierz `commandlinetools-win-XXXXX_latest.zip`

Rozpakuj do `C:\Android\cmdline-tools\latest\`

### 3. Zainstaluj wymagane pakiety
```bash
cd C:\Android\cmdline-tools\latest\bin
sdkmanager "platform-tools" "platforms;android-36" "build-tools;35.0.0"
```

### 4. Ustaw zmienne środowiskowe
```
ANDROID_HOME=C:\Android
ANDROID_SDK_ROOT=C:\Android
PATH += C:\Android\platform-tools
PATH += C:\Android\cmdline-tools\latest\bin
```

---

## BUDOWANIE APK

### Dla TABLETU (FuckingCalculator):

**Opcja A - Przez Android Studio:**
1. Otwórz folder: `FuckingCalculator/platforms/android`
2. `Build` → `Build Bundle(s) / APK(s)` → `Build APK(s)`
3. APK będzie w `app/build/outputs/apk/debug/app-debug.apk`

**Opcja B - Przez terminal:**
```bash
cd FuckingCalculator/platforms/android
gradlew.bat assembleDebug
```

### Dla ZEGARKA (trading_watch_app):

**Przez terminal:**
```bash
cd trading_watch_app
flutter build apk --debug
```

APK będzie w `build/app/outputs/flutter-apk/app-debug.apk`

---

## INSTALACJA NA URZĄDZENIACH

### 1. Włącz debugowanie USB (na obu urządzeniach)

**Samsung A9 Plus 5G:**
- Ustawienia → Informacje o telefonie
- Stukaj 7x w "Numer kompilacji"
- Ustawienia → Opcje dewelopera → Debugowanie USB ✅

**Galaxy Watch Ultra:**
- Ustawienia → Informacje o urządzeniu  
- Stukaj 7x w "Numer wersji oprogramowania"
- Ustawienia → Opcje programisty → Debugowanie USB ✅

### 2. Podłącz urządzenia i sprawdź ADB

```bash
adb devices
```

Powinno pokazać:
```
List of devices attached
XXXXXXXXXX      device
YYYYYYYYYY      device
```

Jeśli pokazuje `unauthorized`:
- Na urządzeniu pojawi się okno "Zezwolić na debugowanie USB?"
- Zaznacz "Zawsze zezwalaj z tego komputera"
- Kliknij OK

### 3. Zainstaluj APK

```bash
# Dla tabletu:
adb -s XXXXXXXXXX install -r FuckingCalculator/platforms/android/app/build/outputs/apk/debug/app-debug.apk

# Dla zegarka:
adb -s YYYYYYYYYY install -r trading_watch_app/build/app/outputs/flutter-apk/app-debug.apk
```

Lub jeśli jedno urządzenie naraz:
```bash
adb install -r ścieżka/do/apk
```

---

## ROZWIĄZYWANIE PROBLEMÓW

### "adb nie jest rozpoznawany jako polecenie"
✅ Dodaj `platform-tools` do PATH (patrz wyżej)

### "Unauthorized device"
✅ Zaakceptuj dialog na urządzeniu
✅ Spróbuj: `adb kill-server` → `adb start-server`

### "Installation failed"
✅ Upewnij się, że targetSdk jest zgodny z wersją Android
✅ Odinstaluj starą wersję z urządzenia
✅ Użyj flagi `-r` (reinstall)

### Zegarek nie pokazuje się w ADB
✅ Użyj kabla USB-C z obsługą danych (nie tylko ładowania)
✅ Sprawdź czy zegarek wymaga specjalnego trybu debugowania
✅ Niektóre zegarki wymagają parowania z telefonem przez Wear OS app

---

## SZYBKIE STARTY (TL;DR)

**Masz już zainstalowane Android Studio?**
```bash
# Tablet
cd FuckingCalculator/platforms/android
gradlew.bat assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Zegarek  
cd trading_watch_app
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Nie masz nic?**
1. Zainstaluj Android Studio (link wyżej)
2. Zainstaluj Flutter SDK (link wyżej)
3. Uruchom polecenia wyżej

---

**Potrzebujesz pomocy?** Powiedz mi na którym kroku masz problem!
