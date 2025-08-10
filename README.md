[![Codespaces Prebuilds](https://github.com/mikaelkraft/Quicknote_Pro/actions/workflows/codespaces/create_codespaces_prebuilds/badge.svg)](https://github.com/mikaelkraft/Quicknote_Pro/actions/workflows/codespaces/create_codespaces_prebuilds)

# Quicknote Pro

A modern note-taking application that allows you to doodle, take screenshots, upload images, use voice note, sync to cloud and save to multiple servers.

## 📋 Prerequisites

- Flutter SDK (^3.29.2)
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

## 📁 Project Structure

```
flutter_app/
├── android/            # Android-specific configuration
├── ios/                # iOS-specific configuration
├── lib/
│   ├── core/           # Core utilities and services
│   │   └── utils/      # Utility classes
│   ├── presentation/   # UI screens and widgets
│   │   └── splash_screen/ # Splash screen implementation
│   ├── routes/         # Application routing
│   ├── theme/          # Theme configuration
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # Application entry point
├── assets/             # Static assets (images, fonts, etc.)
├── pubspec.yaml        # Project dependencies and configuration
└── README.md           # Project documentation
```

## 🧩 Adding Routes

To add new routes to the application, update the `lib/routes/app_routes.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:package_name/presentation/home_screen/home_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    // Add more routes as needed
  }
}
```

## 🎨 Theming

This project includes a comprehensive theming system with both light and dark themes:

```dart
// Access the current theme
ThemeData theme = Theme.of(context);

// Use theme colors
Color primaryColor = theme.colorScheme.primary;
```

The theme configuration includes:
- Color schemes for light and dark modes
- Typography styles
- Button themes
- Input decoration themes
- Card and dialog themes

## 📱 Responsive Design

The app is built with responsive design using the Sizer package:

```dart
// Example of responsive sizing
Container(
  width: 50.w, // 50% of screen width
  height: 20.h, // 20% of screen height
  child: Text('Responsive Container'),
)
```
## 📦 Deployment

Build the application for production:

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

## ☁️ Cloud Sync

QuickNote Pro supports multiple cloud storage providers for syncing your notes and media. All providers are optional - the app works perfectly in Local Only mode without any cloud configuration.

### Supported Providers

#### Google Drive & OneDrive
*Coming soon - OAuth 2.0 integration*

#### Dropbox
OAuth 2.0 authentication with secure token storage.
- **Requirements**: Client ID configuration in build settings
- **Features**: File upload/download, automatic sync
- **File size limit**: 150MB per file
- **Setup**: Configure `DROPBOX_CLIENT_ID` in your build environment

#### Box
Enterprise-grade cloud storage with OAuth 2.0.
- **Requirements**: Client ID configuration in build settings  
- **Features**: File upload/download, folder organization
- **File size limit**: 5GB per file
- **Setup**: Configure `BOX_CLIENT_ID` in your build environment

#### WebDAV (Nextcloud/ownCloud)
Direct WebDAV integration with username/password authentication.
- **Requirements**: Server URL, username, app password
- **Features**: PROPFIND/PUT/GET operations, folder management
- **File size limit**: Server dependent (usually unlimited)
- **Setup**: Configure in Cloud Connections settings
- **Security**: Uses app passwords (recommended) or main password

#### S3-Compatible Storage (AWS S3/MinIO)
Support for AWS S3 and S3-compatible services.
- **Requirements**: Access key, secret key, region, bucket name
- **Features**: putObject/getObject/list operations  
- **File size limit**: 5GB per file
- **Custom endpoints**: Supports MinIO and other S3-compatible services
- **Setup**: Configure credentials in Cloud Connections settings

#### Bitbucket (Repository-based)
Store notes as JSON files in a Git repository.
- **Requirements**: OAuth 2.0 client ID, workspace, repository
- **Features**: Git-based versioning, structured note storage
- **File organization**: Notes in `notes/` folder, media in `media/` folder
- **File size limit**: 100MB (Git LFS recommended for larger files)
- **Setup**: Configure `BITBUCKET_CLIENT_ID` and repository details

### Configuration

#### Build-time Configuration
For OAuth-based providers (Dropbox, Box, Bitbucket), you need to configure client IDs:

1. **Android**: Update `android/app/build.gradle`
2. **iOS**: Update `ios/Runner/Info.plist`  
3. **Redirect URIs**: 
   - Dropbox: `com.quicknote.pro://oauth/dropbox`
   - Box: `com.quicknote.pro://oauth/box`
   - Bitbucket: `com.quicknote.pro://oauth/bitbucket`

#### Runtime Configuration
For credential-based providers (WebDAV, S3), configure through the app:

1. Open Settings → Cloud Connections
2. Select your provider
3. Enter credentials and server details
4. Test connection

### Local Only Mode

The app builds and runs perfectly without any provider configuration:
- All cloud sync features are safely disabled
- Settings show "Not Configured" status
- Sync operations become no-ops
- Full offline functionality maintained

### Premium Features

Premium subscription required for:
- File uploads (images, voice recordings)
- Drawing/doodling features
- Multi-provider sync

Free users can:
- Create and sync text notes
- Use all cloud providers for text content
- Access all organizational features

### Development Notes

- All providers implement safe no-op fallbacks
- Credentials stored in Flutter Secure Storage
- Feature flags prevent crashes when unconfigured
- Last-write-wins conflict resolution
- Automatic retry with exponential backoff
- Provider capability flags guide sync behavior

### Security

- OAuth tokens stored securely
- App passwords recommended for WebDAV
- S3 signature validation (when implemented)
- No credentials stored in source code
- Secure storage encryption on device

## 🙏 Acknowledgments
- Powered by [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Styled with Material Design

Built with ❤️ by [Mikael Kraft](https://x.com/mikael_kraft)
