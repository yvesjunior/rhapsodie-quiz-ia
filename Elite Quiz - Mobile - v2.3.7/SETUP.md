# Mobile App Setup Guide

## Prerequisites

### 1. Install Flutter

Flutter is required to build and run the mobile app. Install it using one of these methods:

#### Option A: Using Homebrew (Recommended for macOS)
```bash
brew install --cask flutter
```

#### Option B: Manual Installation
1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/macos
2. Extract the archive to a location like `~/development/flutter`
3. Add Flutter to your PATH:
   ```bash
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```
   Add this to your `~/.zshrc` or `~/.bash_profile` for persistence

#### Verify Installation
```bash
flutter doctor
```

### 2. Install Additional Dependencies

#### Android Development
- Android Studio (https://developer.android.com/studio)
- Android SDK (installed via Android Studio)
- Accept Android licenses:
  ```bash
  flutter doctor --android-licenses
  ```

#### iOS Development (macOS only)
- Xcode (from App Store)
- CocoaPods:
  ```bash
  sudo gem install cocoapods
  ```

## Configuration

### API URL
The API URL has been configured to point to your local admin panel:
- **Local IP**: `http://10.0.0.39:8080`
- **Android Emulator**: Use `http://10.0.2.2:8080` (special IP for Android emulator)
- **iOS Simulator**: Use `http://localhost:8080` or `http://10.0.0.39:8080`

To change the API URL, edit: `lib/core/config/config.dart`

## Building the App

### 1. Get Dependencies
```bash
cd "Elite Quiz - Mobile - v2.3.7"
flutter pub get
```

### 2. iOS Setup (macOS only)
```bash
cd ios
pod install
cd ..
```

### 3. Run on Device/Emulator

#### Android
```bash
# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# Or build APK
flutter build apk --debug
flutter build apk --release
```

#### iOS (macOS only)
```bash
# List available devices
flutter devices

# Run on connected device/simulator
flutter run

# Or build IPA
flutter build ios --release
```

### 4. Build Release Versions

#### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS (requires Apple Developer account)
```bash
flutter build ios --release
# Then open Xcode to archive and upload
```

## Troubleshooting

### Flutter Doctor Issues
Run `flutter doctor -v` to see detailed information about your setup.

### Common Issues

1. **Android licenses not accepted**
   ```bash
   flutter doctor --android-licenses
   ```

2. **iOS CocoaPods issues**
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   ```

3. **Build cache issues**
   ```bash
   flutter clean
   flutter pub get
   ```

4. **API connection issues on Android Emulator**
   - Change API URL in `config.dart` to `http://10.0.2.2:8080`

5. **API connection issues on physical device**
   - Ensure your device and computer are on the same network
   - Use your computer's local IP (currently: `10.0.0.39:8080`)
   - Ensure firewall allows connections on port 8080

## Firebase Configuration

The app uses Firebase for:
- Authentication
- Cloud Firestore
- Analytics
- Push Notifications

Firebase configuration files are already in place:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## Notes

- The admin panel must be running before testing the mobile app
- For production, update the `panelUrl` in `config.dart` to your production server
- Ensure CORS is properly configured on the admin panel if needed

