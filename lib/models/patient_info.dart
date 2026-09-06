import 'dart:typed_data';
import 'package:flutter/material.dart';

class Appointment {
  final String id;
  final String title;
  final String doctorName;
  final DateTime date;
  final TimeOfDay time;
  final String location;
  final String notes;
  final bool reminderEnabled;

  const Appointment({
    required this.id,
    required this.title,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.location,
    this.notes = '',
    this.reminderEnabled = true,
  });

  Appointment copyWith({
    String? id,
    String? title,
    String? doctorName,
    DateTime? date,
    TimeOfDay? time,
    String? location,
    String? notes,
    bool? reminderEnabled,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      doctorName: doctorName ?? this.doctorName,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}

class PatientFile {
  final String id;
  final String title;
  final String category; // 'Prescription', 'Medical Report', 'Personal Document'
  final DateTime uploadDate;
  final String fileType; // 'PDF', 'JPG', 'PNG', 'DOC'
  final String notes;
  final String? localPath;
  final Uint8List? fileBytes;
  final String? originalFileName;
  final int? fileSize;

  const PatientFile({
    required this.id,
    required this.title,
    required this.category,
    required this.uploadDate,
    this.fileType = 'PDF',
    this.notes = '',
    this.localPath,
    this.fileBytes,
    this.originalFileName,
    this.fileSize,
  });
}
