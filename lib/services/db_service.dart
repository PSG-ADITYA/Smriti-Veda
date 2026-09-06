import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/everyday_memory.dart';
import '../models/patient_info.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  SharedPreferences? _prefs;
  final Map<String, String> _memoryStorage = {};
  final Map<String, Map<String, dynamic>> _registeredUsers = {};

  String? _getPersistentItem(String key) {
    if (_prefs != null) {
      return _prefs!.getString(key);
    }
    return _memoryStorage[key];
  }

  void _setPersistentItem(String key, String value) {
    _memoryStorage[key] = value;
    _prefs?.setString(key, value);
  }

  void _removePersistentItem(String key) {
    _memoryStorage.remove(key);
    _prefs?.remove(key);
  }

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences init error: $e');
    }
    _loadRegisteredUsers();
    debugPrint('Smriti Veda DBMS Persistent Storage Service Initialized on ${kIsWeb ? "Web" : "Android/Native"}.');
  }

  // ── Active Session / Ownership ID ───────────────────────────────────────
  String get activeUserId => _getPersistentItem('active_user_uid') ?? '';
  bool get hasActiveSession => activeUserId.isNotEmpty;

  void setActiveUserId(String uid) {
    _setPersistentItem('active_user_uid', uid);
  }

  void clearActiveSession() {
    _removePersistentItem('active_user_uid');
  }

  bool get isDemoModeActive => activeUserId == 'uid_demo_sih';

  // ── Password Hashing (Never store plaintext passwords) ──────────────────
  static String _hashPassword(String password) {
    final bytes = utf8.encode('smriti_salt_2026_$password');
    int hash = 0x811c9dc5;
    for (final b in bytes) {
      hash = ((hash ^ b) * 0x01000193) & 0x7FFFFFFF;
    }
    return 'sec_${hash.toRadixString(16).padLeft(8, '0')}';
  }

  // ── User Accounts Registry ──────────────────────────────────────────────
  void _saveRegisteredUsers() {
    _setPersistentItem('registered_users_db', jsonEncode(_registeredUsers));
  }

  void _loadRegisteredUsers() {
    final str = _getPersistentItem('registered_users_db');
    if (str != null && str.isNotEmpty) {
      try {
        final decoded = jsonDecode(str);
        _registeredUsers.clear();
        if (decoded is Map) {
          decoded.forEach((key, val) {
            if (val is Map) {
              _registeredUsers[key.toString()] = Map<String, dynamic>.from(val);
            }
          });
        }
      } catch (e) {
        debugPrint('DBMS User Registry Load Error: $e');
      }
    }
  }

  bool registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String language,
    int? age,
    String? emergencyContact,
    String? medicalNotes,
  }) {
    _loadRegisteredUsers();
    final key = email.trim().toLowerCase();
    if (_registeredUsers.containsKey(key)) {
      return false; // User already exists
    }

    final uid = 'uid_${DateTime.now().millisecondsSinceEpoch}';
    final userMap = {
      'uid': uid,
      'name': name.trim(),
      'email': key,
      'passwordHash': _hashPassword(password),
      'role': role,
      'language': language,
      'createdAt': DateTime.now().toIso8601String(),
    };

    _registeredUsers[key] = userMap;
    _registeredUsers[uid] = userMap;
    _saveRegisteredUsers();

    setActiveUserId(uid);
    saveUserProfile(
      name: name.trim(),
      role: role,
      credentialId: uid,
      language: language,
      age: age ?? 0,
      emergencyContact: emergencyContact ?? '',
      medicalNotes: medicalNotes ?? '',
      userId: uid,
    );
    return true;
  }

  Map<String, dynamic>? authenticateUser(String credential, String password) {
    _loadRegisteredUsers();
    final q = credential.trim().toLowerCase();
    final hashed = _hashPassword(password);

    for (final entry in _registeredUsers.entries) {
      final user = entry.value;
      final email = (user['email'] ?? '').toString().toLowerCase();
      final uid = (user['uid'] ?? '').toString();

      if (email == q || uid == credential.trim() || entry.key == q) {
        // Check password hash or legacy password
        final storedHash = user['passwordHash'];
        final storedPlain = user['password'];

        if ((storedHash != null && storedHash == hashed) ||
            (storedPlain != null && storedPlain == password)) {
          // Auto-migrate legacy plain passwords
          if (storedPlain != null) {
            user['passwordHash'] = hashed;
            user.remove('password');
            _saveRegisteredUsers();
          }

          setActiveUserId(user['uid']);
          return {
            'uid': user['uid'],
            'name': user['name'] ?? 'User',
            'email': user['email'] ?? '',
            'role': user['role'] ?? 'Patient',
            'language': user['language'] ?? 'en',
          };
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? findUserByEmailOrPhone(String query) {
    _loadRegisteredUsers();
    final q = query.trim().toLowerCase();
    for (final entry in _registeredUsers.entries) {
      final user = entry.value;
      final email = (user['email'] ?? '').toString().toLowerCase();
      final uid = (user['uid'] ?? '').toString().toLowerCase();
      final name = (user['name'] ?? '').toString().toLowerCase();
      if (email == q || uid == q || email.contains(q) || name.contains(q)) {
        return {
          'uid': user['uid'],
          'name': user['name'],
          'email': user['email'],
          'role': user['role'],
        };
      }
    }
    return null;
  }

  // ── User Profile Persistence (Keyed per user) ───────────────────────────
  void saveUserProfile({
    required String name,
    required String role,
    required String credentialId,
    required String language,
    int? age,
    String? emergencyContact,
    String? medicalNotes,
    String? userId,
  }) {
    final targetUid = userId ?? (credentialId.isNotEmpty ? credentialId : activeUserId);
    if (targetUid.isEmpty) return;

    final profileData = {
      'name': name,
      'role': role,
      'credentialId': targetUid,
      'language': language,
      'age': age ?? 0,
      'emergencyContact': emergencyContact ?? '',
      'medicalNotes': medicalNotes ?? '',
      'updatedAt': DateTime.now().toIso8601String(),
    };
    _setPersistentItem('user_profile_$targetUid', jsonEncode(profileData));
  }

  Map<String, dynamic>? getUserProfile([String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return null;

    final str = _getPersistentItem('user_profile_$targetUid');
    if (str != null && str.isNotEmpty) {
      try {
        return jsonDecode(str) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('DBMS Profile Parse Error: $e');
      }
    }
    return null;
  }

  // ── Patient Medical Files (Keyed per user) ───────────────────────────────
  List<PatientFile> getPatientFiles([String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return [];

    final str = _getPersistentItem('patient_files_db_$targetUid');
    if (str != null && str.isNotEmpty) {
      try {
        final decoded = jsonDecode(str) as List<dynamic>;
        final List<PatientFile> list = [];
        for (final item in decoded) {
          final m = item as Map<String, dynamic>;
          Uint8List? bytes;
          if (m['base64Bytes'] != null && (m['base64Bytes'] as String).isNotEmpty) {
            try {
              bytes = base64Decode(m['base64Bytes']);
            } catch (_) {}
          }
          list.add(PatientFile(
            id: m['id'] ?? '',
            title: m['title'] ?? '',
            category: m['category'] ?? 'Medical Report',
            uploadDate: DateTime.tryParse(m['uploadDate'] ?? '') ?? DateTime.now(),
            fileType: m['fileType'] ?? 'PDF',
            notes: m['notes'] ?? '',
            localPath: m['localPath'],
            fileBytes: bytes,
            originalFileName: m['originalFileName'],
            fileSize: m['fileSize'] as int?,
          ));
        }
        return list;
      } catch (e) {
        debugPrint('DBMS Patient Files Parse Error: $e');
      }
    }
    return [];
  }

  void savePatientFile(PatientFile file, [String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return;

    final files = getPatientFiles(targetUid).toList();
    final idx = files.indexWhere((f) => f.id == file.id);
    if (idx != -1) {
      files[idx] = file;
    } else {
      files.add(file);
    }

    final serializable = files.map((f) => {
      'id': f.id,
      'title': f.title,
      'category': f.category,
      'uploadDate': f.uploadDate.toIso8601String(),
      'fileType': f.fileType,
      'notes': f.notes,
      'localPath': f.localPath,
      'originalFileName': f.originalFileName,
      'fileSize': f.fileSize,
      'base64Bytes': f.fileBytes != null ? base64Encode(f.fileBytes!) : null,
    }).toList();

    _setPersistentItem('patient_files_db_$targetUid', jsonEncode(serializable));
  }

  void deletePatientFile(String id, [String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return;

    final files = getPatientFiles(targetUid).toList();
    files.removeWhere((f) => f.id == id);

    final serializable = files.map((f) => {
      'id': f.id,
      'title': f.title,
      'category': f.category,
      'uploadDate': f.uploadDate.toIso8601String(),
      'fileType': f.fileType,
      'notes': f.notes,
      'localPath': f.localPath,
      'originalFileName': f.originalFileName,
      'fileSize': f.fileSize,
      'base64Bytes': f.fileBytes != null ? base64Encode(f.fileBytes!) : null,
    }).toList();

    _setPersistentItem('patient_files_db_$targetUid', jsonEncode(serializable));
  }

  Map<String, dynamic>? getPatientFileAsSqlRecord(String id, [String? userId]) {
    final targetUid = userId ?? activeUserId;
    final list = getPatientFiles(targetUid);
    final file = list.cast<PatientFile?>().firstWhere((f) => f?.id == id, orElse: () => null);
    if (file == null) return null;
    return {
      'fileId': file.id,
      'userId': targetUid,
      'fileName': file.title,
      'fileType': file.fileType,
      'fileSizeBytes': file.fileSize ?? 0,
      'uploadedAt': file.uploadDate.toIso8601String(),
      'category': file.category,
      'notes': file.notes,
      'storagePath': file.localPath ?? 'local_storage/medical_reports/${file.id}',
    };
  }

  // ── Appointments (Keyed per user) ───────────────────────────────────────
  List<Appointment> getAppointments([String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return [];

    final str = _getPersistentItem('appointments_db_$targetUid');
    if (str != null && str.isNotEmpty) {
      try {
        final decoded = jsonDecode(str) as List<dynamic>;
        return decoded.map((item) {
          final m = item as Map<String, dynamic>;
          final hour = m['hour'] as int? ?? 10;
          final minute = m['minute'] as int? ?? 0;
          return Appointment(
            id: m['id'] ?? '',
            title: m['title'] ?? '',
            doctorName: m['doctorName'] ?? '',
            date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
            time: TimeOfDay(hour: hour, minute: minute),
            location: m['location'] ?? '',
            notes: m['notes'] ?? '',
            reminderEnabled: m['reminderEnabled'] ?? true,
          );
        }).toList();
      } catch (e) {
        debugPrint('DBMS Appointments Parse Error: $e');
      }
    }
    return [];
  }

  void saveAppointment(Appointment appointment, [String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return;

    final list = getAppointments(targetUid).toList();
    final idx = list.indexWhere((a) => a.id == appointment.id);
    if (idx != -1) {
      list[idx] = appointment;
    } else {
      list.add(appointment);
    }

    final serializable = list.map((a) => {
      'id': a.id,
      'title': a.title,
      'doctorName': a.doctorName,
      'date': a.date.toIso8601String(),
      'hour': a.time.hour,
      'minute': a.time.minute,
      'location': a.location,
      'notes': a.notes,
      'reminderEnabled': a.reminderEnabled,
    }).toList();

    _setPersistentItem('appointments_db_$targetUid', jsonEncode(serializable));
  }

  void deleteAppointment(String id, [String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return;

    final list = getAppointments(targetUid).toList();
    list.removeWhere((a) => a.id == id);

    final serializable = list.map((a) => {
      'id': a.id,
      'title': a.title,
      'doctorName': a.doctorName,
      'date': a.date.toIso8601String(),
      'hour': a.time.hour,
      'minute': a.time.minute,
      'location': a.location,
      'notes': a.notes,
      'reminderEnabled': a.reminderEnabled,
    }).toList();

    _setPersistentItem('appointments_db_$targetUid', jsonEncode(serializable));
  }

  // ── Everyday Reminders (Keyed per user) ──────────────────────────────────
  List<EverydayReminder> getReminders([String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return [];

    final str = _getPersistentItem('reminders_db_$targetUid');
    if (str != null && str.isNotEmpty) {
      try {
        final decoded = jsonDecode(str) as List<dynamic>;
        return decoded.map((item) {
          final m = item as Map<String, dynamic>;
          final hour = m['hour'] as int? ?? 10;
          final minute = m['minute'] as int? ?? 0;
          return EverydayReminder(
            id: m['id'] ?? '',
            title: m['title'] ?? '',
            description: m['description'] ?? '',
            date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
            time: TimeOfDay(hour: hour, minute: minute),
            category: m['category'] ?? ReminderCategory.routine,
            isCompleted: m['isCompleted'] ?? false,
          );
        }).toList();
      } catch (e) {
        debugPrint('DBMS Reminders Parse Error: $e');
      }
    }
    return [];
  }

  void saveReminder(EverydayReminder reminder, [String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return;

    final list = getReminders(targetUid).toList();
    final idx = list.indexWhere((r) => r.id == reminder.id);
    if (idx != -1) {
      list[idx] = reminder;
    } else {
      list.add(reminder);
    }

    final serializable = list.map((r) => {
      'id': r.id,
      'title': r.title,
      'description': r.description,
      'date': r.date.toIso8601String(),
      'hour': r.time.hour,
      'minute': r.time.minute,
      'category': r.category,
      'isCompleted': r.isCompleted,
    }).toList();

    _setPersistentItem('reminders_db_$targetUid', jsonEncode(serializable));
  }

  void deleteReminder(String id, [String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return;

    final list = getReminders(targetUid).toList();
    list.removeWhere((r) => r.id == id);

    final serializable = list.map((r) => {
      'id': r.id,
      'title': r.title,
      'description': r.description,
      'date': r.date.toIso8601String(),
      'hour': r.time.hour,
      'minute': r.time.minute,
      'category': r.category,
      'isCompleted': r.isCompleted,
    }).toList();

    _setPersistentItem('reminders_db_$targetUid', jsonEncode(serializable));
  }

  // ── Familiar People / Anchors (Keyed per user) ───────────────────────────
  List<FamiliarPerson> getFamiliarPeople([String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return [];

    final str = _getPersistentItem('familiar_people_db_$targetUid');
    if (str != null && str.isNotEmpty) {
      try {
        final decoded = jsonDecode(str) as List<dynamic>;
        return decoded.map((item) {
          final m = item as Map<String, dynamic>;
          final colorVal = m['color'] as int? ?? 0xFFB85028;
          return FamiliarPerson(
            id: m['id'] ?? '',
            name: m['name'] ?? '',
            relationship: m['relationship'] ?? '',
            note: m['note'] ?? '',
            avatarColor: Color(colorVal),
            initials: m['initials'] ?? 'FP',
          );
        }).toList();
      } catch (e) {
        debugPrint('DBMS Familiar People Parse Error: $e');
      }
    }
    return [];
  }

  void saveFamiliarPerson(FamiliarPerson person, [String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return;

    final list = getFamiliarPeople(targetUid).toList();
    final idx = list.indexWhere((p) => p.id == person.id);
    if (idx != -1) {
      list[idx] = person;
    } else {
      list.add(person);
    }

    final serializable = list.map((p) => {
      'id': p.id,
      'name': p.name,
      'relationship': p.relationship,
      'note': p.note,
      'color': p.avatarColor.toARGB32(),
      'initials': p.initials,
    }).toList();

    _setPersistentItem('familiar_people_db_$targetUid', jsonEncode(serializable));
  }

  void deleteFamiliarPerson(String id, [String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return;

    final list = getFamiliarPeople(targetUid).toList();
    list.removeWhere((p) => p.id == id);

    final serializable = list.map((p) => {
      'id': p.id,
      'name': p.name,
      'relationship': p.relationship,
      'note': p.note,
      'color': p.avatarColor.toARGB32(),
      'initials': p.initials,
    }).toList();

    _setPersistentItem('familiar_people_db_$targetUid', jsonEncode(serializable));
  }

  // ── Exercise Attempts Persistence (Keyed per user) ──────────────────────
  void saveAttempt(Map<String, dynamic> attemptJson, [String? userId]) {
    final targetUid = userId ?? (attemptJson['userId'] as String? ?? activeUserId);
    if (targetUid.isEmpty) return;

    final list = getLoggedAttempts(targetUid).toList();
    list.add(attemptJson);
    _setPersistentItem('logged_attempts_db_$targetUid', jsonEncode(list));
  }

  List<Map<String, dynamic>> getLoggedAttempts([String? userId]) {
    final targetUid = userId ?? activeUserId;
    if (targetUid.isEmpty) return [];

    final str = _getPersistentItem('logged_attempts_db_$targetUid');
    if (str != null && str.isNotEmpty) {
      try {
        final decoded = jsonDecode(str) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        debugPrint('DBMS Attempt Load Error: $e');
      }
    }
    return [];
  }

  // ── Demo Profile Mode (SIH Presentation, Strictly Isolated) ──────────────
  void activateDemoMode() {
    const demoUid = 'uid_demo_sih';
    setActiveUserId(demoUid);

    // Seed demo profile only once if not present
    if (getUserProfile(demoUid) == null) {
      saveUserProfile(
        name: 'Aditya Verma (Demo Profile)',
        role: 'Patient',
        credentialId: demoUid,
        language: 'en',
        age: 72,
        emergencyContact: '+91 98765 43210 (Demo Contact)',
        medicalNotes: 'Demonstration profile for SIH evaluation. Mild age-associated memory recall support.',
        userId: demoUid,
      );

      // Seed 1 demo appointment
      saveAppointment(
        Appointment(
          id: 'demo_appt_1',
          title: 'Dr. Mehta Consultation',
          doctorName: 'Dr. K. Mehta (Neurologist)',
          date: DateTime.now(),
          time: const TimeOfDay(hour: 17, minute: 0),
          location: 'Memory Wellness Clinic, Room 302',
          notes: 'Routine memory review & cognitive rhythm check.',
        ),
        demoUid,
      );

      // Seed 1 demo reminder
      saveReminder(
        EverydayReminder(
          id: 'demo_rem_1',
          title: 'Hydration Reminder',
          description: 'Drink warm water or herbal tea.',
          date: DateTime.now(),
          time: TimeOfDay(
            hour: (DateTime.now().hour + 1) % 24,
            minute: 0,
          ),
          category: ReminderCategory.health,
        ),
        demoUid,
      );

      // Seed 1 demo familiar person
      saveFamiliarPerson(
        FamiliarPerson(
          id: 'demo_rel_1',
          name: 'Lakshmi',
          relationship: 'Daughter',
          note: 'Calls every Sunday morning. Enjoys listening to classical music together.',
          avatarColor: const Color(0xFFB85028),
          initials: 'LK',
        ),
        demoUid,
      );

      // Seed 2 authentic completed demo attempts
      saveAttempt({
        'id': 'demo_att_1',
        'userId': demoUid,
        'domain': 'universalCognitive',
        'type': 'sequenceRecall',
        'exerciseId': 'seq_demo',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'stage': 1,
        'rawScore': 4.0,
        'maxScore': 4.0,
        'timeTakenMs': 38000,
      }, demoUid);
    }
  }

  // ── Onboarding status ──────────────────────────────────────────────────
  void setOnboarded(bool val, [String? userId]) {
    final uid = userId ?? activeUserId;
    if (uid.isNotEmpty) {
      _setPersistentItem('app_onboarded_status_$uid', val.toString());
    }
    _setPersistentItem('app_onboarded_status', val.toString());
  }

  bool isOnboarded([String? userId]) {
    final uid = userId ?? activeUserId;
    if (uid.isNotEmpty) {
      final val = _getPersistentItem('app_onboarded_status_$uid');
      if (val != null) return val == 'true';

      // Check if user profile has completed information
      final profile = getUserProfile(uid);
      if (profile != null) {
        final age = profile['age'];
        final contact = profile['emergencyContact'];
        if ((age != null && age is num && age > 0) ||
            (contact != null && contact.toString().trim().isNotEmpty)) {
          return true;
        }
      }
    }
    return _getPersistentItem('app_onboarded_status') == 'true';
  }

  // ── Read-Only SQL Inspection Engine ────────────────────────────────────
  String executeSql(String query) {
    final q = query.trim().toUpperCase();
    if (q.contains('PATIENT_FILES')) {
      final files = getPatientFiles();
      if (files.isEmpty) return '--- Table: patient_files (0 records for user $activeUserId) ---';
      return '--- Table: patient_files (${files.length} records for user $activeUserId) ---\n${files.map((f) => 'ID: ${f.id} | Title: ${f.title} | Size: ${f.fileSize ?? 0} bytes | Date: ${f.uploadDate}').join('\n')}';
    } else if (q.contains('APPOINTMENTS')) {
      final apps = getAppointments();
      if (apps.isEmpty) return '--- Table: appointments (0 records for user $activeUserId) ---';
      return '--- Table: appointments (${apps.length} records for user $activeUserId) ---\n${apps.map((a) => 'ID: ${a.id} | Title: ${a.title} | Doctor: ${a.doctorName} | Date: ${a.date}').join('\n')}';
    } else if (q.contains('USER_PROFILE') || q.contains('USERS')) {
      final profile = getUserProfile();
      return '--- Table: users (Active User: $activeUserId) ---\n${profile != null ? 'Name: ${profile['name']} | Role: ${profile['role']} | Lang: ${profile['language']} | Age: ${profile['age']}' : 'No active profile found'}';
    } else if (q.contains('REMINDERS')) {
      final rems = getReminders();
      if (rems.isEmpty) return '--- Table: reminders (0 records for user $activeUserId) ---';
      return '--- Table: reminders (${rems.length} records for user $activeUserId) ---\n${rems.map((r) => 'ID: ${r.id} | Title: ${r.title} | Done: ${r.isCompleted}').join('\n')}';
    } else if (q.contains('EXERCISE_ATTEMPTS')) {
      final atts = getLoggedAttempts();
      if (atts.isEmpty) return '--- Table: exercise_attempts (0 records for user $activeUserId) ---';
      return '--- Table: exercise_attempts (${atts.length} records for user $activeUserId) ---\n${atts.map((a) => 'ID: ${a['id']} | Type: ${a['type']} | Score: ${a['rawScore']}/${a['maxScore']}').join('\n')}';
    }
    return 'Query executed successfully: 0 rows returned for custom query.';
  }

  // ── Developer AI Configuration ──────────────────────────────────────────
  void saveAiConfig({required String apiKey, required bool isAiEnabled}) {
    _setPersistentItem('gemini_api_key', apiKey);
    _setPersistentItem('ai_enabled', isAiEnabled ? 'true' : 'false');
  }

  String get geminiApiKey =>
      _getPersistentItem('gemini_api_key') ?? const String.fromEnvironment('GEMINI_API_KEY');
  bool get isAiEnabled => _getPersistentItem('ai_enabled') != 'false';
}
