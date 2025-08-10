/// Base interface for cloud sync providers
abstract class CloudSyncService {
  /// Display name for the sync provider
  String get displayName;
  
  /// Whether the provider is currently configured and ready to use
  bool get isConfigured;
  
  /// Whether the user is currently signed in
  bool get isSignedIn;
  
  /// Current sync status
  SyncStatus get status;
  
  /// Sign in to the service
  /// Returns true if successful, false otherwise
  Future<bool> signIn();
  
  /// Sign out from the service
  Future<void> signOut();
  
  /// Sync notes to the cloud
  /// Returns true if successful, false otherwise
  Future<bool> syncNotes();
  
  /// Check if sync is available
  Future<bool> isAvailable();
  
  /// Get storage usage information
  Future<StorageInfo> getStorageInfo();
}

/// Sync status enumeration
enum SyncStatus {
  notConfigured,
  signedOut,
  signedIn,
  syncing,
  error,
}

/// Storage information model
class StorageInfo {
  final double usedBytes;
  final double totalBytes;
  final String displayUsed;
  final String displayTotal;
  
  const StorageInfo({
    required this.usedBytes,
    required this.totalBytes,
    required this.displayUsed,
    required this.displayTotal,
  });
  
  double get usagePercentage => totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0;
}