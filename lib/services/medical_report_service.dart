import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/patient_info.dart';
import 'db_service.dart';

class MedicalReportService extends ChangeNotifier {
  static final MedicalReportService _instance = MedicalReportService._internal();
  factory MedicalReportService() => _instance;
  MedicalReportService._internal();

  List<PatientFile> getReports([String? userId]) {
    return DbService().getPatientFiles(userId);
  }

  Future<PatientFile> uploadReport({
    required String title,
    required String category,
    required String fileType,
    required String notes,
    String? localPath,
    Uint8List? fileBytes,
    String? originalFileName,
    int? fileSize,
    String? targetUserId,
  }) async {
    String? finalLocalPath = localPath;

    // Persist file bytes directly to the application sandbox documents directory
    if (fileBytes != null && fileBytes.isNotEmpty) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final reportsDir = Directory('${directory.path}/medical_reports');
        if (!await reportsDir.exists()) {
          await reportsDir.create(recursive: true);
        }
        final safeName = (originalFileName ?? 'report_${DateTime.now().millisecondsSinceEpoch}')
            .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final savedFile = File('${reportsDir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName');
        await savedFile.writeAsBytes(fileBytes);
        finalLocalPath = savedFile.path;
      } catch (e) {
        debugPrint('File system storage notice: $e');
      }
    }

    final newReport = PatientFile(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      uploadDate: DateTime.now(),
      fileType: fileType,
      notes: notes,
      localPath: finalLocalPath,
      fileBytes: fileBytes,
      originalFileName: originalFileName,
      fileSize: fileSize ?? fileBytes?.length,
    );

    DbService().savePatientFile(newReport, targetUserId);
    notifyListeners();
    return newReport;
  }

  Future<void> deleteReport(String id) async {
    final reports = DbService().getPatientFiles();
    final match = reports.where((r) => r.id == id).firstOrNull;
    if (match != null && match.localPath != null) {
      try {
        final f = File(match.localPath!);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
    DbService().deletePatientFile(id);
    notifyListeners();
  }
}
