# Firebase Analytics Setup Guide

This guide walks you through setting up Firebase Analytics for Quicknote Pro to enable comprehensive monetization and usage tracking.

## 🎯 Analytics Implementation Status

✅ **Monetization Events Implemented:**
- Premium upgrade flow tracking (screen views, plan selection, trial starts)
- Feature limit reached tracking with usage metrics
- Premium feature usage tracking for paying users  
- Subscription status user property setting
- Restore purchases tracking

✅ **Safe Operation:** App runs perfectly without Firebase configuration in no-op mode.

## Prerequisites

- Flutter SDK installed
- Quicknote Pro development environment set up
- Firebase project created (or access to create one)
- FlutterFire CLI installed

## Installation Steps

### 1. Install FlutterFire CLI

If you haven't already, install the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

### 2. Configure Firebase for Your Project

Run the FlutterFire configuration command in your project root:

```bash
flutterfire configure
```

This command will:
- Prompt you to select or create a Firebase project
- Automatically configure your iOS and Android apps
- Generate the necessary configuration files
- Update your platform-specific files

### 3. Platform-Specific Setup

#### Android Setup

The FlutterFire CLI will automatically:
- Add the `google-services.json` file to `android/app/`
- Update `android/build.gradle` and `android/app/build.gradle`
- Configure the Google Services plugin

#### iOS Setup

The FlutterFire CLI will automatically:
- Add the `GoogleService-Info.plist` file to `ios/Runner/`
- Update your iOS project configuration
- Configure Info.plist settings

### 4. Verify Installation

After running `flutterfire configure`, verify that:

1. **Configuration files exist:**
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `lib/firebase_options.dart`

2. **Dependencies are installed:**
   ```bash
   flutter pub get
   ```

3. **App builds successfully:**
   ```bash
   flutter build apk --debug
   # or
   flutter build ios --debug
   ```

## Testing Firebase Analytics

Once configured, the app will automatically start sending analytics events to Firebase. You can verify this by:

### 1. Running the App

```bash
flutter run
```

### 2. Checking Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Analytics → Events
4. You should see events appearing within a few minutes

### 3. Debug Mode (Development)

For immediate event verification during development:

1. Enable debug mode on your device/emulator:
   ```bash
   # Android
   adb shell setprop debug.firebase.analytics.app com.example.quicknote_pro
   
   # iOS (via Xcode scheme or command line)
   # Add -FIRAnalyticsDebugEnabled to your scheme arguments
   ```

2. Events will appear immediately in the Firebase Console DebugView

## Safe No-Op Behavior

The analytics service is designed to work gracefully without Firebase configuration:

- **Before Configuration**: All analytics calls are no-ops with debug logging
- **After Configuration**: Events are sent to Firebase Analytics
- **Error Handling**: If Firebase fails to initialize, the service falls back to no-op mode

This means your app will work perfectly fine during development and testing, even before Firebase is configured.

## Development Workflow

1. **Initial Development**: Work without Firebase configuration
2. **Testing Phase**: Configure Firebase for testing/staging
3. **Production**: Use production Firebase project

## Troubleshooting

### Common Issues

1. **"Firebase not configured" errors**
   - Run `flutterfire configure` again
   - Ensure configuration files are in the correct locations
   - Check that your bundle ID/package name matches Firebase project

2. **Events not appearing in Firebase Console**
   - Wait up to 24 hours for non-debug events
   - Use debug mode for immediate verification
   - Check that analytics collection is enabled

3. **Build errors after configuration**
   - Run `flutter clean && flutter pub get`
   - Ensure all platform-specific configurations are correct
   - Check Firebase project settings

### Support

- [Firebase Documentation](https://firebase.google.com/docs/analytics/get-started?platform=flutter)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/analytics/overview/)
- [Firebase Console](https://console.firebase.google.com)

## Next Steps

After setting up Firebase Analytics:

1. Review the [events documentation](events.md) for available events
2. Implement monetization tracking as per [monetization guide](README.md)
3. Set up custom dashboards in Firebase Console
4. Configure conversion events for your monetization funnel