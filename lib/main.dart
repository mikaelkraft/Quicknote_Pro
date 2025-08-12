import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import '../services/sync/sync_manager.dart';
import '../services/notes/notes_service.dart';
import '../services/widget/home_screen_widget_service.dart';
import '../services/note_persistence_service.dart';
import '../services/attachment_service.dart';
import '../services/pricing_tier_service.dart';
import '../services/monetization_analytics_service.dart';
import '../controllers/note_controller.dart';
import '../repositories/notes_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();

  // Initialize pricing and analytics services
  final pricingTierService = PricingTierService();
  final analyticsService = MonetizationAnalyticsService();
  await pricingTierService.initialize();
  await analyticsService.initialize();

  // Connect analytics to pricing service
  pricingTierService.setAnalyticsCallback(analyticsService.trackEvent);

  // Initialize sync manager
  final syncManager = SyncManager();
  await syncManager.initialize();

  // Initialize notes repository and services
  final notesRepository = NotesRepository();
  final notesService = NotesService(notesRepository);
  await notesService.initialize();

  // Initialize new attachment and persistence services
  final persistenceService = NotePersistenceService(notesRepository);
  final attachmentService = AttachmentService();
  await persistenceService.initialize();
  await attachmentService.initialize();

  // Initialize note controller
  final noteController = NoteController(persistenceService, attachmentService);

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
      pricingTierService: pricingTierService,
      analyticsService: analyticsService,
      syncManager: syncManager,
      notesService: notesService,
      noteController: noteController,
      homeScreenWidgetService: homeScreenWidgetService,
    ));
  });
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;
  final PricingTierService pricingTierService;
  final MonetizationAnalyticsService analyticsService;
  final SyncManager syncManager;
  final NotesService notesService;
  final NoteController noteController;
  final HomeScreenWidgetService homeScreenWidgetService;

  const MyApp({
    Key? key,
    required this.themeService,
    required this.pricingTierService,
    required this.analyticsService,
    required this.syncManager,
    required this.notesService,
    required this.noteController,
    required this.homeScreenWidgetService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: pricingTierService),
        Provider.value(value: analyticsService),
        ChangeNotifierProvider.value(value: syncManager),
        ChangeNotifierProvider.value(value: notesService),
        ChangeNotifierProvider.value(value: noteController),
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
