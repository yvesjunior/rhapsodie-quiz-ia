# Figma to Flutter Code Conversion Guide

## 🎯 Best Tools for 2024

### 1. **Figma to Flutter Plugin** (Free, Recommended)
- **Install**: Figma Community → Search "Figma to Flutter"
- **Best for**: Quick component conversion
- **How it works**:
  1. Select your design frame in Figma
  2. Run the plugin
  3. Copy generated Flutter code
  4. Paste into your project

### 2. **DhiWise** (Free/Paid)
- **Website**: https://www.dhiwise.com
- **Best for**: Complete app generation
- **Features**:
  - Converts entire Figma files to Flutter
  - Generates state management code
  - Supports API integration
  - Clean architecture

### 3. **UI2CODE.AI** (AI-Powered)
- **Website**: https://ui2code.ai
- **Best for**: Production-ready code
- **Features**:
  - AI-powered conversion
  - Material & Cupertino widgets
  - Maintains design fidelity

### 4. **Monday Hero**
- **Website**: https://mondayhero.io
- **Best for**: Responsive designs
- **Features**:
  - Multi-platform support
  - Responsive code generation
  - Component library

## 📱 For Your QCM App

### Recommended Workflow:

1. **Design in Figma**:
   ```
   Screens to design:
   - Home (QCM List)
   - QCM Detail (Questions)
   - Results (Score)
   - Leaderboard
   - Profile
   ```

2. **Use Figma to Flutter Plugin**:
   - Export each screen
   - Get base widget structure
   - Extract colors, fonts, spacing

3. **Manual Refinement**:
   - Connect to Laravel API
   - Add state management (Provider/Riverpod)
   - Implement navigation
   - Add animations

## 🎨 Design Token Extraction

### From Figma to Flutter:

```dart
// theme/app_theme.dart
class AppTheme {
  // Colors from Figma
  static const primaryColor = Color(0xFF667eea);
  static const secondaryColor = Color(0xFF764ba2);
  static const backgroundColor = Color(0xFFF8F9FA);
  
  // Spacing from Figma
  static const spacingSmall = 8.0;
  static const spacingMedium = 16.0;
  static const spacingLarge = 24.0;
  
  // Typography from Figma
  static const headingFont = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
}
```

## 🔧 Step-by-Step Conversion

### Method 1: Plugin (Fastest)
1. Open Figma design
2. Install "Figma to Flutter" plugin
3. Select frame → Generate
4. Copy code → Paste in Flutter

### Method 2: DhiWise (Complete)
1. Go to dhiwise.com
2. Create Flutter project
3. Upload Figma file
4. Map screens
5. Download generated code

### Method 3: Manual (Best Quality)
1. Export assets (images, icons)
2. Extract design tokens
3. Build widgets manually
4. Match exact measurements

## 📦 Flutter Project Setup

```bash
# Create Flutter project
flutter create qcm_app
cd qcm_app

# Add dependencies
flutter pub add http provider shared_preferences
```

## 🔗 Connect to Laravel API

```dart
// lib/services/api_service.dart
class ApiService {
  static const baseUrl = 'http://localhost:8000/api';
  
  Future<List<Qcm>> getQcms() async {
    final response = await http.get(Uri.parse('$baseUrl/qcm'));
    return (jsonDecode(response.body)['data'] as List)
        .map((e) => Qcm.fromJson(e))
        .toList();
  }
  
  Future<ScoreResult> submitAnswers(int qcmId, Map answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/qcm/$qcmId/submit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'answers': answers}),
    );
    return ScoreResult.fromJson(jsonDecode(response.body));
  }
}
```

## 🎯 QCM App Widget Structure

```dart
// lib/widgets/qcm_card.dart
class QcmCard extends StatelessWidget {
  final Qcm qcm;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      // Match Figma design exactly
      child: ListTile(
        title: Text(qcm.title),
        subtitle: Text('${qcm.totalQuestions} questions'),
        trailing: Icon(Icons.arrow_forward),
      ),
    );
  }
}
```

## 🚀 Quick Start Checklist

- [ ] Design app screens in Figma
- [ ] Install Figma to Flutter plugin
- [ ] Generate base code from designs
- [ ] Extract design tokens (colors, fonts)
- [ ] Create Flutter project
- [ ] Set up API service
- [ ] Connect to Laravel backend
- [ ] Test on iOS/Android

## 📚 Resources

- **Figma Plugin**: https://www.figma.com/community/plugin/901832450488260934
- **DhiWise Docs**: https://docs.dhiwise.com
- **Flutter Docs**: https://docs.flutter.dev
- **Material Design**: https://material.io/design

## 💡 Pro Tips

1. **Start with Components**: Convert reusable components first
2. **Use Design Tokens**: Extract colors, fonts, spacing systematically
3. **Test Responsively**: Check different screen sizes
4. **API Integration**: Connect early to test data flow
5. **State Management**: Use Provider or Riverpod for app state
