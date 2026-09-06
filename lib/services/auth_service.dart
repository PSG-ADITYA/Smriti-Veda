import 'package:flutter/material.dart';
import 'db_service.dart';

class AuthUser {
  final String uid;
  final String email;
  final String name;
  final String role; // 'Patient' or 'Caregiver'
  final String language;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.language = 'hi',
  });
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AuthUser? _currentUser;
  bool _isLoading = false;

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    final profile = DbService().getUserProfile();
    if (profile != null && profile['credentialId'] != null) {
      _currentUser = AuthUser(
        uid: profile['credentialId'],
        email: profile['email'] ?? '',
        name: profile['name'] ?? 'User',
        role: profile['role'] ?? 'Patient',
        language: profile['language'] ?? 'hi',
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    final userMap = DbService().authenticateUser(email, password);
    if (userMap != null) {
      _currentUser = AuthUser(
        uid: userMap['uid'],
        email: userMap['email'],
        name: userMap['name'],
        role: userMap['role'],
        language: userMap['language'] ?? 'hi',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String language = 'hi',
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    final success = DbService().registerUser(
      name: name,
      email: email,
      password: password,
      role: role,
      language: language,
    );

    if (success) {
      final userMap = DbService().authenticateUser(email, password);
      if (userMap != null) {
        _currentUser = AuthUser(
          uid: userMap['uid'],
          email: userMap['email'],
          name: userMap['name'],
          role: userMap['role'],
          language: userMap['language'] ?? language,
        );
      }
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}
