import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_info.dart';
import '../providers/app_state.dart';
import '../services/medical_report_service.dart';
import '../theme/app_theme.dart';
import '../utils/pc_file_picker.dart';
import '../widgets/pdf_viewer_dialog.dart';

class MedicalReportsScreen extends StatefulWidget {
  const MedicalReportsScreen({super.key});

  @override
  State<MedicalReportsScreen> createState() => _MedicalReportsScreenState();
}

class _MedicalReportsScreenState extends State<MedicalReportsScreen> {
  final bool _isDragging = false;

  void _openUploadModal(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = 'Medical Report';
    String selectedFileType = 'PDF';
    Uint8List? pickedBytes;
    String? pickedFileName;
    int? pickedFileSize;
    bool isUploading = false;

    Future<void> doPickFile(StateSetter setModalState) async {
      try {
        final picked = await PcFilePicker.pickFileFromPc();
        if (picked != null) {
          setModalState(() {
            pickedBytes = picked.bytes;
            pickedFileName = picked.name;
            pickedFileSize = picked.size;
            if (titleController.text.trim().isEmpty) {
              titleController.text = picked.name;
            }
            final ext = picked.extension.toUpperCase();
            if (ext == 'PDF') {
              selectedFileType = 'PDF';
            } else if (ext == 'JPG' || ext == 'JPEG') {
              selectedFileType = 'JPG';
            } else if (ext == 'PNG') {
              selectedFileType = 'PNG';
            } else {
              selectedFileType = ext;
            }
          });
        }
      } catch (e) {
        debugPrint('File pick error: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Upload New Medical Report from PC',
            style: GoogleFonts.newsreader(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.terracottaPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PC File Picker Button
                InkWell(
                  onTap: () => doPickFile(setModalState),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: pickedFileName != null ? AppColors.sageSoft : AppColors.canvasIvory,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: pickedFileName != null ? AppColors.sageSecondary : AppColors.sandalwoodGold,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pickedFileName != null ? Icons.check_circle : Icons.laptop_mac,
                          color: pickedFileName != null ? AppColors.sageSecondary : AppColors.terracottaPrimary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pickedFileName != null ? 'Selected File from PC:' : 'Choose File from PC / Local Drive',
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.charcoalText,
                                ),
                              ),
                              Text(
                                pickedFileName != null
                                    ? '$pickedFileName (${((pickedFileSize ?? 0) / 1024).toStringAsFixed(1)} KB)'
                                    : 'Click to open file explorer (PDF, JPG, PNG)',
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => doPickFile(setModalState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracottaPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Browse PC'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Report Title (Required)',
                    hintText: 'e.g. Neurology MRI Scan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Report Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Medical Report', child: Text('Neurology / Blood Test Report')),
                    DropdownMenuItem(value: 'Prescription', child: Text('Medication Prescription')),
                    DropdownMenuItem(value: 'Doctor Note', child: Text('Consultation Note')),
                  ],
                  onChanged: (v) {
                    if (v != null) selectedCategory = v;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedFileType,
                  decoration: InputDecoration(
                    labelText: 'File Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PDF', child: Text('PDF Document (.pdf)')),
                    DropdownMenuItem(value: 'JPG', child: Text('JPEG Image (.jpg)')),
                    DropdownMenuItem(value: 'PNG', child: Text('PNG Image (.png)')),
                  ],
                  onChanged: (v) {
                    if (v != null) selectedFileType = v;
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Clinical Notes / Doctor Instructions',
                    hintText: 'e.g. Follow-up after 3 weeks',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading
                  ? null
                  : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.pop(context);
                    },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracottaPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isUploading
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a report title or choose a file.')),
                        );
                        return;
                      }

                      FocusManager.instance.primaryFocus?.unfocus();
                      setModalState(() {
                        isUploading = true;
                      });

                      try {
                        await MedicalReportService().uploadReport(
                          title: title,
                          category: selectedCategory,
                          fileType: selectedFileType,
                          notes: notesController.text.trim().isEmpty ? 'Uploaded medical record.' : notesController.text.trim(),
                          fileBytes: pickedBytes,
                          originalFileName: pickedFileName,
                          fileSize: pickedFileSize,
                        );

                        if (context.mounted) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.pop(context);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Medical report uploaded and saved successfully!')),
                          );
                        }
                      } catch (e) {
                        setModalState(() {
                          isUploading = false;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Upload failed: $e')),
                          );
                        }
                      }
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Upload Report'),
            ),
          ],
        ),
      ),
    ).then((_) {
      titleController.dispose();
      notesController.dispose();
    });
  }

  void _confirmDelete(BuildContext context, PatientFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medical Report?'),
        content: Text('Are you sure you want to delete "${file.title}"? Both database record and storage file will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await MedicalReportService().deleteReport(file.id);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medical report deleted.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final reports = MedicalReportService().getReports();

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoalText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Medical Reports Hub',
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Patient Information Header Card ───────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.terracottaPrimary.withValues(alpha: 0.2)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.terracottaSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: AppColors.terracottaPrimary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.userName,
                              style: GoogleFonts.newsreader(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoalText,
                              ),
                            ),
                            Text(
                              'Patient ID: ${appState.credentialId} • Senior Care Plan',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoDetail(
                          'Age / DOB',
                          appState.userAge != null ? '${appState.userAge} Yrs' : 'Not provided',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoDetail(
                          'Language',
                          appState.selectedLanguage.toUpperCase() == 'HI'
                              ? 'Hindi'
                              : (appState.selectedLanguage.toUpperCase() == 'EN'
                                  ? 'English'
                                  : appState.selectedLanguage.toUpperCase()),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoDetail(
                          'Emergency Contact',
                          appState.emergencyContact?.isNotEmpty == true
                              ? appState.emergencyContact!
                              : 'Not provided',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 2. Drag and Drop File Upload Zone ────────────────────
            InkWell(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                _openUploadModal(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: _isDragging ? AppColors.terracottaSoft : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDragging ? AppColors.terracottaPrimary : AppColors.sandalwoodGold,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: _isDragging ? AppColors.terracottaPrimary : AppColors.sageSecondary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Drag & Drop your Medical Report here',
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supported formats: PDF, JPG, JPEG, PNG (Click to browse file)',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openUploadModal(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Medical Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracottaPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── 3. Medical Reports List Section ──────────────────────
            Row(
              children: [
                const Icon(Icons.folder_shared_rounded, color: AppColors.terracottaPrimary),
                const SizedBox(width: 8),
                Text(
                  'SAVED MEDICAL REPORTS (${reports.length})',
                  style: GoogleFonts.newsreader(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (reports.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('No medical reports uploaded yet.')),
              )
            else
              Column(
                children: reports.map((file) {
                  final isPdf = file.fileType.toUpperCase() == 'PDF';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isPdf ? Colors.redAccent.withOpacity(0.1) : AppColors.sageSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPdf ? Icons.picture_as_pdf : Icons.image,
                              color: isPdf ? Colors.redAccent : AppColors.sageSecondary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.title,
                                  style: GoogleFonts.newsreader(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.charcoalText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Category: ${file.category} • Uploaded: ${file.uploadDate.toString().split(' ')[0]}',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  file.notes,
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 13,
                                    color: AppColors.charcoalText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => PDFViewerDialog(file: file),
                              );
                            },
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.sageSecondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(context, file),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoalText,
          ),
        ),
      ],
    );
  }
}
