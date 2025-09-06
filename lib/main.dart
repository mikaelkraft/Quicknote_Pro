import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'services/sync/sync_manager.dart';
import 'services/notes/notes_service.dart';
import 'services/widget/home_screen_widget_service.dart';
import 'services/note_persistence_service.dart';
import 'services/attachment_service.dart';
import 'controllers/note_controller.dart';
import 'repositories/notes_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();

  // Initialize sync manager
  final syncManager = SyncManager();
  await syncManager.initialize();

  // Initialize notes repository and services
  final notesRepository = NotesRepository();
  final notesService = NotesService(notesRepository);
  await notesService.initialize();

  // Initialize monetization services
  final analyticsService = AnalyticsService();
  await analyticsService.initialize();
  
  final adsService = AdsService();
  await adsService.initialize();
  
  final monetizationService = MonetizationService();
  await monetizationService.initialize();

  // Connect ads service to monetization status
  adsService.setPremiumStatus(monetizationService.isPremium);
  
  // Listen for tier changes to update ads status
  monetizationService.addListener(() {
    adsService.setPremiumStatus(monetizationService.isPremium);
  });

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
      syncManager: syncManager,
      notesService: notesService,
      noteController: noteController,
      homeScreenWidgetService: homeScreenWidgetService,
      analyticsService: analyticsService,
      adsService: adsService,
      monetizationService: monetizationService,
    ));
  });
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;
  final SyncManager syncManager;
  final NotesService notesService;
  final NoteController noteController;
  final HomeScreenWidgetService homeScreenWidgetService;
  final AnalyticsService analyticsService;
  final AdsService adsService;
  final MonetizationService monetizationService;

  const MyApp({
    Key? key,
    required this.themeService,
    required this.syncManager,
    required this.notesService,
    required this.noteController,
    required this.homeScreenWidgetService,
    required this.analyticsService,
    required this.adsService,
    required this.monetizationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: syncManager),
        ChangeNotifierProvider.value(value: notesService),
        ChangeNotifierProvider.value(value: noteController),
        ChangeNotifierProvider.value(value: analyticsService),
        ChangeNotifierProvider.value(value: adsService),
        ChangeNotifierProvider.value(value: monetizationService),
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
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
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
