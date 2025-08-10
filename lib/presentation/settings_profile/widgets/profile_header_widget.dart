import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final VoidCallback onEditAvatar;
  final VoidCallback onEditName;

  const ProfileHeaderWidget({
    Key? key,
    required this.userProfile,
    required this.onEditAvatar,
    required this.onEditName,
  }) : super(key: key);

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppTheme.surfaceDark.withOpacity(0.8),
                  AppTheme.primaryDark.withOpacity(0.1),
                ]
              : [
                  AppTheme.surfaceLight.withOpacity(0.8),
                  AppTheme.primaryLight.withOpacity(0.1),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
              .withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Shimmer effect
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Positioned(
                  left: _shimmerAnimation.value * 100.w,
                  top: 0,
                  child: Container(
                    width: 30.w,
                    height: 100.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Content
            Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: widget.onEditAvatar,
                      child: Stack(
                        children: [
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  isDark
                                      ? AppTheme.primaryDark
                                      : AppTheme.primaryLight,
                                  isDark
                                      ? AppTheme.accentDark
                                      : AppTheme.accentLight,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                          ? AppTheme.primaryDark
                                          : AppTheme.primaryLight)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(0.5.w),
                              child: ClipOval(
                                child: widget.userProfile['avatar'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: widget.userProfile['avatar'],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: isDark
                                              ? AppTheme.surfaceDark
                                              : AppTheme.surfaceLight,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                isDark
                                                    ? AppTheme.primaryDark
                                                    : AppTheme.primaryLight,
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: isDark
                                              ? AppTheme.surfaceDark
                                              : AppTheme.surfaceLight,
                                          child: CustomIconWidget(
                                            iconName: 'person',
                                            color: isDark
                                                ? AppTheme.textSecondaryDark
                                                : AppTheme.textSecondaryLight,
                                            size: 10.w,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: isDark
                                            ? AppTheme.surfaceDark
                                            : AppTheme.surfaceLight,
                                        child: CustomIconWidget(
                                          iconName: 'person',
                                          color: isDark
                                              ? AppTheme.textSecondaryDark
                                              : AppTheme.textSecondaryLight,
                                          size: 10.w,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(1.w),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.primaryDark
                                    : AppTheme.primaryLight,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? AppTheme.shadowDark
                                        : AppTheme.shadowLight,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CustomIconWidget(
                                iconName: 'edit',
                                color: Colors.white,
                                size: 3.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 4.w),

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: widget.onEditName,
                                  child: Text(
                                    widget.userProfile['name'] ?? 'User',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                              if (widget.userProfile['isPremium'])
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                    vertical: 0.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        isDark
                                            ? AppTheme.warningDark
                                            : AppTheme.warningLight,
                                        (isDark
                                                ? AppTheme.warningDark
                                                : AppTheme.warningLight)
                                            .withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomIconWidget(
                                        iconName: 'star',
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      SizedBox(width: 1.w),
                                      Text(
                                        'PRO',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            widget.userProfile['email'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Statistics
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color:
                        (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight)
                            .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isDark
                              ? AppTheme.dividerDark
                              : AppTheme.dividerLight)
                          .withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Notes Created',
                          '${widget.userProfile['notesCreated']}',
                          'note',
                        ),
                      ),
                      Container(
                        height: 5.h,
                        width: 1,
                        color: isDark
                            ? AppTheme.dividerDark
                            : AppTheme.dividerLight,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Storage Used',
                          '${widget.userProfile['storageUsed']} MB',
                          'storage',
                        ),
                      ),
                      Container(
                        height: 5.h,
                        width: 1,
                        color: isDark
                            ? AppTheme.dividerDark
                            : AppTheme.dividerLight,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Member Since',
                          _formatMemberSince(widget.userProfile['joinedDate']),
                          'calendar_today',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, String icon) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
          size: 20,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatMemberSince(String? dateString) {
    if (dateString == null) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays < 30) {
        return '${difference.inDays} days';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()} months';
      } else {
        return '${(difference.inDays / 365).floor()} years';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}
