# Monetization Integration Guide

This guide shows how to integrate the monetization system into existing screens and features.

## Quick Start

### 1. Basic Feature Gating

Wrap any premium feature with a `FeatureGate`:

```dart
FeatureGate(
  featureType: FeatureType.advancedDrawing,
  featureContext: 'drawing_tools',
  child: AdvancedDrawingButton(),
)
```

### 2. Usage Tracking

Check and record feature usage:

```dart
// Check if user can use feature
if (await context.monetization.checkFeatureAccess(
  context,
  featureType: FeatureType.voiceNoteRecording,
  featureContext: 'voice_recording',
)) {
  // Record usage
  await context.monetization.recordFeatureUsage(FeatureType.voiceNoteRecording);
  
  // Proceed with feature
  startVoiceRecording();
}
```

### 3. Adding Ads

Insert ads into content lists:

```dart
// In a note list
children: [
  ...noteWidgets,
  // Add banner ad every 5 notes
  if (index % 5 == 4) 
    SimpleBannerAd(placement: AdPlacement.noteListBanner),
],
```

### 4. Usage Dashboard

Add tier status and usage tracking:

```dart
Column(
  children: [
    // Tier status in app bar
    TierStatusBadge(),
    
    // Expandable usage dashboard
    UsageDashboard(),
    
    // Your existing content
    YourContentWidget(),
  ],
)
```

## Detailed Integration Examples

### Notes Dashboard Integration

```dart
class NotesDashboard extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        actions: [
          // Show tier status
          TierStatusBadge(),
        ],
      ),
      body: Column(
        children: [
          // Usage dashboard at top
          UsageDashboard(),
          
          // Note creation with feature gate
          FeatureGate(
            featureType: FeatureType.noteCreation,
            featureContext: 'notes_dashboard',
            child: CreateNoteButton(),
          ),
          
          // Notes list with ads
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final widgets = <Widget>[
                  NoteCard(note: notes[index]),
                ];
                
                // Add banner ad every 5 notes
                if ((index + 1) % 5 == 0) {
                  widgets.add(SimpleBannerAd(
                    placement: AdPlacement.noteListBanner,
                  ));
                }
                
                return Column(children: widgets);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNote(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _createNote(BuildContext context) async {
    // Check feature access
    if (await context.monetization.checkFeatureAccess(
      context,
      featureType: FeatureType.noteCreation,
      featureContext: 'fab_create',
    )) {
      // Record usage
      await context.monetization.recordFeatureUsage(FeatureType.noteCreation);
      
      // Create note
      Navigator.pushNamed(context, '/note-editor');
      
      // Show interstitial ad occasionally
      await context.monetization.showSmartInterstitial(
        context,
        AdPlacement.noteCreationInterstitial,
      );
    }
  }
}
```

### Voice Recording Integration

```dart
class VoiceRecordingScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Recording'),
        actions: [
          // Show usage for voice recordings
          Consumer<MonetizationService>(
            builder: (context, service, _) {
              final remaining = service.getRemainingUsage(FeatureType.voiceNoteRecording);
              if (remaining >= 0) {
                return Chip(
                  label: Text('$remaining left'),
                  backgroundColor: remaining > 5 ? Colors.green : Colors.orange,
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Feature gate for transcription
          FeatureGate(
            featureType: FeatureType.advancedExport, // Transcription is premium
            featureContext: 'voice_transcription',
            upgradeTitle: 'Voice Transcription',
            upgradeDescription: 'Get automatic transcription of your voice notes with Premium.',
            child: TranscriptionToggle(),
          ),
          
          // Record button with feature gate
          FeatureGate(
            featureType: FeatureType.voiceNoteRecording,
            featureContext: 'voice_recording',
            child: RecordButton(onPressed: _startRecording),
          ),
        ],
      ),
    );
  }

  void _startRecording() async {
    // Record usage
    await context.monetization.recordFeatureUsage(FeatureType.voiceNoteRecording);
    
    // Start recording logic
    startRecording();
  }
}
```

### Settings Integration

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          // Monetization quick actions
          MonetizationQuickActions(),
          
          // Settings sections
          SettingsSection(title: 'Account'),
          
          // Premium features section
          Consumer<MonetizationService>(
            builder: (context, service, _) {
              if (!service.isPremium) {
                return Column(
                  children: [
                    // Banner ad in settings
                    SimpleBannerAd(placement: AdPlacement.settingsBanner),
                    
                    // Upgrade prompt
                    Card(
                      child: ListTile(
                        title: Text('Upgrade to Premium'),
                        subtitle: Text('Remove ads and unlock all features'),
                        trailing: ElevatedButton(
                          onPressed: () => _showUpgrade(context),
                          child: Text('Upgrade'),
                        ),
                      ),
                    ),
                  ],
                );
              }
              
              return Card(
                child: ListTile(
                  title: Text('Premium Active'),
                  subtitle: Text('Thank you for supporting the app!'),
                  leading: Icon(Icons.star, color: Colors.gold),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUpgrade(BuildContext context) {
    context.monetization.showUpgradePrompt(
      context,
      featureContext: 'settings_upgrade',
    );
  }
}
```

## Extension Methods Usage

Use the convenient extension methods for cleaner code:

```dart
// Feature gating with extension
Widget myButton = ElevatedButton(
  onPressed: () => doSomething(),
  child: Text('Premium Feature'),
).gateFeature(
  FeatureType.advancedDrawing,
  'drawing_context',
);

// Access services easily
final canUse = context.monetizationService.canUseFeature(FeatureType.noteCreation);
final adWidget = context.monetization.buildAdWidget(AdPlacement.noteListBanner);
```

## Analytics Integration

Track important monetization events:

```dart
// Track feature usage
context.monetization.trackEvent(
  MonetizationEventType.featureLimitReached,
  properties: {'feature': 'voice_recording'},
);

// Track upgrade events
context.monetization.trackEvent(
  MonetizationEventType.upgradeStarted,
  properties: {'tier': 'premium'},
);

// Track ad interactions
context.monetization.trackEvent(
  MonetizationEventType.adClicked,
  properties: {'placement': 'note_list_banner'},
);
```

## Best Practices

### 1. Feature Gating
- Always check feature access before proceeding with premium features
- Provide clear value propositions in upgrade prompts
- Use contextual messaging based on the feature being accessed

### 2. Ad Placement
- Respect frequency caps to avoid user fatigue
- Place ads at natural break points in user flow
- Never show ads to premium users

### 3. Usage Tracking
- Record usage immediately after feature access is granted
- Update UI to reflect new usage counts
- Show approaching limits proactively

### 4. Analytics
- Track all monetization-related events
- Include context in event properties
- Monitor conversion funnel performance

### 5. Error Handling
- Gracefully handle purchase failures
- Provide restore purchase options
- Fall back to free tier if entitlement check fails

## Testing

Use the monetization demo screen to test all features:

```dart
Navigator.pushNamed(context, '/monetization-demo');
```

This screen includes:
- Feature gate examples
- Usage tracking demos
- Ad display testing
- Manual paywall triggers
- Analytics event testing

## Configuration

Adjust limits and pricing in:
- `lib/constants/product_ids.dart` - Product IDs and pricing
- `lib/services/monetization/monetization_service.dart` - Feature limits
- `lib/services/ads/ads_service.dart` - Ad frequency caps