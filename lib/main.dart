import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import '../services/sync/sync_manager.dart';
import '../services/notes/notes_service.dart';
import '../services/widget/home_screen_widget_service.dart';
import '../repositories/notes_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();

  // Initialize sync manager
  final syncManager = SyncManager();
  await syncManager.initialize();

  // Initialize notes service
  final notesRepository = NotesRepository();
  final notesService = NotesService(notesRepository);
  await notesService.initialize();

  // Initialize home screen widget service
  final homeScreenWidgetService = HomeScreenWidgetService();
  await homeScreenWidgetService.initializeWidgets();

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
    runApp(MyApp(
      themeService: themeService,
      syncManager: syncManager,
      notesService: notesService,
      homeScreenWidgetService: homeScreenWidgetService,
    ));
  });
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;
  final SyncManager syncManager;
  final NotesService notesService;
  final HomeScreenWidgetService homeScreenWidgetService;

  const MyApp({
    Key? key,
    required this.themeService,
    required this.syncManager,
    required this.notesService,
    required this.homeScreenWidgetService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: syncManager),
        ChangeNotifierProvider.value(value: notesService),
        Provider.value(value: homeScreenWidgetService),
      ],
      child: Sizer(builder: (context, orientation, screenType) {
        return Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return MaterialApp(
              title: 'quicknote_pro',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeService.themeMode,
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
          },
        );
      }),
    );
  }
}
