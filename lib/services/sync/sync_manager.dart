import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_provider.dart';
import 'provider_registry.dart';

/// Central sync manager that coordinates all sync providers
/// 
/// Manages sync operations, conflict resolution, offline queuing,
/// and provides a unified interface for sync across the app.
class SyncManager extends ChangeNotifier {
  static const String _autoSyncEnabledKey = 'auto_sync_enabled';
  static const String _syncIntervalKey = 'sync_interval_minutes';
  static const String _lastGlobalSyncKey = 'last_global_sync';

  final SyncProviderRegistry _registry = SyncProviderRegistry();
  
  bool _autoSyncEnabled = true;
  int _syncIntervalMinutes = 30; // Default 30 minutes
  DateTime? _lastGlobalSync;
  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  String? _currentSyncStatus;
  
  SharedPreferences? _prefs;

  /// Whether auto-sync is enabled
  bool get autoSyncEnabled => _autoSyncEnabled;
  
  /// Sync interval in minutes
  int get syncIntervalMinutes => _syncIntervalMinutes;
  
  /// Last global sync time across all providers
  DateTime? get lastGlobalSync => _lastGlobalSync;
  
  /// Whether any sync operation is currently running
  bool get isSyncing => _isSyncing;
  
  /// Current sync status message
  String? get currentSyncStatus => _currentSyncStatus;
  
  /// Get the provider registry
  SyncProviderRegistry get registry => _registry;

  /// Initialize the sync manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    await _registry.initialize();
    
    if (_autoSyncEnabled) {
      _startAutoSync();
    }
  }

  /// Load sync settings from preferences
  Future<void> _loadSettings() async {
    if (_prefs == null) return;
    
    _autoSyncEnabled = _prefs!.getBool(_autoSyncEnabledKey) ?? true;
    _syncIntervalMinutes = _prefs!.getInt(_syncIntervalKey) ?? 30;
    
    final lastSyncString = _prefs!.getString(_lastGlobalSyncKey);
    if (lastSyncString != null) {
      _lastGlobalSync = DateTime.tryParse(lastSyncString);
    }
  }

  /// Enable or disable auto-sync
  Future<void> setAutoSyncEnabled(bool enabled) async {
    if (_autoSyncEnabled == enabled) return;
    
    _autoSyncEnabled = enabled;
    
    if (_prefs != null) {
      await _prefs!.setBool(_autoSyncEnabledKey, enabled);
    }
    
    if (enabled) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
    
    notifyListeners();
  }

  /// Set sync interval in minutes
  Future<void> setSyncInterval(int minutes) async {
    if (_syncIntervalMinutes == minutes) return;
    
    _syncIntervalMinutes = minutes;
    
    if (_prefs != null) {
      await _prefs!.setInt(_syncIntervalKey, minutes);
    }
    
    // Restart auto-sync with new interval
    if (_autoSyncEnabled) {
      _stopAutoSync();
      _startAutoSync();
    }
    
    notifyListeners();
  }

  /// Start auto-sync timer
  void _startAutoSync() {
    _stopAutoSync(); // Clear any existing timer
    
    final interval = Duration(minutes: _syncIntervalMinutes);
    _autoSyncTimer = Timer.periodic(interval, (_) {
      if (!_isSyncing) {
        syncAll(background: true);
      }
    });
  }

  /// Stop auto-sync timer
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Perform manual sync of all connected providers
  Future<Map<String, SyncResult>> syncAll({bool background = false}) async {
    if (_isSyncing) {
      return {}; // Already syncing
    }

    _isSyncing = true;
    _currentSyncStatus = 'Syncing...';
    if (!background) notifyListeners();

    try {
      final results = await _registry.syncAllProviders();
      
      // Update last global sync time if any provider synced successfully
      if (results.values.any((result) => result.success)) {
        _lastGlobalSync = DateTime.now();
        if (_prefs != null) {
          await _prefs!.setString(_lastGlobalSyncKey, _lastGlobalSync!.toIso8601String());
        }
      }
      
      _currentSyncStatus = _generateSyncStatusMessage(results);
      return results;
    } catch (e) {
      _currentSyncStatus = 'Sync failed: $e';
      return {};
    } finally {
      _isSyncing = false;
      if (!background) notifyListeners();
      
      // Clear status after a delay
      Timer(const Duration(seconds: 3), () {
        _currentSyncStatus = null;
        if (!background) notifyListeners();
      });
    }
  }

  /// Sync a specific provider
  Future<SyncResult> syncProvider(String providerId) async {
    final provider = _registry.getProvider(providerId);
    if (provider == null) {
      return SyncResult.error('Provider not found');
    }

    if (provider.state != SyncProviderState.connected) {
      return SyncResult.error('Provider not connected');
    }

    _currentSyncStatus = 'Syncing ${provider.displayName}...';
    notifyListeners();

    try {
      final result = await provider.sync();
      
      if (result.success) {
        _currentSyncStatus = '${provider.displayName} synced successfully';
      } else {
        _currentSyncStatus = '${provider.displayName} sync failed: ${result.error}';
      }
      
      return result;
    } catch (e) {
      _currentSyncStatus = '${provider.displayName} sync error: $e';
      return SyncResult.error('Sync error: $e');
    } finally {
      // Clear status after a delay
      Timer(const Duration(seconds: 3), () {
        _currentSyncStatus = null;
        notifyListeners();
      });
    }
  }

  /// Connect to a sync provider
  Future<SyncResult> connectProvider(String providerId) async {
    final result = await _registry.connectProvider(providerId);
    notifyListeners(); // Notify about state change
    return result;
  }

  /// Disconnect from a sync provider
  Future<SyncResult> disconnectProvider(String providerId) async {
    final result = await _registry.disconnectProvider(providerId);
    notifyListeners(); // Notify about state change
    return result;
  }

  /// Get sync status summary
  Map<String, dynamic> getSyncStatusSummary() {
    final connected = _registry.connectedProviders;
    final lastSync = _registry.mostRecentlySynced?.lastSyncTime ?? _lastGlobalSync;
    
    return {
      'connectedProviders': connected.length,
      'totalProviders': _registry.allProviders.length,
      'configuredProviders': _registry.configuredProviders.length,
      'lastSync': lastSync?.toIso8601String(),
      'autoSyncEnabled': _autoSyncEnabled,
      'isSyncing': _isSyncing,
      'status': _currentSyncStatus,
    };
  }

  /// Get storage usage across all providers
  Future<Map<String, dynamic>> getStorageUsageSummary() async {
    final storageInfo = await _registry.getAllStorageInfo();
    
    int totalUsed = 0;
    int totalLimit = 0;
    
    for (final info in storageInfo.values) {
      totalUsed += (info['usedBytes'] as int? ?? 0);
      totalLimit += (info['totalBytes'] as int? ?? 0);
    }
    
    return {
      'totalUsedBytes': totalUsed,
      'totalLimitBytes': totalLimit,
      'usagePercentage': totalLimit > 0 ? (totalUsed / totalLimit * 100).round() : 0,
      'providers': storageInfo,
    };
  }

  /// Generate human-readable sync status message
  String _generateSyncStatusMessage(Map<String, SyncResult> results) {
    if (results.isEmpty) {
      return 'No providers to sync';
    }
    
    final successful = results.values.where((r) => r.success).length;
    final total = results.length;
    
    if (successful == total) {
      return 'All providers synced successfully';
    } else if (successful == 0) {
      return 'All providers failed to sync';
    } else {
      return '$successful of $total providers synced successfully';
    }
  }

  /// Force sync now (ignores auto-sync settings)
  Future<Map<String, SyncResult>> forceSyncNow() async {
    return await syncAll(background: false);
  }

  /// Check if sync is needed based on last sync time and interval
  bool get isSyncNeeded {
    if (_lastGlobalSync == null) return true;
    
    final timeSinceSync = DateTime.now().difference(_lastGlobalSync!);
    final syncInterval = Duration(minutes: _syncIntervalMinutes);
    
    return timeSinceSync >= syncInterval;
  }

  /// Get next scheduled sync time
  DateTime? get nextScheduledSync {
    if (!_autoSyncEnabled || _lastGlobalSync == null) return null;
    
    return _lastGlobalSync!.add(Duration(minutes: _syncIntervalMinutes));
  }

  /// Clean up resources
  @override
  void dispose() {
    _stopAutoSync();
    _registry.dispose();
    super.dispose();
  }
}