import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/biometric_dialog_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';

class SettingsProfile extends StatefulWidget {
  const SettingsProfile({Key? key}) : super(key: key);

  @override
  State<SettingsProfile> createState() => _SettingsProfileState();
}

class _SettingsProfileState extends State<SettingsProfile>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _sectionsController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _sectionsAnimation;

  // Settings state  
  bool _autoBackup = true;
  bool _syncEnabled = true;
  bool _reminderNotifications = true;
  bool _syncNotifications = false;
  bool _marketingNotifications = false;
  double _fontSize = 16.0;
  String _defaultNoteType = 'Text';

  // User data
  final Map<String, dynamic> _userProfile = {
    'name': 'Alex Johnson',
    'email': 'alexjohnson@email.com',
    'avatar':
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
    'isPremium': false,
    'notesCreated': 127,
    'storageUsed': 45.2, // MB
    'storageLimit': 100.0, // MB
    'joinedDate': '2024-01-15',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _sectionsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _sectionsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sectionsController,
      curve: Curves.elasticOut,
    ));

    _backgroundController.repeat(reverse: true);
    _sectionsController.forward();
  }

  void _loadSettings() {
    // Settings are now managed by ThemeService and loaded automatically
    // Local settings like fontSize, notifications etc. can be loaded from SharedPreferences here
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _sectionsController.dispose();
    super.dispose();
  }

  void _showBiometricDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => BiometricDialogWidget(
        action: action,
        onConfirm: onConfirm,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _updateAvatar('camera');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _updateAvatar('gallery');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'person',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Use Default Avatar'),
              onTap: () {
                Navigator.pop(context);
                _updateAvatar('default');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateAvatar(String source) {
    // Implement avatar update logic
    setState(() {
      // Update avatar source
    });
  }

  void _exportData() {
    // Redirect to the new backup & import screen
    Navigator.pushNamed(context, AppRoutes.backupImport);
  }

  void _deleteAccount() {
    _showBiometricDialog('Delete Account', () {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
              'This will permanently delete your account and all data. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement account deletion
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    });
  }

  void _manualBackup() async {
    setState(() {
      // Show loading state
    });

    // Simulate backup process
    await Future.delayed(const Duration(seconds: 2));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup completed successfully!')),
    );
  }

  void _openFeedback() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Text(
              'Send Feedback',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Tell us what you think...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Feedback sent! Thank you.')),
                      );
                    },
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
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
                      'Settings & Profile',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: AnimatedBuilder(
                  animation: _sectionsAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _sectionsAnimation.value,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Column(
                          children: [
                            // Profile header
                            ProfileHeaderWidget(
                              userProfile: _userProfile,
                              onEditAvatar: _showAvatarOptions,
                              onEditName: () {
                                // Implement name editing
                              },
                            ),

                            SizedBox(height: 3.h),

                            // App Preferences
                            SettingsSectionWidget(
                              title: 'App Preferences',
                              icon: 'tune',
                              children: [
                                _buildThemeSelector(),
                                _buildFontSizeSlider(),
                                _buildDefaultNoteTypeSelector(),
                              ],
                            ),

                            SizedBox(height: 2.h),

                            // Backup & Sync
                            SettingsSectionWidget(
                              title: 'Cloud & Data',
                              icon: 'cloud_sync',
                              children: [
                                _buildSyncStatus(),
                                _buildSwitchTile(
                                  'Auto Backup',
                                  'Automatically backup notes',
                                  _autoBackup,
                                  (value) =>
                                      setState(() => _autoBackup = value),
                                ),
                                _buildManualBackupTile(),
                                _buildBackupImportTile(),
                              ],
                            ),

                            SizedBox(height: 2.h),

                            // Notifications
                            SettingsSectionWidget(
                              title: 'Notification Settings',
                              icon: 'notifications',
                              children: [
                                _buildSwitchTile(
                                  'Reminder Alerts',
                                  'Get notified about note reminders',
                                  _reminderNotifications,
                                  (value) => setState(
                                      () => _reminderNotifications = value),
                                ),
                                _buildSwitchTile(
                                  'Sync Notifications',
                                  'Notifications when sync completes',
                                  _syncNotifications,
                                  (value) => setState(
                                      () => _syncNotifications = value),
                                ),
                                _buildSwitchTile(
                                  'Marketing Communications',
                                  'Tips, updates, and offers',
                                  _marketingNotifications,
                                  (value) => setState(
                                      () => _marketingNotifications = value),
                                ),
                              ],
                            ),

                            SizedBox(height: 2.h),

                            // Account Management
                            SettingsSectionWidget(
                              title: 'Account Management',
                              icon: 'account_circle',
                              children: [
                                _buildSubscriptionStatus(),
                                _buildActionTile(
                                  'Export Data',
                                  'Download all your notes and settings',
                                  'file_download',
                                  _exportData,
                                ),
                                _buildActionTile(
                                  'Send Feedback',
                                  'Help us improve QuickNote Pro',
                                  'feedback',
                                  _openFeedback,
                                ),
                                _buildActionTile(
                                  'Delete Account',
                                  'Permanently delete your account',
                                  'delete_forever',
                                  _deleteAccount,
                                  isDestructive: true,
                                ),
                              ],
                            ),

                            SizedBox(height: 4.h),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: ThemeMode.values.map((mode) {
                  final isSelected = themeService.themeMode == mode;
                  final displayName = themeService.getThemeModeDisplayName(mode);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => themeService.setThemeMode(mode),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: mode != ThemeMode.dark ? 2.w : 0),
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFontSizeSlider() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Font Size',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '${_fontSize.round()}sp',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          Slider(
            value: _fontSize,
            min: 12.0,
            max: 24.0,
            divisions: 12,
            onChanged: (value) => setState(() => _fontSize = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultNoteTypeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Note Type',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 1.h),
          DropdownButton<String>(
            value: _defaultNoteType,
            isExpanded: true,
            items: ['Text', 'Voice', 'Drawing', 'Template'].map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) => setState(() => _defaultNoteType = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'cloud_done',
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cloud Storage',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${_userProfile['storageUsed']} MB of ${_userProfile['storageLimit']} MB used',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 15.w,
            height: 1.h,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor:
                  _userProfile['storageUsed'] / _userProfile['storageLimit'],
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildManualBackupTile() {
    return GestureDetector(
      onTap: _manualBackup,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'backup',
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual Backup',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Backup now',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatus() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: (_userProfile['isPremium']
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: _userProfile['isPremium'] ? 'star' : 'person',
              color: _userProfile['isPremium']
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile['isPremium'] ? 'Premium Member' : 'Free Account',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  _userProfile['isPremium']
                      ? 'All features unlocked'
                      : 'Upgrade to unlock premium features',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!_userProfile['isPremium'])
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              ),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    String icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupImportTile() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.backupImport),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'folder_copy',
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup & Import',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Export notes or import from backup files',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
