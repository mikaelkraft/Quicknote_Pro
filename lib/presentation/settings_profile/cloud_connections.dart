import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/sync/sync_manager.dart';
import '../../services/sync/cloud_sync_service.dart';

class CloudConnectionsScreen extends StatefulWidget {
  const CloudConnectionsScreen({Key? key}) : super(key: key);

  @override
  State<CloudConnectionsScreen> createState() => _CloudConnectionsScreenState();
}

class _CloudConnectionsScreenState extends State<CloudConnectionsScreen> {
  final SyncManager _syncManager = SyncManager();
  SyncStatus? _currentStatus;
  SyncProgress? _currentProgress;

  @override
  void initState() {
    super.initState();
    _listenToSyncStatus();
  }

  void _listenToSyncStatus() {
    _syncManager.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
      }
    });

    _syncManager.syncProgressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentProgress = progress;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            size: 6.w,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        title: Text(
          'Cloud Storage',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStatusCard(),
            SizedBox(height: 3.h),
            _buildProvidersSection(),
            SizedBox(height: 3.h),
            _buildSyncOptionsSection(),
            SizedBox(height: 3.h),
            _buildStorageInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isConnected = _currentStatus?.isConnected ?? false;
    final bool isSyncing = _currentStatus?.isSyncing ?? false;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isSyncing) {
      statusColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
      statusIcon = Icons.sync;
      statusText = 'Syncing...';
    } else if (isConnected) {
      statusColor = isDark ? AppTheme.successDark : AppTheme.successLight;
      statusIcon = Icons.cloud_done;
      statusText = _currentStatus?.message ?? 'Connected';
    } else {
      statusColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
      statusIcon = Icons.cloud_off;
      statusText = 'Not connected';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            statusIcon,
            size: 12.w,
            color: statusColor,
          ),
          SizedBox(height: 2.h),
          Text(
            statusText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (_currentStatus?.timestamp != null) ...[
            SizedBox(height: 1.h),
            Text(
              'Last synced: ${_formatDateTime(_currentStatus!.timestamp!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
            ),
          ],
          if (isSyncing && _currentProgress != null) ...[
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: _currentProgress!.progress,
              backgroundColor: statusColor.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            SizedBox(height: 1.h),
            Text(
              _currentProgress!.message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (isConnected && !isSyncing) ...[
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: _syncNow,
              icon: CustomIconWidget(
                iconName: 'sync',
                size: 5.w,
                color: Colors.white,
              ),
              label: const Text('Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProvidersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cloud Providers',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 2.h),
        ...(_syncManager.availableProviders.map((provider) => _buildProviderCard(provider))),
      ],
    );
  }

  Widget _buildProviderCard(CloudSyncService provider) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = _syncManager.activeProvider == provider;
    final bool isConnected = isActive && provider.isSignedIn;

    String iconName;
    switch (provider.providerName) {
      case 'Google Drive':
        iconName = 'google_drive';
        break;
      case 'OneDrive':
        iconName = 'onedrive';
        break;
      default:
        iconName = 'cloud';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
              : (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              size: 8.w,
              color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.providerName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _getProviderStatusText(provider, isConnected),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getProviderStatusColor(provider, isConnected, isDark),
                      ),
                ),
              ],
            ),
          ),
          _buildProviderAction(provider, isConnected),
        ],
      ),
    );
  }

  Widget _buildProviderAction(CloudSyncService provider, bool isConnected) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (!provider.isConfigured) {
      return Text(
        'Not configured',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
      );
    }

    if (isConnected) {
      return PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'disconnect':
              _disconnectProvider();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'disconnect',
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'logout',
                  size: 5.w,
                  color: Theme.of(context).colorScheme.error,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Disconnect',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
        ],
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.successDark : AppTheme.successLight).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                size: 4.w,
                color: isDark ? AppTheme.successDark : AppTheme.successLight,
              ),
              SizedBox(width: 1.w),
              Text(
                'Connected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.successDark : AppTheme.successLight,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: () => _connectProvider(provider),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        side: BorderSide(
          color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        ),
      ),
      child: const Text('Connect'),
    );
  }

  Widget _buildSyncOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sync Options',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 2.h),
        _buildSyncOptionTile(
          icon: 'sync',
          title: 'Auto Sync',
          subtitle: 'Automatically sync changes every 30 minutes',
          value: true, // TODO: Make this configurable
          onChanged: (value) {
            // TODO: Implement auto sync toggle
          },
        ),
        _buildSyncOptionTile(
          icon: 'wifi',
          title: 'Sync on WiFi Only',
          subtitle: 'Only sync when connected to WiFi',
          value: false, // TODO: Make this configurable
          onChanged: (value) {
            // TODO: Implement WiFi-only sync toggle
          },
        ),
      ],
    );
  }

  Widget _buildSyncOptionTile({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        leading: CustomIconWidget(
          iconName: icon,
          size: 6.w,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStorageInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Storage Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 2.h),
        _buildInfoTile(
          icon: 'note',
          title: 'Local Notes',
          value: '${_syncManager.isConnected ? 42 : 0} notes', // TODO: Get actual count
        ),
        _buildInfoTile(
          icon: 'image',
          title: 'Media Files',
          value: '${_syncManager.isConnected ? 15 : 0} files', // TODO: Get actual count
        ),
        _buildInfoTile(
          icon: 'storage',
          title: 'Storage Used',
          value: '${_syncManager.isConnected ? 2.3 : 0} MB', // TODO: Calculate actual usage
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required String icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        leading: CustomIconWidget(
          iconName: icon,
          size: 6.w,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  String _getProviderStatusText(CloudSyncService provider, bool isConnected) {
    if (!provider.isConfigured) {
      return 'OAuth credentials not configured';
    }
    if (isConnected) {
      final user = provider.currentUser;
      return user?.email ?? 'Connected';
    }
    return 'Not connected';
  }

  Color _getProviderStatusColor(CloudSyncService provider, bool isConnected, bool isDark) {
    if (!provider.isConfigured) {
      return isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    }
    if (isConnected) {
      return isDark ? AppTheme.successDark : AppTheme.successLight;
    }
    return isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Future<void> _connectProvider(CloudSyncService provider) async {
    final providerId = _getProviderId(provider);
    if (providerId != null) {
      final success = await _syncManager.connectProvider(providerId);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${provider.providerName}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _disconnectProvider() async {
    await _syncManager.disconnectProvider();
  }

  Future<void> _syncNow() async {
    final success = await _syncManager.syncNow();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync failed. Please try again.'),
        ),
      );
    }
  }

  String? _getProviderId(CloudSyncService provider) {
    switch (provider.providerName) {
      case 'Google Drive':
        return 'google_drive';
      case 'OneDrive':
        return 'onedrive';
      default:
        return null;
    }
  }
}