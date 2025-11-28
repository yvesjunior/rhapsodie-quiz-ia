# Mac-Specific Setup Guide

## Advantages of Mac Development

As a Mac user, you can develop for **both iOS and Android** platforms!

## Current Configuration

### API URL Settings
The app is configured to use `http://localhost:8080` which works perfectly for:
- ✅ **iOS Simulator** (runs on your Mac, can access localhost)
- ✅ **Physical iOS devices** (when on same network, use Mac's IP: `10.0.0.39:8080`)
- ✅ **Android Emulator** (use `http://10.0.2.2:8080` - special Android emulator IP)
- ✅ **Physical Android devices** (use Mac's IP: `10.0.0.39:8080`)

### Your Mac's Network Info
- **Local IP**: `10.0.0.39`
- **Admin Panel URL**: `http://localhost:8080` (for iOS Simulator)
- **Admin Panel URL**: `http://10.0.0.39:8080` (for physical devices)

## Quick Start Commands

### iOS Development (Mac Only)

#### 1. Launch iOS Simulator
```bash
flutter emulators --launch apple_ios_simulator
```

#### 2. Run on iOS Simulator
```bash
cd "Elite Quiz - Mobile - v2.3.7"
flutter run
```

#### 3. Build iOS App
```bash
# Debug build (no code signing needed)
flutter build ios --debug --no-codesign

# Release build (requires Apple Developer account)
flutter build ios --release
```

### Android Development

#### 1. Run on Android Emulator/Device
```bash
flutter run
```

#### 2. Build Android APK
```bash
# Debug APK (already built)
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

## Testing on Physical Devices

### iOS Device (iPhone/iPad)
1. Connect device via USB
2. Trust the computer on your device
3. Open Xcode and select your device
4. Run: `flutter run`

**Note**: For physical iOS devices, update `config.dart` to use your Mac's IP:
```dart
const panelUrl = 'http://10.0.0.39:8080';
```

### Android Device
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter run`

**Note**: For physical Android devices, update `config.dart` to use your Mac's IP:
```dart
const panelUrl = 'http://10.0.0.39:8080';
```

## Switching API URLs

Edit `lib/core/config/config.dart`:

```dart
// For iOS Simulator (current setting)
const panelUrl = 'http://localhost:8080';

// For physical devices (uncomment when needed)
// const panelUrl = 'http://10.0.0.39:8080';

// For Android Emulator (uncomment when needed)
// const panelUrl = 'http://10.0.2.2:8080';
```

## Current Build Status

✅ **Android Debug APK**: Built successfully
- Location: `build/app/outputs/flutter-apk/app-debug.apk`
- Size: 116 MB

✅ **iOS**: Ready to build (Xcode 16.1 installed)
- CocoaPods installed
- Dependencies ready

## Troubleshooting

### iOS Simulator Issues
```bash
# Reset simulator
xcrun simctl erase all

# List available simulators
xcrun simctl list devices
```

### Android Emulator Issues
```bash
# List available emulators
flutter emulators

# Create new emulator (if needed)
flutter emulators --create
```

### Network Issues
- Ensure admin panel is running: `docker-compose up` in admin panel directory
- Check firewall settings on Mac
- Verify devices are on same network

### Xcode Command Line Tools
If Xcode issues occur:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

## Next Steps

1. **Test on iOS Simulator**:
   ```bash
   flutter emulators --launch apple_ios_simulator
   flutter run
   ```

2. **Test on Android** (if emulator available):
   ```bash
   flutter run
   ```

3. **Build Release Versions** when ready for production

