import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/backup/backup_service.dart';
import '../../services/backup/import_service.dart';
import '../../services/sync/sync_manager.dart';

class BackupImportScreen extends StatefulWidget {
  const BackupImportScreen({Key? key}) : super(key: key);

  @override
  State<BackupImportScreen> createState() => _BackupImportScreenState();
}

class _BackupImportScreenState extends State<BackupImportScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  final BackupService _backupService = BackupService();
  final ImportService _importService = ImportService();

  bool _isExporting = false;
  bool _isImporting = false;
  bool _importAsCopies = false;
  bool _syncAfterImport = true;
  
  ImportResult? _lastImportResult;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _backgroundController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _exportAllNotes() async {
    setState(() => _isExporting = true);

    try {
      // Get sample data (in real implementation, fetch from storage)
      final notes = _backupService.getSampleNotesData();
      final mediaPaths = _backupService.getSampleMediaPaths();

      // Create export summary
      final summary = _backupService.createExportSummary(notes, mediaPaths);

      // Show confirmation dialog with summary
      final confirm = await _showExportConfirmationDialog(summary);
      if (!confirm) {
        setState(() => _isExporting = false);
        return;
      }

      // Create ZIP backup
      final zipPath = await _backupService.exportNotesToZip(
        notes: notes,
        mediaPaths: mediaPaths,
      );

      // Share the backup file
      await _backupService.shareBackupFile(
        zipPath,
        subject: 'QuickNote Pro Backup - ${notes.length} notes',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created with ${notes.length} notes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<bool> _showExportConfirmationDialog(Map<String, dynamic> summary) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will create a backup containing:'),
            SizedBox(height: 2.h),
            Text('• ${summary['notesCount']} notes'),
            Text('• ${summary['mediaFilesCount']} media files'),
            Text('• Estimated size: ${summary['estimatedSizeMB']} MB'),
            SizedBox(height: 2.h),
            const Text(
              'The backup will be saved to your device and you can share it to any location.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Export'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _importFromFile() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        _showErrorSnackBar('Unable to access selected file');
        return;
      }

      setState(() => _isImporting = true);

      // Validate file first
      final validation = await _importService.validateBackupFile(file.path!);
      
      if (!validation['isValid']) {
        final errors = validation['errors'] as List<String>;
        _showErrorSnackBar('Invalid backup file: ${errors.join(', ')}');
        setState(() => _isImporting = false);
        return;
      }

      // Show import confirmation
      final confirm = await _showImportConfirmationDialog(validation);
      if (!confirm) {
        setState(() => _isImporting = false);
        return;
      }

      // Perform import
      ImportResult importResult;
      
      if (validation['fileType'] == 'zip') {
        importResult = await _importService.importFromZip(
          filePath: file.path!,
          importAsCopies: _importAsCopies,
          mergeStrategy: _importAsCopies ? 'importAsCopies' : 'lastWriteWins',
        );
      } else {
        importResult = await _importService.importFromJson(
          filePath: file.path!,
          importAsCopies: _importAsCopies,
          mergeStrategy: _importAsCopies ? 'importAsCopies' : 'lastWriteWins',
        );
      }

      _lastImportResult = importResult;

      // Show import result
      _showImportResultDialog(importResult);

      // Trigger sync if enabled and connected
      if (_syncAfterImport && context.mounted) {
        final syncManager = Provider.of<SyncManager>(context, listen: false);
        if (syncManager.shouldAutoSyncAfterImport()) {
          _triggerPostImportSync(syncManager);
        }
      }

    } catch (e) {
      _showErrorSnackBar('Import failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<bool> _showImportConfirmationDialog(Map<String, dynamic> validation) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Found ${validation['notesCount']} notes'),
            if (validation['mediaFilesCount'] > 0)
              Text('Found ${validation['mediaFilesCount']} media files'),
            SizedBox(height: 2.h),
            Row(
              children: [
                Checkbox(
                  value: _importAsCopies,
                  onChanged: (value) => setState(() => _importAsCopies = value ?? false),
                ),
                const Expanded(
                  child: Text('Import as copies\n(Create new IDs to avoid conflicts)'),
                ),
              ],
            ),
            if (context.watch<SyncManager>().isConnected) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Checkbox(
                    value: _syncAfterImport,
                    onChanged: (value) => setState(() => _syncAfterImport = value ?? true),
                  ),
                  const Expanded(
                    child: Text('Sync to cloud after import'),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showImportResultDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.getSummary()),
            if (result.warnings.isNotEmpty) ...[
              SizedBox(height: 2.h),
              const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.warnings.map((warning) => Text('• $warning', style: const TextStyle(fontSize: 12))),
            ],
            if (result.errors.isNotEmpty) ...[
              SizedBox(height: 2.h),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ...result.errors.map((error) => Text('• $error', style: const TextStyle(fontSize: 12, color: Colors.red))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _triggerPostImportSync(SyncManager syncManager) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting sync to cloud...'),
        duration: Duration(seconds: 2),
      ),
    );

    final success = await syncManager.triggerSync();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sync completed successfully' : 'Sync failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppTheme.backgroundDark,
                        AppTheme.surfaceDark.withOpacity(0.7),
                        AppTheme.accentDark.withOpacity(0.05),
                      ]
                    : [
                        AppTheme.backgroundLight,
                        AppTheme.surfaceLight.withOpacity(0.7),
                        AppTheme.accentLight.withOpacity(0.05),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [
                  0.0,
                  0.4 + (_backgroundAnimation.value * 0.2),
                  1.0,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: 'arrow_back',
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Backup & Import',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    children: [
                      SizedBox(height: 2.h),
                      
                      // Export Section
                      _buildExportSection(context, isDark),
                      
                      SizedBox(height: 3.h),
                      
                      // Import Section
                      _buildImportSection(context, isDark),
                      
                      SizedBox(height: 3.h),
                      
                      // Settings Section
                      _buildSettingsSection(context, isDark),
                      
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark.withOpacity(0.5) : AppTheme.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.textSecondaryDark.withOpacity(0.1) : AppTheme.textSecondaryLight.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'file_download',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Export Data',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          const Text(
            'Create a backup of all your notes and media files. The backup will be saved as a ZIP file that you can store anywhere.',
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportAllNotes,
              icon: _isExporting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const CustomIconWidget(
                      iconName: 'file_download',
                      size: 20,
                      color: Colors.white,
                    ),
              label: Text(_isExporting ? 'Creating Backup...' : 'Export All Notes'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportSection(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark.withOpacity(0.5) : AppTheme.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.textSecondaryDark.withOpacity(0.1) : AppTheme.textSecondaryLight.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'file_upload',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Import Data',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          const Text(
            'Import notes from a backup file (ZIP or JSON). Notes will be merged with your existing data using smart conflict resolution.',
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _importFromFile,
              icon: _isImporting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const CustomIconWidget(
                      iconName: 'file_upload',
                      size: 20,
                      color: Colors.white,
                    ),
              label: Text(_isImporting ? 'Importing...' : 'Import from File'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          if (_lastImportResult != null) ...[
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Import:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_lastImportResult!.getSummary()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark.withOpacity(0.5) : AppTheme.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.textSecondaryDark.withOpacity(0.1) : AppTheme.textSecondaryLight.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'settings',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Import Options',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          
          // Import as copies option
          Row(
            children: [
              Checkbox(
                value: _importAsCopies,
                onChanged: (value) => setState(() => _importAsCopies = value ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import as copies',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Create new IDs for imported notes to avoid conflicts',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Sync after import option (only show if connected)
          Consumer<SyncManager>(
            builder: (context, syncManager, child) {
              if (!syncManager.isConnected) {
                return const SizedBox.shrink();
              }
              
              return Row(
                children: [
                  Checkbox(
                    value: _syncAfterImport,
                    onChanged: (value) => setState(() => _syncAfterImport = value ?? true),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sync after import',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Automatically sync to ${syncManager.connectedProvider} after importing',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          
          SizedBox(height: 2.h),
          
          // Sync status
          Consumer<SyncManager>(
            builder: (context, syncManager, child) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: syncManager.isConnected 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: syncManager.isConnected ? 'cloud_done' : 'cloud_off',
                      color: syncManager.isConnected ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        syncManager.getSyncStatusText(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}