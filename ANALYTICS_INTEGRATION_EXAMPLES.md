# Analytics Integration Example

This document provides practical examples of how to integrate the analytics system into the existing Quicknote Pro application.

## Basic Setup

### 1. Initialize Analytics in Main App

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final analyticsService = AnalyticsService();
  final themeService = ThemeService();
  
  await analyticsService.initialize();
  await themeService.initialize();
  
  final integrationService = AnalyticsIntegrationService(
    analyticsService: analyticsService,
    themeService: themeService,
  );
  await integrationService.initialize();
  
  runApp(MyApp(
    analyticsService: analyticsService,
    themeService: themeService,
    integrationService: integrationService,
  ));
}

class MyApp extends StatelessWidget {
  final AnalyticsService analyticsService;
  final ThemeService themeService;
  final AnalyticsIntegrationService integrationService;

  const MyApp({
    Key? key,
    required this.analyticsService,
    required this.themeService,
    required this.integrationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: analyticsService),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: integrationService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Quicknote Pro',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
```

### 2. Analytics Consent Screen

```dart
// lib/presentation/analytics_consent/analytics_consent_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';

class AnalyticsConsentScreen extends StatelessWidget {
  const AnalyticsConsentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: Consumer<AnalyticsService>(
        builder: (context, analyticsService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics & Usage Data',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Help us improve Quicknote Pro by sharing anonymous usage data. '
                  'This helps us understand which features are most valuable and identify areas for improvement.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                
                // Privacy information
                _buildPrivacyInfo(context),
                const SizedBox(height: 24),
                
                // Consent toggle
                SwitchListTile(
                  title: const Text('Share Analytics Data'),
                  subtitle: const Text('Anonymous usage and performance data'),
                  value: analyticsService.userConsent,
                  onChanged: (value) async {
                    await analyticsService.setUserConsent(value);
                    
                    // Track the consent change itself
                    if (value) {
                      await analyticsService.trackEvent(
                        AnalyticsEventType.sessionStarted,
                        entryPoint: AnalyticsEntryPoint.settings,
                      );
                    }
                  },
                ),
                
                const Spacer(),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Track settings completion
                          final integrationService = context.read<AnalyticsIntegrationService>();
                          integrationService.trackFeatureDiscovered(
                            feature: 'analytics_settings',
                            entryPoint: AnalyticsEntryPoint.settings,
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivacyInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Privacy',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• No personal information is collected\n'
            '• Data is anonymized and aggregated\n'
            '• You can opt out anytime\n'
            '• Data helps improve app performance',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
```

### 3. Note Editor Integration

```dart
// lib/presentation/note_editor/note_editor_screen.dart (example integration)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? existingNote;
  
  const NoteEditorScreen({Key? key, this.existingNote}) : super(key: key);

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Note? _currentNote;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
    _currentNote = widget.existingNote;
    
    // Track note editor opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final integration = context.read<AnalyticsIntegrationService>();
      if (widget.existingNote == null) {
        // New note
        integration.trackNoteCreated(
          entryPoint: AnalyticsEntryPoint.dashboard,
          method: AnalyticsMethod.tap,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentNote == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _recordVoiceNote,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _addImage,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Note title...',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
              onChanged: (_) => _markAsChanged(),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Start writing...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                onChanged: (_) => _markAsChanged(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveNote() async {
    final integration = context.read<AnalyticsIntegrationService>();
    
    try {
      // Create or update note
      final note = _currentNote?.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        updatedAt: DateTime.now(),
      ) ?? Note.create(
        title: _titleController.text,
        content: _contentController.text,
      );

      // Save note logic here...
      
      // Track the save event
      if (_currentNote == null) {
        await integration.trackNoteCreated(
          entryPoint: AnalyticsEntryPoint.noteEditor,
          method: AnalyticsMethod.keyboard,
          hasAttachments: note.hasAttachments,
          attachmentCount: note.attachments.length,
          hasImages: note.imageAttachments.isNotEmpty,
        );
      } else {
        await integration.trackNoteEdited(
          entryPoint: AnalyticsEntryPoint.noteEditor,
          method: AnalyticsMethod.keyboard,
          wordCount: note.wordCount,
          contentChanged: true,
        );
      }

      setState(() {
        _currentNote = note;
        _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved successfully')),
      );
    } catch (e) {
      // Track save error
      await integration.analyticsService.trackErrorEvent(
        AnalyticsEventType.storageError,
        AnalyticsErrorCode.unknownError,
        entryPoint: AnalyticsEntryPoint.noteEditor,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _recordVoiceNote() async {
    final integration = context.read<AnalyticsIntegrationService>();
    
    try {
      // Voice recording logic here...
      final success = true; // Result of recording
      const durationMs = 30000; // Recording duration
      
      await integration.trackVoiceNoteRecorded(
        entryPoint: AnalyticsEntryPoint.noteEditor,
        success: success,
        durationMs: durationMs,
      );
    } catch (e) {
      await integration.trackVoiceNoteRecorded(
        entryPoint: AnalyticsEntryPoint.noteEditor,
        success: false,
        errorCode: AnalyticsErrorCode.permissionDenied,
      );
    }
  }

  Future<void> _addImage() async {
    final integration = context.read<AnalyticsIntegrationService>();
    
    try {
      // Image picker logic here...
      const success = true;
      
      if (success) {
        await integration.analyticsService.trackUsageEvent(
          AnalyticsEventType.imageAttached,
          entryPoint: AnalyticsEntryPoint.noteEditor,
          method: AnalyticsMethod.tap,
        );
      }
    } catch (e) {
      await integration.analyticsService.trackErrorEvent(
        AnalyticsEventType.appError,
        AnalyticsErrorCode.permissionDenied,
        entryPoint: AnalyticsEntryPoint.noteEditor,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
```

### 4. Premium Purchase Flow Integration

```dart
// lib/presentation/premium/premium_purchase_screen.dart (example)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';

class PremiumPurchaseScreen extends StatelessWidget {
  const PremiumPurchaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Premium features list
            _buildFeaturesList(context),
            const Spacer(),
            
            // Purchase buttons
            _buildPurchaseOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    return Column(
      children: [
        Text(
          'Premium Features',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        // Feature list items...
      ],
    );
  }

  Widget _buildPurchaseOptions(BuildContext context) {
    final integration = context.read<AnalyticsIntegrationService>();
    
    return Column(
      children: [
        // Monthly subscription
        ElevatedButton(
          onPressed: () => _purchasePremium(
            context,
            ProductIds.premiumMonthly,
            1.0,
          ),
          child: const Text('Monthly - \$1.00'),
        ),
        const SizedBox(height: 8),
        
        // Lifetime purchase
        ElevatedButton(
          onPressed: () => _purchasePremium(
            context,
            ProductIds.premiumLifetime,
            5.0,
          ),
          child: const Text('Lifetime - \$5.00'),
        ),
      ],
    );
  }

  Future<void> _purchasePremium(
    BuildContext context,
    String productId,
    double price,
  ) async {
    final integration = context.read<AnalyticsIntegrationService>();
    
    // Track purchase started
    await integration.trackPremiumPurchaseStarted(
      entryPoint: AnalyticsEntryPoint.paywall,
      productId: productId,
      price: price,
    );

    try {
      // Simulate purchase flow
      final success = true; // Result from actual purchase API
      
      if (success) {
        await integration.trackPremiumPurchaseCompleted(
          entryPoint: AnalyticsEntryPoint.paywall,
          productId: productId,
          price: price,
          currency: 'USD',
        );
        
        // Show success message and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase successful!')),
        );
      }
    } catch (e) {
      await integration.trackPremiumPurchaseFailed(
        entryPoint: AnalyticsEntryPoint.paywall,
        productId: productId,
        errorCode: AnalyticsErrorCode.paymentFailed,
        price: price,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase failed. Please try again.')),
      );
    }
  }
}
```

### 5. Theme Settings Integration

```dart
// lib/presentation/settings/theme_settings_screen.dart (example)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: Consumer2<ThemeService, AnalyticsIntegrationService>(
        builder: (context, themeService, integration, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Theme mode selection
              Text(
                'Theme Mode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              ...ThemeMode.values.map((mode) => RadioListTile<ThemeMode>(
                title: Text(themeService.getThemeModeDisplayName(mode)),
                value: mode,
                groupValue: themeService.themeMode,
                onChanged: (value) async {
                  if (value != null) {
                    await themeService.setThemeMode(value);
                    
                    // Analytics tracking happens automatically through
                    // the integration service listener
                  }
                },
              )),
              
              const SizedBox(height: 24),
              
              // Accent color picker
              Text(
                'Accent Color',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                children: [
                  _buildColorOption(context, null, themeService),
                  _buildColorOption(context, Colors.blue, themeService),
                  _buildColorOption(context, Colors.green, themeService),
                  _buildColorOption(context, Colors.purple, themeService),
                  _buildColorOption(context, Colors.orange, themeService),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    Color? color,
    ThemeService themeService,
  ) {
    final isSelected = themeService.accentColor == color;
    
    return GestureDetector(
      onTap: () async {
        await themeService.setAccentColor(color);
        
        // Track accent color change
        final integration = context.read<AnalyticsIntegrationService>();
        await integration.analyticsService.trackUsageEvent(
          AnalyticsEventType.accentColorChanged,
          entryPoint: AnalyticsEntryPoint.themeSettings,
          method: AnalyticsMethod.tap,
          additionalProperties: {
            'color_value': color?.value.toString(),
            'is_default': color == null,
          },
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: color == null
            ? Icon(
                Icons.palette_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )
            : isSelected
                ? Icon(
                    Icons.check,
                    color: Colors.white,
                  )
                : null,
      ),
    );
  }
}
```

This example demonstrates how to:

1. **Initialize** the analytics system in the main app
2. **Handle user consent** with a dedicated screen
3. **Track events** in the note editor
4. **Monitor monetization** during purchase flows
5. **Integrate with theme** settings automatically

The key principle is that analytics tracking should be transparent to the user and not interfere with the app's core functionality. All tracking respects user consent and provides meaningful business insights while maintaining privacy.