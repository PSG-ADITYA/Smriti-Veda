import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // Theme state: 0 = Dark (Temple Obsidian), 1 = Light (Vedic Parchment)
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Authentication & Profile State
  bool _isLoggedIn = false;
  String _userName = 'Dadi Ma / Grandpa';
  String _credentialId = 'patient123';
  String _userRole = 'Patient'; // 'Patient' or 'Caregiver'
  String _selectedLanguage = 'hi'; // 'hi', 'as', 'bn', 'en'
  int _currentTab = 0;

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get credentialId => _credentialId;
  String get userRole => _userRole;
  String get selectedLanguage => _selectedLanguage;
  int get currentTab => _currentTab;

  void setCurrentTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  void login({
    required String name,
    required String credentialId,
    required String role,
    String language = 'hi',
  }) {
    _isLoggedIn = true;
    _userName = name.trim().isEmpty ? (role == 'Caregiver' ? 'Dr. Sharma (Caregiver)' : 'Senior Patient') : name.trim();
    _credentialId = credentialId.trim().isEmpty ? (role == 'Caregiver' ? 'caregiver456' : 'patient123') : credentialId.trim();
    _userRole = role;
    _selectedLanguage = language;
    _currentTab = 0; // Guarantee return to Home Tab on login
    notifyListeners();
  }

  void switchRole() {
    if (_userRole == 'Patient') {
      _userRole = 'Caregiver';
      if (_userName == 'Senior Patient' || _userName == 'Dadi Ma / Grandpa') {
        _userName = 'Dr. Sharma (Caregiver)';
      }
    } else {
      _userRole = 'Patient';
      if (_userName == 'Dr. Sharma (Caregiver)') {
        _userName = 'Dadi Ma / Grandpa';
      }
    }
    _currentTab = 0; // Return to Home Tab when switching role
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _currentTab = 0;
    notifyListeners();
  }

  // Font scale multiplier (1.0 to 1.8)
  double _fontScale = 1.2;
  double get fontScale => _fontScale;

  void setFontScale(double value) {
    _fontScale = value.clamp(0.9, 2.0);
    notifyListeners();
  }

  // Display toggles
  bool _showDevanagari = true;
  bool _showTransliteration = true;
  bool _showTranslation = true;

  bool get showDevanagari => _showDevanagari;
  bool get showTransliteration => _showTransliteration;
  bool get showTranslation => _showTranslation;

  void toggleDevanagari() {
    _showDevanagari = !_showDevanagari;
    notifyListeners();
  }

  void toggleTransliteration() {
    _showTransliteration = !_showTransliteration;
    notifyListeners();
  }

  void toggleTranslation() {
    _showTranslation = !_showTranslation;
    notifyListeners();
  }

  // Bookmarks
  final Set<String> _bookmarkedVerseIds = {'gm_v1', 'bg247_v1'};
  Set<String> get bookmarkedVerseIds => _bookmarkedVerseIds;

  bool isBookmarked(String verseId) => _bookmarkedVerseIds.contains(verseId);

  void toggleBookmark(String verseId) {
    if (_bookmarkedVerseIds.contains(verseId)) {
      _bookmarkedVerseIds.remove(verseId);
    } else {
      _bookmarkedVerseIds.add(verseId);
    }
    notifyListeners();
  }

  // Daily Streak & Mastery
  final int _dailyStreak = 5;
  int get dailyStreak => _dailyStreak;

  int _versesMastered = 14;
  int get versesMastered => _versesMastered;

  void incrementMastery() {
    _versesMastered++;
    notifyListeners();
  }

  // Audio Recitation Simulation State
  String? _currentlyPlayingVerseId;
  bool _isPlayingAudio = false;

  String? get currentlyPlayingVerseId => _currentlyPlayingVerseId;
  bool get isPlayingAudio => _isPlayingAudio;

  void playVerseAudio(String verseId) {
    if (_currentlyPlayingVerseId == verseId && _isPlayingAudio) {
      _isPlayingAudio = false;
    } else {
      _currentlyPlayingVerseId = verseId;
      _isPlayingAudio = true;
    }
    notifyListeners();
  }

  void stopAudio() {
    _isPlayingAudio = false;
    _currentlyPlayingVerseId = null;
    notifyListeners();
  }

  // User Notes on Verses
  final Map<String, String> _verseNotes = {
    'gm_v1': 'Chant 108 times at dawn facing East.',
    'bg247_v1': 'Reflect on Nishkama Karma before starting daily work.',
  };

  Map<String, String> get verseNotes => _verseNotes;

  String getNote(String verseId) => _verseNotes[verseId] ?? '';

  void setNote(String verseId, String note) {
    if (note.trim().isEmpty) {
      _verseNotes.remove(verseId);
    } else {
      _verseNotes[verseId] = note.trim();
    }
    notifyListeners();
  }
}

class AppStateScope extends InheritedWidget {
  final AppState state;

  const AppStateScope({
    super.key,
    required this.state,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.state;
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) => true;
}
