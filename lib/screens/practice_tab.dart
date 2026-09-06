import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'attention_exercise_screen.dart';
import 'cultural_pipeline_screen.dart';
import 'delayed_recall_screen.dart';
import 'object_memory_screen.dart';
import 'pattern_memory_screen.dart';
import 'sequence_recall_screen.dart';
import 'story_memory_screen.dart';
import 'word_association_screen.dart';

class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key});

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  String _selectedLanguageFilter = 'all';

  List<dynamic> get _allCulturalItems {
    return AppStateScope.of(context).culturalContentRepo.getAllItems();
  }

  List<dynamic> get _filteredCulturalItems {
    final all = _allCulturalItems;
    if (_selectedLanguageFilter == 'all') return all;
    return all.where((item) => item.languageCode == _selectedLanguageFilter).toList();
  }

  String _getLanguageFlag(String code) {
    switch (code) {
      case 'te':
        return '🇮🇳 Telugu';
      case 'hi':
        return '🇮🇳 Hindi';
      case 'ta':
        return '🇮🇳 Tamil';
      case 'as':
        return '🇮🇳 Assamese';
      case 'bn':
        return '🇮🇳 Bengali';
      case 'en':
        return '🏡 English';
      case 'sa':
        return '📜 Sanskrit';
      default:
        return '🇮🇳 Regional';
    }
  }

  Widget _buildLanguageFilterChip(String langCode, String label) {
    final isSelected = _selectedLanguageFilter == langCode;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: GoogleFonts.atkinsonHyperlegible(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.charcoalText,
        ),
      ),
      selectedColor: AppColors.terracottaPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.terracottaPrimary : AppColors.terracottaPrimary.withOpacity(0.3),
      ),
      onSelected: (selected) {
        setState(() {
          _selectedLanguageFilter = langCode;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        title: Text(
          'Practice Sanctuary',
          style: GoogleFonts.newsreader(
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
            fontSize: 22 * fontScale,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION 1: UNIVERSAL COGNITIVE MEMORY GAMES
            Row(
              children: [
                const Icon(Icons.psychology_outlined, color: AppColors.terracottaPrimary),
                const SizedBox(width: 8),
                Text(
                  'UNIVERSAL COGNITIVE GAMES',
                  style: GoogleFonts.newsreader(
                    fontSize: 16 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Game Grid 1: Sequence Recall & Recognition
            Row(
              children: [
                Expanded(
                  child: _buildGameCard(
                    title: '1. Sequence Recall',
                    subtitle: 'Memorize & order sequences',
                    icon: Icons.format_list_numbered_rounded,
                    color: AppColors.sageSecondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SequenceRecallScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGameCard(
                    title: '2. Object Memory',
                    subtitle: 'Recall items from a scene',
                    icon: Icons.grid_view_rounded,
                    color: AppColors.terracottaPrimary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ObjectMemoryScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Game Grid 2: Pattern Memory & Story Recall
            Row(
              children: [
                Expanded(
                  child: _buildGameCard(
                    title: '3. Pattern Memory',
                    subtitle: 'Reconstruct visual grid',
                    icon: Icons.pattern_rounded,
                    color: AppColors.sandalwoodGold,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatternMemoryScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGameCard(
                    title: '4. Story Recall',
                    subtitle: 'Read story & answer quiz',
                    icon: Icons.auto_stories_rounded,
                    color: AppColors.sageSecondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoryMemoryScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Game Grid 3: Word Association & Attention
            Row(
              children: [
                Expanded(
                  child: _buildGameCard(
                    title: '5. Word Association',
                    subtitle: 'Link semantic concepts',
                    icon: Icons.link_rounded,
                    color: AppColors.terracottaPrimary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WordAssociationScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGameCard(
                    title: '6. Attention & Focus',
                    subtitle: 'Target vs distractor grid',
                    icon: Icons.center_focus_strong_rounded,
                    color: AppColors.sandalwoodGold,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AttentionExerciseScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Game Row 4: Delayed Recall
            _buildGameCard(
              title: '7. Delayed Recall Exercise',
              subtitle: 'Memorize 3 items, complete intermediate task, then recall later',
              icon: Icons.history_toggle_off_rounded,
              color: AppColors.sageSecondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DelayedRecallScreen()),
              ),
              fontScale: fontScale,
            ),

            const SizedBox(height: 32),

            // SECTION 2: CULTURAL & ORAL MEMORY SYSTEM
            Row(
              children: [
                const Icon(Icons.record_voice_over_rounded, color: AppColors.sageSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CULTURAL & ORAL MEMORY SYSTEM',
                    style: GoogleFonts.newsreader(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppColors.sageSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Practicing structured recall inspired by Indian oral memory traditions (Listen ➔ Pada Chunk ➔ Krama Overlap ➔ Reverse ➔ Missing Element ➔ Delayed Recall). Works with familiar poems, regional rhymes, family stories, and proverbs.',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13 * fontScale,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Language Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLanguageFilterChip('all', 'All Languages (${_allCulturalItems.length})'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('te', 'Telugu 🇮🇳'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('hi', 'Hindi 🇮🇳'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('ta', 'Tamil 🇮🇳'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('as', 'Assamese 🇮🇳'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('bn', 'Bengali 🇮🇳'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('en', 'English / Family 🏡'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('sa', 'Sanskrit 📜'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Builder(
              builder: (context) {
                final items = _filteredCulturalItems;
                if (items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No content items found for this language filter.'),
                    ),
                  );
                }

                return Column(
                  children: items.map((item) {
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.terracottaPrimary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_getLanguageFlag(item.languageCode)} ${item.category.toUpperCase()}',
                                    style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.terracottaPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.newsreader(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.charcoalText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.originalScriptText,
                              style: GoogleFonts.newsreader(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.charcoalText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Transliteration: ${item.transliteration}',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Meaning: ${item.englishMeaning}',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13,
                                color: AppColors.charcoalText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.sageSecondary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.psychology, size: 16, color: AppColors.sageSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Cognitive Target: ${item.cognitivePurpose}',
                                      style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.sageSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CulturalPipelineScreen(item: item),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_circle_fill, size: 20),
                              label: const Text('Start 7-Stage Recitation Progression'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sageSecondary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double fontScale,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.newsreader(
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 12 * fontScale,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onTap,
              child: Text(
                'Play Game',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 14 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
