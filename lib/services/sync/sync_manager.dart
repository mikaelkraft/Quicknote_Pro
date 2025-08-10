import 'dart:async';
import 'dart:convert';
import '../local/hive_initializer.dart';
import '../local/note_repository.dart';
import 'cloud_sync_service.dart';
import 'providers/google_drive_sync_provider.dart';
import 'providers/onedrive_sync_provider.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  // Available providers
  late final Map<String, CloudSyncService> _providers;
  
  // Current active provider
  CloudSyncService? _activeProvider;
  
  // Repository for notes
  final _noteRepository = NoteRepository();
  
  // Stream controllers
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  final _syncProgressController = StreamController<SyncProgress>.broadcast();
  
  // Sync state
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;
  
  // Constants
  static const String _activeSyncProviderKey = 'active_sync_provider';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const Duration _autoSyncInterval = Duration(minutes: 30);

  /// Initialize the sync manager
  void init() {
    _providers = {
      'google_drive': GoogleDriveSyncProvider(),
      'onedrive': OneDriveSyncProvider(),
    };
    
    _loadSyncSettings();
    _startAutoSync();
  }

  /// Get sync status stream
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  /// Get sync progress stream  
  Stream<SyncProgress> get syncProgressStream => _syncProgressController.stream;
  
  /// Get available providers
  List<CloudSyncService> get availableProviders => _providers.values.toList();
  
  /// Get active provider
  CloudSyncService? get activeProvider => _activeProvider;
  
  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;
  
  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Check if any provider is connected
  bool get isConnected => _activeProvider?.isSignedIn ?? false;

  /// Connect to a cloud provider
  Future<bool> connectProvider(String providerId) async {
    final provider = _providers[providerId];
    if (provider == null) {
      _emitSyncStatus(SyncStatus.error('Provider not found: $providerId'));
      return false;
    }

    try {
      _emitSyncStatus(SyncStatus.connecting());
      
      // Check if provider is configured
      if (!provider.isConfigured) {
        _emitSyncStatus(SyncStatus.error('Provider not configured: ${provider.providerName}'));
        return false;
      }

      // Sign in to the provider
      final authResult = await provider.signIn();
      if (!authResult.success) {
        _emitSyncStatus(SyncStatus.error('Failed to sign in: ${authResult.errorMessage}'));
        return false;
      }

      // Set as active provider
      _activeProvider = provider;
      await _saveActiveSyncProvider(providerId);
      
      _emitSyncStatus(SyncStatus.connected(provider.providerName));
      
      // Perform initial sync
      await syncNow();
      
      return true;
    } catch (e) {
      _emitSyncStatus(SyncStatus.error('Connection failed: $e'));
      return false;
    }
  }

  /// Disconnect from current provider
  Future<void> disconnectProvider() async {
    if (_activeProvider != null) {
      try {
        await _activeProvider!.signOut();
      } catch (e) {
        print('Error signing out: $e');
      }
      
      _activeProvider = null;
      await _saveActiveSyncProvider(null);
      _emitSyncStatus(SyncStatus.disconnected());
    }
  }

  /// Perform manual sync now
  Future<bool> syncNow() async {
    if (_isSyncing || _activeProvider == null || !_activeProvider!.isSignedIn) {
      return false;
    }

    _isSyncing = true;
    _emitSyncStatus(SyncStatus.syncing());
    _emitSyncProgress(SyncProgress(0, 'Starting sync...'));

    try {
      // Step 1: Sync notes data
      _emitSyncProgress(SyncProgress(0.2, 'Uploading notes...'));
      final notesData = _noteRepository.exportAllNotes();
      final syncUpResult = await _activeProvider!.syncUp(notesData);
      
      if (!syncUpResult.success) {
        throw Exception('Upload failed: ${syncUpResult.errorMessage}');
      }

      // Step 2: Download any remote changes
      _emitSyncProgress(SyncProgress(0.5, 'Downloading updates...'));
      final syncDownResult = await _activeProvider!.syncDown();
      
      if (syncDownResult.success && syncDownResult.data != null) {
        // TODO: Implement conflict resolution here
        // For now, we'll use last-write-wins strategy
        await _noteRepository.importNotes(syncDownResult.data!, replaceExisting: false);
      }

      // Step 3: Sync media files
      _emitSyncProgress(SyncProgress(0.8, 'Syncing media files...'));
      await _syncMediaFiles();

      // Step 4: Update sync metadata
      _emitSyncProgress(SyncProgress(0.9, 'Updating sync metadata...'));
      final metadata = CloudSyncMetadata(
        lastSyncTime: DateTime.now(),
        lastSyncId: DateTime.now().millisecondsSinceEpoch.toString(),
        notesCount: _noteRepository.getNotesCount(),
        syncedNoteIds: _noteRepository.getAllNotes().map((n) => n.id).toList(),
      );
      await _activeProvider!.setSyncMetadata(metadata);

      _lastSyncTime = DateTime.now();
      await _saveLastSyncTime();
      
      _emitSyncProgress(SyncProgress(1.0, 'Sync completed'));
      _emitSyncStatus(SyncStatus.synced(_lastSyncTime!));
      
      return true;
    } catch (e) {
      _emitSyncStatus(SyncStatus.error('Sync failed: $e'));
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync media files (images and attachments)
  Future<void> _syncMediaFiles() async {
    // TODO: Implement media file sync
    // This would involve:
    // 1. Upload new/modified media files
    // 2. Download missing media files
    // 3. Clean up orphaned files
    
    // For now, this is a placeholder
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Load sync settings from storage
  void _loadSyncSettings() {
    try {
      final box = HiveInitializer.settingsBox;
      
      // Load active provider
      final activeProviderId = box.get(_activeSyncProviderKey) as String?;
      if (activeProviderId != null && _providers.containsKey(activeProviderId)) {
        _activeProvider = _providers[activeProviderId];
      }
      
      // Load last sync time
      final lastSyncTimeString = box.get(_lastSyncTimeKey) as String?;
      if (lastSyncTimeString != null) {
        _lastSyncTime = DateTime.parse(lastSyncTimeString);
      }
      
      // Emit initial status
      if (_activeProvider?.isSignedIn == true) {
        _emitSyncStatus(SyncStatus.connected(_activeProvider!.providerName));
      } else {
        _emitSyncStatus(SyncStatus.disconnected());
      }
    } catch (e) {
      print('Error loading sync settings: $e');
      _emitSyncStatus(SyncStatus.disconnected());
    }
  }

  /// Save active sync provider
  Future<void> _saveActiveSyncProvider(String? providerId) async {
    try {
      final box = HiveInitializer.settingsBox;
      if (providerId != null) {
        await box.put(_activeSyncProviderKey, providerId);
      } else {
        await box.delete(_activeSyncProviderKey);
      }
    } catch (e) {
      print('Error saving active sync provider: $e');
    }
  }

  /// Save last sync time
  Future<void> _saveLastSyncTime() async {
    try {
      final box = HiveInitializer.settingsBox;
      if (_lastSyncTime != null) {
        await box.put(_lastSyncTimeKey, _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      print('Error saving last sync time: $e');
    }
  }

  /// Start auto sync timer
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) {
      if (_activeProvider?.isSignedIn == true && !_isSyncing) {
        syncNow();
      }
    });
  }

  /// Stop auto sync timer
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Emit sync status
  void _emitSyncStatus(SyncStatus status) {
    _syncStatusController.add(status);
  }

  /// Emit sync progress
  void _emitSyncProgress(SyncProgress progress) {
    _syncProgressController.add(progress);
  }

  /// Dispose the sync manager
  void dispose() {
    _stopAutoSync();
    _syncStatusController.close();
    _syncProgressController.close();
  }
}

/// Sync status states
class SyncStatus {
  final String state;
  final String? message;
  final DateTime? timestamp;

  SyncStatus._(this.state, this.message, this.timestamp);

  static SyncStatus disconnected() => SyncStatus._('disconnected', null, null);
  static SyncStatus connecting() => SyncStatus._('connecting', 'Connecting to cloud...', null);
  static SyncStatus connected(String provider) => SyncStatus._('connected', 'Connected to $provider', DateTime.now());
  static SyncStatus syncing() => SyncStatus._('syncing', 'Synchronizing...', null);
  static SyncStatus synced(DateTime time) => SyncStatus._('synced', 'Last synced', time);
  static SyncStatus error(String error) => SyncStatus._('error', error, DateTime.now());

  bool get isConnected => state == 'connected' || state == 'synced';
  bool get isSyncing => state == 'syncing';
  bool get hasError => state == 'error';
}

/// Sync progress information
class SyncProgress {
  final double progress; // 0.0 to 1.0
  final String message;

  SyncProgress(this.progress, this.message);
}