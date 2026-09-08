import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/patient_info.dart';
import '../theme/app_theme.dart';

class PDFViewerDialog extends StatefulWidget {
  final PatientFile file;

  const PDFViewerDialog({super.key, required this.file});

  @override
  State<PDFViewerDialog> createState() => _PDFViewerDialogState();
}

class _PDFViewerDialogState extends State<PDFViewerDialog> {
  late final PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  int _totalPages = 1;
  double _zoomLevel = 1.0;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _checkFileAvailability();
  }

  void _checkFileAvailability() {
    final file = widget.file;
    final hasBytes = file.fileBytes != null && file.fileBytes!.isNotEmpty;
    final hasValidPath = file.localPath != null && File(file.localPath!).existsSync();

    if (!hasBytes && !hasValidPath) {
      _errorMessage = 'The file could not be found on this device.\n'
          'Expected path: ${file.localPath ?? 'Local file system'}\n'
          'The document may have been deleted or moved externally.';
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  bool get _isPdf => widget.file.fileType.toUpperCase() == 'PDF';

  bool get _isImage {
    final t = widget.file.fileType.toUpperCase();
    return t == 'JPG' || t == 'JPEG' || t == 'PNG';
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 400;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: isCompact ? 12 : 20,
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 900),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── 1. Top Header Toolbar ──────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 20,
                vertical: 12,
              ),
              decoration: const BoxDecoration(
                color: AppColors.canvasIvory,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isPdf
                          ? Colors.redAccent.withValues(alpha: 0.12)
                          : AppColors.sageSecondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isPdf ? Icons.picture_as_pdf : Icons.image,
                      color: _isPdf ? Colors.redAccent : AppColors.sageSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.title,
                          style: GoogleFonts.newsreader(
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${file.category} • ${file.fileType} • ${file.formattedFileSize}',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_isPdf && _errorMessage == null) ...[
                    IconButton(
                      icon: const Icon(Icons.zoom_out, size: 20),
                      tooltip: 'Zoom Out',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
                          _pdfViewerController.zoomLevel = _zoomLevel;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_in, size: 20),
                      tooltip: 'Zoom In',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
                          _pdfViewerController.zoomLevel = _zoomLevel;
                        });
                      },
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.charcoalText),
                    tooltip: 'Close Viewer',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── 2. Document Content Area ──────────────────────────────
            Expanded(
              child: Container(
                color: const Color(0xFFF0EEE9),
                child: _buildDocumentBody(file),
              ),
            ),

            // ── 3. Bottom Controls Bar ────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 20,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isPdf && _errorMessage == null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          visualDensity: VisualDensity.compact,
                          onPressed: _currentPage > 1
                              ? () => _pdfViewerController.previousPage()
                              : null,
                        ),
                        Text(
                          'Page $_currentPage of $_totalPages',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          visualDensity: VisualDensity.compact,
                          onPressed: _currentPage < _totalPages
                              ? () => _pdfViewerController.nextPage()
                              : null,
                        ),
                      ],
                    )
                  else if (_isImage && _errorMessage == null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pinch, size: 18, color: AppColors.secondaryText),
                        const SizedBox(width: 6),
                        Text(
                          'Pinch or drag to zoom & examine scan',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'SmritiVeda Document Vault',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracottaPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentBody(PatientFile file) {
    if (_errorMessage != null) {
      return _buildErrorCard(file, _errorMessage!);
    }

    if (_isPdf) {
      return _buildPdfView(file);
    }

    if (_isImage) {
      return _buildImageView(file);
    }

    return _buildErrorCard(file, 'Unsupported document format: ${file.fileType}');
  }

  Widget _buildPdfView(PatientFile file) {
    final hasValidPath = file.localPath != null && File(file.localPath!).existsSync();
    final hasBytes = file.fileBytes != null && file.fileBytes!.isNotEmpty;

    if (!hasValidPath && !hasBytes) {
      return _buildErrorCard(file, 'PDF file not accessible on this device storage.');
    }

    Widget pdfWidget;
    if (hasValidPath) {
      pdfWidget = SfPdfViewer.file(
        File(file.localPath!),
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          if (mounted) {
            setState(() {
              _totalPages = details.document.pages.count;
              _isLoading = false;
            });
          }
        },
        onPageChanged: (PdfPageChangedDetails details) {
          if (mounted) {
            setState(() {
              _currentPage = details.newPageNumber;
            });
          }
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to load PDF document: ${details.description}';
              _isLoading = false;
            });
          }
        },
      );
    } else {
      pdfWidget = SfPdfViewer.memory(
        file.fileBytes!,
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          if (mounted) {
            setState(() {
              _totalPages = details.document.pages.count;
              _isLoading = false;
            });
          }
        },
        onPageChanged: (PdfPageChangedDetails details) {
          if (mounted) {
            setState(() {
              _currentPage = details.newPageNumber;
            });
          }
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to load PDF document: ${details.description}';
              _isLoading = false;
            });
          }
        },
      );
    }

    return Stack(
      children: [
        pdfWidget,
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.terracottaPrimary),
          ),
      ],
    );
  }

  Widget _buildImageView(PatientFile file) {
    final hasValidPath = file.localPath != null && File(file.localPath!).existsSync();
    final hasBytes = file.fileBytes != null && file.fileBytes!.isNotEmpty;

    Widget imageWidget;
    if (hasBytes) {
      imageWidget = Image.memory(
        file.fileBytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, error, __) {
          return _buildErrorCard(file, 'Image decoding error: $error');
        },
      );
    } else if (hasValidPath) {
      imageWidget = Image.file(
        File(file.localPath!),
        fit: BoxFit.contain,
        errorBuilder: (_, error, __) {
          return _buildErrorCard(file, 'Could not read image file from path: $error');
        },
      );
    } else {
      return _buildErrorCard(file, 'Image file not found on local storage.');
    }

    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      clipBehavior: Clip.none,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: imageWidget,
        ),
      ),
    );
  }

  Widget _buildErrorCard(PatientFile file, String reason) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document Unavailable',
                          style: GoogleFonts.newsreader(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        Text(
                          'File cannot be viewed in app',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  reason,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 13,
                    color: Colors.red.shade900,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 14),
              Text(
                'Preserved Clinical Record & Notes:',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoalText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Title: ${file.title}\n'
                'Category: ${file.category}\n'
                'Date: ${file.uploadDate.toString().split(' ')[0]}\n'
                'Original Name: ${file.originalFileName ?? 'N/A'}\n'
                'Doctor Notes: ${file.notes.isNotEmpty ? file.notes : 'None provided'}',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13,
                  color: AppColors.charcoalText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
