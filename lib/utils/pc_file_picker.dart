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
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final path = file.path;
        Uint8List? bytes = file.bytes;
        int size = file.size;

        // If bytes are not loaded directly (common on native Android/iOS), read from path
        if ((bytes == null || bytes.isEmpty) && path != null && !kIsWeb) {
          try {
            final f = File(path);
            if (await f.exists()) {
              bytes = await f.readAsBytes();
              size = await f.length();
            }
          } catch (e) {
            debugPrint('Failed to read file bytes from path: $e');
          }
        }

        if (size > maxFileSizeBytes) {
          debugPrint('File too large: $size bytes (limit: $maxFileSizeBytes)');
          return null;
        }

        final fileName = file.name;
        final ext = (fileName.contains('.') ? fileName.split('.').last : '').toLowerCase();

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
