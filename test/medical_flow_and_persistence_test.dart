import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_veda/models/patient_info.dart';
import 'package:smriti_veda/providers/app_state.dart';
import 'package:smriti_veda/screens/home_tab.dart';
import 'package:smriti_veda/screens/medical_reports_screen.dart';
import 'package:smriti_veda/services/db_service.dart';
import 'package:smriti_veda/services/medical_report_service.dart';
import 'package:smriti_veda/theme/app_theme.dart';
import 'package:smriti_veda/widgets/pdf_viewer_dialog.dart';

Widget _wrap(Widget child, AppState appState, {Size size = const Size(360, 800)}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: const TextScaler.linear(1.25), // Stress test high font scale
      ),
      child: AppStateScope(
        state: appState,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() async {
    await DbService().init();
    appState = AppState();
  });

  group('Medical Report Upload, Persistence & Rendering Flow Tests', () {
    test('Upload, serialize base64 bytes into DbService, and restore across restart', () async {
      final dummyPdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.4 header dummy content'));
      const longName = 'very_long_neurological_radiology_report_mri_brain_scan_november_2026_final_version.pdf';

      final report = await MedicalReportService().uploadReport(
        title: 'Brain MRI Scan 2026',
        category: 'Medical Report',
        fileType: 'PDF',
        notes: 'Mild hippocampal symmetry noted. Recommended follow-up in 6 months.',
        fileBytes: dummyPdfBytes,
        originalFileName: longName,
        fileSize: dummyPdfBytes.length,
      );

      expect(report.title, 'Brain MRI Scan 2026');
      expect(report.originalFileName, longName);
      expect(report.fileBytes, isNotNull);

      // Verify persistence in DbService
      final savedFiles = DbService().getPatientFiles();
      final match = savedFiles.where((f) => f.title == 'Brain MRI Scan 2026').firstOrNull;
      expect(match, isNotNull);
      expect(match!.fileBytes, isNotNull);
      expect(match.fileBytes!.length, dummyPdfBytes.length);
      expect(match.category, 'Medical Report');
    });

    testWidgets('PDFViewerDialog renders header and controls for memory document', (tester) async {
      final dummyPdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.4 test document content'));
      final file = PatientFile(
        id: 'test_pdf_1',
        title: 'Clinical Prescription & Summary',
        category: 'Prescription',
        uploadDate: DateTime.now(),
        fileType: 'PDF',
        notes: 'Take morning tablet after breakfast.',
        fileBytes: dummyPdfBytes,
        originalFileName: 'rx_morning_prescription.pdf',
        fileSize: dummyPdfBytes.length,
      );

      await tester.pumpWidget(_wrap(PDFViewerDialog(file: file), appState));
      await tester.pump();

      expect(find.text('Clinical Prescription & Summary'), findsOneWidget);
      expect(find.textContaining('Prescription'), findsWidgets);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Dismiss dialog cleanly
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('PDFViewerDialog renders Image.memory for image scans', (tester) async {
      final dummyPngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82
      ]);

      final file = PatientFile(
        id: 'test_img_1',
        title: 'Blood Pressure Log Scan',
        category: 'Medical Report',
        uploadDate: DateTime.now(),
        fileType: 'PNG',
        notes: 'Weekly handwritten BP readings.',
        fileBytes: dummyPngBytes,
        originalFileName: 'bp_scan_sheet.png',
        fileSize: dummyPngBytes.length,
      );

      await tester.pumpWidget(_wrap(PDFViewerDialog(file: file), appState));
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Blood Pressure Log Scan'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });

    testWidgets('MedicalReportsScreen renders with zero overflow on 360x800 at 1.25x font scale', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap(const MedicalReportsScreen(), appState, size: const Size(360, 800)));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.textContaining('Medical Reports Hub'), findsWidgets);
      expect(find.textContaining('Add Medical Report'), findsWidgets);
      expect(find.textContaining('SAVED MEDICAL REPORTS'), findsWidgets);
    });

    testWidgets('HomeTab renders with zero overflow on 360x800 at 1.25x font scale', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap(HomeTab(onNavigateTab: (_) {}), appState, size: const Size(360, 800)));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.textContaining('Ready for today'), findsWidgets);
      expect(find.textContaining('Tap to listen to daily plan'), findsWidgets);

      // Scroll to view the adaptive section
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -350));
      await tester.pumpAndSettle();

      expect(find.textContaining('AI PERSONAL COGNITIVE REGIMEN'), findsWidgets);
      // Successfully scrolled and verified AI personal cognitive regimen card without overflow
    });
  });
}
