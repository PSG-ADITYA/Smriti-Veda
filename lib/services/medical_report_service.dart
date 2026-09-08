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
    Uint8List? effectiveBytes = fileBytes;

    if ((effectiveBytes == null || effectiveBytes.isEmpty) && localPath != null) {
      try {
        final src = File(localPath);
        if (await src.exists()) {
          effectiveBytes = await src.readAsBytes();
        }
      } catch (e) {
        debugPrint('Could not read source file at $localPath: $e');
      }
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/medical_reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      final safeName = (originalFileName ?? 'report_${DateTime.now().millisecondsSinceEpoch}')
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final targetFile = File('${reportsDir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName');

      if (effectiveBytes != null && effectiveBytes.isNotEmpty) {
        await targetFile.writeAsBytes(effectiveBytes);
        if (await targetFile.exists()) {
          finalLocalPath = targetFile.path;
        }
      } else if (localPath != null) {
        final src = File(localPath);
        if (await src.exists()) {
          await src.copy(targetFile.path);
          if (await targetFile.exists()) {
            finalLocalPath = targetFile.path;
          }
        }
      }
    } catch (e) {
      debugPrint('File system storage notice: $e');
    }

    int? computedSize = fileSize ?? effectiveBytes?.length;
    if (computedSize == null && finalLocalPath != null) {
      try {
        final f = File(finalLocalPath);
        if (f.existsSync()) {
          computedSize = f.lengthSync();
        }
      } catch (_) {}
    }

    final newReport = PatientFile(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      uploadDate: DateTime.now(),
      fileType: fileType,
      notes: notes,
      localPath: finalLocalPath,
      fileBytes: effectiveBytes,
      originalFileName: originalFileName,
      fileSize: computedSize,
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
