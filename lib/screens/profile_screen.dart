import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/everyday_memory.dart';
import '../models/patient_info.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/pc_file_picker.dart';
import 'document_viewer_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _doctorController = TextEditingController();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _docTitleController = TextEditingController();
  final _docCategoryController = TextEditingController();

  bool _isEditingProfile = false;
  final _editNameController = TextEditingController();
  final _editAgeController = TextEditingController();
  final _editContactController = TextEditingController();
  String _editLanguage = 'hi';
  String _selectedFileType = 'PDF';

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));

  String _getLanguageName(String code) {
    switch (code) {
      case 'te': return 'Telugu 🇮🇳';
      case 'hi': return 'Hindi 🇮🇳';
      case 'ta': return 'Tamil 🇮🇳';
      case 'as': return 'Assamese 🇮🇳';
      case 'bn': return 'Bengali 🇮🇳';
      case 'en': return 'English / Family 🏡';
      case 'sa': return 'Sanskrit 📜';
      default: return 'English';
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _docTitleController.dispose();
    _docCategoryController.dispose();
    _editNameController.dispose();
    _editAgeController.dispose();
    _editContactController.dispose();
    super.dispose();
  }

  void _showAddRelativeDialog(AppState appState) {
    final relName = TextEditingController();
    final relRelation = TextEditingController();
    final relNotes = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Family Relative', style: GoogleFonts.newsreader(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: relName,
                decoration: const InputDecoration(labelText: 'Relative Full Name'),
              ),
              TextField(
                controller: relRelation,
                decoration: const InputDecoration(labelText: 'Relationship (e.g. Daughter, Son, Sister)'),
              ),
              TextField(
                controller: relNotes,
                decoration: const InputDecoration(labelText: 'Personal Memory Note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracottaPrimary),
            onPressed: () {
              if (relName.text.trim().isNotEmpty && relRelation.text.trim().isNotEmpty) {
                FocusManager.instance.primaryFocus?.unfocus();
                SoundService().playTapSound();
                final name = relName.text.trim();
                final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
                appState.addFamiliarPerson(
                  FamiliarPerson(
                    id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    relationship: relRelation.text.trim(),
                    note: relNotes.text.trim().isEmpty ? 'Family relative' : relNotes.text.trim(),
                    avatarColor: AppColors.terracottaPrimary,
                    initials: initials,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Save Relative', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((_) {
      relName.dispose();
      relRelation.dispose();
      relNotes.dispose();
    });
  }

  void _showAddAppointmentDialog(AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Schedule Appointment', style: GoogleFonts.newsreader(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title (e.g. Neurology Consultation)'),
              ),
              TextField(
                controller: _doctorController,
                decoration: const InputDecoration(labelText: 'Doctor / Provider Name'),
              ),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location / Hospital'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: const Text('Select Date'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracottaPrimary),
            onPressed: () {
              if (_titleController.text.isNotEmpty && _doctorController.text.isNotEmpty) {
                FocusManager.instance.primaryFocus?.unfocus();
                appState.appointmentRepo.addAppointment(
                  Appointment(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _titleController.text,
                    doctorName: _doctorController.text,
                    date: _selectedDate,
                    time: const TimeOfDay(hour: 10, minute: 30),
                    location: _locationController.text.isEmpty ? 'City Clinic' : _locationController.text,
                  ),
                );
                _titleController.clear();
                _doctorController.clear();
                _locationController.clear();
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentDialog(AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Select & Attach System File', style: GoogleFonts.newsreader(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose document type to pick from system:',
                  style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Medical Report'),
                      selected: _docCategoryController.text == 'Medical Report' || _docCategoryController.text.isEmpty,
                      onSelected: (_) {
                        setDialogState(() {
                          _docCategoryController.text = 'Medical Report';
                          _docTitleController.text = 'Blood & Lipid Panel Report.pdf';
                          _selectedFileType = 'PDF';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Prescription'),
                      selected: _docCategoryController.text == 'Prescription',
                      onSelected: (_) {
                        setDialogState(() {
                          _docCategoryController.text = 'Prescription';
                          _docTitleController.text = 'Dr_Sharma_Prescription_Sept.jpg';
                          _selectedFileType = 'Image';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Lab Scan'),
                      selected: _docCategoryController.text == 'Lab Scan',
                      onSelected: (_) {
                        setDialogState(() {
                          _docCategoryController.text = 'Lab Scan';
                          _docTitleController.text = 'Brain_MRI_Scan_Report.pdf';
                          _selectedFileType = 'PDF';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _docTitleController,
                  decoration: const InputDecoration(
                    labelText: 'System File Name / Document Title',
                    prefixIcon: Icon(Icons.attach_file, color: AppColors.terracottaPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sageSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open, color: AppColors.sageSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'System Location: LocalStorage/Documents/${_docTitleController.text.isEmpty ? "document.pdf" : _docTitleController.text}',
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 12, color: AppColors.charcoalText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Attach System Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracottaPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_docTitleController.text.isNotEmpty) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  appState.patientFileRepo.addFile(
                    PatientFile(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _docTitleController.text,
                      category: _docCategoryController.text.isEmpty ? 'Medical Report' : _docCategoryController.text,
                      uploadDate: DateTime.now(),
                      fileType: _selectedFileType,
                      localPath: 'documents/${_docTitleController.text.replaceAll(' ', '_')}.${_selectedFileType.toLowerCase()}',
                    ),
                  );
                  _docTitleController.clear();
                  _docCategoryController.clear();
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPickerModal(BuildContext context, AppState appState) {
    final avatarEmojis = ['👴', '👵', '📜', '🩺', '🪷', '🌸', '🎨', '🕉️', '🧘‍♂️', '👑', '🌟'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Customize Profile Avatar & Photo',
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Pick Built-in Avatar Icon:',
                style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: avatarEmojis.map((emoji) {
                  final isSelected = appState.customProfileImageBytes == null && appState.profileAvatarEmoji == emoji;
                  return InkWell(
                    onTap: () {
                      SoundService().playTapSound();
                      appState.setProfileAvatarEmoji(emoji);
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.terracottaSoft : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.terracottaPrimary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                '2. Or Upload Custom Photo from PC:',
                style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageSecondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.photo_library),
                label: const Text('Browse Photo from PC / Device'),
                onPressed: () async {
                  final picked = await PcFilePicker.pickFileFromPc();
                  if (picked != null && picked.bytes != null) {
                    SoundService.playSuccess();
                    appState.setCustomProfileImageBytes(picked.bytes);
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final user = appState.activeUser;
    final isCaregiver = appState.isCaregiverMode;

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
          'Profile & Settings',
          style: GoogleFonts.newsreader(
            color: AppColors.charcoalText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header & Editable Profile Card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _isEditingProfile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Profile Information',
                            style: GoogleFonts.newsreader(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.terracottaPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _editNameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _editAgeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age (Years)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _editLanguage,
                            decoration: InputDecoration(
                              labelText: 'Preferred Language',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'hi', child: Text('🇮🇳 Hindi')),
                              DropdownMenuItem(value: 'te', child: Text('🇮🇳 Telugu')),
                              DropdownMenuItem(value: 'ta', child: Text('🇮🇳 Tamil')),
                              DropdownMenuItem(value: 'as', child: Text('🇮🇳 Assamese')),
                              DropdownMenuItem(value: 'bn', child: Text('🇮🇳 Bengali')),
                              DropdownMenuItem(value: 'en', child: Text('🏡 English / Family')),
                              DropdownMenuItem(value: 'sa', child: Text('📜 Sanskrit Traditional')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _editLanguage = v);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _editContactController,
                            decoration: InputDecoration(
                              labelText: 'Emergency Contact Phone',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  setState(() => _isEditingProfile = false);
                                },
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.terracottaPrimary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  final newName = _editNameController.text.trim();
                                  final newAge = int.tryParse(_editAgeController.text.trim()) ?? ((appState.userAge ?? 0) > 0 ? (appState.userAge ?? 0) : 0);
                                  final newContact = _editContactController.text.trim();

                                  DbService().saveUserProfile(
                                    name: newName,
                                    role: user.isCaregiver ? 'Caregiver' : 'Patient',
                                    credentialId: user.id,
                                    language: _editLanguage,
                                    age: newAge,
                                    emergencyContact: newContact,
                                  );

                                  appState.login(
                                    name: newName,
                                    credentialId: user.id,
                                    role: user.isCaregiver ? 'Caregiver' : 'Patient',
                                    language: _editLanguage,
                                  );

                                  setState(() => _isEditingProfile = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile changes saved successfully!')),
                                  );
                                },
                                child: const Text('Save Changes'),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showAvatarPickerModal(context, appState),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 38,
                                  backgroundColor: AppColors.terracottaPrimary,
                                  backgroundImage: appState.customProfileImageBytes != null
                                      ? MemoryImage(appState.customProfileImageBytes!)
                                      : null,
                                  child: appState.customProfileImageBytes == null
                                      ? Text(
                                          appState.profileAvatarEmoji,
                                          style: const TextStyle(fontSize: 32),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.sandalwoodGold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: GoogleFonts.newsreader(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.charcoalText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Role: ${isCaregiver ? "Caregiver / Guardian" : "Patient User"}',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 15,
                                    color: AppColors.sageSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Language: ${_getLanguageName(appState.selectedLanguage)}',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 14,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.terracottaPrimary),
                            tooltip: 'Edit Profile',
                            onPressed: () {
                              final profileData = DbService().getUserProfile() ?? {};
                              _editNameController.text = user.name;
                              _editAgeController.text = (profileData['age'] != null && profileData['age'] != 0) ? '${profileData['age']}' : (((appState.userAge ?? 0) > 0) ? '${appState.userAge}' : '');
                              _editContactController.text = profileData['emergencyContact'] ?? appState.emergencyContact;
                              _editLanguage = appState.selectedLanguage;
                              setState(() => _isEditingProfile = true);
                            },
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Role Switcher Card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account & Role Mode',
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      activeThumbColor: AppColors.terracottaPrimary,
                      title: Text(
                        'Caregiver Dashboard Mode',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Switch view to monitor patient activity logs and trends'),
                      value: isCaregiver,
                      onChanged: (val) {
                        appState.setCaregiverMode(val);
                        setState(() {});
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.terracottaPrimary),
                      title: const Text('Switch User / Sign Out'),
                      onTap: () {
                        Navigator.pop(context);
                        appState.logout();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Family Members & Relatives Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Family Members & Relatives',
                  style: GoogleFonts.newsreader(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddRelativeDialog(appState),
                  icon: const Icon(Icons.person_add, color: AppColors.terracottaPrimary),
                  label: const Text('Add Relative', style: TextStyle(color: AppColors.terracottaPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Builder(
              builder: (context) {
                final relatives = appState.familiarPeople;
                if (relatives.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'No family members added. Tap Add Relative to enter real family details.',
                      style: GoogleFonts.atkinsonHyperlegible(color: AppColors.secondaryText),
                    ),
                  );
                }

                return Column(
                  children: relatives.map((rel) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.terracottaPrimary.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rel.avatarColor,
                          child: Text(rel.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          '${rel.name} (${rel.relationship})',
                          style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(rel.note),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            SoundService().playTapSound();
                            appState.deleteFamiliarPerson(rel.id);
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Appointments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Appointments',
                  style: GoogleFonts.newsreader(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddAppointmentDialog(appState),
                  icon: const Icon(Icons.add, color: AppColors.terracottaPrimary),
                  label: const Text('Schedule', style: TextStyle(color: AppColors.terracottaPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Builder(
              builder: (context) {
                final appointments = appState.appointmentRepo.getAppointments();
                if (appointments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'No appointments scheduled.',
                      style: GoogleFonts.atkinsonHyperlegible(color: AppColors.secondaryText),
                    ),
                  );
                }

                return Column(
                  children: appointments.map((app) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.canvasIvory,
                          child: Icon(Icons.calendar_month, color: AppColors.terracottaPrimary),
                        ),
                        title: Text(
                          app.title,
                          style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${app.doctorName} • ${app.location}\n${app.date.day}/${app.date.month}/${app.date.year}'),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Patient Files & Documents Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patient Documents',
                  style: GoogleFonts.newsreader(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoalText,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddDocumentDialog(appState),
                  icon: const Icon(Icons.upload_file, color: AppColors.terracottaPrimary),
                  label: const Text('Add System File', style: TextStyle(color: AppColors.terracottaPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Builder(
              builder: (context) {
                final files = appState.patientFileRepo.getFiles();
                if (files.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'No medical reports or documents added yet.',
                      style: GoogleFonts.atkinsonHyperlegible(color: AppColors.secondaryText),
                    ),
                  );
                }

                return Column(
                  children: files.map((file) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.canvasIvory,
                          child: Icon(Icons.description, color: AppColors.sageSecondary),
                        ),
                        title: Text(
                          file.title,
                          style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Category: ${file.category} • Uploaded: ${file.uploadDate.day}/${file.uploadDate.month}/${file.uploadDate.year}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                SoundService().playTapSound();
                                appState.patientFileRepo.deleteFile(file.id);
                                setState(() {});
                              },
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DocumentViewerScreen(file: file),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
