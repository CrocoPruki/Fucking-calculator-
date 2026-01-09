# Instrukcje uruchomienia - setup-windows.ps1

## Krok 1: Otwórz PowerShell jako Administrator
1. Naciśnij `Win + X`
2. Wybierz "Windows PowerShell (Admin)" lub "Terminal (Admin)"

## Krok 2: Uruchom skrypt
```powershell
cd C:\Users\Maacias\FuckingCalculator
.\setup-windows.ps1
```

## Krok 3: Zainstaluj Android Studio RĘCZNIE
1. Pobierz z: https://developer.android.com/studio
2. Uruchom instalator
3. Podczas instalacji zaznacz:
   ✅ Android SDK
   ✅ Android SDK Platform
   ✅ Android Virtual Device

## Krok 4: Skonfiguruj Android SDK
1. Otwórz Android Studio
2. File → Settings → Android SDK
3. Zakładka **SDK Platforms**:
   - Zaznacz: Android 15.0 (V) - API Level 35
4. Zakładka **SDK Tools**:
   - Zaznacz: Android SDK Build-Tools 35
   - Zaznacz: Android SDK Platform-Tools
   - Zaznacz: Android SDK Command-line Tools
5. Kliknij **Apply** i poczekaj

## Krok 5: Ustaw zmienne środowiskowe
1. Wyszukaj: "Zmienne środowiskowe" w Start
2. Kliknij: "Edytuj zmienne środowiskowe systemu"
3. Kliknij: "Zmienne środowiskowe"
4. W sekcji "Zmienne systemowe" kliknij "Nowa":
   - Nazwa: `ANDROID_HOME`
   - Wartość: `C:\Users\Maacias\AppData\Local\Android\Sdk`
5. Edytuj zmienną `Path` i dodaj:
   - `C:\Users\Maacias\AppData\Local\Android\Sdk\platform-tools`
   - `C:\Users\Maacias\AppData\Local\Android\Sdk\cmdline-tools\latest\bin`

## Krok 6: Zbuduj APK
Otwórz NOWY terminal CMD i uruchom:
```cmd
cd C:\Users\Maacias\FuckingCalculator
cordova build android
```

APK będzie w:
`platforms\android\app\build\outputs\apk\debug\app-debug.apk`

## Krok 7: Zainstaluj na tablecie
```cmd
adb install -r platforms\android\app\build\outputs\apk\debug\app-debug.apk
```
