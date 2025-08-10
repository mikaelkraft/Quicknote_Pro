import 'cloud_sync_service.dart';
import 'providers/icloud_drive_sync_provider.dart';

/// Registry for all available cloud sync providers
class ProviderRegistry {
  static final ProviderRegistry _instance = ProviderRegistry._internal();
  factory ProviderRegistry() => _instance;
  ProviderRegistry._internal();
  
  final List<CloudSyncService> _providers = [];
  CloudSyncService? _activeProvider;
  
  /// Initialize all available providers
  void initialize() {
    _providers.clear();
    
    // Add iCloud Drive provider
    _providers.add(iCloudDriveSyncProvider());
    
    // TODO: Add other providers (Google Drive, Dropbox, etc.)
    // _providers.add(GoogleDriveSyncProvider());
    // _providers.add(DropboxSyncProvider());
  }
  
  /// Get all available providers
  List<CloudSyncService> get providers => List.unmodifiable(_providers);
  
  /// Get configured providers only
  List<CloudSyncService> get configuredProviders => 
      _providers.where((p) => p.isConfigured).toList();
  
  /// Get the currently active provider
  CloudSyncService? get activeProvider => _activeProvider;
  
  /// Set the active provider
  Future<void> setActiveProvider(CloudSyncService? provider) async {
    if (provider != null && !_providers.contains(provider)) {
      throw ArgumentError('Provider not registered');
    }
    
    _activeProvider = provider;
    // TODO: Persist active provider preference
  }
  
  /// Get provider by name
  CloudSyncService? getProviderByName(String name) {
    try {
      return _providers.firstWhere((p) => p.displayName == name);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if any provider is currently syncing
  bool get isAnySyncing => _providers.any((p) => p.status == SyncStatus.syncing);
  
  /// Sync all configured providers
  Future<Map<String, bool>> syncAll() async {
    final results = <String, bool>{};
    
    for (final provider in configuredProviders) {
      if (provider.isSignedIn) {
        final success = await provider.syncNotes();
        results[provider.displayName] = success;
      }
    }
    
    return results;
  }
  
  /// Get sync status summary
  Map<String, dynamic> getSyncStatusSummary() {
    final configuredCount = configuredProviders.length;
    final signedInCount = _providers.where((p) => p.isSignedIn).length;
    final syncingCount = _providers.where((p) => p.status == SyncStatus.syncing).length;
    
    return {
      'totalProviders': _providers.length,
      'configuredProviders': configuredCount,
      'signedInProviders': signedInCount,
      'currentlySyncing': syncingCount,
      'activeProvider': _activeProvider?.displayName,
    };
  }
}