[![Codespaces Prebuilds](https://github.com/mikaelkraft/Quicknote_Pro/actions/workflows/codespaces/create_codespaces_prebuilds/badge.svg)](https://github.com/mikaelkraft/Quicknote_Pro/actions/workflows/codespaces/create_codespaces_prebuilds)

# Quicknote Pro

A modern note-taking application with cloud sync, voice notes, drawing tools, and premium features. Supports multiple cloud storage providers including Google Drive, OneDrive, Dropbox, and more.

## 📋 Prerequisites

- Flutter SDK (^3.6.0)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

## 🛠️ Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:
```bash
flutter run
```

## ☁️ Cloud Sync Setup

QuickNote Pro supports multiple cloud storage providers. Google Drive is fully functional, while other providers are placeholders for future implementation.

### Google Drive (Fully Functional)

To enable Google Drive sync, you need to configure OAuth 2.0:

#### 1. Google Cloud Console Setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Drive API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client IDs"
5. Configure consent screen if prompted

#### 2. Create OAuth Client IDs

**For Android:**
1. Select "Android" as application type
2. Package name: `com.quicknotepro.app` (or your package name)
3. Get SHA-1 certificate fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

**For iOS:**
1. Select "iOS" as application type  
2. Bundle ID: `com.quicknotepro.app` (or your bundle ID)

**For Web (optional):**
1. Select "Web application" as application type
2. Add authorized redirect URIs

#### 3. Configure Environment Variables

Set the Google Drive client ID as an environment variable:

```bash
# For development
export GOOGLE_DRIVE_CLIENT_ID="your-client-id.googleusercontent.com"

# Or add to your IDE run configuration
--dart-define=GOOGLE_DRIVE_CLIENT_ID=your-client-id.googleusercontent.com
```

#### 4. Android Configuration

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name="net.openid.appauth.RedirectUriReceiverActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="com.quicknotepro.app" />
    </intent-filter>
</activity>
```

#### 5. iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.quicknotepro.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.quicknotepro.app</string>
        </array>
    </dict>
</array>
```

### Other Cloud Providers (Coming Soon)

#### OneDrive
- **Status**: Placeholder implementation
- **Requirements**: Microsoft Graph API credentials
- **Setup**: Configure `ONEDRIVE_CLIENT_ID` environment variable
- **Features**: Delta sync support, 250MB file limit

#### Dropbox  
- **Status**: Placeholder implementation
- **Requirements**: Dropbox API app credentials
- **Setup**: Configure `DROPBOX_CLIENT_ID` environment variable
- **Features**: Cursor-based delta sync, 150MB file limit

#### iCloud Drive
- **Status**: Placeholder implementation (iOS/macOS only)
- **Requirements**: CloudKit configuration
- **Features**: Offline sync, Apple ecosystem integration

#### Box
- **Status**: Placeholder implementation
- **Requirements**: Box API credentials
- **Setup**: Configure `BOX_CLIENT_ID` environment variable
- **Features**: Enterprise features, 250MB file limit

#### WebDAV
- **Status**: Placeholder implementation
- **Requirements**: WebDAV server credentials
- **Setup**: Configure `WEBDAV_URL`, `WEBDAV_USERNAME`, `WEBDAV_PASSWORD`
- **Features**: Self-hosted storage, custom server support

#### Amazon S3
- **Status**: Placeholder implementation
- **Requirements**: AWS credentials and S3 bucket
- **Setup**: Configure `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_BUCKET`
- **Features**: Scalable storage, 5GB file limit

#### Bitbucket
- **Status**: Placeholder implementation
- **Requirements**: Bitbucket repository and OAuth
- **Setup**: Configure `BITBUCKET_CLIENT_ID`, `BITBUCKET_REPOSITORY`
- **Features**: Git-based sync, version history

## 🎨 Theme System

The app includes a reactive theme system with persistence:

```dart
// Access theme service
final themeService = Provider.of<ThemeService>(context);

// Change theme mode
await themeService.setThemeMode(ThemeMode.dark);

// Check current theme
bool isDark = themeService.isDarkMode(context);
```

### Available Theme Modes:
- **System**: Follows device theme settings
- **Light**: Always light theme
- **Dark**: Always dark theme

Themes persist across app restarts and update instantly without restart.

## 💎 Premium Features

QuickNote Pro offers premium subscriptions with centralized pricing:

### Premium Plans
- **Monthly**: $1.00/month (`quicknote_premium_monthly`)
- **Lifetime**: $5.00 one-time (`quicknote_premium_lifetime`)

### Premium Features
- Unlimited voice notes (free: 10/month)
- Advanced drawing tools with layers
- Cloud sync across all devices
- Ad-free experience
- Priority support

### IAP Configuration

The app includes feature flags for In-App Purchases:

```dart
// Enable/disable IAP
ProductIds.iapEnabled = true;

// Allow dev bypass in debug builds
ProductIds.allowDevBypass = true;
```

For production, configure platform-specific IAP:
- **Android**: Google Play Console products
- **iOS**: App Store Connect products  
- **Web**: Stripe or similar payment provider

## 📁 Project Structure

```
lib/
├── constants/          # App-wide constants
│   └── product_ids.dart   # Premium product IDs
├── core/              # Core utilities and exports
├── presentation/      # UI screens and widgets
│   ├── settings_profile/
│   │   ├── settings_profile.dart
│   │   └── cloud_connections.dart
│   └── premium_upgrade/
├── routes/           # Application routing
├── services/         # Business logic services
│   ├── theme/           # Theme management
│   ├── sync/            # Cloud sync providers
│   └── iap/             # In-app purchases
├── theme/            # Theme configuration
├── widgets/          # Reusable UI components
└── main.dart         # Application entry point
```

## 🔧 Build Configuration

### Android Build
```bash
flutter build apk --release --dart-define=GOOGLE_DRIVE_CLIENT_ID=your-client-id
```

### iOS Build  
```bash
flutter build ios --release --dart-define=GOOGLE_DRIVE_CLIENT_ID=your-client-id
```

### Web Build
```bash
flutter build web --release --dart-define=GOOGLE_DRIVE_CLIENT_ID=your-client-id
```

## 🧪 Testing

### Theme Testing
1. Launch app and go to Settings
2. Toggle between Light/Dark/System themes
3. Restart app to verify persistence
4. Check that theme applies instantly

### Google Drive Testing
1. Configure OAuth credentials (see setup above)
2. Go to Settings → Cloud Storage → Connect Google Drive
3. Complete OAuth flow
4. Verify connection status in settings
5. Test manual sync functionality

### Premium Testing
In debug builds, you can use the dev bypass:
1. Enable `ProductIds.allowDevBypass = true`
2. Use IAP service toggle for testing premium features

## 🔒 Security & Privacy

- OAuth tokens stored securely using `flutter_secure_storage`
- No credentials stored in source code
- Environment variables for sensitive configuration
- Secure token refresh and revocation
- Feature flags for safe deployment

## 🚀 Deployment

### Environment Variables Checklist
- [ ] `GOOGLE_DRIVE_CLIENT_ID` - Google OAuth client ID
- [ ] `ONEDRIVE_CLIENT_ID` - Microsoft OAuth client ID (future)
- [ ] `DROPBOX_CLIENT_ID` - Dropbox OAuth client ID (future)
- [ ] Platform-specific IAP configuration

### Build Safety
- All sync providers include feature flags
- App builds successfully without any credentials
- Helpful error messages when providers are not configured
- Graceful degradation when services are unavailable

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with proper error handling
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

Built with ❤️ by [Mikael Kraft](https://x.com/mikael_kraft)
