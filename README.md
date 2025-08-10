[![Codespaces Prebuilds](https://github.com/mikaelkraft/Quicknote_Pro/actions/workflows/codespaces/create_codespaces_prebuilds/badge.svg)](https://github.com/mikaelkraft/Quicknote_Pro/actions/workflows/codespaces/create_codespaces_prebuilds)

# Quicknote Pro

A modern note-taking application with real-time local persistence and optional cloud synchronization. Features include rich text editing, image insertion, drawing/doodling, voice notes, file attachments, and premium gating for advanced features.

## ✨ Features

### Core Features (Free)
- **Rich Text Editing**: Full markdown support with formatting toolbar
- **Image Insertion**: Camera capture and gallery selection with local file management
- **Voice Notes**: Voice-to-text transcription
- **Local Persistence**: Robust local storage using Hive database
- **Search & Filtering**: Powerful search across note content, tags, and folders
- **Organization**: Pin notes, add tags, and organize in folders

### Premium Features
- **Drawing & Doodling**: Digital canvas with various brushes and colors
- **File Attachments**: Attach any file type to notes
- **Cloud Synchronization**: 
  - Google Drive integration (configurable)
  - OneDrive integration (configurable)
  - Automatic sync with conflict resolution
- **Advanced Search**: AI-powered search suggestions

### Cloud Sync Configuration (Optional)

By default, the app runs in **local-only mode** and builds successfully without any cloud credentials. To enable cloud sync:

#### Google Drive Setup
1. Create a project in [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the Google Drive API
3. Create OAuth 2.0 credentials for your app
4. Update `lib/services/sync/providers/google_drive_sync_provider.dart`:
   ```dart
   static const bool _isEnabled = true; // Enable Google Drive
   ```
5. Configure OAuth credentials in your app's Info.plist (iOS) or AndroidManifest.xml

#### OneDrive Setup
1. Register your app in [Microsoft Azure Portal](https://portal.azure.com/)
2. Configure Microsoft Graph API permissions
3. Update `lib/services/sync/providers/onedrive_sync_provider.dart`:
   ```dart
   static const bool _isEnabled = true; // Enable OneDrive
   ```
4. Configure OAuth redirect URIs

**Note**: The app builds and runs perfectly without cloud credentials. Cloud sync features will show "Not configured" in settings.

## 📋 Prerequisites

- Flutter SDK (^3.29.2)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

## 🛠️ Installation

1. Clone the repository:
```bash
git clone https://github.com/mikaelkraft/Quicknote_Pro.git
cd Quicknote_Pro
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate Hive type adapters:
```bash
dart run build_runner build
```

4. Run the application:
```bash
flutter run
```

### Development Setup

For development with premium features enabled:
```dart
// Enable premium for testing
final premiumService = PremiumService();
await premiumService.grantPremium(); // Grants lifetime premium
```

## 📁 Project Structure

```
lib/
├── core/                 # Core utilities and services
├── models/               # Data models (Note, etc.)
│   ├── note.dart        # Note model with Hive annotations
│   └── note.g.dart      # Generated Hive adapters
├── services/            # Business logic services
│   ├── local/           # Local persistence services
│   │   ├── hive_initializer.dart    # Database initialization
│   │   └── note_repository.dart     # Note CRUD operations
│   ├── premium/         # Premium feature management
│   │   └── premium_service.dart     # Premium status and gating
│   └── sync/            # Cloud synchronization
│       ├── cloud_sync_service.dart  # Abstract sync interface
│       ├── sync_manager.dart        # Sync orchestration
│       └── providers/               # Cloud provider implementations
│           ├── google_drive_sync_provider.dart
│           └── onedrive_sync_provider.dart
├── presentation/        # UI screens and widgets
│   ├── notes_dashboard/             # Main notes interface
│   ├── note_creation_editor/        # Note editing interface
│   ├── settings_profile/
│   │   └── cloud_connections.dart   # Cloud sync settings
│   └── ...              # Other UI screens
├── routes/              # Application routing
├── theme/               # Theme configuration
├── widgets/             # Reusable UI components
└── main.dart            # Application entry point with service initialization
```

## 🧩 Architecture

### Local Persistence
- **Hive Database**: NoSQL database for fast local storage
- **Repository Pattern**: Clean separation between data access and business logic
- **Reactive Streams**: Real-time UI updates via note repository streams

### Cloud Sync (Optional)
- **Pluggable Providers**: Easy to add new cloud storage providers
- **Offline-First**: Works seamlessly without internet connection
- **Conflict Resolution**: Last-write-wins with basic merge safeguards
- **Background Sync**: Automatic synchronization every 30 minutes when connected

### Premium System
- **Local Premium State**: Stored in Hive for offline access
- **Feature Gating**: Centralized premium feature management
- **Extensible**: Easy to integrate with real IAP systems later

### File Management
- **Stable Storage**: Images and attachments copied to app documents directory
- **Relative Paths**: Notes store relative paths for portability
- **Auto-Cleanup**: Orphaned files removed during sync operations

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

## 🙏 Acknowledgments
- Powered by [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Styled with Material Design

Built with ❤️ by [Mikael Kraft](https://x.com/mikael_kraft)
