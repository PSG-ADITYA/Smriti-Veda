import 'package:flutter/material.dart';
import 'providers/app_state.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() {
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
          return MaterialApp(
            title: 'Smriti Veda - Sacred Scriptures & Chanting Companion',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _appState.themeMode,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
