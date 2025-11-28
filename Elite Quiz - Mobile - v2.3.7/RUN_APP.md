# How to Run the Mobile App

## Current Situation
No iOS or Android emulators are currently available. Here are your options:

## Option 1: iOS Simulator (Recommended for Mac)

### Quick Setup:
1. **Xcode is opening** - Wait for it to fully load
2. In Xcode, go to: **Xcode → Settings → Platforms** (or **Components** in older versions)
3. Install **iOS Simulator Runtime** (iOS 18.1 or latest available)
4. Wait for download to complete (this may take 10-30 minutes depending on internet speed)

### Once iOS Simulator is installed:
```bash
cd "Elite Quiz - Mobile - v2.3.7"
flutter emulators --launch apple_ios_simulator
flutter run
```

### Alternative: Open Simulator directly
```bash
open -a Simulator
# Wait for simulator to boot, then:
flutter run
```

---

## Option 2: Android Emulator

### If you have Android Studio installed:
1. Open Android Studio
2. Go to **Tools → Device Manager**
3. Click **Create Device** (or use existing emulator)
4. Select a device (e.g., Pixel 5)
5. Click **Start** to launch the emulator
6. Once emulator is running:
```bash
cd "Elite Quiz - Mobile - v2.3.7"
flutter run
```

### If Android Studio is not installed:
Download from: https://developer.android.com/studio

---

## Option 3: Physical Device

### Android Device:
1. Enable **Developer Options** on your Android phone:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
2. Enable **USB Debugging**:
   - Settings → Developer Options → USB Debugging
3. Connect phone via USB
4. Run:
```bash
cd "Elite Quiz - Mobile - v2.3.7"
flutter run
```

### iOS Device (iPhone/iPad):
1. Connect device via USB
2. Trust the computer on your device
3. Open Xcode: `open ios/Runner.xcworkspace`
4. Select your device in Xcode
5. Sign in with your Apple ID in Xcode (Settings → Accounts)
6. Select a Development Team
7. Run:
```bash
cd "Elite Quiz - Mobile - v2.3.7"
flutter run
```

---

## Option 4: Use Pre-built APK (Android Only)

The Android APK is already built and ready to install:

**Location**: `build/app/outputs/flutter-apk/app-debug.apk` (148 MB)

### Install on Android device:
1. Transfer the APK to your Android device
2. Enable "Install from Unknown Sources" in Settings
3. Tap the APK file to install
4. Open the app

### Or use ADB (if device connected):
```bash
cd "Elite Quiz - Mobile - v2.3.7"
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## Quick Check Commands

### Check available devices:
```bash
flutter devices
```

### List emulators:
```bash
flutter emulators
```

### Check Flutter setup:
```bash
flutter doctor
```

---

## Troubleshooting

### iOS Simulator not showing:
- Wait for Xcode to finish downloading iOS runtime
- Restart Xcode
- Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

### Android Emulator not found:
- Install Android Studio
- Create an AVD (Android Virtual Device) in Android Studio
- Ensure Android SDK is properly installed

### No devices found:
- Make sure at least one emulator is running OR
- Physical device is connected and authorized

---

## Recommended Next Steps

1. **Wait for iOS Simulator download** (if Xcode is downloading)
   - This is the easiest option on Mac
   - Once complete, just run `flutter run`

2. **Or use Android Emulator** (if you have Android Studio)
   - Faster to set up if Android Studio is already installed

3. **Or install APK on physical Android device**
   - Quickest if you have an Android phone handy

The app is ready to run - you just need a device/emulator to run it on!

