# Windows Build Workaround (Temporary)

## Problem
The `flutter_facebook_auth` package requires ATL libraries on Windows, which causes build failures if ATL is not installed in Visual Studio.

## Quick Workaround (If you can't install ATL right now)

If you need to build for Windows immediately and can't install ATL, you can temporarily comment out the Facebook auth package:

### Step 1: Comment out Facebook package in pubspec.yaml
```yaml
  # Facebook Login (commented out for Windows build - requires ATL)
  # flutter_facebook_auth: ^7.1.2
```

### Step 2: Update sample_auth.dart
Remove or comment out the Facebook import:
```dart
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
```

### Step 3: Clean and rebuild
```bash
flutter clean
flutter pub get
flutter build windows
```

**Note:** This will disable Facebook login on all platforms. The simulated Facebook login will still work on Windows.

## Permanent Solution (Recommended)

Install ATL libraries in Visual Studio (see WINDOWS_BUILD_FIX.md for detailed instructions). This is the proper solution and will allow Facebook login to work on Android, iOS, and Web while using simulated login on Windows.

## Current Status

The code is already set up to:
- Use simulated Facebook login on Windows/Linux/macOS
- Use real Facebook login on Android/iOS/Web
- Gracefully handle missing Facebook auth package

The build will work once ATL is installed, or you can use the workaround above to build without Facebook auth temporarily.

