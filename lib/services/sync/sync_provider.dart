import 'dart:typed_data';

/// Enumeration of possible sync provider connection states
enum SyncProviderState {
  /// Provider is not configured with necessary credentials
  notConfigured,
  
  /// Provider is configured but not connected/authenticated
  disconnected,
  
  /// Provider is in the process of connecting
  connecting,
  
  /// Provider is connected and ready for sync operations
  connected,
  
  /// Provider connection has an error
  error,
  
  /// Provider is currently syncing data
  syncing,
}

/// Capabilities that a sync provider may support
class SyncProviderCapabilities {
  /// Whether the provider supports blob/file storage
  final bool supportsBlobs;
  
  /// Whether the provider supports delta/incremental sync
  final bool supportsDelta;
  
  /// Maximum file size supported (in bytes, null for unlimited)
  final int? maxFileSize;
  
  /// Whether the provider supports real-time sync
  final bool supportsRealTimeSync;
  
  /// Whether the provider requires internet connection
  final bool requiresInternet;

  const SyncProviderCapabilities({
    this.supportsBlobs = true,
    this.supportsDelta = false,
    this.maxFileSize,
    this.supportsRealTimeSync = false,
    this.requiresInternet = true,
  });
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String? error;
  final int? syncedItemCount;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    this.error,
    this.syncedItemCount,
    required this.timestamp,
  });

  factory SyncResult.success({int? syncedItemCount}) {
    return SyncResult(
      success: true,
      syncedItemCount: syncedItemCount,
      timestamp: DateTime.now(),
    );
  }

  factory SyncResult.error(String error) {
    return SyncResult(
      success: false,
      error: error,
      timestamp: DateTime.now(),
    );
  }
}

/// Base abstract class for all sync providers
abstract class SyncProvider {
  /// Unique identifier for this provider
  String get providerId;
  
  /// Human-readable name for this provider
  String get displayName;
  
  /// Icon name for this provider (from MaterialIcons)
  String get iconName;
  
  /// Current connection state
  SyncProviderState get state;
  
  /// Provider capabilities
  SyncProviderCapabilities get capabilities;
  
  /// Last sync timestamp (null if never synced)
  DateTime? get lastSyncTime;
  
  /// Whether this provider is properly configured
  bool get isConfigured;

  /// Stream of state changes
  Stream<SyncProviderState> get stateStream;

  /// Initialize the provider (load credentials, setup, etc.)
  Future<void> initialize();
  
  /// Connect/authenticate with the service
  Future<SyncResult> connect();
  
  /// Disconnect from the service
  Future<SyncResult> disconnect();
  
  /// Sync all data up to the service
  Future<SyncResult> syncUp();
  
  /// Sync all data down from the service
  Future<SyncResult> syncDown();
  
  /// Full bidirectional sync
  Future<SyncResult> sync() async {
    try {
      final downResult = await syncDown();
      if (!downResult.success) return downResult;
      
      final upResult = await syncUp();
      return upResult;
    } catch (e) {
      return SyncResult.error('Sync failed: $e');
    }
  }
  
  /// Upload a blob/file to the service
  Future<SyncResult> uploadBlob(String fileName, Uint8List data);
  
  /// Download a blob/file from the service  
  Future<Uint8List?> downloadBlob(String fileName);
  
  /// Delete a blob/file from the service
  Future<SyncResult> deleteBlob(String fileName);
  
  /// Get storage usage information
  Future<Map<String, dynamic>?> getStorageInfo();
  
  /// Dispose of any resources
  void dispose();
}