[![Codespaces Prebuilds](https://github.com/mikaelkraft/Quicknote_Pro/actions/workflows/codespaces/create_codespaces_prebuilds/badge.svg)](https://github.com/mikaelkraft/Quicknote_Pro/actions/workflows/codespaces/create_codespaces_prebuilds)

# QuickNote Pro

A modern note-taking application with cloud sync, premium features, and advanced organization capabilities. Create text notes, voice memos, drawings, and templates with seamless synchronization across devices.

## ✨ Features

### Core Features
- **📝 Multiple Note Types**: Text, voice, drawing, and template support
- **📌 Pin & Sort**: Pin important notes with smart sorting (pinned first, then by recency)
- **🏷️ Tag Management**: Organize notes with tags and visual filtering
- **🔍 Smart Search**: AI-powered search with content recognition
- **📁 Folder Organization**: Nested folder structures for better organization
- **📤 Share & Export**: Native share integration with export capabilities

### Cloud Sync
- **☁️ iCloud Drive Integration**: Seamless sync across Apple devices (requires setup)
- **🔄 Multi-Provider Support**: Extensible sync architecture for multiple providers
- **📊 Sync Status**: Real-time sync monitoring and status updates

### Premium Features
- **⭐ Premium Monetization**: $1/month or $5 lifetime subscription
- **🎨 Theme Customization**: Light/dark/auto themes with accent color selection
- **💾 Advanced Backup**: Automatic backups with version history
- **🔐 Premium Tools**: Advanced drawing tools and unlimited features

## 📋 Prerequisites

- Flutter SDK (^3.6.0)
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

3. Run the application:
```bash
flutter run
```

## 📁 Project Structure

```
QuickNote_Pro/
├── android/              # Android-specific configuration
├── ios/                  # iOS-specific configuration  
├── lib/
│   ├── core/             # Core utilities and feature flags
│   │   ├── app_export.dart    # Central exports
│   │   └── feature_flags.dart # Build-safe feature toggles
│   ├── models/           # Data models
│   │   └── note.dart     # Note model with full functionality
│   ├── services/         # Business logic services
│   │   ├── theme/        # Theme management with persistence
│   │   ├── payments/     # IAP service with local fallback
│   │   ├── sync/         # Cloud sync providers
│   │   │   └── providers/ # Individual sync implementations
│   │   └── notes/        # Note management service
│   ├── presentation/     # UI screens and widgets
│   │   ├── notes_dashboard/   # Main notes interface
│   │   ├── settings_profile/ # Settings and profile
│   │   ├── paywall/          # Premium upgrade screen
│   │   └── ...               # Other screens
│   ├── routes/           # Application routing
│   ├── theme/            # Theme configuration
│   ├── widgets/          # Reusable UI components
│   └── main.dart         # Application entry point
├── assets/               # Static assets
├── pubspec.yaml          # Dependencies and configuration
└── README.md             # This file
```

## ⚙️ Configuration

### Feature Flags

The app uses feature flags for safe builds without external dependencies:

```dart
// lib/core/feature_flags.dart
class FeatureFlags {
  static const bool enableIAP = false;           // In-App Purchases
  static const bool enableiCloudSync = false;    // iCloud Drive sync
  static const bool isDevelopment = true;        // Development mode
  static const bool enableLocalEntitlements = true; // Local premium testing
}
```

### iCloud Drive Setup

To enable iCloud Drive synchronization:

1. **Apple Developer Console**:
   - Create iCloud container: `iCloud.com.yourcompany.quicknote`
   - Enable iCloud Documents service

2. **Xcode Configuration**:
   ```xml
   <!-- ios/Runner/Info.plist -->
   <key>NSUbiquitousContainers</key>
   <dict>
       <key>iCloud.com.yourcompany.quicknote</key>
       <dict>
           <key>NSUbiquitousContainerIsDocumentScopePublic</key>
           <true/>
           <key>NSUbiquitousContainerSupportedFolderLevels</key>
           <string>Any</string>
           <key>NSUbiquitousContainerName</key>
           <string>QuickNote Pro</string>
       </dict>
   </dict>
   ```

3. **Capabilities**:
   - Enable iCloud capability in Xcode
   - Select "iCloud Documents" service
   - Configure container identifier

4. **Enable Feature**:
   ```dart
   // Set in feature_flags.dart
   static const bool enableiCloudSync = true;
   ```

### In-App Purchases Setup

To enable premium features with real purchases:

1. **App Store Connect**:
   - Create products:
     - `quicknote_premium_monthly` ($1.00)
     - `quicknote_premium_lifetime` ($5.00)

2. **iOS Configuration**:
   ```xml
   <!-- ios/Runner/Info.plist -->
   <key>SKAdNetworkItems</key>
   <array>
       <!-- Add your advertising network IDs -->
   </array>
   ```

3. **Enable Feature**:
   ```dart
   // Set in feature_flags.dart
   static const bool enableIAP = true;
   ```

4. **Test Environment**:
   - Use sandbox environment for testing
   - Create test users in App Store Connect
   - Test purchase flows before production

## 🎨 Theme System

The app includes a persistent theme system with user customization:

### Theme Service Usage

```dart
// Access theme service
final themeService = context.read<ThemeService>();

// Change theme mode
await themeService.setThemeMode(ThemeMode.dark);

// Set accent color
await themeService.setAccentColor(Colors.purple);

// Get current settings
ThemeMode currentMode = themeService.themeMode;
Color? currentAccent = themeService.accentColor;
```

### Available Options

- **Theme Modes**: Light, Dark, System
- **Accent Colors**: Purple, Green, Amber, Red, Blue, Pink
- **Persistence**: Settings saved automatically with Hive
- **Real-time Updates**: Changes apply instantly across the app

## 💰 Monetization

### Subscription Plans

- **Monthly Plan**: $1.00/month - Cancel anytime
- **Lifetime Plan**: $5.00 one-time - Best value

### Premium Features

- Unlimited cloud sync across devices
- Advanced drawing tools with layers
- File attachments (images, documents, media)
- Unlimited folder structures
- Advanced backup with version history
- AI-powered search capabilities

### Development Testing

For development and testing without store setup:

```dart
// Use local entitlements
final iapService = context.read<IAPService>();
await iapService.purchaseProduct('quicknote_premium_lifetime');

// Check entitlement status
bool hasPremium = iapService.hasPremiumAccess;
Map<String, dynamic> info = iapService.getEntitlementInfo();
```

## 📱 Usage Examples

### Note Management

```dart
// Access notes service
final notesService = context.read<NotesService>();

// Create and manage notes
notesService.togglePin(noteId);           // Pin/unpin notes
notesService.setFilter('Work');           // Filter by folder
notesService.setTagFilter('important');   // Filter by tag
notesService.shareNote(noteId);           // Share note content

// Search notes
notesService.setSearchQuery('meeting');   // Smart search
```

### Sync Providers

```dart
// Access provider registry
final registry = context.read<ProviderRegistry>();

// Check available providers
List<CloudSyncService> providers = registry.providers;
CloudSyncService? active = registry.activeProvider;

// Sync operations
await provider.syncNotes();               // Manual sync
bool available = await provider.isAvailable(); // Check status
```

## 🔧 Development

### Building Without External Dependencies

The app is designed to build and run without requiring:
- Apple Developer account or certificates
- App Store Connect configuration
- iCloud container setup
- Payment processor integration

All premium features work with local simulation for development.

### Adding New Sync Providers

1. Implement `CloudSyncService` interface
2. Add to `ProviderRegistry.initialize()`
3. Update settings UI as needed

### Customizing Themes

1. Modify `AppTheme` class for new color schemes
2. Add colors to `ThemeService.availableAccentColors`
3. Update theme picker UI if needed

## 📦 Deployment

### Build Commands

```bash
# Debug builds
flutter run

# Release builds
flutter build apk --release    # Android
flutter build ios --release    # iOS

# With specific features enabled
flutter build apk --release --dart-define=ENABLE_IAP=true
```

### Environment Variables

```bash
# Build with specific configurations
flutter build apk --dart-define=ENABLE_IAP=true --dart-define=ENABLE_ICLOUD=true
```

## 🧪 Testing

### Manual Testing

1. **Theme Changes**: Verify persistence across app restarts
2. **Note Operations**: Test pin/unpin, tag management, sharing
3. **Premium Flow**: Test upgrade screen and local entitlements
4. **Sync Status**: Verify iCloud provider shows "Not Configured"

### Automated Testing

```bash
flutter test                    # Run unit tests
flutter integration_test        # Run integration tests
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- UI inspired by Material Design principles
- Cloud sync architecture inspired by modern productivity apps
- Icons provided by Material Icons

## 📞 Support

- 📧 Email: support@quicknotepro.app
- 🐛 Issues: [GitHub Issues](https://github.com/mikaelkraft/Quicknote_Pro/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/mikaelkraft/Quicknote_Pro/discussions)

Built with ❤️ by [Mikael Kraft](https://x.com/mikael_kraft)
