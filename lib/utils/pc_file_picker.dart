import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class PickedPcFile {
  final String name;
  final Uint8List? bytes;
  final int size;
  final String extension;
  final String? path;

  PickedPcFile({
    required this.name,
    required this.bytes,
    required this.size,
    required this.extension,
    this.path,
  });
}

class PcFilePicker {
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25MB limit

  static Future<PickedPcFile?> pickFileFromPc() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (file != null) {
        final path = file.path;
        Uint8List? bytes;
        int size = 0;

        try {
          size = await file.length();
        } catch (_) {
          if (path != null && !kIsWeb) {
            try {
              final f = File(path);
              if (await f.exists()) {
                size = await f.length();
              }
            } catch (_) {}
          }
        }

        if (size > maxFileSizeBytes) {
          debugPrint('File too large: $size bytes (limit: $maxFileSizeBytes)');
          return null;
        }

        try {
          bytes = await file.readAsBytes();
        } catch (e) {
          debugPrint('Failed to read file bytes from PlatformFile: $e');
          if (path != null && !kIsWeb) {
            try {
              final f = File(path);
              if (await f.exists()) {
                bytes = await f.readAsBytes();
                size = await f.length();
              }
            } catch (_) {}
          }
        }
        if (bytes != null && size == 0) {
          size = bytes.lengthInBytes;
        }

        final fileName = file.name;
        final ext = (file.extension ?? (fileName.contains('.') ? fileName.split('.').last : '')).toLowerCase();

        return PickedPcFile(
          name: fileName,
          bytes: bytes,
          size: size > 0 ? size : (bytes?.lengthInBytes ?? 0),
          extension: ext,
          path: path,
        );
      }
    } catch (e) {
      debugPrint('FilePicker error: $e');
    }
    return null;
  }
}
