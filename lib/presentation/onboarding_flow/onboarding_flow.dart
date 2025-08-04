import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import './widgets/navigation_buttons_widget.dart';
import './widgets/onboarding_page_widget.dart';
import './widgets/page_indicator_widget.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Mock onboarding data
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "imageUrl":
          "https://images.unsplash.com/photo-1586281380349-632531db7ed4?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "title": "Create Rich Text Notes",
      "description":
          "Write beautiful notes with Markdown support. Add headings, lists, and formatting to organize your thoughts perfectly.",
    },
    {
      "imageUrl":
          "https://images.pexels.com/photos/6913393/pexels-photo-6913393.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "title": "Voice to Text Magic",
      "description":
          "Transform your voice into text instantly. Perfect for capturing ideas on the go when typing isn't convenient.",
    },
    {
      "imageUrl":
          "https://cdn.pixabay.com/photo/2017/09/07/08/54/money-2724241_1280.jpg",
      "title": "Draw & Sketch Ideas",
      "description":
          "Express creativity with powerful drawing tools. Sketch diagrams, doodle ideas, or create visual notes with your finger.",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Haptic feedback on iOS
    HapticFeedback.lightImpact();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    Navigator.pushReplacementNamed(context, '/notes-dashboard');
  }

  void _getStarted() {
    Navigator.pushReplacementNamed(context, '/note-creation-editor');
  }

  void _startFreeTrial() {
    // Navigate to premium signup flow
    Navigator.pushReplacementNamed(context, '/notes-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with skip button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Empty space for balance
                  SizedBox(width: 20.w),

                  // Page indicator
                  PageIndicatorWidget(
                    currentPage: _currentPage,
                    totalPages: _onboardingData.length,
                  ),

                  // Skip button
                  TextButton(
                    onPressed: _skipOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    ),
                    child: Text(
                      "Skip",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return OnboardingPageWidget(
                    imageUrl: data["imageUrl"] as String,
                    title: data["title"] as String,
                    description: data["description"] as String,
                    isLastPage: index == _onboardingData.length - 1,
                  );
                },
              ),
            ),

            // Navigation buttons
            NavigationButtonsWidget(
              currentPage: _currentPage,
              totalPages: _onboardingData.length,
              onNext: _nextPage,
              onGetStarted: _getStarted,
              onStartTrial: _startFreeTrial,
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
