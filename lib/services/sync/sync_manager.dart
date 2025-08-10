import 'dart:async';
import 'dart:typed_data';
import 'cloud_sync_service.dart';
import 'provider_registry.dart';

/// Queue item for sync operations
class SyncOperation {
  final String operationType; // 'upload', 'download', 'delete'
  final String fileName;
  final Uint8List? data;
  final String? folder;
  final String providerType;
  final DateTime timestamp;

  SyncOperation({
    required this.operationType,
    required this.fileName,
    this.data,
    this.folder,
    required this.providerType,
    required this.timestamp,
  });
}

/// Manages sync operations across multiple cloud providers
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final ProviderRegistry _registry = ProviderRegistry();
  final List<SyncOperation> _operationQueue = [];
  bool _isProcessing = false;
  Timer? _syncTimer;

  /// Initialize the sync manager
  Future<void> initialize() async {
    _registry.initialize();
    await _registry.initializeAllProviders();
    
    // Setup periodic sync (every 5 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      processQueue();
    });
  }

  /// Add an operation to the sync queue
  void queueOperation(SyncOperation operation) {
    // Last-write-wins: remove any existing operations for the same file
    _operationQueue.removeWhere((op) => 
        op.fileName == operation.fileName && 
        op.providerType == operation.providerType);
    
    _operationQueue.add(operation);
    
    // Process queue immediately for high-priority operations
    if (operation.operationType == 'upload') {
      processQueue();
    }
  }

  /// Process the sync operation queue
  Future<void> processQueue() async {
    if (_isProcessing || _operationQueue.isEmpty) return;
    
    _isProcessing = true;
    
    try {
      while (_operationQueue.isNotEmpty) {
        final operation = _operationQueue.removeAt(0);
        await _executeOperation(operation);
      }
    } catch (e) {
      print('Error processing sync queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Execute a single sync operation
  Future<void> _executeOperation(SyncOperation operation) async {
    final provider = _registry.getProvider(operation.providerType);
    if (provider == null || !provider.isConfigured) {
      return; // Skip unconfigured providers
    }

    try {
      switch (operation.operationType) {
        case 'upload':
          if (operation.data != null) {
            // Check provider capabilities before upload
            if (!provider.capabilities.supportsBlobs) {
              print('Provider ${provider.providerName} does not support blob uploads');
              return;
            }
            
            if (provider.capabilities.maxFileSize > 0 && 
                operation.data!.length > provider.capabilities.maxFileSize) {
              print('File too large for provider ${provider.providerName}');
              return;
            }
            
            await provider.uploadFile(
              operation.fileName, 
              operation.data!, 
              folder: operation.folder,
            );
          }
          break;
          
        case 'delete':
          await provider.deleteFile(
            operation.fileName, 
            folder: operation.folder,
          );
          break;
          
        default:
          print('Unknown operation type: ${operation.operationType}');
          return;
      }
    } catch (e) {
      print('Failed to execute operation ${operation.operationType} for ${operation.fileName}: $e');
    }
  }

  /// Manually trigger sync for a specific provider
  Future<SyncResult> syncProvider(String providerType) async {
    final provider = _registry.getProvider(providerType);
    if (provider == null) {
      return SyncResult.error('Provider not found: $providerType');
    }
    
    if (!provider.isConfigured) {
      return SyncResult.error('Provider not configured: $providerType');
    }

    try {
      // For now, just return success - actual sync logic would be implemented here
      return SyncResult.success();
    } catch (e) {
      return SyncResult.error('Sync failed: $e');
    }
  }

  /// Get all available providers with their status
  List<Map<String, dynamic>> getProviderStatuses() {
    return _registry.getAllProviders().map((provider) {
      return {
        'type': provider.runtimeType.toString().toLowerCase(),
        'name': provider.providerName,
        'status': provider.status,
        'isConfigured': provider.isConfigured,
        'capabilities': provider.capabilities,
        'statusInfo': provider.getStatusInfo(),
      };
    }).toList();
  }

  /// Upload a file to multiple providers (premium feature)
  Future<List<SyncResult>> uploadToMultipleProviders(
    String fileName, 
    Uint8List data, 
    List<String> providerTypes, {
    String? folder,
  }) async {
    final results = <SyncResult>[];
    
    for (String providerType in providerTypes) {
      queueOperation(SyncOperation(
        operationType: 'upload',
        fileName: fileName,
        data: data,
        folder: folder,
        providerType: providerType,
        timestamp: DateTime.now(),
      ));
    }
    
    await processQueue();
    return results;
  }

  /// Dispose of resources
  void dispose() {
    _syncTimer?.cancel();
  }
}