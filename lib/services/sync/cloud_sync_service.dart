import 'dart:typed_data';

/// Represents the status of a cloud sync provider
enum CloudSyncStatus {
  notConfigured,
  connected,
  disconnected,
  error,
  syncing,
}

/// Provider capability flags to guide Sync Manager behavior
class ProviderCapabilities {
  final bool supportsBlobs;
  final bool supportsDelta;
  final int maxFileSize; // in bytes, 0 = unlimited
  final List<String> supportedFileTypes;
  
  const ProviderCapabilities({
    this.supportsBlobs = true,
    this.supportsDelta = false,
    this.maxFileSize = 0,
    this.supportedFileTypes = const ['*'],
  });
}

/// Sync result data transfer object
class SyncResult {
  final bool success;
  final String? errorMessage;
  final DateTime timestamp;
  final int filesProcessed;
  
  const SyncResult({
    required this.success,
    this.errorMessage,
    required this.timestamp,
    this.filesProcessed = 0,
  });
  
  factory SyncResult.success({int filesProcessed = 0}) {
    return SyncResult(
      success: true,
      timestamp: DateTime.now(),
      filesProcessed: filesProcessed,
    );
  }
  
  factory SyncResult.error(String errorMessage) {
    return SyncResult(
      success: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }
}

/// Abstract base class for all cloud sync providers
abstract class CloudSyncProvider {
  /// Provider name (e.g., "Google Drive", "Dropbox", etc.)
  String get providerName;
  
  /// Provider capabilities
  ProviderCapabilities get capabilities;
  
  /// Current connection status
  CloudSyncStatus get status;
  
  /// Initialize the provider (setup configurations, check credentials, etc.)
  Future<void> initialize();
  
  /// Connect/authenticate with the provider
  Future<SyncResult> connect();
  
  /// Disconnect from the provider
  Future<void> disconnect();
  
  /// Upload a file to the cloud
  Future<SyncResult> uploadFile(String fileName, Uint8List data, {String? folder});
  
  /// Download a file from the cloud
  Future<Uint8List?> downloadFile(String fileName, {String? folder});
  
  /// List files in the cloud storage
  Future<List<String>> listFiles({String? folder});
  
  /// Delete a file from the cloud
  Future<SyncResult> deleteFile(String fileName, {String? folder});
  
  /// Check if the provider is properly configured
  bool get isConfigured;
  
  /// Get provider configuration status for UI display
  Map<String, dynamic> getStatusInfo();
  
  /// Validate provider configuration
  Future<bool> validateConfiguration();
}

/// Factory for creating sync providers
class CloudSyncProviderFactory {
  static CloudSyncProvider? createProvider(String providerType) {
    // Providers will be registered here via the registry
    return null;
  }
}