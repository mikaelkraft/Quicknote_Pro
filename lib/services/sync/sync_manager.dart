import 'package:flutter/foundation.dart';

/// Service for managing cloud synchronization.
/// 
/// Provides centralized sync operations and status management.
class SyncManager extends ChangeNotifier {
  bool _isSyncing = false;
  bool _isConnected = false;
  String? _connectedProvider;
  DateTime? _lastSyncTime;
  String? _lastSyncError;

  /// Whether a sync operation is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Whether a cloud provider is connected and configured.
  bool get isConnected => _isConnected;

  /// Name of the connected cloud provider (e.g., 'Google Drive', 'Dropbox').
  String? get connectedProvider => _connectedProvider;

  /// Time of the last successful sync operation.
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Error message from the last sync attempt, if any.
  String? get lastSyncError => _lastSyncError;

  /// Initialize the sync manager and check connection status.
  Future<void> initialize() async {
    // Mock implementation - would check for stored credentials and connectivity
    await _checkConnectionStatus();
  }

  /// Trigger a manual sync operation.
  /// 
  /// This is called from the backup/import screen when the user has the
  /// "Sync after import" option enabled.
  Future<bool> triggerSync() async {
    if (_isSyncing) {
      return false; // Already syncing
    }

    if (!_isConnected) {
      _lastSyncError = 'No cloud provider connected';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      // Mock sync operation
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate success
      _lastSyncTime = DateTime.now();
      _lastSyncError = null;
      
      return true;
    } catch (e) {
      _lastSyncError = 'Sync failed: $e';
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Check if sync should be triggered automatically.
  /// 
  /// Used to determine if the "Sync after import" option should be available.
  bool shouldAutoSyncAfterImport() {
    return _isConnected && !_isSyncing;
  }

  /// Connect to a cloud provider.
  Future<bool> connectProvider(String providerName) async {
    try {
      // Mock implementation - would handle OAuth flow
      await Future.delayed(const Duration(seconds: 1));
      
      _isConnected = true;
      _connectedProvider = providerName;
      _lastSyncError = null;
      
      notifyListeners();
      return true;
    } catch (e) {
      _lastSyncError = 'Failed to connect to $providerName: $e';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from the current cloud provider.
  Future<void> disconnectProvider() async {
    _isConnected = false;
    _connectedProvider = null;
    _lastSyncTime = null;
    _lastSyncError = null;
    
    notifyListeners();
  }

  /// Get sync status summary for display in UI.
  String getSyncStatusText() {
    if (_isSyncing) {
      return 'Syncing...';
    }
    
    if (!_isConnected) {
      return 'Not connected to cloud storage';
    }
    
    if (_lastSyncError != null) {
      return 'Last sync failed';
    }
    
    if (_lastSyncTime != null) {
      final duration = DateTime.now().difference(_lastSyncTime!);
      if (duration.inMinutes < 1) {
        return 'Synced just now';
      } else if (duration.inHours < 1) {
        return 'Synced ${duration.inMinutes}m ago';
      } else if (duration.inDays < 1) {
        return 'Synced ${duration.inHours}h ago';
      } else {
        return 'Synced ${duration.inDays}d ago';
      }
    }
    
    return 'Connected to $_connectedProvider';
  }

  /// Check the current connection status (mock implementation).
  Future<void> _checkConnectionStatus() async {
    // Mock implementation - would check stored credentials
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate that no provider is connected initially
    _isConnected = false;
    _connectedProvider = null;
  }

  /// Force a connection status refresh.
  Future<void> refreshConnectionStatus() async {
    await _checkConnectionStatus();
    notifyListeners();
  }
}