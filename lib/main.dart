import 'package:flutter/material.dart';
import 'providers/app_state.dart';
import 'screens/main_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'theme/app_theme.dart';
import 'widgets/confetti_overlay.dart';
import 'widgets/smritiveda_splash_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbService().init();
  await AuthService().init();
  runApp(const SmritiVedaApp());
}

class SmritiVedaApp extends StatefulWidget {
  const SmritiVedaApp({super.key});

  @override
  State<SmritiVedaApp> createState() => _SmritiVedaAppState();
}

class _SmritiVedaAppState extends State<SmritiVedaApp> {
  final AppState _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          Widget initialScreen;
          if (_appState.isLoggedIn) {
            initialScreen = const MainScreen();
          } else {
            initialScreen = const WelcomeScreen();
          }

          return MaterialApp(
            title: 'SmritiVeda - AI Cognitive Memory Platform',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _appState.themeMode,
            home: ConfettiOverlay(
              child: SmritiVedaSplashOverlay(
                child: initialScreen,
              ),
            ),
          );
        },
      ),
    );
  }
}
