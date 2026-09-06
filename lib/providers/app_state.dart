import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/everyday_memory.dart';
import '../models/exercise_attempt.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/exercise_attempt_repository.dart';
import '../repositories/local_exercise_attempt_repository.dart';
import '../repositories/patient_file_repository.dart';
import '../services/db_service.dart';

class AppUser {
  final String id;
  final String name;
  final bool isCaregiver;

  const AppUser({required this.id, required this.name, required this.isCaregiver});
}

class AppState extends ChangeNotifier {
  // Repositories Architecture
  final ExerciseAttemptRepository attemptRepository = LocalExerciseAttemptRepository();
  final AppointmentRepository appointmentRepository = LocalAppointmentRepository();
  final PatientFileRepository patientFileRepository = LocalPatientFileRepository();
  final CulturalContentRepository culturalContentRepository = LocalCulturalContentRepository();

  ExerciseAttemptRepository get attemptRepo => attemptRepository;
  AppointmentRepository get appointmentRepo => appointmentRepository;
  PatientFileRepository get patientFileRepo => patientFileRepository;
  CulturalContentRepository get culturalContentRepo => culturalContentRepository;

  void logAttempt(ExerciseAttempt attempt) {
    attemptRepository.logAttempt(attempt);
    notifyListeners();
  }

  // Theme state: default Light (Warm Canvas Ivory)
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Authentication & Profile State
  bool _isLoggedIn = false;
  String _userName = '';
  String _credentialId = '';
  String _userRole = 'Patient'; // 'Patient' or 'Caregiver'
  String _selectedLanguage = 'en'; // default English
  int? _userAge;
  String? _emergencyContact;
  String? _medicalNotes;
  int _currentTab = 0;

  // Profile Avatar & Customization State
  String _profileAvatarEmoji = '👴';
  Uint8List? _customProfileImageBytes;
  String _cognitiveGoalPref = 'Auditory Recitation & Memory Retention';
  bool _soundFeedbackEnabled = true;

  // In-memory collections synced with DbService
  final List<EverydayReminder> _reminders = [];
  final List<RoutineStep> _routineSteps = [];
  final List<FamiliarPerson> _familiarPeople = [];

  AppState() {
    _restoreSession();
  }

  void _restoreSession() {
    final activeUid = DbService().activeUserId;
    if (activeUid.isNotEmpty) {
      final profile = DbService().getUserProfile(activeUid);
      if (profile != null) {
        _isLoggedIn = true;
        _userName = profile['name'] as String? ?? 'Patient';
        _credentialId = profile['credentialId'] as String? ?? activeUid;
        _userRole = profile['role'] as String? ?? 'Patient';
        _selectedLanguage = profile['language'] as String? ?? 'en';
        _userAge = profile['age'] as int?;
        _emergencyContact = profile['emergencyContact'] as String?;
        _medicalNotes = profile['medicalNotes'] as String?;
      }
    }
    _reloadUserData();
  }

  void _reloadUserData() {
    final db = DbService();
    _reminders.clear();
    _reminders.addAll(db.getReminders());

    _familiarPeople.clear();
    _familiarPeople.addAll(db.getFamiliarPeople());

    // If demo mode is active and routine steps are empty, initialize demo routine
    _routineSteps.clear();
    if (db.isDemoModeActive) {
      _routineSteps.addAll([
        RoutineStep(
          id: 'demo_step_1',
          stepNumber: 1,
          title: 'Morning Sun Salutation & Breathing',
          description: 'Gentle stretching and deep breathing exercises',
          targetTime: '7:00 AM',
          icon: Icons.wb_sunny_outlined,
          isCompleted: true,
        ),
        RoutineStep(
          id: 'demo_step_2',
          stepNumber: 2,
          title: 'Morning Herbal Tea & Breakfast',
          description: 'Warm ginger tea and nutritional breakfast',
          targetTime: '8:00 AM',
          icon: Icons.coffee_outlined,
          isCompleted: false,
        ),
      ]);
    }
  }

  String get profileAvatarEmoji => _profileAvatarEmoji;
  Uint8List? get customProfileImageBytes => _customProfileImageBytes;
  String get cognitiveGoalPref => _cognitiveGoalPref;
  bool get soundFeedbackEnabled => _soundFeedbackEnabled;

  void setProfileAvatarEmoji(String emoji) {
    _profileAvatarEmoji = emoji;
    _customProfileImageBytes = null;
    notifyListeners();
  }

  void setCustomProfileImageBytes(Uint8List? bytes) {
    _customProfileImageBytes = bytes;
    notifyListeners();
  }

  void setCognitiveGoalPref(String goal) {
    _cognitiveGoalPref = goal;
    notifyListeners();
  }

  void toggleSoundFeedback() {
    _soundFeedbackEnabled = !_soundFeedbackEnabled;
    notifyListeners();
  }

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName.isEmpty ? (_userRole == 'Caregiver' ? 'Caregiver' : 'Patient') : _userName;
  String get credentialId => _credentialId;
  String get userRole => _userRole;
  String get selectedLanguage => _selectedLanguage;
  int? get userAge => _userAge;
  String? get emergencyContact => _emergencyContact;
  String? get medicalNotes => _medicalNotes;
  int get currentTab => _currentTab;

  AppUser get activeUser => AppUser(
        id: _credentialId,
        name: userName,
        isCaregiver: _userRole == 'Caregiver',
      );

  bool get isCaregiverMode => _userRole == 'Caregiver';

  void setCaregiverMode(bool value) {
    if (value != (_userRole == 'Caregiver')) {
      switchRole();
    }
  }

  void setCurrentTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  void login({
    required String name,
    required String credentialId,
    required String role,
    String language = 'en',
    int? age,
    String? emergencyContact,
    String? medicalNotes,
  }) {
    _isLoggedIn = true;
    _credentialId = credentialId.trim().isEmpty ? (role == 'Caregiver' ? 'caregiver456' : 'patient123') : credentialId.trim();

    final db = DbService();
    db.setActiveUserId(_credentialId);
    final existingProfile = db.getUserProfile(_credentialId);

    _userName = name.trim().isNotEmpty
        ? name.trim()
        : (existingProfile?['name'] != null && existingProfile!['name'].toString().trim().isNotEmpty
            ? existingProfile['name'].toString().trim()
            : (role == 'Caregiver' ? 'Dr. Sharma (Caregiver)' : 'Senior Patient'));

    _userRole = role.trim().isNotEmpty
        ? role.trim()
        : (existingProfile?['role']?.toString().trim() ?? 'Patient');

    _selectedLanguage = language.trim().isNotEmpty
        ? language.trim()
        : (existingProfile?['language']?.toString().trim() ?? 'en');

    _userAge = age ?? (existingProfile?['age'] as int?);
    _emergencyContact = emergencyContact ?? (existingProfile?['emergencyContact'] as String?);
    _medicalNotes = medicalNotes ?? (existingProfile?['medicalNotes'] as String?);
    _currentTab = 0; // Return to Home Tab on login

    db.saveUserProfile(
      name: _userName,
      role: _userRole,
      credentialId: _credentialId,
      language: _selectedLanguage,
      age: _userAge,
      emergencyContact: _emergencyContact,
      medicalNotes: _medicalNotes,
      userId: _credentialId,
    );
    _reloadUserData();
    notifyListeners();
  }

  void updateProfile({
    String? name,
    int? age,
    String? emergencyContact,
    String? medicalNotes,
    String? language,
  }) {
    if (name != null) _userName = name.trim();
    if (age != null) _userAge = age;
    if (emergencyContact != null) _emergencyContact = emergencyContact.trim();
    if (medicalNotes != null) _medicalNotes = medicalNotes.trim();
    if (language != null) _selectedLanguage = language;

    if (_credentialId.isNotEmpty) {
      DbService().saveUserProfile(
        name: _userName,
        role: _userRole,
        credentialId: _credentialId,
        language: _selectedLanguage,
        age: _userAge,
        emergencyContact: _emergencyContact,
        medicalNotes: _medicalNotes,
        userId: _credentialId,
      );
    }
    notifyListeners();
  }

  void switchRole() {
    if (_userRole == 'Patient') {
      _userRole = 'Caregiver';
      if (_userName == 'Senior Patient' || _userName == 'Patient') {
        _userName = 'Dr. Sharma (Caregiver)';
      }
    } else {
      _userRole = 'Patient';
      if (_userName == 'Dr. Sharma (Caregiver)') {
        _userName = 'Senior Patient';
      }
    }
    _currentTab = 0;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _currentTab = 0;
    DbService().clearActiveSession();
    _userName = '';
    _credentialId = '';
    _userRole = 'Patient';
    _userAge = null;
    _emergencyContact = null;
    _medicalNotes = null;
    _aiPersonalPlanText = null;
    _reminders.clear();
    _familiarPeople.clear();
    _routineSteps.clear();
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
  final Set<String> _bookmarkedVerseIds = {};
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

  // Daily Streak & Mastery — Calculated from authentic ExerciseAttempt history
  int get dailyStreak {
    final attempts = attemptRepository.getAttempts();
    if (attempts.isEmpty) return 0;
    final dates = attempts.map((a) => DateTime(a.timestamp.year, a.timestamp.month, a.timestamp.day)).toSet().toList();
    dates.sort((a, b) => b.compareTo(a));

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (!dates.contains(today) && !dates.contains(today.subtract(const Duration(days: 1)))) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = dates.contains(today) ? today : today.subtract(const Duration(days: 1));
    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get versesMastered {
    final attempts = attemptRepository.getAttempts();
    return attempts.where((a) => a.exerciseId == 'verse_mastery' || (a.maxScore > 0 && a.rawScore >= a.maxScore)).length;
  }

  void incrementMastery() {
    attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_${DateTime.now().millisecondsSinceEpoch}',
        userId: credentialId,
        domain: ExerciseDomain.culturalOral,
        type: ExerciseType.structuredRecallPipeline,
        exerciseId: 'verse_mastery',
        responseMode: 'voice',
        rawScore: 100.0,
        maxScore: 100.0,
      ),
    );
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
  final Map<String, String> _verseNotes = {};

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

  // ==========================================
  // EVERYDAY MEMORY ASSISTANT STATE
  // ==========================================

  // 1. Things to Remember (Reminders)
  List<EverydayReminder> get reminders => List.unmodifiable(_reminders);
  List<EverydayReminder> get todayReminders => _reminders.where((r) => r.isToday).toList();
  List<EverydayReminder> get upcomingReminders => _reminders.where((r) => !r.isToday).toList();

  void addReminder(EverydayReminder reminder) {
    _reminders.add(reminder);
    DbService().saveReminder(reminder);
    notifyListeners();
  }

  void updateReminder(EverydayReminder updated) {
    final index = _reminders.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _reminders[index] = updated;
      DbService().saveReminder(updated);
      notifyListeners();
    }
  }

  void deleteReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    DbService().deleteReminder(id);
    notifyListeners();
  }

  void toggleReminderComplete(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final newStatus = !_reminders[index].isCompleted;
      _reminders[index] = _reminders[index].copyWith(
        isCompleted: newStatus,
      );
      DbService().saveReminder(_reminders[index]);
      if (newStatus) {
        attemptRepository.logAttempt(
          ExerciseAttempt(
            id: 'att_rem_${DateTime.now().millisecondsSinceEpoch}',
            userId: credentialId,
            domain: ExerciseDomain.everydayMemory,
            type: ExerciseType.reminderCheck,
            exerciseId: id,
            responseMode: 'action',
            rawScore: 1.0,
            maxScore: 1.0,
            metadata: {'title': _reminders[index].title},
          ),
        );
      }
      notifyListeners();
    }
  }

  // 2. Routine Memory
  List<RoutineStep> get routineSteps => List.unmodifiable(_routineSteps);

  void addRoutineStep(RoutineStep step) {
    _routineSteps.add(step);
    notifyListeners();
  }

  void updateRoutineStep(RoutineStep updated) {
    final index = _routineSteps.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _routineSteps[index] = updated;
      notifyListeners();
    }
  }

  void deleteRoutineStep(String id) {
    _routineSteps.removeWhere((s) => s.id == id);
    for (int i = 0; i < _routineSteps.length; i++) {
      _routineSteps[i] = _routineSteps[i].copyWith(stepNumber: i + 1);
    }
    notifyListeners();
  }

  void toggleStepComplete(String id) {
    final index = _routineSteps.indexWhere((s) => s.id == id);
    if (index != -1) {
      final newStatus = !_routineSteps[index].isCompleted;
      _routineSteps[index] = _routineSteps[index].copyWith(
        isCompleted: newStatus,
      );
      if (newStatus) {
        attemptRepository.logAttempt(
          ExerciseAttempt(
            id: 'att_step_${DateTime.now().millisecondsSinceEpoch}',
            userId: credentialId,
            domain: ExerciseDomain.everydayMemory,
            type: ExerciseType.routineStepCheck,
            exerciseId: id,
            responseMode: 'action',
            rawScore: 1.0,
            maxScore: 1.0,
            metadata: {'stepTitle': _routineSteps[index].title},
          ),
        );
      }
      notifyListeners();
    }
  }

  // 3. Parichay / Familiar People
  List<FamiliarPerson> get familiarPeople => List.unmodifiable(_familiarPeople);

  void addFamiliarPerson(FamiliarPerson person) {
    _familiarPeople.add(person);
    DbService().saveFamiliarPerson(person);
    notifyListeners();
  }

  void deleteFamiliarPerson(String id) {
    _familiarPeople.removeWhere((p) => p.id == id);
    DbService().deleteFamiliarPerson(id);
    notifyListeners();
  }

  // 4. Parichay Recall Game Score
  int _lastRecallScore = 0;
  int get lastRecallScore => _lastRecallScore;

  void recordRecallScore(int score) {
    _lastRecallScore = score;
    attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_recall_${DateTime.now().millisecondsSinceEpoch}',
        userId: credentialId,
        domain: ExerciseDomain.everydayMemory,
        type: ExerciseType.familiarPersonRecall,
        exerciseId: 'people_recall_game',
        responseMode: 'choice',
        rawScore: score.toDouble(),
        maxScore: (_familiarPeople.isEmpty ? 1 : _familiarPeople.length * 10).toDouble(),
      ),
    );
    notifyListeners();
  }

  // AI Personal Plan State
  String? _aiPersonalPlanText;
  Map<String, dynamic>? _questionnaireData;
  String _geminiApiKey = '';
  bool _isAiEnabled = true;

  String? get aiPersonalPlanText => _aiPersonalPlanText;
  Map<String, dynamic>? get questionnaireData => _questionnaireData;
  String get geminiApiKey => _geminiApiKey;
  bool get isAiEnabled => _isAiEnabled;

  void setAiPersonalPlan(String planText, Map<String, dynamic> data) {
    _aiPersonalPlanText = planText;
    _questionnaireData = data;
    notifyListeners();
  }

  void setGeminiApiKey(String key) {
    _geminiApiKey = key.trim();
    notifyListeners();
  }

  void toggleAiEnabled(bool enabled) {
    _isAiEnabled = enabled;
    notifyListeners();
  }

  // Speech & Voice State Helpers — Honest state without fake acoustic claims
  bool _isListening = false;
  String _lastRecognizedWords = '';

  bool get isListening => _isListening;
  String get lastRecognizedWords => _lastRecognizedWords;

  void speak(String text, {String languageCode = 'en'}) {
    debugPrint('Reading aloud ($languageCode): $text');
  }

  Future<void> startListening({String? simulatedInputText}) async {
    _isListening = true;
    _lastRecognizedWords = simulatedInputText ?? '';
    notifyListeners();
  }

  void setRecognizedWords(String text) {
    _lastRecognizedWords = text;
    notifyListeners();
  }

  void stopListening() {
    _isListening = false;
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
