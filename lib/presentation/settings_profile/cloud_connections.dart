import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

/// Cloud sync connections management screen
/// 
/// Displays all available sync providers with their status,
/// connection controls, and sync options.
class CloudConnections extends StatefulWidget {
  const CloudConnections({Key? key}) : super(key: key);

  @override
  State<CloudConnections> createState() => _CloudConnectionsState();
}

class _CloudConnectionsState extends State<CloudConnections> {
  late SyncManager _syncManager;

  @override
  void initState() {
    super.initState();
    _syncManager = SyncManager();
    _initializeSyncManager();
  }

  Future<void> _initializeSyncManager() async {
    await _syncManager.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _syncManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _syncManager,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('Cloud Sync'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Consumer<SyncManager>(
          builder: (context, syncManager, child) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sync status card
                  _buildSyncStatusCard(syncManager, isDark),
                  SizedBox(height: 3.h),

                  // Primary providers section
                  _buildProviderSection(
                    'Popular Cloud Storage',
                    syncManager.registry.primaryProviders,
                    isDark,
                  ),
                  SizedBox(height: 3.h),

                  // Advanced providers section
                  _buildProviderSection(
                    'Advanced & Self-Hosted',
                    syncManager.registry.advancedProviders,
                    isDark,
                  ),
                  SizedBox(height: 2.h),

                  // Auto-sync settings
                  _buildAutoSyncSettings(syncManager, isDark),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard(SyncManager syncManager, bool isDark) {
    final summary = syncManager.getSyncStatusSummary();
    final isConnected = summary['connectedProviders'] > 0;
    final lastSync = summary['lastSync'] != null 
        ? DateTime.tryParse(summary['lastSync']) 
        : null;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? 'Cloud Sync Active' : 'No Cloud Storage Connected',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${summary['connectedProviders']} of ${summary['configuredProviders']} providers connected',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (syncManager.isSyncing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            
            if (lastSync != null) ...[
              SizedBox(height: 2.h),
              Text(
                'Last sync: ${_formatLastSync(lastSync)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            if (syncManager.currentSyncStatus != null) ...[
              SizedBox(height: 1.h),
              Text(
                syncManager.currentSyncStatus!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected && !syncManager.isSyncing
                        ? () => _performManualSync(syncManager)
                        : null,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync Now'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStorageInfo(syncManager),
                    icon: const Icon(Icons.storage, size: 16),
                    label: const Text('Storage'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSection(String title, List<SyncProvider> providers, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        ...providers.map((provider) => _buildProviderCard(provider, isDark)),
      ],
    );
  }

  Widget _buildProviderCard(SyncProvider provider, bool isDark) {
    final isConfigured = provider.isConfigured;
    final isConnected = provider.state == SyncProviderState.connected;
    final isConnecting = provider.state == SyncProviderState.connecting;
    final hasError = provider.state == SyncProviderState.error;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getProviderIcon(provider.iconName),
                  size: 24,
                  color: isConnected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getProviderStatusText(provider),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasError 
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildProviderActions(provider, isConfigured, isConnected, isConnecting),
              ],
            ),
            
            // Provider capabilities
            if (isConfigured) ...[
              SizedBox(height: 2.h),
              _buildProviderCapabilities(provider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderActions(SyncProvider provider, bool isConfigured, bool isConnected, bool isConnecting) {
    if (!isConfigured) {
      return TextButton(
        onPressed: () => _showConfigurationHelp(provider),
        child: const Text('Setup'),
      );
    }

    if (isConnecting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (isConnected) {
      return PopupMenuButton<String>(
        onSelected: (value) => _handleProviderAction(provider, value),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'sync', child: Text('Sync Now')),
          const PopupMenuItem(value: 'disconnect', child: Text('Disconnect')),
        ],
        icon: const Icon(Icons.more_vert),
      );
    }

    return ElevatedButton(
      onPressed: () => _connectProvider(provider),
      child: const Text('Connect'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      ),
    );
  }

  Widget _buildProviderCapabilities(SyncProvider provider) {
    final caps = provider.capabilities;
    final badges = <Widget>[];

    if (caps.supportsBlobs) {
      badges.add(_buildCapabilityBadge('Files', Icons.attachment));
    }
    if (caps.supportsDelta) {
      badges.add(_buildCapabilityBadge('Fast Sync', Icons.fast_forward));
    }
    if (caps.maxFileSize != null) {
      final sizeMB = (caps.maxFileSize! / (1024 * 1024)).round();
      badges.add(_buildCapabilityBadge('${sizeMB}MB limit', Icons.storage));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 1.w,
      children: badges,
    );
  }

  Widget _buildCapabilityBadge(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 1.w),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSyncSettings(SyncManager syncManager, bool isDark) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auto-Sync Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            
            SwitchListTile(
              title: const Text('Auto-Sync'),
              subtitle: const Text('Automatically sync in the background'),
              value: syncManager.autoSyncEnabled,
              onChanged: (value) => syncManager.setAutoSyncEnabled(value),
              contentPadding: EdgeInsets.zero,
            ),
            
            if (syncManager.autoSyncEnabled) ...[
              SizedBox(height: 1.h),
              Text(
                'Sync Interval',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: 1.h),
              DropdownButton<int>(
                value: syncManager.syncIntervalMinutes,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 15, child: Text('Every 15 minutes')),
                  DropdownMenuItem(value: 30, child: Text('Every 30 minutes')),
                  DropdownMenuItem(value: 60, child: Text('Every hour')),
                  DropdownMenuItem(value: 180, child: Text('Every 3 hours')),
                  DropdownMenuItem(value: 360, child: Text('Every 6 hours')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    syncManager.setSyncInterval(value);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon(String iconName) {
    switch (iconName) {
      case 'cloud_sync': return Icons.cloud_sync;
      case 'cloud': return Icons.cloud;
      case 'cloud_upload': return Icons.cloud_upload;
      case 'cloud_done': return Icons.cloud_done;
      case 'archive': return Icons.archive;
      case 'storage': return Icons.storage;
      case 'code': return Icons.code;
      default: return Icons.cloud;
    }
  }

  String _getProviderStatusText(SyncProvider provider) {
    switch (provider.state) {
      case SyncProviderState.notConfigured:
        return 'Setup required';
      case SyncProviderState.disconnected:
        return 'Not connected';
      case SyncProviderState.connecting:
        return 'Connecting...';
      case SyncProviderState.connected:
        final lastSync = provider.lastSyncTime;
        if (lastSync != null) {
          return 'Connected • Last sync ${_formatLastSync(lastSync)}';
        }
        return 'Connected';
      case SyncProviderState.error:
        return 'Connection error';
      case SyncProviderState.syncing:
        return 'Syncing...';
    }
  }

  String _formatLastSync(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _connectProvider(SyncProvider provider) async {
    try {
      final result = await _syncManager.connectProvider(provider.providerId);
      if (!result.success && mounted) {
        _showErrorDialog('Connection Failed', result.error ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Connection Error', e.toString());
      }
    }
  }

  void _handleProviderAction(SyncProvider provider, String action) async {
    switch (action) {
      case 'sync':
        await _syncManager.syncProvider(provider.providerId);
        break;
      case 'disconnect':
        await _syncManager.disconnectProvider(provider.providerId);
        break;
    }
  }

  void _performManualSync(SyncManager syncManager) async {
    await syncManager.forceSyncNow();
  }

  void _showStorageInfo(SyncManager syncManager) async {
    final storageInfo = await syncManager.getStorageUsageSummary();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Usage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Usage: ${_formatBytes(storageInfo['totalUsedBytes'])}'),
              Text('Total Limit: ${_formatBytes(storageInfo['totalLimitBytes'])}'),
              SizedBox(height: 1.h),
              LinearProgressIndicator(
                value: storageInfo['usagePercentage'] / 100.0,
              ),
              SizedBox(height: 1.h),
              Text('${storageInfo['usagePercentage']}% used'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showConfigurationHelp(SyncProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${provider.displayName} Setup'),
        content: Text(
          'To use ${provider.displayName} sync, you need to configure your app with the appropriate credentials. '
          'Please check the README for setup instructions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}