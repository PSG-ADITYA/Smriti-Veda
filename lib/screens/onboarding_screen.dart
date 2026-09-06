import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/everyday_memory.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0; // 0 to 5 (6 steps total)

  // Form Controllers
  final _nameController = TextEditingController(text: 'Dadi Ma / Grandpa');
  final _credentialController = TextEditingController(text: 'patient123');
  final _ageController = TextEditingController(text: '72');
  final _emergencyContactController = TextEditingController(text: '+91 98765 43210');
  final _medicalNotesController = TextEditingController(text: 'Mild memory recall support; active daily routine.');
  final _geminiApiKeyController = TextEditingController(text: 'AIzaSyDemoKeySmriti2026');

  // Relatives Form Controllers
  final _relNameController = TextEditingController();
  final _relRelationController = TextEditingController();
  final _relNotesController = TextEditingController();

  final List<FamiliarPerson> _addedRelatives = [
    FamiliarPerson(
      id: 'rel_1',
      name: 'Lakshmi',
      relationship: 'Daughter',
      note: 'Lives in Bengaluru. Calls every Sunday morning. Loves classical music.',
      avatarColor: const Color(0xFFB85028),
      initials: 'LK',
    ),
    FamiliarPerson(
      id: 'rel_2',
      name: 'Ravi',
      relationship: 'Son',
      note: 'Works in tech. Visits on weekends with sweets.',
      avatarColor: const Color(0xFF3D6B58),
      initials: 'RV',
    ),
  ];

  String _selectedRole = 'Patient';
  final String _selectedLanguage = 'en';
  bool _enableAiFeatures = true;
  double _fontScalePreference = 1.2;
  bool _readAloudPreference = true;
  String _selectedProfileAvatar = 'avatar_1';

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _nameController.dispose();
    _credentialController.dispose();
    _ageController.dispose();
    _emergencyContactController.dispose();
    _medicalNotesController.dispose();
    _geminiApiKeyController.dispose();
    _relNameController.dispose();
    _relRelationController.dispose();
    _relNotesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    SoundService().playTapSound();
    setState(() {
      if (_currentStep < 5) {
        _currentStep++;
      }
    });
  }

  void _prevStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    SoundService().playTapSound();
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  void _addRelative() {
    if (_relNameController.text.trim().isNotEmpty && _relRelationController.text.trim().isNotEmpty) {
      SoundService().playTapSound();
      final name = _relNameController.text.trim();
      final rel = _relRelationController.text.trim();
      final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();

      setState(() {
        _addedRelatives.add(
          FamiliarPerson(
            id: 'rel_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            relationship: rel,
            note: _relNotesController.text.trim().isEmpty ? 'Family relative of patient' : _relNotesController.text.trim(),
            avatarColor: AppColors.terracottaPrimary,
            initials: initials,
          ),
        );
        _relNameController.clear();
        _relRelationController.clear();
        _relNotesController.clear();
      });
    }
  }

  void _completeOnboarding(AppState appState) {
    FocusManager.instance.primaryFocus?.unfocus();
    SoundService().playFanfareSound();
    final db = DbService();
    final credId = _credentialController.text.trim();
    db.saveUserProfile(
      name: _nameController.text,
      role: _selectedRole,
      credentialId: credId,
      language: _selectedLanguage,
      age: int.tryParse(_ageController.text) ?? 70,
      emergencyContact: _emergencyContactController.text,
      medicalNotes: _medicalNotesController.text,
    );

    db.saveAiConfig(
      apiKey: _geminiApiKeyController.text,
      isAiEnabled: _enableAiFeatures,
    );

    for (var rel in _addedRelatives) {
      appState.addFamiliarPerson(rel);
    }

    db.setOnboarded(true, credId.isNotEmpty ? credId : null);

    appState.login(
      name: _nameController.text,
      credentialId: _credentialController.text,
      role: _selectedRole,
      language: _selectedLanguage,
    );
    appState.setFontScale(_fontScalePreference);

    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        title: Text(
          'Smriti Veda Onboarding Wizard',
          style: GoogleFonts.newsreader(
            color: AppColors.terracottaPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          // Step Progress Bar (6 Steps)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: List.generate(6, (idx) {
                final isCompleted = idx <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.terracottaPrimary : AppColors.sandalwoodGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStepHeader(),
                  const SizedBox(height: 20),
                  _buildStepBody(appState),
                ],
              ),
            ),
          ),

          // Bottom Stepper Controls
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.charcoalText,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep == 5 ? () => _completeOnboarding(appState) : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracottaPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _currentStep == 5 ? 'Launch Smriti Veda Platform ➔' : 'Continue ➔',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    final titles = [
      'Welcome & Role Selection',
      'Patient Profile & Avatar Picture',
      'Family Relatives & Memory Details',
      'Accessibility & Voice Preferences',
      'AI Setup & Gemini Configuration',
      'Database Confirmation & Setup',
    ];

    final subtitles = [
      'Choose whether you are setting up as a Senior Patient or Caregiver.',
      'Enter patient demographics, emergency contacts, and select profile picture.',
      'Enter real names of family members & relatives to personalize recall games.',
      'Configure font scaling, read aloud voice preferences, and controls.',
      'Configure Gemini AI API Key for personalized AI game creation & caregiver notes.',
      'Review settings and save to local DBMS storage engine.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP ${_currentStep + 1} OF 6',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: AppColors.sageSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titles[_currentStep],
          style: GoogleFonts.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitles[_currentStep],
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildStepBody(AppState appState) {
    return KeyedSubtree(
      key: ValueKey(_currentStep),
      child: _getStepContent(appState),
    );
  }

  Widget _getStepContent(AppState appState) {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            Center(
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 100,
                height: 100,
                errorBuilder: (_, __, ___) => const Icon(Icons.psychology, size: 80, color: AppColors.terracottaPrimary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Primary Role:',
              style: GoogleFonts.newsreader(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRoleCard(
                    role: 'Patient',
                    title: 'Senior Patient',
                    subtitle: 'Cognitive Memory Exercises',
                    icon: Icons.elderly,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRoleCard(
                    role: 'Caregiver',
                    title: 'Caregiver / Doctor',
                    subtitle: 'Progress Telemetry & Notes',
                    icon: Icons.family_restroom,
                  ),
                ),
              ],
            ),
          ],
        );
      case 1:
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Profile Avatar Picture:', style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAvatarOption('avatar_1', Icons.person, AppColors.terracottaPrimary),
                    _buildAvatarOption('avatar_2', Icons.elderly, AppColors.sageSecondary),
                    _buildAvatarOption('avatar_3', Icons.face_retouching_natural, AppColors.sandalwoodGold),
                    _buildAvatarOption('avatar_4', Icons.account_circle, Colors.deepPurple),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.terracottaPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age (Years)',
                    prefixIcon: Icon(Icons.cake_outlined, color: AppColors.terracottaPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emergencyContactController,
                  decoration: const InputDecoration(labelText: 'Emergency Family Phone Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _medicalNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Medical & Memory Recall Notes'),
                ),
              ],
            ),
          ),
        );
      case 2:
        return Column(
          children: [
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Real Family Member / Relative:', style: GoogleFonts.newsreader(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _relNameController,
                      decoration: const InputDecoration(labelText: 'Relative Name (e.g. Lakshmi, Ramesh)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _relRelationController,
                      decoration: const InputDecoration(labelText: 'Relationship (e.g. Daughter, Grandson, Brother)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _relNotesController,
                      decoration: const InputDecoration(labelText: 'Personal Memory Note (e.g. Calls every Sunday)'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addRelative,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Relative to DBMS Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sageSecondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Saved Family Members (${_addedRelatives.length}):', style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: _addedRelatives.map((rel) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rel.avatarColor,
                      child: Text(rel.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${rel.name} (${rel.relationship})', style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold)),
                    subtitle: Text(rel.note),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        SoundService().playTapSound();
                        setState(() => _addedRelatives.removeWhere((r) => r.id == rel.id));
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      case 3:
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Text Size Scale: ${_fontScalePreference.toStringAsFixed(1)}x', style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold)),
                Slider(
                  value: _fontScalePreference,
                  min: 1.0,
                  max: 1.6,
                  divisions: 6,
                  activeColor: AppColors.terracottaPrimary,
                  onChanged: (val) => setState(() => _fontScalePreference = val),
                ),
                const Divider(),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    activeThumbColor: AppColors.terracottaPrimary,
                    title: const Text('Read Aloud Voice Support'),
                    subtitle: const Text('Automatically offer voice reading for instructions'),
                    value: _readAloudPreference,
                    onChanged: (val) => setState(() => _readAloudPreference = val),
                  ),
                ),
              ],
            ),
          ),
        );
      case 4:
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    activeThumbColor: AppColors.terracottaPrimary,
                    title: Text('Enable Gemini AI Engine', style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold)),
                    subtitle: const Text('AI personalized activity recommendations and caregiver progress notes'),
                    value: _enableAiFeatures,
                    onChanged: (val) => setState(() => _enableAiFeatures = val),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.sageSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: AppColors.sageSecondary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Gemini GenAI is configured by Smriti Veda environment. Your personal health profile stays strictly confidential.',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 12,
                            color: AppColors.charcoalText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case 5:
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.terracottaPrimary.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.storage, size: 48, color: AppColors.terracottaPrimary),
                const SizedBox(height: 12),
                Text('DBMS Profile Confirmation', style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Name: ${_nameController.text}'),
                Text('Role: $_selectedRole'),
                Text('Age: ${_ageController.text}'),
                Text('Emergency Contact: ${_emergencyContactController.text}'),
                Text('Family Relatives: ${_addedRelatives.map((r) => r.name).join(", ")}'),
                Text('AI Status: ${_enableAiFeatures ? "Enabled (Gemini active)" : "Disabled (Offline fallback)"}'),
                const Divider(height: 24),
                Text('All parameters will be saved into local persistent DBMS storage.', style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: AppColors.secondaryText)),
              ],
            ),
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildAvatarOption(String avatarId, IconData icon, Color color) {
    final isSelected = _selectedProfileAvatar == avatarId;
    return GestureDetector(
      onTap: () {
        SoundService().playTapSound();
        setState(() => _selectedProfileAvatar = avatarId);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 3),
        ),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    final color = role == 'Patient' ? AppColors.terracottaPrimary : AppColors.sageSecondary;

    return GestureDetector(
      onTap: () {
        SoundService().playTapSound();
        setState(() => _selectedRole = role);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.canvasIvory,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.sandalwoodGold.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.secondaryText, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.charcoalText,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 11, color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
