import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scripture.dart';
import '../providers/app_state.dart';
import '../services/sanskrit_pronunciation_service.dart';
import '../theme/app_theme.dart';

class ScriptureDetailScreen extends StatefulWidget {
  final Suktam suktam;

  const ScriptureDetailScreen({super.key, required this.suktam});

  @override
  State<ScriptureDetailScreen> createState() => _ScriptureDetailScreenState();
}

class _ScriptureDetailScreenState extends State<ScriptureDetailScreen> {
  final SanskritPronunciationService _pronunciationService = SanskritPronunciationService();
  PronunciationMode _activeMode = PronunciationMode.continuous;
  bool _isPlayingPronunciation = false;

  @override
  void dispose() {
    _pronunciationService.stop();
    super.dispose();
  }

  void _handlePronounce(Verse verse, PronunciationMode mode) async {
    setState(() {
      _activeMode = mode;
      _isPlayingPronunciation = true;
    });

    await _pronunciationService.pronounceMantra(
      text: verse.sanskritText,
      mode: mode,
    );

    if (mounted) {
      setState(() {
        _isPlayingPronunciation = false;
      });
    }
  }

  void _showWordBreakdownDialog(BuildContext context, Verse verse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ' पदच्छेद (Word Breakdown)',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (verse.wordBreakdown.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Word-by-word breakdown is being updated.'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: verse.wordBreakdown.length,
                    separatorBuilder: (context, index) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final item = verse.wordBreakdown[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.sanskritWord,
                                  style: AppTheme.devanagariStyle(
                                    fontSize: 18,
                                    color: AppColors.primarySaffron,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item.transliteration,
                                  style: GoogleFonts.outfit(
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.englishMeaning,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNoteDialog(BuildContext context, AppState appState, Verse verse) {
    final noteController = TextEditingController(text: appState.getNote(verse.id));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Personal Reflection Note',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add your thoughts, insights, or chanting notes...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                appState.setNote(verse.id, noteController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note updated!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.suktam.titleTransliteration),
            actions: [
              IconButton(
                icon: const Icon(Icons.format_size),
                tooltip: 'Font Size',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setModalState) {
                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Adjust Font Size',
                                  style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Text('A', style: TextStyle(fontSize: 14)),
                                    Expanded(
                                      child: Slider(
                                        value: appState.fontScale,
                                        min: 0.9,
                                        max: 1.8,
                                        divisions: 9,
                                        label: '${(appState.fontScale * 100).round()}%',
                                        onChanged: (val) {
                                          appState.setFontScale(val);
                                          setModalState(() {});
                                        },
                                      ),
                                    ),
                                    const Text('A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Header Meta Info Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkSurface, AppColors.darkSurfaceCard]
                        : [AppColors.lightSurface, AppColors.lightSurfaceCard],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.suktam.titleSanskrit,
                      style: AppTheme.devanagariStyle(
                        fontSize: 26,
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.suktam.titleEnglish,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildChip(Icons.person, 'Rishi: ${widget.suktam.rishi}'),
                        _buildChip(Icons.auto_awesome, 'Deity: ${widget.suktam.deity}'),
                        _buildChip(Icons.music_note, 'Meter: ${widget.suktam.meter}'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Research & Cognitive Domain Annotation Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.science, color: AppColors.primaryGold, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cognitive Domain: ${widget.suktam.cognitiveTarget}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                                Text(
                                  widget.suktam.researchNotes,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Verses List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.suktam.verses.length,
                  itemBuilder: (context, index) {
                    final verse = widget.suktam.verses[index];
                    final isBookmarked = appState.isBookmarked(verse.id);
                    final note = appState.getNote(verse.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top Header Row with Verse Number & Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySaffron.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Verse ${verse.verseNumber}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primarySaffron,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                        color: isBookmarked ? AppColors.primaryGold : null,
                                      ),
                                      onPressed: () => appState.toggleBookmark(verse.id),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        note.isNotEmpty ? Icons.note_alt : Icons.note_add_outlined,
                                        color: note.isNotEmpty ? AppColors.primarySaffron : null,
                                      ),
                                      onPressed: () => _showNoteDialog(context, appState, verse),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // AI Traditional Sanskrit Pronunciation Controls Bar
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.record_voice_over, size: 16, color: AppColors.primarySaffron),
                                          const SizedBox(width: 6),
                                          Text(
                                            'AUDIO RECITATION GUIDANCE (TTS)',
                                            style: GoogleFonts.cinzel(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primarySaffron,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_isPlayingPronunciation)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySaffron.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Playing ${_activeMode.name}...',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primarySaffron,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _handlePronounce(verse, PronunciationMode.continuous),
                                        icon: const Icon(Icons.volume_up, size: 14),
                                        label: const Text('Full Chant'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primarySaffron,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          textStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _handlePronounce(verse, PronunciationMode.padachhedaSyllable),
                                        icon: const Icon(Icons.spellcheck, size: 14),
                                        label: const Text('Spell-Out (पदच्छेद)'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primaryGold,
                                          side: const BorderSide(color: AppColors.primaryGold),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          textStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _handlePronounce(verse, PronunciationMode.kramaPaired),
                                        icon: const Icon(Icons.compare_arrows, size: 14),
                                        label: const Text('Paired (क्रम)'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primaryGold,
                                          side: const BorderSide(color: AppColors.primaryGold),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          textStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Devanagari Sanskrit Text
                            if (appState.showDevanagari) ...[
                              SelectableText(
                                verse.sanskritText,
                                style: AppTheme.devanagariStyle(
                                  fontSize: 20 * appState.fontScale,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Transliteration
                            if (appState.showTransliteration) ...[
                              Text(
                                verse.transliteration,
                                style: GoogleFonts.notoSerif(
                                  fontSize: 14 * appState.fontScale,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                            ],

                            const Divider(height: 16),

                            // Translation
                            if (appState.showTranslation) ...[
                              Text(
                                verse.englishMeaning,
                                style: GoogleFonts.outfit(
                                  fontSize: 15 * appState.fontScale,
                                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Word Breakdown Button
                            OutlinedButton.icon(
                              onPressed: () => _showWordBreakdownDialog(context, verse),
                              icon: const Icon(Icons.translate, size: 18),
                              label: const Text('Word-by-Word Breakdown (पदच्छेद)'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primaryGold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryGold),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGold,
            ),
          ),
        ],
      ),
    );
  }
}
