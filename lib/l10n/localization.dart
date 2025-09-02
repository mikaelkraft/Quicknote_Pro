/// Simple localization service that provides access to localized strings
/// This acts as a fallback until auto-generated AppLocalizations is available
/// 
/// Usage:
/// ```dart
/// final localizations = LocalizationService.instance;
/// String freeText = localizations.getString('pricing_free');
/// ```

import 'dart:convert';
import 'package:flutter/services.dart';

class LocalizationService {
  static LocalizationService? _instance;
  static LocalizationService get instance => _instance ??= LocalizationService._();
  
  LocalizationService._();
  
  Map<String, String> _localizedStrings = {};
  String _currentLocale = 'en';
  
  /// Initialize the localization service with a specific locale
  Future<void> initialize([String locale = 'en']) async {
    _currentLocale = locale;
    await _loadLocalizedStrings();
  }
  
  /// Load localized strings from ARB file
  Future<void> _loadLocalizedStrings() async {
    try {
      String jsonString = await rootBundle.loadString('lib/l10n/app_$_currentLocale.arb');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      _localizedStrings = Map.fromEntries(
        jsonMap.entries
          .where((entry) => !entry.key.startsWith('@') && entry.value is String)
          .map((entry) => MapEntry(entry.key, entry.value as String)),
      );
    } catch (e) {
      // Fallback to English if locale not found
      if (_currentLocale != 'en') {
        _currentLocale = 'en';
        await _loadLocalizedStrings();
      } else {
        // If even English fails, use hardcoded fallbacks
        _loadFallbackStrings();
      }
    }
  }
  
  /// Load hardcoded fallback strings in case ARB loading fails
  void _loadFallbackStrings() {
    _localizedStrings = {
      // Pricing tiers
      'pricing_free': 'Free',
      'pricing_premium': 'Premium',
      'pricing_pro': 'Pro',
      'pricing_enterprise': 'Enterprise',
      
      // Plan terms
      'planTerm_monthly': 'Monthly',
      'planTerm_annual': 'Annual',
      'planTerm_lifetime': 'Lifetime',
      'planTerm_perUser': 'Per User',
      'planTerm_save20': 'Save 20%',
      
      // Actions
      'action_upgradeNow': 'Upgrade Now',
      'action_startFreeTrial': 'Start Free Trial',
      'action_restorePurchase': 'Restore Purchase',
      'action_continue': 'Continue',
      'action_cancel': 'Cancel',
      'pricing_pricePerUser': 'Price per user',
      'pricing_teamPlan': 'Team Plan',
      
      // Features
      'feature_unlimitedNotes': 'Unlimited notes',
      'feature_advancedDrawingTools': 'Advanced drawing tools',
      'feature_voiceTranscription': 'Voice transcription',
      'feature_collaboration': 'Collaboration',
      'feature_adminControls': 'Admin controls',
      'feature_noAds': 'No ads',
      'feature_prioritySupport': 'Priority support',
      
      // Basic app strings
      'app_notes': 'Notes',
      'app_newNote': 'New Note',
      'app_delete': 'Delete',
      'app_edit': 'Edit',
      'app_settings': 'Settings',
    };
  }
  
  /// Get a localized string by key, with fallback to English
  String getString(String key, [String? fallback]) {
    return _localizedStrings[key] ?? fallback ?? key;
  }
  
  /// Change the current locale and reload strings
  Future<void> setLocale(String locale) async {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      await _loadLocalizedStrings();
    }
  }
  
  /// Get current locale
  String get currentLocale => _currentLocale;
  
  /// Get all available locales
  static const List<String> supportedLocales = ['en', 'es', 'fr', 'de'];
  
  // Convenience getters for commonly used strings
  
  // Pricing tiers
  String get pricingFree => getString('pricing_free');
  String get pricingPremium => getString('pricing_premium');
  String get pricingPro => getString('pricing_pro');
  String get pricingEnterprise => getString('pricing_enterprise');
  
  // Plan terms
  String get planTermMonthly => getString('planTerm_monthly');
  String get planTermAnnual => getString('planTerm_annual');
  String get planTermLifetime => getString('planTerm_lifetime');
  String get planTermPerUser => getString('planTerm_perUser');
  String get planTermSave20 => getString('planTerm_save20');
  
  // Actions
  String get actionUpgradeNow => getString('action_upgradeNow');
  String get actionStartFreeTrial => getString('action_startFreeTrial');
  String get actionRestorePurchase => getString('action_restorePurchase');
  String get actionContinue => getString('action_continue');
  String get actionCancel => getString('action_cancel');
  String get pricingPricePerUser => getString('pricing_pricePerUser');
  String get pricingTeamPlan => getString('pricing_teamPlan');
  
  // Features
  String get featureUnlimitedNotes => getString('feature_unlimitedNotes');
  String get featureAdvancedDrawingTools => getString('feature_advancedDrawingTools');
  String get featureVoiceTranscription => getString('feature_voiceTranscription');
  String get featureCollaboration => getString('feature_collaboration');
  String get featureAdminControls => getString('feature_adminControls');
  String get featureNoAds => getString('feature_noAds');
  String get featurePrioritySupport => getString('feature_prioritySupport');
  
  // Basic app strings
  String get appNotes => getString('app_notes');
  String get appNewNote => getString('app_newNote');
  String get appDelete => getString('app_delete');
  String get appEdit => getString('app_edit');
  String get appSettings => getString('app_settings');
}