import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import '../services/local/hive_initializer.dart';
import '../services/local/note_repository.dart';
import '../services/premium/premium_service.dart';
import '../services/sync/sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before running the app
  try {
    await HiveInitializer.init();
    print('✅ Hive initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Hive: $e');
    // Continue with app launch even if Hive fails (graceful degradation)
  }

  // Initialize services
  try {
    final noteRepository = NoteRepository();
    noteRepository.init();
    
    final premiumService = PremiumService();
    premiumService.init();
    
    final syncManager = SyncManager();
    syncManager.init();
    
    print('✅ Services initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize services: $e');
  }

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(
      errorDetails: details,
    );
  };
  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'quicknote_pro',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        // 🚨 END CRITICAL SECTION
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.initial,
      );
    });
  }
}
