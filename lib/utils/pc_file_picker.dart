import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class PickedPcFile {
  final String name;
  final Uint8List? bytes;
  final int size;
  final String extension;

  PickedPcFile({
    required this.name,
    required this.bytes,
    required this.size,
    required this.extension,
  });
}

class PcFilePicker {
  static const int maxFileSizeBytes = 15 * 1024 * 1024; // 15MB limit

  static Future<PickedPcFile?> pickFileFromPc() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (file != null) {
        Uint8List? bytes;
        try {
          bytes = await file.readAsBytes();
        } catch (_) {
          if (!kIsWeb && file.path != null) {
            try {
              bytes = await File(file.path!).readAsBytes();
            } catch (e) {
              debugPrint('Failed to read file bytes from path: $e');
            }
          }
        }

        int size = bytes?.lengthInBytes ?? (file.lengthSync() ?? 0);
        if (size == 0) {
          try {
            size = await file.length();
          } catch (_) {}
        }

        if (size > maxFileSizeBytes) {
          debugPrint('File too large: $size bytes (limit: $maxFileSizeBytes)');
          return null;
        }

        final ext = (file.extension ?? (file.name.contains('.') ? file.name.split('.').last : '')).toLowerCase();

        return PickedPcFile(
          name: file.name,
          bytes: bytes,
          size: size,
          extension: ext,
        );
      }
    } catch (e) {
      debugPrint('FilePicker error: $e');
    }
    return null;
  }
}
