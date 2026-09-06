import 'package:flutter/material.dart';

class ReminderCategory {
  static const String appointment = 'Appointment';
  static const String family = 'Family';
  static const String routine = 'Routine';
  static const String health = 'Health Reminder';
  static const String other = 'Other';

  static const List<String> all = [
    appointment,
    family,
    routine,
    health,
    other,
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case appointment:
        return Icons.calendar_month;
      case family:
        return Icons.people_outline;
      case routine:
        return Icons.alarm;
      case health:
        return Icons.medical_services_outlined;
      default:
        return Icons.push_pin_outlined;
    }
  }

  static Color getColor(String category) {
    switch (category) {
      case appointment:
        return const Color(0xFF3D6B58); // Sage Green
      case family:
        return const Color(0xFFB85028); // Terracotta
      case routine:
        return const Color(0xFF8A643E); // Sandalwood
      case health:
        return const Color(0xFFC0392B); // Soft Red
      default:
        return const Color(0xFF5D6D7E);
    }
  }
}

class EverydayReminder {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay time;
  final String category;
  final bool isCompleted;

  EverydayReminder({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.time,
    required this.category,
    this.isCompleted = false,
  });

  EverydayReminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    String? category,
    bool? isCompleted,
  }) {
    return EverydayReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class RoutineStep {
  final String id;
  final int stepNumber;
  final String title;
  final String description;
  final String targetTime;
  final bool isCompleted;
  final IconData icon;

  RoutineStep({
    required this.id,
    required this.stepNumber,
    required this.title,
    this.description = '',
    this.targetTime = '',
    this.isCompleted = false,
    this.icon = Icons.check_circle_outline,
  });

  RoutineStep copyWith({
    String? id,
    int? stepNumber,
    String? title,
    String? description,
    String? targetTime,
    bool? isCompleted,
    IconData? icon,
  }) {
    return RoutineStep(
      id: id ?? this.id,
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      targetTime: targetTime ?? this.targetTime,
      isCompleted: isCompleted ?? this.isCompleted,
      icon: icon ?? this.icon,
    );
  }
}

class FamiliarPerson {
  final String id;
  final String name;
  final String relationship;
  final String note;
  final Color avatarColor;
  final String initials;

  FamiliarPerson({
    required this.id,
    required this.name,
    required this.relationship,
    this.note = '',
    this.avatarColor = const Color(0xFFB85028),
    required this.initials,
  });

  FamiliarPerson copyWith({
    String? id,
    String? name,
    String? relationship,
    String? note,
    Color? avatarColor,
    String? initials,
  }) {
    return FamiliarPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      note: note ?? this.note,
      avatarColor: avatarColor ?? this.avatarColor,
      initials: initials ?? this.initials,
    );
  }
}
