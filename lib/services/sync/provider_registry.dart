import 'cloud_sync_service.dart';
import 'providers/dropbox_sync_provider.dart';
import 'providers/box_sync_provider.dart';
import 'providers/webdav_sync_provider.dart';
import 'providers/s3_sync_provider.dart';
import 'providers/bitbucket_sync_provider.dart';

/// Central registry for managing cloud sync providers
class ProviderRegistry {
  static final ProviderRegistry _instance = ProviderRegistry._internal();
  factory ProviderRegistry() => _instance;
  ProviderRegistry._internal();

  final Map<String, CloudSyncProvider> _providers = {};
  final Map<String, CloudSyncProvider Function()> _providerFactories = {};

  /// Initialize the registry with all available providers
  void initialize() {
    // Register provider factories
    _providerFactories['dropbox'] = () => DropboxSyncProvider();
    _providerFactories['box'] = () => BoxSyncProvider();
    _providerFactories['webdav'] = () => WebDAVSyncProvider();
    _providerFactories['s3'] = () => S3SyncProvider();
    _providerFactories['bitbucket'] = () => BitbucketSyncProvider();
    
    // Create provider instances
    for (String key in _providerFactories.keys) {
      _providers[key] = _providerFactories[key]!();
    }
  }

  /// Get a provider by its type key
  CloudSyncProvider? getProvider(String providerType) {
    return _providers[providerType];
  }

  /// Get all available provider types
  List<String> getAvailableProviders() {
    return _providerFactories.keys.toList();
  }

  /// Get all provider instances
  List<CloudSyncProvider> getAllProviders() {
    return _providers.values.toList();
  }

  /// Check if a provider is registered
  bool hasProvider(String providerType) {
    return _providers.containsKey(providerType);
  }

  /// Initialize all providers
  Future<void> initializeAllProviders() async {
    for (CloudSyncProvider provider in _providers.values) {
      try {
        await provider.initialize();
      } catch (e) {
        // Log error but continue initializing other providers
        print('Failed to initialize provider ${provider.providerName}: $e');
      }
    }
  }
}