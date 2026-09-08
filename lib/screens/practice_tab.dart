import '../services/sound_service.dart';
import 'dice_memory_screen.dart';
import 'word_memory_puzzle_screen.dart';
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
import 'arranging_order_screen.dart';
import 'story_memory_screen.dart';
import 'word_association_screen.dart';

class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key});

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  String? _selectedLanguageGroup;

  static const List<Map<String, dynamic>> _languageGroups = [
    {
      'code': 'sa',
      'name': 'संस्कृतम् (Sanskrit)',
      'sub': 'Vedic Mantras, Shlokas & Peace Chants',
      'badge': '12 Verses',
      'icon': '📜',
      'color': Color(0xFFB85028),
    },
    {
      'code': 'te',
      'name': 'తెలుగు (Telugu)',
      'sub': 'Vemana Shatakam & Potana Bhagavatham Padyalu',
      'badge': '8 Padyalu',
      'icon': '🌸',
      'color': Color(0xFF2E7D32),
    },
    {
      'code': 'hi',
      'name': 'हिन्दी (Hindi)',
      'sub': 'Sant Kabir & Goswami Tulsidas Dohas',
      'badge': '8 Dohas',
      'icon': '🪔',
      'color': Color(0xFFE65100),
    },
    {
      'code': 'en',
      'name': 'English & Heritage',
      'sub': 'Nursery Rhymes & Family Oral Memories',
      'badge': '8 Items',
      'icon': '🏡',
      'color': Color(0xFF1565C0),
    },
    {
      'code': 'regional',
      'name': 'Regional Traditions',
      'sub': 'Tamil Thirukkural, Bengali & Assamese Poetry',
      'badge': '3 Poems',
      'icon': '🇮🇳',
      'color': Color(0xFF6A1B9A),
    },
  ];

  List<dynamic> get _allCulturalItems {
    return AppStateScope.of(context).culturalContentRepo.getAllItems();
  }

  List<dynamic> _getItemsForGroup(String? groupCode) {
    final all = _allCulturalItems;
    if (groupCode == null) return all;
    if (groupCode == 'regional') {
      return all.where((item) => item.languageCode == 'ta' || item.languageCode == 'bn' || item.languageCode == 'as').toList();
    }
    return all.where((item) => item.languageCode == groupCode).toList();
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
                      'Play Fruit Memory Path',
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
                    title: 'Arranging Order',
                    domainLabel: 'Sequential Memory',
                    subtitle: 'Drag & reorder items in sequence',
                    icon: Icons.low_priority_rounded,
                    color: const Color(0xFF5B8E7D),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ArrangingOrderScreen()),
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
            const SizedBox(height: 12),

            // Pair 4: 3D Dice Memory & Word Memory Puzzle
            Row(
              children: [
                Expanded(
                  child: _buildGameCard(
                    title: '3D Dice Memory',
                    domainLabel: 'Spatial & Working Memory',
                    subtitle: 'Tabletop dice value & spatial position recall',
                    icon: Icons.casino_rounded,
                    color: const Color(0xFF386641),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiceMemoryScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGameCard(
                    title: 'Word Memory Puzzle',
                    domainLabel: 'Language & Sequential Memory',
                    subtitle: 'Observe & order culturally familiar words',
                    icon: Icons.spellcheck_rounded,
                    color: const Color(0xFFB85028),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WordMemoryPuzzleScreen()),
                    ),
                    fontScale: fontScale,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // SECTION 3: CULTURAL & ORAL MEMORY SYSTEM (BY LANGUAGE GROUP)
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
              'Select your heritage language or tradition first to practice structured recall (Listen ➔ Pada Chunk ➔ Reverse ➔ Missing Element ➔ Delayed Recall).',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13 * fontScale,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            if (_selectedLanguageGroup == null) ...[
              // Display the Language Groups First as requested
              ..._languageGroups.map((grp) {
                final code = grp['code'] as String;
                final name = grp['name'] as String;
                final sub = grp['sub'] as String;
                                final icon = grp['icon'] as String;
                final color = grp['color'] as Color;
                final count = _getItemsForGroup(code).length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.2),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      SoundService.playTap();
                      setState(() {
                        _selectedLanguageGroup = code;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(icon, style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: GoogleFonts.newsreader(
                                          fontSize: 17 * fontScale,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.charcoalText,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$count items',
                                        style: GoogleFonts.atkinsonHyperlegible(
                                          fontSize: 11 * fontScale,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sub,
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 12 * fontScale,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ] else ...[
              // Header when a specific language group is selected
              Builder(
                builder: (context) {
                  final activeGrp = _languageGroups.firstWhere(
                    (g) => g['code'] == _selectedLanguageGroup,
                    orElse: () => _languageGroups.first,
                  );
                  final color = activeGrp['color'] as Color;
                  final items = _getItemsForGroup(_selectedLanguageGroup);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back to all groups button + Title
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.arrow_back, color: color),
                              onPressed: () {
                                SoundService.playTap();
                                setState(() {
                                  _selectedLanguageGroup = null;
                                });
                              },
                              tooltip: 'Back to all language traditions',
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeGrp['name'] as String,
                                    style: GoogleFonts.newsreader(
                                      fontSize: 16 * fontScale,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    'Showing ${items.length} recitation pieces',
                                    style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 11 * fontScale,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                SoundService.playTap();
                                setState(() {
                                  _selectedLanguageGroup = null;
                                });
                              },
                              child: Text(
                                'Change',
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 12 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // List of Shlokas / Poems for this Language
                      ...items.map((item) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: color.withValues(alpha: 0.25)),
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
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_getLanguageFlag(item.languageCode)} ${item.category.toUpperCase()}',
                                        style: GoogleFonts.atkinsonHyperlegible(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: color,
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
                                    color: color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.psychology, size: 16, color: color),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Cognitive Target: ${item.cognitivePurpose}',
                                          style: GoogleFonts.atkinsonHyperlegible(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: color,
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
                                    backgroundColor: color,
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
                      }),
                    ],
                  );
                },
              ),
            ],
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
