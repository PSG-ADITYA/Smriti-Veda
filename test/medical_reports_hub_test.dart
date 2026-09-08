import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/models/patient_info.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/screens/medical_reports_screen.dart';
import 'package:smriti_veda/services/db_service.dart';
import 'package:smriti_veda/widgets/pdf_viewer_dialog.dart';

Widget _wrapWithScope(Widget child, AppState appState, {Size size = const Size(360, 800)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: AppStateScope(
        state: appState,
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Medical Reports Hub Bug Fix Tests', () {
    late AppState appState;

    setUp(() async {
      await DbService().init();
      DbService().clearActiveSession();
      appState = AppState();
      appState.login(
        name: 'Ramesh Patel',
        credentialId: 'patient_test_1',
        role: 'Patient',
      );
    });

    tearDown(() {
      DbService().clearActiveSession();
      appState.dispose();
    });

    const viewports = [
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
    ];

    testWidgets('1. Report cards render without vertical text distortion or overflow across all viewports', (tester) async {
      final samplePdf = PatientFile(
        id: 'rep_pdf_1',
        title: 'Complete Neurological MRI Brain Scan & Cognitive Assessment Report',
        category: 'Medical Report',
        uploadDate: DateTime.now(),
        fileType: 'PDF',
        notes: 'Follow-up MRI scan required after 6 months to monitor hippocampal atrophy.',
        originalFileName: 'apollo_hospital_neurology_mri_brain_contrast_2026_full_scan.pdf',
        fileSize: 1024 * 350,
      );

      final sampleImage = PatientFile(
        id: 'rep_img_1',
        title: 'Morning Medication Prescription',
        category: 'Prescription',
        uploadDate: DateTime.now(),
        fileType: 'JPG',
        notes: 'Donepezil 5mg once daily at bedtime.',
        originalFileName: 'rx_donepezil_prescription.jpg',
        fileSize: 1024 * 120,
      );

      DbService().savePatientFile(samplePdf, 'patient_test_1');
      DbService().savePatientFile(sampleImage, 'patient_test_1');

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrapWithScope(const MedicalReportsScreen(), appState, size: size));
        await tester.pumpAndSettle();

        // Verify titles are rendered
        expect(find.textContaining('Complete Neurological MRI'), findsOneWidget);
        expect(find.textContaining('Morning Medication Prescription'), findsOneWidget);

        // Verify category badges are present as badges
        expect(find.text('Medical Report'), findsOneWidget);
        expect(find.text('Prescription'), findsOneWidget);

        // Verify format badges
        expect(find.text('PDF'), findsOneWidget);
        expect(find.text('JPG'), findsOneWidget);

        // Verify view action buttons are rendered
        expect(find.text('View PDF Document'), findsOneWidget);
        expect(find.text('View Medical Scan'), findsOneWidget);

        // Verify zero RenderFlex overflow occurred
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('2. Tapping View action button opens in-app report viewer dialog', (tester) async {
      appState.login(
        name: 'Ramesh Patel',
        credentialId: 'patient_test_2',
        role: 'Patient',
      );

      final samplePdf = PatientFile(
        id: 'rep_pdf_tap',
        title: 'Brain Scan Report',
        category: 'Medical Report',
        uploadDate: DateTime.now(),
        fileType: 'PDF',
        notes: 'Patient memory assessment normal.',
        originalFileName: 'brain_scan.pdf',
        fileSize: 1024 * 50,
      );
      DbService().savePatientFile(samplePdf, 'patient_test_2');

      await tester.pumpWidget(_wrapWithScope(const MedicalReportsScreen(), appState));
      await tester.pumpAndSettle();

      // Tap View PDF Document
      await tester.tap(find.text('View PDF Document').first);
      await tester.pumpAndSettle();

      // Verify PDFViewerDialog opened
      expect(find.byType(PDFViewerDialog), findsOneWidget);
      expect(find.text('Brain Scan Report'), findsWidgets);
      expect(find.text('Done'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(PDFViewerDialog), findsNothing);
    });

    testWidgets('3. Tapping the report card surface directly opens viewer dialog (InkWell)', (tester) async {
      appState.login(
        name: 'Ramesh Patel',
        credentialId: 'patient_test_3',
        role: 'Patient',
      );

      final sampleImage = PatientFile(
        id: 'rep_img_tap',
        title: 'Lab Test Blood Work',
        category: 'Medical Report',
        uploadDate: DateTime.now(),
        fileType: 'PNG',
        notes: 'Vitamin B12 levels evaluated.',
        originalFileName: 'b12_blood_test.png',
        fileSize: 1024 * 80,
      );
      DbService().savePatientFile(sampleImage, 'patient_test_3');

      await tester.pumpWidget(_wrapWithScope(const MedicalReportsScreen(), appState));
      await tester.pumpAndSettle();

      // Tap the card title directly
      await tester.tap(find.text('Lab Test Blood Work').first);
      await tester.pumpAndSettle();

      // Verify PDFViewerDialog opened
      expect(find.byType(PDFViewerDialog), findsOneWidget);
      expect(find.text('Lab Test Blood Work'), findsWidgets);

      // Dismiss
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });

    testWidgets('4. Missing/deleted file shows clear graceful fallback card in viewer without crashing', (tester) async {
      final missingFile = PatientFile(
        id: 'rep_missing',
        title: 'Deleted Scan',
        category: 'Medical Report',
        uploadDate: DateTime.now(),
        fileType: 'PDF',
        notes: 'Clinical notes remain preserved.',
        localPath: '/non/existent/path/file.pdf',
        originalFileName: 'deleted_file.pdf',
        fileSize: 1024 * 200,
      );

      await tester.pumpWidget(_wrapWithScope(PDFViewerDialog(file: missingFile), appState));
      await tester.pumpAndSettle();

      // Verify graceful fallback error card
      expect(find.text('Document Unavailable'), findsOneWidget);
      expect(find.textContaining('Preserved Clinical Record & Notes:'), findsOneWidget);
      expect(find.textContaining('Clinical notes remain preserved.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. In-memory image report renders with zoomable viewer', (tester) async {
      // 1x1 transparent PNG bytes
      final tinyPngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      final validImageFile = PatientFile(
        id: 'rep_img_valid',
        title: 'Valid Medical Scan',
        category: 'Medical Report',
        uploadDate: DateTime.now(),
        fileType: 'PNG',
        notes: 'Image byte preview verified.',
        fileBytes: tinyPngBytes,
        fileSize: tinyPngBytes.length,
      );

      await tester.pumpWidget(_wrapWithScope(PDFViewerDialog(file: validImageFile), appState));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Pinch or drag to zoom & examine scan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
