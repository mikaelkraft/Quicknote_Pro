import 'sync_provider.dart';
import 'providers/google_drive_sync_provider.dart';
import 'providers/cloud_providers.dart';
import 'providers/other_providers.dart';

/// Registry of all available sync providers
/// 
/// Manages the lifecycle and discovery of sync providers,
/// allowing the app to work with multiple providers uniformly.
class SyncProviderRegistry {
  static final SyncProviderRegistry _instance = SyncProviderRegistry._internal();
  factory SyncProviderRegistry() => _instance;
  SyncProviderRegistry._internal();

  final Map<String, SyncProvider> _providers = {};
  bool _initialized = false;

  /// Initialize all sync providers
  Future<void> initialize() async {
    if (_initialized) return;

    // Register Google Drive (fully functional)
    _providers['google_drive'] = GoogleDriveSyncProvider();

    // Register cloud providers (placeholders)
    _providers['onedrive'] = OneDriveSyncProvider();
    _providers['dropbox'] = DropboxSyncProvider();
    _providers['box'] = BoxSyncProvider();

    // Register other providers (placeholders)
    _providers['icloud_drive'] = ICloudDriveSyncProvider();
    _providers['webdav'] = WebDAVSyncProvider();
    _providers['s3'] = S3SyncProvider();
    _providers['bitbucket'] = BitbucketSyncProvider();

    // Initialize all providers
    await Future.wait(_providers.values.map((provider) => provider.initialize()));

    _initialized = true;
  }

  /// Get all available providers
  List<SyncProvider> get allProviders => List.unmodifiable(_providers.values);

  /// Get providers that are properly configured
  List<SyncProvider> get configuredProviders => 
      _providers.values.where((p) => p.isConfigured).toList();

  /// Get providers that are currently connected
  List<SyncProvider> get connectedProviders => 
      _providers.values.where((p) => p.state == SyncProviderState.connected).toList();

  /// Get a specific provider by ID
  SyncProvider? getProvider(String providerId) => _providers[providerId];

  /// Get provider by display name
  SyncProvider? getProviderByName(String displayName) {
    return _providers.values
        .where((p) => p.displayName.toLowerCase() == displayName.toLowerCase())
        .firstOrNull;
  }

  /// Get providers that support a specific capability
  List<SyncProvider> getProvidersWithCapability({
    bool? supportsBlobs,
    bool? supportsDelta,
    bool? supportsRealTimeSync,
    int? maxFileSize,
  }) {
    return _providers.values.where((provider) {
      final caps = provider.capabilities;
      
      if (supportsBlobs != null && caps.supportsBlobs != supportsBlobs) return false;
      if (supportsDelta != null && caps.supportsDelta != supportsDelta) return false;
      if (supportsRealTimeSync != null && caps.supportsRealTimeSync != supportsRealTimeSync) return false;
      if (maxFileSize != null && caps.maxFileSize != null && caps.maxFileSize! < maxFileSize) return false;
      
      return true;
    }).toList();
  }

  /// Get primary/recommended providers for display
  List<SyncProvider> get primaryProviders => [
    // Google Drive first (fully functional)
    if (_providers['google_drive'] != null) _providers['google_drive']!,
    
    // Popular cloud providers
    if (_providers['onedrive'] != null) _providers['onedrive']!,
    if (_providers['dropbox'] != null) _providers['dropbox']!,
    if (_providers['icloud_drive'] != null) _providers['icloud_drive']!,
  ];

  /// Get advanced/technical providers for power users
  List<SyncProvider> get advancedProviders => [
    if (_providers['box'] != null) _providers['box']!,
    if (_providers['webdav'] != null) _providers['webdav']!,
    if (_providers['s3'] != null) _providers['s3']!,
    if (_providers['bitbucket'] != null) _providers['bitbucket']!,
  ];

  /// Connect to a provider
  Future<SyncResult> connectProvider(String providerId) async {
    final provider = _providers[providerId];
    if (provider == null) {
      return SyncResult.error('Provider not found: $providerId');
    }

    return await provider.connect();
  }

  /// Disconnect from a provider
  Future<SyncResult> disconnectProvider(String providerId) async {
    final provider = _providers[providerId];
    if (provider == null) {
      return SyncResult.error('Provider not found: $providerId');
    }

    return await provider.disconnect();
  }

  /// Sync with all connected providers
  Future<Map<String, SyncResult>> syncAllProviders() async {
    final results = <String, SyncResult>{};
    
    for (final provider in connectedProviders) {
      try {
        results[provider.providerId] = await provider.sync();
      } catch (e) {
        results[provider.providerId] = SyncResult.error('Sync failed: $e');
      }
    }
    
    return results;
  }

  /// Get combined storage info from all connected providers
  Future<Map<String, Map<String, dynamic>>> getAllStorageInfo() async {
    final storageInfo = <String, Map<String, dynamic>>{};
    
    for (final provider in connectedProviders) {
      try {
        final info = await provider.getStorageInfo();
        if (info != null) {
          storageInfo[provider.providerId] = info;
        }
      } catch (e) {
        // Ignore individual provider errors
      }
    }
    
    return storageInfo;
  }

  /// Dispose all providers
  void dispose() {
    for (final provider in _providers.values) {
      provider.dispose();
    }
    _providers.clear();
    _initialized = false;
  }

  /// Check if any provider is currently syncing
  bool get isAnySyncing => _providers.values
      .any((p) => p.state == SyncProviderState.syncing);

  /// Get count of providers by state
  Map<SyncProviderState, int> get providerStateCount {
    final counts = <SyncProviderState, int>{};
    
    for (final state in SyncProviderState.values) {
      counts[state] = _providers.values
          .where((p) => p.state == state)
          .length;
    }
    
    return counts;
  }

  /// Get the most recently synced provider
  SyncProvider? get mostRecentlySynced {
    SyncProvider? mostRecent;
    DateTime? latestSync;
    
    for (final provider in _providers.values) {
      if (provider.lastSyncTime != null) {
        if (latestSync == null || provider.lastSyncTime!.isAfter(latestSync)) {
          latestSync = provider.lastSyncTime;
          mostRecent = provider;
        }
      }
    }
    
    return mostRecent;
  }
}