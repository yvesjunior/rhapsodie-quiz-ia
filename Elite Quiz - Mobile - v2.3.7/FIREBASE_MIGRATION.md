# Firebase Migration Guide: Update Mobile App to Use `rhapsodie-quizz`

## Current Situation
- **Admin Panel**: Uses `rhapsodie-quizz` ✅
- **Mobile App**: Uses `quiz-flutter-new` ❌
- **Action Needed**: Update mobile app to use `rhapsodie-quizz`

## Step 1: Add Mobile Apps to Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select the **`rhapsodie-quizz`** project
3. Click the gear icon ⚙️ → **Project Settings**

### Add Android App:
1. Scroll to **"Your apps"** section
2. Click **"Add app"** → Select **Android**
3. Enter:
   - **Package name**: `com.wrteam.flutterquiz` (or your desired package name)
   - **App nickname**: Elite Quiz Android (optional)
   - **Debug signing certificate SHA-1**: (optional for now)
4. Click **Register app**
5. Download `google-services.json`
6. Replace: `android/app/google-services.json`

### Add iOS App:
1. Click **"Add app"** → Select **iOS**
2. Enter:
   - **Bundle ID**: `com.wrteam.flutterquiz` (must match your iOS app)
   - **App nickname**: Elite Quiz iOS (optional)
3. Click **Register app**
4. Download `GoogleService-Info.plist`
5. Replace: `ios/Runner/GoogleService-Info.plist`

## Step 2: Update FlutterFire Configuration

After downloading the config files, regenerate the Flutter configuration:

```bash
cd "Elite Quiz - Mobile - v2.3.7"

# Install FlutterFire CLI if not already installed
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure --project=rhapsodie-quizz
```

This will:
- Update `firebase.json`
- Update `lib/firebase_options.dart`
- Verify the config files are in place

## Step 3: Verify Configuration

Check that all files reference `rhapsodie-quizz`:

```bash
# Check firebase_options.dart
grep "projectId" lib/firebase_options.dart

# Check google-services.json
grep "project_id" android/app/google-services.json

# Check GoogleService-Info.plist
grep "PROJECT_ID" ios/Runner/GoogleService-Info.plist
```

All should show: `rhapsodie-quizz`

## Step 4: Rebuild the App

```bash
# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter build apk --debug
# or
flutter build ios --debug --no-codesign
```

## Important Notes

1. **Package Name/Bundle ID**: Make sure the package name in Firebase matches your app's package name
2. **SHA-1 Certificate**: For production, you'll need to add your release signing certificate SHA-1 to Firebase
3. **Firebase Services**: Ensure these are enabled in Firebase Console:
   - ✅ Cloud Messaging (for push notifications)
   - ✅ Authentication (if using Firebase Auth)
   - ✅ Firestore (if using Firestore)
   - ✅ Analytics (if using Analytics)

## Verification Checklist

- [ ] Android app added to `rhapsodie-quizz` in Firebase Console
- [ ] iOS app added to `rhapsodie-quizz` in Firebase Console
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] `GoogleService-Info.plist` downloaded and placed in `ios/Runner/`
- [ ] `flutterfire configure` run successfully
- [ ] `firebase_options.dart` updated with `rhapsodie-quizz`
- [ ] App rebuilt and tested

## Troubleshooting

### If FlutterFire CLI is not found:
```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### If you get "project not found":
- Make sure you're logged into the correct Google account
- Verify the project ID is exactly `rhapsodie-quizz`

### If push notifications don't work:
- Verify Cloud Messaging API is enabled in Firebase Console
- Check that the service account in admin panel has proper permissions
- Ensure FCM server key is configured in admin panel (if needed)

