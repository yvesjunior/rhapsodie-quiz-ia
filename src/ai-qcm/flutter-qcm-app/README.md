# QCM Mobile App - Flutter

Flutter mobile app for the QCM (Multiple Choice Questions) system with Laravel backend.

## 🎨 Design to Code Workflow

### Step 1: Design in Figma
Create your app screens:
- **Home Screen**: List of available QCMs
- **QCM Screen**: Questions with multiple choice options
- **Results Screen**: Score and correct answers
- **Leaderboard Screen**: Rankings
- **Profile Screen**: User stats

### Step 2: Convert to Flutter

#### Using Figma Plugin:
1. Install "Figma to Flutter" plugin in Figma
2. Select your design frame
3. Generate Flutter code
4. Copy to your project

#### Manual Conversion:
1. Extract design tokens (colors, fonts, spacing)
2. Create widget structure
3. Match exact measurements from Figma
4. Add interactivity

### Step 3: Connect to Laravel API

```dart
// api_service.dart
class ApiService {
  final String baseUrl = 'http://localhost:8000/api';
  
  Future<List<Qcm>> getQcms() async {
    final response = await http.get(Uri.parse('$baseUrl/qcm'));
    // Parse and return QCMs
  }
  
  Future<ScoreResult> submitAnswers(int qcmId, Map answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/qcm/$qcmId/submit'),
      body: jsonEncode({'answers': answers}),
    );
    // Parse and return score
  }
}
```

## 📱 App Structure

```
lib/
├── main.dart
├── models/
│   ├── qcm.dart
│   ├── question.dart
│   └── score.dart
├── screens/
│   ├── home_screen.dart
│   ├── qcm_screen.dart
│   ├── results_screen.dart
│   └── leaderboard_screen.dart
├── widgets/
│   ├── qcm_card.dart
│   ├── question_widget.dart
│   └── option_button.dart
├── services/
│   ├── api_service.dart
│   └── auth_service.dart
└── theme/
    └── app_theme.dart
```

## 🎯 Key Features

- **QCM List**: Browse available quizzes
- **Interactive Questions**: Select multiple answers
- **Real-time Scoring**: Immediate feedback
- **Leaderboards**: Global and per-QCM rankings
- **User Authentication**: Login/Register
- **Offline Support**: Cache QCMs locally

## 🔗 API Integration

All endpoints from Laravel API:
- `GET /api/qcm` - List QCMs
- `GET /api/qcm/{id}` - Get QCM details
- `POST /api/qcm/{id}/submit` - Submit answers
- `GET /api/qcm/{id}/leaderboard` - QCM leaderboard
- `GET /api/leaderboard` - Global leaderboard

## 🚀 Getting Started

1. **Install Flutter**: https://flutter.dev/docs/get-started/install
2. **Create Project**: `flutter create qcm_app`
3. **Add Dependencies**:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     http: ^1.1.0
     provider: ^6.1.1
     shared_preferences: ^2.2.2
   ```
4. **Design**: Use Figma to Flutter plugin or manual conversion
5. **Connect**: Integrate with Laravel API
6. **Test**: Run on iOS/Android devices

## 📦 Recommended Packages

- **http**: API calls
- **provider**: State management
- **shared_preferences**: Local storage
- **cached_network_image**: Image caching
- **flutter_svg**: SVG support
- **lottie**: Animations

