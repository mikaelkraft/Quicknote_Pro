import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/animated_logo_widget.dart';
import './widgets/brand_gradient_widget.dart';
import './widgets/loading_indicator_widget.dart';
import './widgets/retry_connection_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  bool _showRetry = false;
  String _loadingText = 'Initializing QuickNote Pro...';
  Timer? _timeoutTimer;
  Timer? _loadingTextTimer;

  // Mock user data for demonstration
  final Map<String, dynamic> _mockUserData = {
    "isFirstTime": false,
    "isAuthenticated": true,
    "userId": "user_12345",
    "preferences": {
      "theme": "auto",
      "autoBackup": true,
      "reminderEnabled": true,
    },
    "cachedNotes": [
      {
        "id": "note_001",
        "title": "Meeting Notes",
        "content": "Discuss project timeline and deliverables",
        "folder": "Work",
        "lastModified": "2025-07-29T10:30:00Z",
      },
      {
        "id": "note_002",
        "title": "Shopping List",
        "content": "Milk, Bread, Eggs, Coffee",
        "folder": "Personal",
        "lastModified": "2025-07-29T09:15:00Z",
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _setSystemUIOverlay();
    _startInitialization();
  }

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _startInitialization() {
    _startLoadingTextAnimation();
    _startTimeoutTimer();
    _performInitializationTasks();
  }

  void _startLoadingTextAnimation() {
    final loadingMessages = [
      'Initializing QuickNote Pro...',
      'Loading your notes...',
      'Preparing workspace...',
      'Almost ready...',
    ];

    int messageIndex = 0;
    _loadingTextTimer =
        Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted && _isLoading && !_showRetry) {
        setState(() {
          _loadingText = loadingMessages[messageIndex % loadingMessages.length];
          messageIndex++;
        });
      }
    });
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() {
          _showRetry = true;
          _isLoading = false;
        });
        _loadingTextTimer?.cancel();
      }
    });
  }

  Future<void> _performInitializationTasks() async {
    try {
      // Simulate checking authentication status
      await Future.delayed(const Duration(milliseconds: 800));
      final isAuthenticated = _mockUserData['isAuthenticated'] as bool;

      // Simulate loading user preferences
      await Future.delayed(const Duration(milliseconds: 600));
      final preferences = _mockUserData['preferences'] as Map<String, dynamic>;

      // Simulate fetching essential config data
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate preparing cached notes for offline access
      await Future.delayed(const Duration(milliseconds: 700));
      final cachedNotes = _mockUserData['cachedNotes'] as List;

      // Check if initialization completed within timeout
      if (mounted && !_showRetry) {
        _timeoutTimer?.cancel();
        _loadingTextTimer?.cancel();

        // Determine navigation path
        final isFirstTime = _mockUserData['isFirstTime'] as bool;

        if (isFirstTime) {
          _navigateToOnboarding();
        } else {
          _navigateToMainDashboard();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showRetry = true;
          _isLoading = false;
        });
        _loadingTextTimer?.cancel();
      }
    }
  }

  void _navigateToOnboarding() {
    Navigator.pushReplacementNamed(context, '/onboarding-flow');
  }

  void _navigateToMainDashboard() {
    Navigator.pushReplacementNamed(context, '/notes-dashboard');
  }

  void _retryInitialization() {
    setState(() {
      _isLoading = true;
      _showRetry = false;
      _loadingText = 'Retrying connection...';
    });
    _startInitialization();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _loadingTextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BrandGradientWidget(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _showRetry ? _buildRetryView() : _buildLoadingView(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(),
        ),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedLogoWidget(
                onAnimationComplete: () {
                  // Logo animation completed
                },
              ),
              SizedBox(height: 6.h),
              Text(
                'QuickNote Pro',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Capture ideas seamlessly',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingIndicatorWidget(
                loadingText: _loadingText,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRetryView() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Container(),
        ),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedLogoWidget(),
              SizedBox(height: 4.h),
              Text(
                'QuickNote Pro',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: RetryConnectionWidget(
            onRetry: _retryInitialization,
            message:
                'Unable to initialize the app. Please check your connection and try again.',
          ),
        ),
      ],
    );
  }
}
