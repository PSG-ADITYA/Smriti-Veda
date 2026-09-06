import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/patient_info.dart';
import 'db_service.dart';

class MedicalReportService extends ChangeNotifier {
  static final MedicalReportService _instance = MedicalReportService._internal();
  factory MedicalReportService() => _instance;
  MedicalReportService._internal();

  List<PatientFile> getReports() {
    return DbService().getPatientFiles();
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final newReport = PatientFile(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      uploadDate: DateTime.now(),
      fileType: fileType,
      notes: notes,
      localPath: localPath,
      fileBytes: fileBytes,
      originalFileName: originalFileName,
      fileSize: fileSize,
    );

    DbService().savePatientFile(newReport);
    notifyListeners();
    return newReport;
  }

  Future<void> deleteReport(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    DbService().deletePatientFile(id);
    notifyListeners();
  }
}
