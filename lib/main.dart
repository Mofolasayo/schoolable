import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:schoolable/app/app.bottomsheets.dart';
import 'package:schoolable/app/app.dialogs.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:stacked_services/stacked_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env variables
  await dotenv.load(fileName: "assets/.env");

  await setupLocator();
  setupDialogUi();
  setupBottomSheetUi();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kcBackgroundColor,
        colorScheme: const ColorScheme.light(
          primary: kcPrimaryColor,
          onPrimary: Colors.white,
          secondary: kcPurpleColor,
          onSecondary: Colors.white,
          background: kcBackgroundColor,
          surface: kcSurfaceColor,
          error: kcRoseColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kcBackgroundColor,
          elevation: 0,
          foregroundColor: kcTextColor,
          centerTitle: false,
        ),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: kcTextColor,
              displayColor: kcTextColor,
              fontFamily:
                  'Inter', // Ensure Inter is added to pubspec if not already
            ),
        // cardTheme: CardTheme(
        //   color: kcSurfaceColor,
        //   elevation: 0,
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(16),
        //     side: const BorderSide(color: kcBorderColor, width: 1),
        //   ),
        // ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kcPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: Routes.startupView,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [StackedService.routeObserver],
    );
  }
}
