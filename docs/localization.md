# Localization (i18n) Documentation

## Overview

Quicknote Pro uses Flutter's built-in localization system with ARB (Application Resource Bundle) files to support multiple languages. This document explains the architecture, key naming conventions, and workflows for adding new locales.

## Architecture

### Core Components

1. **ARB Files** (`lib/l10n/`): JSON-based translation files containing localized strings
2. **LocalizationService** (`lib/l10n/localization.dart`): Fallback service for accessing localized strings
3. **Generated Localizations**: Auto-generated `AppLocalizations` class from ARB files
4. **Configuration**: `l10n.yaml` defines generation settings

### File Structure

```
lib/l10n/
├── app_en.arb          # English (source locale)
├── app_es.arb          # Spanish translations
├── app_fr.arb          # French translations
├── app_de.arb          # German translations
└── localization.dart   # Manual localization service
```

## ARB Structure

### Key Naming Conventions

We use a consistent `domain.group.key` pattern:

```
pricing.free              # Pricing tier names
pricing.premium
planTerm.monthly          # Billing periods
planTerm.annual
action.upgradeNow         # User actions
action.restorePurchase
feature.unlimitedNotes    # Feature descriptions
feature.voiceTranscription
app.notes                 # Basic app strings
app.settings
```

### ARB File Format

Each ARB file follows this structure:

```json
{
  "@@locale": "en",
  "@@last_modified": "2024-01-01T00:00:00.000Z",
  
  "@_SECTION_NAME": {},
  "key_name": "Localized string",
  "@key_name": {
    "description": "Description for translators"
  }
}
```

## Currently Localized Strings

### Pricing & Monetization
- **Tier Names**: `pricing_free`, `pricing_premium`, `pricing_pro`, `pricing_enterprise`
- **Plan Terms**: `planTerm_monthly`, `planTerm_annual`, `planTerm_lifetime`, `planTerm_perUser`
- **Actions**: `action_upgradeNow`, `action_startFreeTrial`, `action_restorePurchase`
- **Labels**: `pricing_pricePerUser`, `pricing_teamPlan`, `planTerm_save20`

### Feature Highlights
- `feature_unlimitedNotes`
- `feature_advancedDrawingTools`
- `feature_voiceTranscription`
- `feature_collaboration`
- `feature_adminControls`
- `feature_noAds`
- `feature_prioritySupport`

### Basic App Strings
- `app_notes`, `app_newNote`, `app_delete`, `app_edit`, `app_settings`

## Adding a New Language

### 1. Create ARB File

Create a new file `lib/l10n/app_{locale}.arb` (e.g., `app_ja.arb` for Japanese):

```json
{
  "@@locale": "ja",
  "@@last_modified": "2024-01-01T00:00:00.000Z",
  
  "@_TODO": "Japanese translations - replace with proper localization",
  
  "pricing_free": "無料",
  "pricing_premium": "プレミアム",
  // ... continue with all keys from app_en.arb
}
```

### 2. Update LocalizationService

Add the new locale to the supported locales list in `lib/l10n/localization.dart`:

```dart
static const List<String> supportedLocales = ['en', 'es', 'fr', 'de', 'ja'];
```

### 3. Test the Integration

1. Initialize the service with the new locale:
   ```dart
   await LocalizationService.instance.setLocale('ja');
   ```

2. Verify strings are loaded correctly:
   ```dart
   print(LocalizationService.instance.pricingFree); // Should print "無料"
   ```

## Usage in Code

### Using LocalizationService

```dart
import 'package:quicknote_pro/l10n/localization.dart';

// Get service instance
final l10n = LocalizationService.instance;

// Use convenience getters
String title = l10n.pricingPremium;
String action = l10n.actionUpgradeNow;

// Or use generic getString method
String custom = l10n.getString('pricing_free', 'Free');
```

### Using Generated AppLocalizations (Future)

Once Flutter's code generation is enabled:

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// In MaterialApp
MaterialApp(
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: [
    Locale('en', ''),
    Locale('es', ''),
    Locale('fr', ''),
    Locale('de', ''),
  ],
  // ...
)

// In widgets
Text(AppLocalizations.of(context)!.pricingFree)
```

## Integration with Monetization

### Localized Pricing Info

The monetization services now provide localized versions:

```dart
// Get localized pricing information
List<PricingInfo> tiers = PricingInfo.getAllTiersLocalized();
List<LegacyPricingInfo> legacy = LegacyPricingInfo.getAllTiersLocalized();

// Tier names will be localized
print(tiers[1].displayName); // "Premium" (en) or "Premium" (es)
```

### Pricing Models Integration

Both `MonetizationService` and `PricingService` classes use the localized strings for:
- Tier display names (`Free`, `Premium`, `Pro`, `Enterprise`)
- Billing periods (`Monthly`, `Annual`, `Lifetime`)
- Feature descriptions where applicable

## QA Checklist

### Before Adding New Locale

- [ ] All required keys present in ARB file
- [ ] Translation quality reviewed by native speaker
- [ ] Special characters properly encoded
- [ ] Pluralization rules considered (if applicable)
- [ ] Context-appropriate translations (not literal)

### Testing New Locale

- [ ] LocalizationService loads ARB file without errors
- [ ] All pricing tier names display correctly
- [ ] Feature descriptions are properly localized
- [ ] App builds and runs without localization errors
- [ ] UI layout accommodates longer/shorter text
- [ ] Currency formatting works (future enhancement)

### Pre-Release Verification

- [ ] Localization coverage report generated
- [ ] All user-facing strings use localization keys
- [ ] Fallback to English works properly
- [ ] Performance impact measured (ARB loading time)
- [ ] Memory usage reasonable for multiple locales

## Current Limitations

1. **Partial Coverage**: Only pricing/monetization and basic app strings are localized
2. **No Pluralization**: Complex plural forms not yet implemented
3. **No RTL Support**: Right-to-left languages not supported
4. **No Currency Localization**: Prices shown in USD only
5. **Manual Loading**: ARB files loaded manually, not auto-generated

## Future Enhancements

### Phase 2: Full UI Localization
- Extract all remaining user-facing strings
- Add proper pluralization support
- Implement context-sensitive translations

### Phase 3: Advanced Features
- RTL language support
- Currency localization by region
- Date/time formatting
- Number formatting

### Phase 4: Dynamic Localization
- Runtime locale switching
- Over-the-air translation updates
- A/B testing for different translations
- Analytics on locale usage

## Troubleshooting

### Common Issues

1. **ARB File Not Loading**: Check file path and JSON syntax
2. **Missing Translations**: Verify all keys exist in target ARB file
3. **Fallback Not Working**: Ensure English ARB file is valid
4. **Build Errors**: Check import statements and service initialization

### Debug Commands

```dart
// Check current locale
print(LocalizationService.instance.currentLocale);

// Test specific key
print(LocalizationService.instance.getString('pricing_free'));

// List all loaded strings
print(LocalizationService.instance._localizedStrings);
```