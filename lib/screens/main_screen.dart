import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'home_tab.dart';
import 'library_tab.dart';
import 'smriti_trainer_tab.dart';
import 'bookmarks_tab.dart';
import 'settings_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final currentIndex = appState.currentTab;

        final tabs = [
          HomeTab(onNavigateTab: (index) => appState.setCurrentTab(index)),
          const LibraryTab(),
          const SmritiTrainerTab(),
          const BookmarksTab(),
          const SettingsTab(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: tabs,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => appState.setCurrentTab(index),
            selectedItemColor: AppColors.primaryGold,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology_outlined),
                activeIcon: Icon(Icons.psychology),
                label: 'Trainer',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_border),
                activeIcon: Icon(Icons.bookmark),
                label: 'Bookmarks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
