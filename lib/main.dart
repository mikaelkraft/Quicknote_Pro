import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final themeService = ThemeService();
  await themeService.init();
  
  final iapService = IAPService();
  // IAP will be initialized when first accessed
  
  // Initialize sync provider registry
  final providerRegistry = ProviderRegistry();
  providerRegistry.initialize();
  
  // Initialize notes service
  final notesService = NotesService();
  notesService.initialize();

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
      iapService: iapService,
      providerRegistry: providerRegistry,
      notesService: notesService,
    ));
  });
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;
  final IAPService iapService;
  final ProviderRegistry providerRegistry;
  final NotesService notesService;
  
  const MyApp({
    Key? key,
    required this.themeService,
    required this.iapService,
    required this.providerRegistry,
    required this.notesService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: iapService),
        ChangeNotifierProvider.value(value: notesService),
        Provider.value(value: providerRegistry),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Sizer(builder: (context, orientation, screenType) {
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
          });
        },
      ),
    );
  }
}
