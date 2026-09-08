import '../models/connected_senior.dart';
import '../services/caregiver_service.dart';
import 'caregiver_dashboard_screen.dart';
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
    String? pickedFilePath;
    int? pickedFileSize;
    String uploadStatus = 'idle'; // 'idle', 'uploading', 'complete'

    String formatFileSize(int bytes) {
      if (bytes <= 0) return '0 B';
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    Future<void> doPickFile(StateSetter setModalState) async {
      try {
        final picked = await PcFilePicker.pickFileFromPc();
        if (picked != null) {
          setModalState(() {
            pickedBytes = picked.bytes;
            pickedFileName = picked.name;
            pickedFilePath = picked.path;
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
            'Upload Medical Report & Records',
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
                // Local Storage File Picker - Responsive Horizontal Flex Layout
                if (pickedFileName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.canvasIvory,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sageSecondary, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedFileType == 'PDF'
                                ? Colors.redAccent.withValues(alpha: 0.1)
                                : AppColors.sageSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            selectedFileType == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                            color: selectedFileType == 'PDF' ? Colors.redAccent : AppColors.sageSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                pickedFileName!,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.charcoalText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatFileSize(pickedFileSize ?? 0),
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => doPickFile(setModalState),
                          icon: const Icon(Icons.change_circle_outlined, size: 16),
                          label: const Text('Change', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.terracottaPrimary,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Remove file',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setModalState(() {
                              pickedBytes = null;
                              pickedFileName = null;
                              pickedFilePath = null;
                              pickedFileSize = null;
                              titleController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: () => doPickFile(setModalState),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.canvasIvory,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.sandalwoodGold, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.folder_open_rounded,
                            color: AppColors.terracottaPrimary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose File from Local Storage',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.charcoalText,
                                  ),
                                ),
                                Text(
                                  'Tap to select PDF, JPG, or PNG document',
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
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => doPickFile(setModalState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.terracottaPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Browse'),
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
              onPressed: uploadStatus != 'idle'
                  ? null
                  : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.pop(context);
                    },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: uploadStatus == 'complete'
                    ? AppColors.sageSecondary
                    : AppColors.terracottaPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: uploadStatus != 'idle'
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
                        uploadStatus = 'uploading';
                      });

                      try {
                        await MedicalReportService().uploadReport(
                          title: title,
                          category: selectedCategory,
                          fileType: selectedFileType,
                          notes: notesController.text.trim().isEmpty ? 'Uploaded medical record.' : notesController.text.trim(),
                          localPath: pickedFilePath,
                          fileBytes: pickedBytes,
                          originalFileName: pickedFileName,
                          fileSize: pickedFileSize,
                        );

                        setModalState(() {
                          uploadStatus = 'complete';
                        });

                        await Future.delayed(const Duration(milliseconds: 650));

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
                          uploadStatus = 'idle';
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unable to upload report right now. Please verify the file and try again.')),
                          );
                        }
                      }
                    },
              child: uploadStatus == 'uploading'
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Uploading...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  : uploadStatus == 'complete'
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Upload complete', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Text('Upload Report', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final isCaregiver = appState.isCaregiverMode;
    final caregiverId = appState.credentialId.isNotEmpty ? appState.credentialId : 'caregiver';
    final caregiverService = CaregiverService();

    ConnectedSenior? activeSenior;
    String targetPatientId = appState.credentialId;
    String targetPatientName = appState.userName;

    if (isCaregiver) {
      activeSenior = caregiverService.getActiveSenior(caregiverId);
      if (activeSenior != null) {
        targetPatientId = activeSenior.patientId;
        targetPatientName = activeSenior.name;
      }
    }

    final bool isUnauthorized = isCaregiver && activeSenior != null &&
        !caregiverService.isAuthorized(caregiverId, activeSenior.patientId);

    final reports = (isCaregiver && activeSenior != null && !isUnauthorized)
        ? MedicalReportService().getReports(activeSenior.patientId)
        : (isCaregiver ? <PatientFile>[] : MedicalReportService().getReports());

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.charcoalText),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Medical Reports Hub',
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
      ),
      body: (isCaregiver && activeSenior == null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 56, color: AppColors.sandalwoodGold),
                    const SizedBox(height: 16),
                    Text(
                      'No Connected Senior',
                      style: GoogleFonts.newsreader(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.charcoalText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Medical records require an authorized senior connection. Connect an elderly family member to review their prescriptions and diagnostic reports.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_link_rounded),
                      label: const Text('Connect Senior'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracottaPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(180, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => showConnectSeniorModal(context, caregiverId),
                    ),
                  ],
                ),
              ),
            )
          : (isUnauthorized)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gpp_bad_outlined, size: 56, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          'Access Denied',
                          style: GoogleFonts.newsreader(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Security Boundary: You are not authorized to view medical records for patient ID $targetPatientId.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: Colors.red.shade900),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
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
                              targetPatientName,
                              style: GoogleFonts.newsreader(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoalText,
                              ),
                            ),
                            Text(
                              'Patient ID: $targetPatientId • ${isCaregiver ? "Authorized Senior Record" : "Senior Care Plan"}',
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoDetail(
                                    'Age / DOB',
                                    appState.userAge != null ? '${appState.userAge} Yrs' : 'Not provided',
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildInfoDetail(
                              'Emergency Contact',
                              appState.emergencyContact?.isNotEmpty == true
                                  ? appState.emergencyContact!
                                  : 'Not provided',
                            ),
                          ],
                        );
                      }
                      return Row(
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
                      );
                    },
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
                Expanded(
                  child: Text(
                    'SAVED MEDICAL REPORTS (${reports.length})',
                    style: GoogleFonts.newsreader(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.terracottaPrimary,
                    ),
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
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.35)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => PDFViewerDialog(file: file),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Top Row: Thumbnail + Title/Badges + Delete ──
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPdf
                                        ? Colors.redAccent.withValues(alpha: 0.1)
                                        : AppColors.sageSecondary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isPdf ? Icons.picture_as_pdf : Icons.image,
                                    color: isPdf ? Colors.redAccent : AppColors.sageSecondary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.terracottaSoft,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              file.category,
                                              style: GoogleFonts.atkinsonHyperlegible(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.terracottaPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F1ED),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.borderSubtle),
                                            ),
                                            child: Text(
                                              file.fileType.toUpperCase(),
                                              style: GoogleFonts.atkinsonHyperlegible(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.charcoalText,
                                              ),
                                            ),
                                          ),
                                          if (file.formattedFileSize.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3F1ED),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                file.formattedFileSize,
                                                style: GoogleFonts.atkinsonHyperlegible(
                                                  fontSize: 11,
                                                  color: AppColors.secondaryText,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                  tooltip: 'Delete Report',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _confirmDelete(context, file),
                                ),
                              ],
                            ),

                            // ── Metadata: Upload Date & File Info ──
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F5F0),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.borderSubtle),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.secondaryText),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Uploaded: ${file.uploadDate.toString().split(' ')[0]}',
                                          style: GoogleFonts.atkinsonHyperlegible(
                                            fontSize: 12,
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (file.originalFileName != null &&
                                      file.originalFileName!.isNotEmpty &&
                                      file.originalFileName != file.title)
                                    Container(
                                      constraints: const BoxConstraints(maxWidth: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F5F0),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.borderSubtle),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.attach_file, size: 12, color: AppColors.secondaryText),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              file.originalFileName!,
                                              style: GoogleFonts.atkinsonHyperlegible(
                                                fontSize: 12,
                                                color: AppColors.secondaryText,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // ── Clinical Notes (If Present) ──
                            if (file.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F7F4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Text(
                                  file.notes,
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 12,
                                    color: AppColors.charcoalText,
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],

                            // ── Action Button: View Report ──
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => PDFViewerDialog(file: file),
                                  );
                                },
                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                label: Text(
                                  isPdf ? 'View PDF Document' : 'View Medical Scan',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.terracottaPrimary,
                                  side: const BorderSide(color: AppColors.terracottaPrimary, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoalText,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
      ],
    );
  }
}
