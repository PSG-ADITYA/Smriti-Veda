import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../services/gemini_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/validation_utils.dart';
import '../widgets/confetti_overlay.dart';
import 'main_screen.dart';

class PersonalizedQuestionnaireScreen extends StatefulWidget {
  final bool isInitialSetup;

  const PersonalizedQuestionnaireScreen({
    super.key,
    this.isInitialSetup = true,
  });

  @override
  State<PersonalizedQuestionnaireScreen> createState() =>
      _PersonalizedQuestionnaireScreenState();
}

class _PersonalizedQuestionnaireScreenState
    extends State<PersonalizedQuestionnaireScreen> {
  int _currentStep = 1; // 1 to 5

  // Form Controllers
  late TextEditingController _nameController;
  final _ageController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _relativesController = TextEditingController();
  final _memoriesController = TextEditingController();
  final _apiKeyController = TextEditingController();

  String _setupMode = 'Caregiver'; // 'Caregiver' or 'Patient'
  String _selectedGoal = 'Auditory Recitation & Memory Retention';
  String _selectedCountryCode = '+91';

  // Multi-Select for Languages (Sanskrit, Hindi, Telugu, etc.)
  final Set<String> _selectedLanguages = {'sa', 'hi'};

  bool _enableAi = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameController.text.isEmpty) {
      final appState = AppStateScope.of(context);
      _nameController.text = appState.userName == 'Dadi Ma / Grandpa' ? '' : appState.userName;
      if (appState.selectedLanguage.isNotEmpty) {
        _selectedLanguages.add(appState.selectedLanguage);
      }
    }
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _nameController.dispose();
    _ageController.dispose();
    _emergencyContactController.dispose();
    _relativesController.dispose();
    _memoriesController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  /// Validation method enforcing COMPULSORY fields on steps 1-4
  String? _validateCurrentStep() {
    if (_currentStep == 1) {
      if (_nameController.text.trim().isEmpty) {
        return 'Compulsory field missing: Patient Full Name is required.';
      }
      if (_ageController.text.trim().isEmpty) {
        return 'Compulsory field missing: Patient Age is required.';
      }
      final ageVal = int.tryParse(_ageController.text.trim());
      if (ageVal == null || ageVal < 40 || ageVal > 120) {
        return 'Invalid Age: Please enter a valid senior citizen age (40 - 120).';
      }
      final phoneErr = ValidationUtils.validatePhoneNumber(
        _emergencyContactController.text,
        countryCode: _selectedCountryCode,
      );
      if (phoneErr != null) {
        return phoneErr;
      }
    } else if (_currentStep == 2) {
      if (_selectedGoal.isEmpty) {
        return 'Compulsory choice missing: Please pick a primary cognitive wellness goal.';
      }
    } else if (_currentStep == 3) {
      if (_selectedLanguages.isEmpty) {
        return 'Compulsory choice missing: Please select at least 1 heritage language.';
      }
    } else if (_currentStep == 4) {
      if (_relativesController.text.trim().isEmpty) {
        return 'Compulsory field missing: Please enter family member names.';
      }
      if (_memoriesController.text.trim().isEmpty) {
        return 'Compulsory field missing: Please enter childhood memories or hobbies.';
      }
    }
    return null;
  }

  Future<void> _generateAndSavePlan(AppState appState) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isGenerating = true);
    SoundService().playClickSound();

    final name = _nameController.text.trim();
    final age = _ageController.text.trim();
    final emergency = ValidationUtils.formatPhone(
      _emergencyContactController.text,
      countryCode: _selectedCountryCode,
    );
    final relatives = _relativesController.text.trim();
    final memories = _memoriesController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isNotEmpty) {
      appState.setGeminiApiKey(apiKey);
    }
    appState.toggleAiEnabled(_enableAi);

    final primaryLangCode = _selectedLanguages.first;
    final formattedLanguages = _getFormattedLanguageNames();

    // Mark user as onboarded in DBMS so they are never redirected to questionnaire on login
    DbService().setOnboarded(true, appState.credentialId);

    // Save profile to DBMS
    DbService().saveUserProfile(
      name: name,
      role: _setupMode,
      credentialId: appState.credentialId,
      language: primaryLangCode,
      age: int.tryParse(age) ?? 70,
      emergencyContact: emergency,
      medicalNotes: '',
    );

    final geminiService = GeminiService(apiKey: apiKey.isNotEmpty ? apiKey : appState.geminiApiKey);

    final generatedPlan = await geminiService.generatePersonalizedCognitivePlan(
      patientName: name,
      age: age,
      cognitiveGoal: _selectedGoal,
      language: formattedLanguages,
      relatives: relatives,
      memoriesAndHobbies: memories,
    );

    final questionnaireData = {
      'patientName': name,
      'age': age,
      'emergencyContact': emergency,
      'setupMode': _setupMode,
      'primaryGoal': _selectedGoal,
      'preferredLanguages': _selectedLanguages.toList(),
      'relatives': relatives,
      'memoriesAndHobbies': memories,
      'aiEnabled': _enableAi,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    appState.setAiPersonalPlan(generatedPlan, questionnaireData);

    if (mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _isGenerating = false);
      ConfettiOverlay.of(context)?.triggerCelebration(
        title: 'Profile & Plan Saved! ✨',
        subtitle: 'Personalized memory regimen tailored for $name.',
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  String _getFormattedLanguageNames() {
    final Map<String, String> names = {
      'sa': 'Sanskrit Traditional Mantras',
      'hi': 'Hindi (Kabir Dohe & Folk Rhymes)',
      'te': 'Telugu (Vemana Padyalu)',
      'ta': 'Tamil (Thirukkural)',
      'as': 'Assamese Folk Poetry',
      'bn': 'Bengali (Rabindra Sangeet)',
      'en': 'English & Family Memories',
    };
    return _selectedLanguages.map((code) => names[code] ?? code).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.charcoalText),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          'Personalized Profile & Setup',
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Indicator Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP $_currentStep OF 5 (COMPULSORY QUESTIONS)',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.sageSecondary,
                        ),
                      ),
                      Text(
                        '${(_currentStep / 5.0 * 100).toInt()}% Completed',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _currentStep / 5.0,
                      minHeight: 8,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.terracottaPrimary),
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (_isGenerating)
                    _buildGeneratingOverlay()
                  else ...[
                    if (_currentStep == 1) KeyedSubtree(key: const ValueKey('step_1_demographics'), child: _buildStep1Demographics()),
                    if (_currentStep == 2) KeyedSubtree(key: const ValueKey('step_2_goals'), child: _buildStep2CognitiveGoals()),
                    if (_currentStep == 3) KeyedSubtree(key: const ValueKey('step_3_languages'), child: _buildStep3LanguagePreferences()),
                    if (_currentStep == 4) KeyedSubtree(key: const ValueKey('step_4_anchors'), child: _buildStep4MemoryAnchors()),
                    if (_currentStep == 5) KeyedSubtree(key: const ValueKey('step_5_ai'), child: _buildStep5AiSettings(appState)),
                    const SizedBox(height: 32),

                    // Navigation Controls
                    Row(
                      children: [
                        if (_currentStep > 1)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                SoundService().playClickSound();
                                setState(() => _currentStep--);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.charcoalText,
                                minimumSize: const Size.fromHeight(52),
                                side: const BorderSide(
                                    color: AppColors.borderSubtle),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Back'),
                            ),
                          ),
                        if (_currentStep > 1) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final err = _validateCurrentStep();
                              if (err != null) {
                                SoundService().playClickSound();
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('⚠️ $err'),
                                    backgroundColor: Colors.redAccent.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                return;
                              }

                              SoundService().playClickSound();
                              if (_currentStep < 5) {
                                setState(() => _currentStep++);
                              } else {
                                _generateAndSavePlan(appState);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.terracottaPrimary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            child: Text(
                              _currentStep == 5
                                  ? '✨ Save Details & Build AI Plan'
                                  : 'Continue ➔',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Demographics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Patient Demographics & Emergency Contacts *',
          style: GoogleFonts.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fill in your details to create your personalized memory care profile.',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 24),

        // Setup Role
        Text(
          'WHO IS SETTING UP THIS PROFILE?',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    '🧑‍⚕️ Caregiver',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontWeight: FontWeight.bold,
                      color: _setupMode == 'Caregiver' ? Colors.white : AppColors.charcoalText,
                    ),
                  ),
                ),
                selected: _setupMode == 'Caregiver',
                selectedColor: AppColors.terracottaPrimary,
                backgroundColor: Colors.white,
                onSelected: (selected) {
                  if (selected) setState(() => _setupMode = 'Caregiver');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    '👴 Patient (Senior)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontWeight: FontWeight.bold,
                      color: _setupMode == 'Patient' ? Colors.white : AppColors.charcoalText,
                    ),
                  ),
                ),
                selected: _setupMode == 'Patient',
                selectedColor: AppColors.terracottaPrimary,
                backgroundColor: Colors.white,
                onSelected: (selected) {
                  if (selected) setState(() => _setupMode = 'Patient');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Full Name Field
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Patient Full Name * (Compulsory)',
            hintText: 'e.g. Ramachandran Rao / Rukmini Devi',
            prefixIcon: const Icon(Icons.person, color: AppColors.terracottaPrimary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Age Field
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Age (Years) * (Compulsory)',
            hintText: 'e.g. 72',
            prefixIcon: const Icon(Icons.cake, color: AppColors.sageSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Emergency Contact Field with Country Code Selection
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  items: const [
                    DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                    DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                    DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                    DropdownMenuItem(value: '+61', child: Text('🇦🇺 +61')),
                    DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCountryCode = val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _emergencyContactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Emergency Phone Number (10 Digits) *',
                  hintText: '9876543210',
                  prefixIcon: const Icon(Icons.phone, color: Colors.redAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Must be exactly 10 digits.',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2CognitiveGoals() {
    final List<Map<String, String>> goals = [
      {
        'title': 'Auditory Recitation & Memory Retention',
        'desc': 'Focus on rhythmic verses, mantras, and auditory repetition exercises.',
        'icon': '📜',
      },
      {
        'title': 'Everyday Family & Orientation Care',
        'desc': 'Focus on remembering family relative names, daily routines & medication schedule.',
        'icon': '🏡',
      },
      {
        'title': 'Spatial & Visual Object Recall',
        'desc': 'Focus on visual memory games, pattern matching & spatial orientation.',
        'icon': '🧩',
      },
      {
        'title': 'Multi-Lingual Wisdom & Storytelling',
        'desc': 'Focus on multi-language cultural stories and proverb recall.',
        'icon': '📚',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. Primary Cognitive & Memory Goal *',
          style: GoogleFonts.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the primary focus area for daily cognitive practice (Compulsory).',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 20),

        ...goals.map((g) {
          final isSelected = _selectedGoal == g['title'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                SoundService().playTapSound();
                setState(() => _selectedGoal = g['title']!);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.terracottaSoft : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.terracottaPrimary : AppColors.borderSubtle,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(g['icon']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g['title']!,
                            style: GoogleFonts.newsreader(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            g['desc']!,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: AppColors.terracottaPrimary),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep3LanguagePreferences() {
    final List<Map<String, String>> languages = [
      {'code': 'sa', 'name': 'Sanskrit Traditional', 'flag': '📜'},
      {'code': 'hi', 'name': 'Hindi (Kabir & Folk)', 'flag': '🇮🇳'},
      {'code': 'te', 'name': 'Telugu (Vemana Padyalu)', 'flag': '🇮🇳'},
      {'code': 'ta', 'name': 'Tamil (Thirukkural)', 'flag': '🇮🇳'},
      {'code': 'as', 'name': 'Assamese Folk Poetry', 'flag': '🇮🇳'},
      {'code': 'bn', 'name': 'Bengali (Rabindra Sangeet)', 'flag': '🇮🇳'},
      {'code': 'en', 'name': 'English / Family Memories', 'flag': '🏡'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3. Heritage Languages & Dialects *',
          style: GoogleFonts.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select all heritage languages preferred for recitation and memory exercises (Select multiple option enabled).',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 20),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: languages.map((lang) {
            final isSelected = _selectedLanguages.contains(lang['code']);
            return FilterChip(
              selected: isSelected,
              showCheckmark: true,
              label: Text('${lang['flag']} ${lang['name']}'),
              selectedColor: AppColors.terracottaSoft,
              checkmarkColor: AppColors.terracottaPrimary,
              labelStyle: GoogleFonts.atkinsonHyperlegible(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.terracottaPrimary : AppColors.charcoalText,
              ),
              onSelected: (bool selected) {
                SoundService().playTapSound();
                setState(() {
                  if (selected) {
                    _selectedLanguages.add(lang['code']!);
                  } else {
                    if (_selectedLanguages.length > 1) {
                      _selectedLanguages.remove(lang['code']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('At least one language is compulsory!')),
                      );
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4MemoryAnchors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '4. Family Relatives & Childhood Memories *',
          style: GoogleFonts.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter familiar names and hometown memories so AI can construct personalized recall questions.',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 24),

        // Family Relatives
        TextFormField(
          controller: _relativesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Family Relatives & Names * (Compulsory)',
            hintText: 'e.g. Lakshmi (Daughter), Ravi (Son), Anitha (Granddaughter), Suresh (Brother)',
            prefixIcon: const Icon(Icons.family_restroom, color: AppColors.terracottaPrimary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Memories & Hobbies
        TextFormField(
          controller: _memoriesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Childhood Memories, Hometown & Hobbies * (Compulsory)',
            hintText: 'e.g. Ancestral home near tea garden, morning prayers, gardening',
            prefixIcon: const Icon(Icons.auto_awesome, color: AppColors.sandalwoodGold),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStep5AiSettings(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '5. Gemini AI & Plan Activation',
          style: GoogleFonts.newsreader(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enable intelligent Gemini GenAI adaptation to dynamically adjust exercise difficulty and memory plans.',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: 24),

        // Enable AI Toggle Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.terracottaPrimary.withValues(alpha: 0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: _enableAi,
              activeThumbColor: AppColors.terracottaPrimary,
              title: Text(
                'Enable Gemini GenAI Cognitive Engine',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Automatically generates adaptive recall games and weekly progress summaries.',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
              onChanged: (val) => setState(() => _enableAi = val),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.sageSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security, color: AppColors.sageSecondary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Smriti Veda uses project-managed AI configuration. Your personal information is protected and never used for public training.',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 13,
                    color: AppColors.charcoalText,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.terracottaPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.terracottaPrimary),
          const SizedBox(height: 24),
          Text(
            'Saving Details & Building AI Plan...',
            style: GoogleFonts.newsreader(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Persisting profile data to private DBMS storage and generating tailored regimen via Gemini AI.',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14,
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
