import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/models/exercise_attempt.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/repositories/local_exercise_attempt_repository.dart';
import 'package:smriti_veda/screens/caregiver_dashboard_screen.dart';
import 'package:smriti_veda/screens/main_screen.dart';
import 'package:smriti_veda/screens/profile_screen.dart';
import 'package:smriti_veda/services/caregiver_service.dart';
import 'package:smriti_veda/services/db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stage 1: Role Separation & Caregiver System Tests', () {
    late AppState appState;

    setUp(() async {
      await DbService().init();
      DbService().clearActiveSession();
      appState = AppState();
    });

    tearDown(() {
      DbService().clearActiveSession();
      appState.dispose();
    });

    testWidgets('1. Patient role navigation renders exactly 4 tabs and patient bottom nav items', (tester) async {
      appState.login(
        name: 'Ramesh Patel',
        credentialId: 'patient_test_1',
        role: 'Patient',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: appState,
            child: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Patient Bottom Nav Items are present
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Practice'), findsWidgets);
      expect(find.text('Everyday'), findsWidgets);
      expect(find.text('Progress'), findsWidgets);

      // Verify Caregiver Nav Items are NOT present
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Seniors'), findsNothing);
      expect(find.text('Insights'), findsNothing);
    });

    testWidgets('2. Caregiver role navigation renders exactly 5 tabs and caregiver bottom nav items', (tester) async {
      appState.login(
        name: 'Dr. Priya Sharma',
        credentialId: 'caregiver_test_1',
        role: 'Caregiver',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: appState,
            child: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Caregiver Bottom Nav Items
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Seniors'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Medical'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify Patient-only Nav Items are NOT present in the bottom nav
      expect(find.text('Practice'), findsNothing);
      expect(find.text('Everyday'), findsNothing);
    });

    test('3. Session restoration correctly respects hasActiveSession and restores roles', () {
      // With no active session
      DbService().clearActiveSession();
      final freshStateNoSession = AppState();
      expect(freshStateNoSession.isLoggedIn, isFalse);
      freshStateNoSession.dispose();

      // With Caregiver active session
      DbService().setActiveUserId('cg_session_test');
      DbService().saveUserProfile(
        name: 'Ananya Caregiver',
        role: 'Caregiver',
        credentialId: 'cg_session_test',
        language: 'en',
      );

      final freshStateCaregiver = AppState();
      expect(freshStateCaregiver.isLoggedIn, isTrue);
      expect(freshStateCaregiver.userRole, 'Caregiver');
      expect(freshStateCaregiver.isCaregiverMode, isTrue);
      expect(freshStateCaregiver.userName, 'Ananya Caregiver');
      freshStateCaregiver.dispose();

      // With Patient active session
      DbService().setActiveUserId('patient_session_test');
      DbService().saveUserProfile(
        name: 'Suresh Senior',
        role: 'Patient',
        credentialId: 'patient_session_test',
        language: 'hi',
      );

      final freshStatePatient = AppState();
      expect(freshStatePatient.isLoggedIn, isTrue);
      expect(freshStatePatient.userRole, 'Patient');
      expect(freshStatePatient.isCaregiverMode, isFalse);
      expect(freshStatePatient.userName, 'Suresh Senior');
      freshStatePatient.dispose();
    });

    test('4. Logout purges all user, caregiver, and session state cleanly', () {
      appState.login(
        name: 'Test Caregiver',
        credentialId: 'cg_logout_test',
        role: 'Caregiver',
      );
      expect(appState.isLoggedIn, isTrue);

      appState.logout();

      expect(appState.isLoggedIn, isFalse);
      expect(appState.credentialId, '');
      expect(appState.userName, 'Patient'); // defaults cleanly when empty
      expect(appState.userRole, 'Patient');
      expect(appState.connectedCaregiver, isNull);
      expect(appState.reminders, isEmpty);
      expect(appState.familiarPeople, isEmpty);
      expect(DbService().hasActiveSession, isFalse);
    });

    testWidgets('5. Empty caregiver state displays prompt to connect senior', (tester) async {
      appState.login(
        name: 'Fresh Caregiver',
        credentialId: 'cg_empty_test_99',
        role: 'Caregiver',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: appState,
            child: const CaregiverDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify empty state text and action button
      expect(find.text('No Connected Seniors Yet'), findsOneWidget);
      expect(find.text('Connect Senior'), findsWidgets);
    });

    test('6. Security boundary prevents unauthorized patient data access and permits authorized access', () async {
      final caregiverService = CaregiverService();
      final attemptRepo = LocalExerciseAttemptRepository();
      const caregiverId = 'cg_security_test_1';
      const patientId = 'patient_secure_1';
      const unauthorizedPatientId = 'patient_unauthorized_99';

      // 1. Initially unauthorized
      expect(caregiverService.isAuthorized(caregiverId, patientId), isFalse);
      expect(caregiverService.isAuthorized(caregiverId, unauthorizedPatientId), isFalse);

      // Attempting access throws CaregiverUnauthorizedException
      expect(
        () => caregiverService.getSeniorAttempts(caregiverId, unauthorizedPatientId, attemptRepo),
        throwsA(isA<CaregiverUnauthorizedException>()),
      );
      expect(
        () => caregiverService.getSeniorFiles(caregiverId, unauthorizedPatientId),
        throwsA(isA<CaregiverUnauthorizedException>()),
      );
      expect(
        () => caregiverService.getSeniorProfile(caregiverId, unauthorizedPatientId),
        throwsA(isA<CaregiverUnauthorizedException>()),
      );

      // 2. Connect senior
      final connected = await caregiverService.connectSenior(
        caregiverId,
        patientId: patientId,
        relationship: 'Grandfather',
        customName: 'Laxman Rao',
      );
      expect(connected, isTrue);

      // 3. Verify authorized state
      expect(caregiverService.isAuthorized(caregiverId, patientId), isTrue);
      expect(caregiverService.isAuthorized(caregiverId, unauthorizedPatientId), isFalse);

      // Authorized query succeeds without exception
      final attempts = caregiverService.getSeniorAttempts(caregiverId, patientId, attemptRepo);
      expect(attempts, isA<List<ExerciseAttempt>>());

      final files = caregiverService.getSeniorFiles(caregiverId, patientId);
      expect(files, isNotNull);

      // 4. Disconnect senior and verify boundary re-enforced
      await caregiverService.disconnectSenior(caregiverId, patientId);
      expect(caregiverService.isAuthorized(caregiverId, patientId), isFalse);
      expect(
        () => caregiverService.getSeniorAttempts(caregiverId, patientId, attemptRepo),
        throwsA(isA<CaregiverUnauthorizedException>()),
      );
    });

    testWidgets('7. Role-based ProfileScreen conditionally renders caregiver vs patient profiles', (tester) async {
      // Test Caregiver Profile
      appState.login(
        name: 'Nurse Kavita',
        credentialId: 'cg_profile_test',
        role: 'Caregiver',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: appState,
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Profile'), findsOneWidget);
      expect(find.text('Authorized Seniors'), findsOneWidget);
      expect(find.text('Family Members & Relatives'), findsNothing); // elderly memory prompt absent

      // Test Patient Profile
      appState.login(
        name: 'Dadi Janaki',
        credentialId: 'patient_profile_test',
        role: 'Patient',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppStateScope(
            state: appState,
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('Family Members & Relatives'), findsOneWidget);
      expect(find.text('Upcoming Appointments'), findsOneWidget);
    });

    testWidgets('8. Responsive Caregiver Dashboard renders at 360x800, 390x844, 412x915 with ZERO overflow', (tester) async {
      appState.login(
        name: 'Vikram Mehta',
        credentialId: 'cg_responsive_test',
        role: 'Caregiver',
      );

      final testSizes = [
        const Size(360, 800),
        const Size(390, 844),
        const Size(412, 915),
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: AppStateScope(
              state: appState,
              child: const CaregiverDashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow occurred at size $size');
        expect(find.text('Caregiver Guardian Portal'), findsOneWidget);
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
