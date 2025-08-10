import 'package:flutter/material.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/folder_organization/folder_organization.dart';
import '../presentation/notes_dashboard/notes_dashboard.dart';
import '../presentation/note_creation_editor/note_creation_editor.dart';
import '../presentation/search_discovery/search_discovery.dart';
import '../presentation/premium_upgrade/premium_upgrade.dart';
import '../presentation/settings_profile/settings_profile.dart';
import '../presentation/paywall/upgrade_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String onboardingFlow = '/onboarding-flow';
  static const String splashScreen = '/splash-screen';
  static const String folderOrganization = '/folder-organization';
  static const String notesDashboard = '/notes-dashboard';
  static const String noteCreationEditor = '/note-creation-editor';
  static const String searchDiscovery = '/search-discovery';
  static const String premiumUpgrade = '/premium-upgrade';
  static const String settingsProfile = '/settings-profile';
  static const String upgradeScreen = '/upgrade-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    splashScreen: (context) => const SplashScreen(),
    folderOrganization: (context) => const FolderOrganization(),
    notesDashboard: (context) => const NotesDashboard(),
    noteCreationEditor: (context) => const NoteCreationEditor(),
    searchDiscovery: (context) => const SearchDiscovery(),
    premiumUpgrade: (context) => const PremiumUpgrade(),
    settingsProfile: (context) => const SettingsProfile(),
    upgradeScreen: (context) => const UpgradeScreen(),
    // TODO: Add your other routes here
  };
}
