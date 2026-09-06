import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_info.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class DocumentViewerScreen extends StatefulWidget {
  final PatientFile file;

  const DocumentViewerScreen({super.key, required this.file});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late TextEditingController _notesController;
  late PatientFile _currentFile;
  bool _isEditingNotes = false;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.file;
    _notesController = TextEditingController(text: _currentFile.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, AppState appState) {
    SoundService().playTapSound();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Document?', style: GoogleFonts.newsreader(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${_currentFile.title}" from local DBMS storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              appState.patientFileRepo.deleteFile(_currentFile.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document deleted from DBMS storage.')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _saveNotes(AppState appState) {
    final updated = PatientFile(
      id: _currentFile.id,
      title: _currentFile.title,
      category: _currentFile.category,
      uploadDate: _currentFile.uploadDate,
      fileType: _currentFile.fileType,
      notes: _notesController.text.trim(),
      localPath: _currentFile.localPath,
    );

    setState(() {
      _currentFile = updated;
      _isEditingNotes = false;
    });

    DbService().savePatientFile(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document notes updated and saved into local DBMS database.'),
        backgroundColor: AppColors.sageSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

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
          'Document Reader & Viewer',
          style: GoogleFonts.newsreader(
            color: AppColors.charcoalText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Document',
            onPressed: () => _confirmDelete(context, appState),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.terracottaPrimary),
            tooltip: 'Print / Save PDF',
            onPressed: () {
              SoundService().playTapSound();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document exported to local print spooler / PDF.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.storage, color: AppColors.sageSecondary),
            tooltip: 'View Raw DBMS Record',
            onPressed: () => _showSqlDataModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Document Header Tag
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _currentFile.fileType == 'PDF'
                        ? Colors.red.shade100
                        : AppColors.sageSecondary.withValues(alpha: 0.2),
                    child: Icon(
                      _currentFile.fileType == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                      color: _currentFile.fileType == 'PDF' ? Colors.red.shade700 : AppColors.sageSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentFile.title,
                          style: GoogleFonts.newsreader(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Category: ${_currentFile.category} • Format: ${_currentFile.fileType}',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        Text(
                          'Uploaded: ${_currentFile.uploadDate.day}/${_currentFile.uploadDate.month}/${_currentFile.uploadDate.year}',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 12,
                            color: AppColors.sageSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Realistic Document Content Reader Canvas
            Card(
              elevation: 2,
              shadowColor: Colors.black12,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildDocumentContentCanvas(appState),
              ),
            ),

            const SizedBox(height: 20),

            // Caregiver Notes Section
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Caregiver & Physician Notes',
                          style: GoogleFonts.newsreader(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isEditingNotes ? Icons.check_circle : Icons.edit,
                            color: AppColors.terracottaPrimary,
                          ),
                          onPressed: () {
                            if (_isEditingNotes) {
                              _saveNotes(appState);
                            } else {
                              setState(() => _isEditingNotes = true);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditingNotes)
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter clinical observations or medicine reminders...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: AppColors.canvasIvory,
                        ),
                      )
                    else
                      Text(
                        _currentFile.notes.isEmpty
                            ? 'No caregiver notes added. Tap the edit icon to add notes.'
                            : _currentFile.notes,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 15,
                          color: AppColors.charcoalText,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentContentCanvas(AppState appState) {
    if (_currentFile.category == 'Prescription') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical Header Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CITY WELLNESS CLINIC',
                    style: GoogleFonts.newsreader(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.terracottaPrimary,
                    ),
                  ),
                  Text(
                    'Dr. A. K. Sharma, MD (Neurology)',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: AppColors.secondaryText),
                  ),
                  Text(
                    'Reg No: MCI-2018-84729',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 11, color: AppColors.secondaryText),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sageSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rx OFFICIAL',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontWeight: FontWeight.bold,
                    color: AppColors.sageSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1.2),

          Text(
            'Patient Name: ${appState.userName}',
            style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            'Date: ${_currentFile.uploadDate.day}/${_currentFile.uploadDate.month}/${_currentFile.uploadDate.year}',
            style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),

          Text('Prescribed Dosage & Schedule:', style: GoogleFonts.newsreader(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Table(
            border: TableBorder.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.4), width: 1),
            children: const [
              TableRow(
                decoration: BoxDecoration(color: AppColors.canvasIvory),
                children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Medicine', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Dosage', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Timing', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Donepezil 5mg')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('1 Tablet')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Night after dinner')),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Multivitamin B12')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('1 Capsule')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Morning after breakfast')),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Amlodipine 5mg')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('1 Tablet')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Morning 8:00 AM')),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              appState.speak(
                'Prescription summary for ${appState.userName}. Take Donepezil 5mg one tablet at night after dinner. Take Multivitamin B12 one capsule in the morning.',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reading prescription dosage instructions aloud...')),
              );
            },
            icon: const Icon(Icons.volume_up, color: Colors.white),
            label: const Text('Read Prescription Aloud'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracottaPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    } else {
      // PDF / Lab Medical Report Viewer
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SMRITI DIAGNOSTICS & COGNITIVE LABS',
                style: GoogleFonts.newsreader(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sageSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('VERIFIED REPORT', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            'Patient Medical Summary & Cognitive Test Baseline',
            style: GoogleFonts.newsreader(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoalText),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.canvasIvory,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildReportRow('Patient ID:', appState.credentialId),
                _buildReportRow('Patient Name:', appState.userName),
                _buildReportRow('Assessing Physician:', 'Dr. A. K. Sharma'),
                _buildReportRow('Cognitive Baseline:', 'MMSE 26/30 (Mild Recall Assistance)'),
                _buildReportRow('Serum Vitamin B12:', '485 pg/mL (Normal Range)'),
                _buildReportRow('Fasting Blood Glucose:', '104 mg/dL'),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Physician Assessment Summary:',
            style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Patient exhibits intact procedural and auditory memory. Recommended daily practice with Smriti Veda cognitive exercises (Sequence Recall, Object Recall, and Gayatri/Mahamrityunjaya chanting) for 20 minutes daily.',
            style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.secondaryText),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Page 1 of 1', style: GoogleFonts.atkinsonHyperlegible(fontSize: 12, color: AppColors.secondaryText)),
              Row(
                children: const [
                  Icon(Icons.zoom_in, color: AppColors.terracottaPrimary, size: 20),
                  SizedBox(width: 12),
                  Icon(Icons.download_outlined, color: AppColors.terracottaPrimary, size: 20),
                ],
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.atkinsonHyperlegible(color: AppColors.secondaryText, fontSize: 13)),
          Text(value, style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoalText)),
        ],
      ),
    );
  }

  void _showSqlDataModal(BuildContext context) {
    final db = DbService();
    final recordMap = db.getPatientFileAsSqlRecord(_currentFile.id);
    final rawJson = recordMap != null
        ? const JsonEncoder.withIndent('  ').convert(recordMap)
        : '{"status": "Record not found in local DBMS for current user"}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.charcoalText,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Text(
                  'DBMS SQL Record View',
                  style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            Text(
              'Executed Query:',
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 12, color: Colors.greenAccent),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                "SELECT * FROM patient_files WHERE id = '${_currentFile.id}';",
                style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'SQL Table Record Result:',
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 12, color: Colors.white70),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                rawJson,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.amberAccent, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
