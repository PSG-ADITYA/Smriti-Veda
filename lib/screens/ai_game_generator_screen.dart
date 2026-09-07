import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../services/gemini_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class AiGameGeneratorScreen extends StatefulWidget {
  final String? initialPrompt;
  final bool autoGenerate;

  const AiGameGeneratorScreen({
    super.key,
    this.initialPrompt,
    this.autoGenerate = false,
  });

  @override
  State<AiGameGeneratorScreen> createState() => _AiGameGeneratorScreenState();
}

class _AiGameGeneratorScreenState extends State<AiGameGeneratorScreen> {
  final _eraController = TextEditingController(text: '1970s Classic Music & Regional Heritage');
  final _relativesController = TextEditingController();
  final _memoriesController = TextEditingController();
  final _promptController = TextEditingController();

  String _cognitiveFocus = 'Auditory & Word Recall';
  bool _isGenerating = false;
  bool _isInitialized = false;
  AiGameTemplate? _generatedGame;
  int _currentStep = 0; // 0 = Study/Memorize, 1 = Quiz Challenge
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _promptController.text = widget.initialPrompt!;
      final lower = widget.initialPrompt!.toLowerCase();
      if (lower.contains('pictorial') || lower.contains('picture') || lower.contains('image') || lower.contains('visual') || lower.contains('object')) {
        _cognitiveFocus = 'Pictorial & Object Recall';
      } else if (lower.contains('garden') || lower.contains('spatial') || lower.contains('path')) {
        _cognitiveFocus = 'Spatial Garden Path';
      } else if (lower.contains('family') || lower.contains('relative')) {
        _cognitiveFocus = 'Family Member Identification';
      } else if (lower.contains('routine') || lower.contains('daily') || lower.contains('sequence')) {
        _cognitiveFocus = 'Sequential Routine Memory';
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final appState = AppStateScope.of(context);
      if (appState.familiarPeople.isNotEmpty) {
        _relativesController.text = appState.familiarPeople.map((p) => '${p.name} (${p.relationship})').join(', ');
      } else {
        _relativesController.text = '';
      }
      if (appState.medicalNotes != null && appState.medicalNotes!.isNotEmpty) {
        _memoriesController.text = appState.medicalNotes!;
      }
      _isInitialized = true;

      if (widget.autoGenerate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _generateGame(appState);
        });
      }
    }
  }

  @override
  void dispose() {
    _eraController.dispose();
    _relativesController.dispose();
    _memoriesController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _generateGame(AppState appState) async {
    SoundService().playTapSound();
    setState(() {
      _isGenerating = true;
      _generatedGame = null;
      _currentStep = 0;
      _selectedItems.clear();
    });

    final apiKey = DbService().geminiApiKey;
    final gemini = GeminiService(apiKey: apiKey);

    final relativesList = _relativesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final game = await gemini.generatePersonalizedGame(
      patientName: appState.userName,
      eraPreference: _eraController.text,
      relativeNames: relativesList,
      favoriteMemories: _memoriesController.text,
      cognitiveFocus: _cognitiveFocus,
      customPrompt: _promptController.text.trim().isNotEmpty ? _promptController.text.trim() : null,
    );

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _generatedGame = game;
      });
      SoundService().playSuccessSound();
    }
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
          'AI Game Architect (Gemini AI)',
          style: GoogleFonts.newsreader(
            color: AppColors.terracottaPrimary,
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
            // AI Header Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.terracottaPrimary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.terracottaPrimary, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalized AI Game Generator',
                          style: GoogleFonts.newsreader(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoalText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gemini AI creates pictorial, audio, routine, and object recall games according to your prompt and memories.',
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
            ),

            const SizedBox(height: 20),

            if (_generatedGame == null) ...[
              // Setup Form Card
              Card(
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
                      Text(
                        '1. Custom Prompt / Game Theme:',
                        style: GoogleFonts.newsreader(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Create a pictorial nostalgic game with household objects',
                          prefixIcon: Icon(Icons.psychology_alt, color: AppColors.terracottaPrimary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        '2. Patient Relatives & Family Members:',
                        style: GoogleFonts.newsreader(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _relativesController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Lakshmi (Daughter), Ravi (Son), Anitha (Granddaughter)',
                          prefixIcon: Icon(Icons.family_restroom, color: AppColors.terracottaPrimary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        '3. Era & Cultural Preference:',
                        style: GoogleFonts.newsreader(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _eraController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 1970s Music, Vedic Hymns, Gardening',
                          prefixIcon: Icon(Icons.history_edu, color: AppColors.terracottaPrimary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        '4. Cognitive Focus Domain:',
                        style: GoogleFonts.newsreader(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _cognitiveFocus,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Pictorial & Object Recall', child: Text('Pictorial & Object Recall (Visual)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Auditory & Word Recall', child: Text('Auditory & Word Recall', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Spatial Garden Path', child: Text('Spatial Garden Path Recall', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Family Member Identification', child: Text('Family Member Identification', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Sequential Routine Memory', child: Text('Sequential Routine Memory', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _cognitiveFocus = val);
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.center_focus_strong, color: AppColors.terracottaPrimary),
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        onPressed: _isGenerating ? null : () => _generateGame(appState),
                        icon: _isGenerating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.auto_awesome, color: Colors.white),
                        label: Text(
                          _isGenerating ? 'Gemini AI is Generating Custom Game...' : 'Generate AI Custom Game ➔',
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracottaPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Generated AI Game Play Canvas
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.terracottaPrimary.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.sageSecondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _generatedGame!.category.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, color: AppColors.sageSecondary, fontSize: 11),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _generatedGame = null),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('New Prompt'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _generatedGame!.title,
                        style: GoogleFonts.newsreader(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.charcoalText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _generatedGame!.description,
                        style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.secondaryText),
                      ),
                      const Divider(height: 24),

                      KeyedSubtree(
                        key: ValueKey(_currentStep),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_currentStep == 0) ...[
                              Text(
                                'Study Phase: Memorize these personalized target items:',
                                style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _generatedGame!.targetItems.map((item) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.canvasIvory,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.sandalwoodGold, width: 1.2),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, color: AppColors.sandalwoodGold, size: 20),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            item,
                                            style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  SoundService().playFlipSound();
                                  setState(() => _currentStep = 1);
                                },
                                icon: const Icon(Icons.play_circle_fill),
                                label: const Text('Start Recall Challenge ➔'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.terracottaPrimary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Recall Challenge: Select only the remembered items!',
                                style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 14),

                              Builder(
                                builder: (context) {
                                  final allOptions = [..._generatedGame!.targetItems, ..._generatedGame!.distractorItems]..shuffle();
                                  return Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: allOptions.map((opt) {
                                      final isSelected = _selectedItems.contains(opt);
                                      return FilterChip(
                                        selected: isSelected,
                                        label: Text(opt, style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w600)),
                                        onSelected: (selected) {
                                          SoundService().playTapSound();
                                          setState(() {
                                            if (selected) {
                                              _selectedItems.add(opt);
                                            } else {
                                              _selectedItems.remove(opt);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  int correct = 0;
                                  for (var item in _generatedGame!.targetItems) {
                                    if (_selectedItems.contains(item)) correct++;
                                  }
                                  final total = _generatedGame!.targetItems.length;
                                  final scorePct = (correct / (total > 0 ? total : 1) * 100).round();

                                  // Log genuine attempt to repository
                                  final attempt = ExerciseAttempt(
                                    id: 'ai_game_${DateTime.now().millisecondsSinceEpoch}',
                                    userId: appState.activeUser.id,
                                    exerciseId: _generatedGame!.title,
                                    domain: ExerciseDomain.universalCognitive,
                                    type: ExerciseType.recognition,
                                    responseMode: 'choice',
                                    rawScore: correct.toDouble(),
                                    maxScore: total.toDouble(),
                                    timeTakenMs: 35000,
                                    timestamp: DateTime.now(),
                                  );
                                  appState.logAttempt(attempt);

                                  ConfettiOverlay.of(context)?.triggerCelebration(
                                    title: 'AI Game Completed! 🎉',
                                    subtitle: 'Score: $scorePct% ($correct of $total target items remembered!)',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.sageSecondary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Submit & Claim Score 🎉', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
