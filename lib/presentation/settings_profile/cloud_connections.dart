import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/sync/sync_manager.dart';
import '../../services/sync/cloud_sync_service.dart';
import '../../services/premium_service.dart';

class CloudConnectionsScreen extends StatefulWidget {
  const CloudConnectionsScreen({Key? key}) : super(key: key);

  @override
  State<CloudConnectionsScreen> createState() => _CloudConnectionsScreenState();
}

class _CloudConnectionsScreenState extends State<CloudConnectionsScreen> {
  final SyncManager _syncManager = SyncManager();
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    try {
      await _syncManager.initialize();
      setState(() {
        _providers = _syncManager.getProviderStatuses();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize cloud providers: $e')),
        );
      }
    }
  }

  Future<void> _refreshProviders() async {
    setState(() {
      _providers = _syncManager.getProviderStatuses();
    });
  }

  Future<void> _connectProvider(String providerType) async {
    // Show configuration dialog based on provider type
    switch (providerType.toLowerCase()) {
      case 'webdavsyncprovider':
        _showWebDAVConfigDialog();
        break;
      case 's3syncprovider':
        _showS3ConfigDialog();
        break;
      case 'bitbucketsyncprovider':
        _showBitbucketConfigDialog();
        break;
      default:
        _showGenericConnectionDialog(providerType);
        break;
    }
  }

  Future<void> _disconnectProvider(String providerType) async {
    // TODO: Implement disconnect logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$providerType disconnected')),
    );
    await _refreshProviders();
  }

  Future<void> _syncProvider(String providerType) async {
    // Check premium access for cloud sync
    if (!PremiumService.validatePremiumAction(context, 'cloud_sync')) {
      return;
    }

    try {
      final result = await _syncManager.syncProvider(providerType);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync completed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: ${result.errorMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync error: $e')),
      );
    }
  }

  void _showWebDAVConfigDialog() {
    final serverUrlController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure WebDAV'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: serverUrlController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://your-server.com/remote.php/dav',
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password/App Password',
                ),
                obscureText: true,
              ),
              SizedBox(height: 2.h),
              Text(
                'For Nextcloud/ownCloud, use an app password instead of your main password.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final serverUrl = serverUrlController.text.trim();
              final username = usernameController.text.trim();
              final password = passwordController.text.trim();
              
              if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // TODO: Configure WebDAV provider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('WebDAV configuration saved (not yet implemented)')),
              );
              await _refreshProviders();
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showS3ConfigDialog() {
    final accessKeyController = TextEditingController();
    final secretKeyController = TextEditingController();
    final regionController = TextEditingController(text: 'us-east-1');
    final bucketController = TextEditingController();
    final endpointController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure S3 Storage'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: accessKeyController,
                decoration: const InputDecoration(
                  labelText: 'Access Key',
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: secretKeyController,
                decoration: const InputDecoration(
                  labelText: 'Secret Key',
                ),
                obscureText: true,
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: regionController,
                decoration: const InputDecoration(
                  labelText: 'Region',
                  hintText: 'us-east-1',
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: bucketController,
                decoration: const InputDecoration(
                  labelText: 'Bucket Name',
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: endpointController,
                decoration: const InputDecoration(
                  labelText: 'Custom Endpoint (optional)',
                  hintText: 'For MinIO or other S3-compatible services',
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Leave endpoint empty for AWS S3. For MinIO, use your MinIO server URL.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final accessKey = accessKeyController.text.trim();
              final secretKey = secretKeyController.text.trim();
              final region = regionController.text.trim();
              final bucket = bucketController.text.trim();
              final endpoint = endpointController.text.trim();
              
              if (accessKey.isEmpty || secretKey.isEmpty || region.isEmpty || bucket.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // TODO: Configure S3 provider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('S3 configuration saved (not yet implemented)')),
              );
              await _refreshProviders();
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showBitbucketConfigDialog() {
    final workspaceController = TextEditingController();
    final repositoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Bitbucket Repository'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: workspaceController,
                decoration: const InputDecoration(
                  labelText: 'Workspace',
                  hintText: 'your-workspace',
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: repositoryController,
                decoration: const InputDecoration(
                  labelText: 'Repository',
                  hintText: 'your-repo-name',
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Notes will be stored as JSON files and media under folders in your repository. Git LFS is recommended for large media files.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final workspace = workspaceController.text.trim();
              final repository = repositoryController.text.trim();
              
              if (workspace.isEmpty || repository.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // TODO: Configure Bitbucket provider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bitbucket configuration saved (authentication required)')),
              );
              await _refreshProviders();
            },
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  void _showGenericConnectionDialog(String providerType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect to $providerType'),
        content: Text('OAuth authentication for $providerType is not yet implemented. This requires client ID configuration in the build settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Cloud Connections'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProviders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Text(
                    'Manage your cloud storage connections. All providers are optional and the app works offline.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 3.h),
                  ..._providers.map((provider) => _buildProviderCard(provider)),
                ],
              ),
            ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final String name = provider['name'] ?? 'Unknown';
    final String type = provider['type'] ?? '';
    final CloudSyncStatus status = provider['status'] ?? CloudSyncStatus.notConfigured;
    final bool isConfigured = provider['isConfigured'] ?? false;
    final Map<String, dynamic> statusInfo = provider['statusInfo'] ?? {};

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case CloudSyncStatus.connected:
        statusColor = Colors.green;
        statusText = 'Connected';
        statusIcon = Icons.check_circle;
        break;
      case CloudSyncStatus.error:
        statusColor = Colors.red;
        statusText = 'Error';
        statusIcon = Icons.error;
        break;
      case CloudSyncStatus.syncing:
        statusColor = Colors.blue;
        statusText = 'Syncing';
        statusIcon = Icons.sync;
        break;
      case CloudSyncStatus.disconnected:
        statusColor = Colors.orange;
        statusText = 'Disconnected';
        statusIcon = Icons.cloud_off;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Not Connected';
        statusIcon = Icons.cloud_queue;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppTheme.dividerDark : AppTheme.dividerLight).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                        (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getProviderIcon(name),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Row(
                        children: [
                          Icon(
                            statusIcon,
                            color: statusColor,
                            size: 16,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            statusText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => isConfigured ? _disconnectProvider(type) : _connectProvider(type),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isConfigured ? Colors.red : Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: isConfigured ? Colors.red : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    child: Text(isConfigured ? 'Disconnect' : 'Connect'),
                  ),
                ),
                if (isConfigured) ...[
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _syncProvider(type),
                      child: const Text('Sync Now'),
                    ),
                  ),
                ],
              ],
            ),
            if (statusInfo.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 1.h),
                    ...statusInfo.entries
                        .where((entry) => entry.key != 'provider' && entry.key != 'status')
                        .map((entry) => Padding(
                              padding: EdgeInsets.only(bottom: 0.5.h),
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon(String providerName) {
    switch (providerName.toLowerCase()) {
      case 'dropbox':
        return Icons.folder;
      case 'box':
        return Icons.inventory;
      case 'webdav':
        return Icons.storage;
      case 's3 storage':
        return Icons.cloud_upload;
      case 'bitbucket':
        return Icons.code;
      default:
        return Icons.cloud;
    }
  }
}