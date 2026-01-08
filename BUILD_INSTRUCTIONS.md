# Instrukcje Budowania APK

## WAŻNE: Urządzenia docelowe
- **Samsung A9 Plus 5G** - Android 16 (tablet)
- **Samsung Galaxy Watch Ultra** - Wear OS 6 (zegarek)

## Aplikacje zostały zaktualizowane dla:
✅ Android 16 (targetSdk = 36)  
✅ Wear OS 6 (dla zegarka)

---

## 1. APK dla TABLETU (FuckingCalculator - Cordova)

### Wymagania:
- Node.js
- Java JDK 17+
- Android SDK (Android 16 / API 36)
- Cordova CLI

### Kroki budowania:

```bash
# 1. Przejdź do folderu projektu
cd FuckingCalculator

# 2. Zainstaluj zależności (jeśli jeszcze nie)
npm install

# 3. Dodaj platformę Android (jeśli jeszcze nie)
cordova platform add android

# 4. Zbuduj APK
cordova build android --debug

# 5. APK będzie w:
# platforms/android/app/build/outputs/apk/debug/app-debug.apk

# 6. Zainstaluj na tablecie Samsung A9 Plus 5G
adb install -r platforms/android/app/build/outputs/apk/debug/app-debug.apk
```

### Dla wersji RELEASE (podpisanej):
```bash
cordova build android --release
```

---

## 2. APK dla ZEGARKA (trading_watch_app - Flutter)

### Wymagania:
- Flutter SDK (najnowszy)
- Android SDK (Android 16 / API 36)
- Java JDK 17+

### Kroki budowania:

```bash
# 1. Przejdź do folderu projektu
cd trading_watch_app

# 2. Pobierz zależności Flutter
flutter pub get

# 3. Zbuduj APK dla Wear OS (debug)
flutter build apk --debug

# 4. APK będzie w:
# build/app/outputs/flutter-apk/app-debug.apk

# 5. Zainstaluj na Galaxy Watch Ultra przez ADB
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Dla wersji RELEASE:
```bash
flutter build apk --release
```

---

## ROZWIĄZYWANIE PROBLEMÓW

### Problem: "Zły enkoding" lub wykrzyknik przy instalacji

**Przyczyny:**
1. APK zbudowany dla starszej wersji Android (rozwiązane ✅)
2. Brak uprawnień USB Debugging
3. APK nie jest podpisany poprawnie

**Rozwiązanie:**

#### Na tablecie/zegarku:
1. Włącz **Opcje dewelopera**:
   - Ustawienia → O urządzeniu
   - Stukaj 7 razy w "Numer kompilacji"
2. Włącz **Debugowanie USB**:
   - Ustawienia → Opcje programisty → Debugowanie USB
3. Połącz kabel USB
4. Zaakceptuj "Zezwolić na debugowanie USB" (zaznacz "Zawsze zezwalaj")

#### Na komputerze:
```bash
# Restart serwera ADB
adb kill-server
adb start-server

# Sprawdź urządzenia
adb devices
# Powinno pokazać:
# List of devices attached
# <device-id>   device

# Zainstaluj APK
adb install -r ścieżka/do/app-debug.apk

# Dla konkretnego urządzenia (gdy podłączone oba):
adb -s <device-id> install -r ścieżka/do/app-debug.apk
```

### Problem: ADB nie widzi urządzeń

```bash
# Windows - może wymagać sterowników Samsung
# Pobierz: Samsung USB Drivers for Mobile Phones

# Linux:
# Dodaj reguły udev
sudo usermod -aG plugdev $LOGNAME

# macOS:
# Sprawdź System Settings → Security & Privacy → Developer Tools
```

---

## AKTUALIZACJE W PROJEKTACH

### FuckingCalculator:
- ✅ `targetSdk` = 36 (Android 16)
- ✅ `compileSdk` = 36
- ✅ `minSdk` = 24

### trading_watch_app:
- ✅ `targetSdk` = 36 (Android 16)  
- ✅ `compileSdk` = 36
- ✅ `minSdk` = 30 (Wear OS 3+ wymaga API 30+)
- ✅ Dodano `uses-feature android.hardware.type.watch`
- ✅ Dodano kategorię `com.google.android.wearable.standalone`
- ✅ Dodano uprawnienia `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`

---

## FUNKCJE APLIKACJI

### FuckingCalculator (na tablet):
- Kalkulator ryzyka tradingowego
- Wprowadzasz: Kapitał, Ryzyko %, Stop Loss %
- Oblicza: Optymalną dźwignię spośród 1x, 1.8x, 2x, 3x, 5x, 8x, 10x, 20x, 50x, 100x

### trading_watch_app (na zegarek):
- **Tab 1:** Kalkulator ryzyka (jak wyżej)
- **Tab 2:** Wykres ceny Bitcoin (live z API)
- **Tab 3:** Alerty cenowe BTC z powiadomieniami

---

**Data aktualizacji:** 8 stycznia 2026  
**SDK:** Android 16 (API 36) + Wear OS 6
