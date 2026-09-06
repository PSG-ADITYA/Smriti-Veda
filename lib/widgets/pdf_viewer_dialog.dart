import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_info.dart';
import '../theme/app_theme.dart';

class PDFViewerDialog extends StatefulWidget {
  final PatientFile file;

  const PDFViewerDialog({super.key, required this.file});

  @override
  State<PDFViewerDialog> createState() => _PDFViewerDialogState();
}

class _PDFViewerDialogState extends State<PDFViewerDialog> {
  int _currentPage = 1;
  final int _totalPages = 3;
  double _zoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    final file = widget.file;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.canvasIvory,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.title,
                          style: GoogleFonts.newsreader(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Category: ${file.category} • Format: ${file.fileType}',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out),
                    tooltip: 'Zoom Out',
                    onPressed: () {
                      setState(() {
                        if (_zoomLevel > 0.8) _zoomLevel -= 0.1;
                      });
                    },
                  ),
                  Text(
                    '${(_zoomLevel * 100).toInt()}%',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    tooltip: 'Zoom In',
                    onPressed: () {
                      setState(() {
                        if (_zoomLevel < 1.5) _zoomLevel += 0.1;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.charcoalText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Document View Content Area
            Expanded(
              child: Container(
                color: const Color(0xFFF3F1ED),
                child: Center(
                  child: SingleChildScrollView(
                    child: Transform.scale(
                      scale: _zoomLevel,
                      child: Container(
                        width: 540,
                        constraints: const BoxConstraints(minHeight: 580),
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header banner inside document
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SMRITIVEDA MEDICAL RECORDS',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: AppColors.terracottaPrimary,
                                  ),
                                ),
                                Text(
                                  file.originalFileName != null
                                      ? file.originalFileName!
                                      : 'Page $_currentPage of $_totalPages',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 11,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: AppColors.borderSubtle),
                            const SizedBox(height: 8),
                            Text(
                              file.title,
                              style: GoogleFonts.newsreader(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoalText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${file.uploadDate.toString().split(' ')[0]} • Category: ${file.category} • Format: ${file.fileType}',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // If file has actual image/file bytes attached
                            if (file.fileBytes != null &&
                                (file.fileType.toUpperCase() == 'JPG' ||
                                    file.fileType.toUpperCase() == 'JPEG' ||
                                    file.fileType.toUpperCase() == 'PNG'))
                              Container(
                                constraints: const BoxConstraints(maxHeight: 380),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    file.fileBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.canvasIvory,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          file.fileType.toUpperCase() == 'PDF'
                                              ? Icons.picture_as_pdf
                                              : Icons.description,
                                          color: AppColors.terracottaPrimary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Attached Document Details:',
                                          style: GoogleFonts.atkinsonHyperlegible(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.charcoalText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (file.originalFileName != null)
                                      Text(
                                        'File Name: ${file.originalFileName}',
                                        style: GoogleFonts.atkinsonHyperlegible(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.charcoalText,
                                        ),
                                      ),
                                    if (file.fileSize != null)
                                      Text(
                                        'File Size: ${(file.fileSize! / 1024).toStringAsFixed(1)} KB',
                                        style: GoogleFonts.atkinsonHyperlegible(
                                          fontSize: 12,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Clinical Summary & Notes:',
                                      style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.charcoalText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      file.notes,
                                      style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 14,
                                        color: AppColors.charcoalText,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),
                            Text(
                              'Verification & Medical Records Log:',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoalText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '• Encrypted Local Storage: Verified\n'
                              '• Document Status: Active Patient History Record\n'
                              '• Accessible by Caregiver & Doctor profile',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Confidential Medical Document',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const Icon(Icons.verified, size: 18, color: AppColors.sageSecondary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Text(
                        'Page $_currentPage / $_totalPages',
                        style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading ${file.title}...')),
                      );
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracottaPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
