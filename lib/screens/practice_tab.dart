import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'attention_exercise_screen.dart';
import 'cultural_pipeline_screen.dart';
import 'daily_routine_recall_screen.dart';
import 'fruit_memory_path_screen.dart';
import 'memory_melody_screen.dart';
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
      case 'as':
        return '🇮🇳 Assamese';
      case 'bn':
        return '🇮🇳 Bengali';
      case 'hi':
        return '🇮🇳 Hindi';
      case 'te':
        return '🇮🇳 Telugu';
      case 'ta':
        return '🇮🇳 Tamil';
      case 'en':
        return '🏡 English';
      case 'sa':
        return '📜 Traditional';
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
        color: isSelected ? AppColors.terracottaPrimary : AppColors.terracottaPrimary.withValues(alpha: 0.3),
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
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SmritiAppBar(screenLabel: 'Practice'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
            // SECTION 1: FLAGSHIP GAME
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF7ED), Color(0xFFFDEEE0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.terracottaPrimary.withValues(alpha: 0.35), width: 1.8),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.terracottaPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🌟 FLAGSHIP COGNITIVE GAME',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 11 * fontScale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.explore_rounded, size: 16, color: AppColors.terracottaPrimary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Spatial & Working Memory',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 12 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.terracottaPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fruit Memory Path',
                    style: GoogleFonts.newsreader(
                      fontSize: 22 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoalText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Memorize fruit locations in the garden paver grid before they vanish, then navigate your character step-by-step along the remembered path.',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 13 * fontScale,
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FruitMemoryPathScreen()),
                      );
                    },
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
                    label: Text(
                      'Play Fruit Memory Path (4 Tiers)',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 15 * fontScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracottaPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            // SECTION 1B: MEMORY MELODY HERO CARD
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF8F5C86).withValues(alpha: 0.35), width: 1.8),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8F5C86),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🎵 AI RHYTHMIC MEMORY',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 11 * fontScale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.music_note_rounded, size: 16, color: Color(0xFF8F5C86)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Auditory & Delayed Recall',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 12 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF8F5C86),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Memory Melody',
                    style: GoogleFonts.newsreader(
                      fontSize: 22 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoalText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Listen to an AI-crafted 25-second melodic verse. Recall the items, chronological sequence, and surprise delayed details through voice or tap.',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 13 * fontScale,
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MemoryMelodyScreen()),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text(
                      'Play Memory Melody',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 15 * fontScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F5C86),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SECTION 2: ADAPTIVE COGNITIVE EXERCISES (7 Domain-Mapped Games)
            Row(
              children: [
                const Icon(Icons.psychology_outlined, color: AppColors.terracottaPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DOMAIN-TARGETED COGNITIVE GAMES',
                    style: GoogleFonts.newsreader(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppColors.terracottaPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Each exercise targets a specific cognitive domain to maintain mental vitality and recall.',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 12 * fontScale,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 14),

            // Pair 1: Object Recall Matrix & Pattern Memory Grid
            Row(
              children: [
                Expanded(
                  child: _buildGameCard(
                    title: 'Object Recall Matrix',
                    domainLabel: 'Visual Memory',
                    subtitle: 'Recall household room items',
                    icon: Icons.visibility_rounded,
                    color: const Color(0xFF3D5A80),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ObjectMemoryScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGameCard(
                    title: 'Pattern Memory Grid',
                    domainLabel: 'Working Memory',
                    subtitle: 'Reconstruct visual patterns',
                    icon: Icons.grid_on_rounded,
                    color: const Color(0xFF4A7C59),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatternMemoryScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pair 2: Sequence Recall & Attention & Focus
            Row(
              children: [
                Expanded(
                  child: _buildGameCard(
                    title: 'Sequence Recall',
                    domainLabel: 'Sequential Memory',
                    subtitle: 'Order symbols & rivers',
                    icon: Icons.format_list_numbered_rounded,
                    color: const Color(0xFF5B8E7D),
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
                    title: 'Attention & Focus',
                    domainLabel: 'Attention / Focus',
                    subtitle: 'Find targets among distractors',
                    icon: Icons.center_focus_strong_rounded,
                    color: const Color(0xFFD4A373),
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

            // Pair 3: Story Recall & Word Association
            Row(
              children: [
                Expanded(
                  child: _buildGameCard(
                    title: 'Story Recall',
                    domainLabel: 'Auditory Recall',
                    subtitle: 'Read/listen to folk stories',
                    icon: Icons.auto_stories_rounded,
                    color: const Color(0xFF8F5C86),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoryMemoryScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGameCard(
                    title: 'Word Association',
                    domainLabel: 'Semantic Memory',
                    subtitle: 'Connect related concepts',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF386641),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WordAssociationScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Full Width: Daily Routine Recall
            _buildGameCard(
              title: 'Daily Routine Recall',
              domainLabel: 'Everyday & Prospective Memory',
              subtitle: 'Sequence your morning routine, hydration, and medication habits',
              icon: Icons.access_time_filled_rounded,
              color: const Color(0xFFB85028),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyRoutineRecallScreen()),
              ),
              fontScale: fontScale,
            ),

            const SizedBox(height: 32),

            // SECTION 3: CULTURAL & ORAL MEMORY SYSTEM
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
              'Practicing structured recall inspired by Indian oral memory traditions (Listen ➔ Pada Chunk ➔ Krama Overlap ➔ Reverse ➔ Missing Element ➔ Delayed Recall). Works with regional folk songs, North Eastern poems, family stories, and sayings.',
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
                  _buildLanguageFilterChip('all', 'All Regions (${_allCulturalItems.length})'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('as', 'Assamese 🇮🇳'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('bn', 'Bengali 🇮🇳'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('hi', 'Hindi 🇮🇳'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('te', 'Telugu 🇮🇳'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('ta', 'Tamil 🇮🇳'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('en', 'English / Family 🏡'),
                  const SizedBox(width: 8),
                  _buildLanguageFilterChip('sa', 'Traditional 📜'),
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
                                    color: AppColors.terracottaPrimary.withValues(alpha: 0.12),
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
                                color: AppColors.sageSecondary.withValues(alpha: 0.08),
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
                              icon: const Icon(Icons.record_voice_over_rounded, size: 20),
                              label: const Text('Start 7-Stage Recitation & Recall'),
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
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String domainLabel,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double fontScale,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  domainLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.newsreader(
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoalText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 12 * fontScale,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onTap,
              child: Text(
                'Play Game',
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13 * fontScale,
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
