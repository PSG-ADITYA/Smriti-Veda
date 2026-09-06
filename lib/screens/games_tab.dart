import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'cultural_pipeline_screen.dart';
import 'main_screen.dart';
import 'sequence_recall_screen.dart';
import 'story_memory_screen.dart';

class GamesTab extends StatefulWidget {
  const GamesTab({super.key});

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  // Memory Match Inline Demo State
  final List<String> _pairs = ['🌸', '🌸', '🌿', '🌿', '🪷', '🪷', '☀️', '☀️'];
  late List<int> _cardState; // -1=hidden, 0=visible, 1=matched
  int? _firstFlipped;
  int _attempts = 0;
  int _matchedPairs = 0;

  @override
  void initState() {
    super.initState();
    _resetMemoryMatch();
  }

  void _resetMemoryMatch() {
    _cardState = List.filled(_pairs.length, -1);
    _cardState[0] = 1; _cardState[1] = 1;
    _matchedPairs = 1;
    _attempts = 2;
    _firstFlipped = null;
  }

  void _onCardTap(int idx) {
    if (_cardState[idx] != -1) return;
    SoundService().playTapSound();

    setState(() {
      _cardState[idx] = 0;
      if (_firstFlipped == null) {
        _firstFlipped = idx;
      } else {
        _attempts++;
        final prev = _firstFlipped!;
        if (_pairs[prev] == _pairs[idx]) {
          _cardState[prev] = 1;
          _cardState[idx] = 1;
          _matchedPairs++;
          _firstFlipped = null;
        } else {
          Timer(const Duration(milliseconds: 700), () {
            if (mounted) {
              setState(() {
                _cardState[prev] = -1;
                _cardState[idx] = -1;
                _firstFlipped = null;
              });
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SmritiAppBar(screenLabel: 'Games'),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCream,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.terracottaSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sports_esports_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cognitive Gaming Sanctuary',
                              style: GoogleFonts.newsreader(
                                fontSize: 22 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Engaging memory challenges organized into Traditional Indian learning practices & Modern Western cognitive games.',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13 * fontScale,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // =========================================================
                // CATEGORY 1: TRADITIONAL GAMES
                // =========================================================
                Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'CATEGORY 1: TRADITIONAL GAMES',
                        style: GoogleFonts.newsreader(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Memory practices inspired by Indian learning traditions (Listen ➔ Repeat ➔ Hide ➔ Speak ➔ Evaluate).',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 13 * fontScale,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Grid of Traditional Games
                Row(
                  children: [
                    Expanded(
                      child: _buildGameTile(
                        title: '1. Vedic Recall',
                        subtitle: 'Listen, hide & speak verse',
                        icon: Icons.psychology_alt_rounded,
                        color: AppColors.primary,
                        bgColor: AppColors.terracottaSoft,
                        onTap: () {
                          final item = appState.culturalContentRepo.getAllItems().first;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CulturalPipelineScreen(item: item)));
                        },
                        fontScale: fontScale,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGameTile(
                        title: '2. Mantra Practice',
                        subtitle: 'Rhythmic syllable alignment',
                        icon: Icons.graphic_eq_rounded,
                        color: AppColors.secondary,
                        bgColor: AppColors.sageSoft,
                        onTap: () {
                          final items = appState.culturalContentRepo.getAllItems();
                          final item = items.length > 1 ? items[1] : items.first;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CulturalPipelineScreen(item: item)));
                        },
                        fontScale: fontScale,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildGameTile(
                        title: '3. Recitation Practice',
                        subtitle: 'Segmented Pada recall',
                        icon: Icons.record_voice_over_outlined,
                        color: AppColors.tertiary,
                        bgColor: const Color(0xFFFFF3E0),
                        onTap: () {
                          final items = appState.culturalContentRepo.getAllItems();
                          final item = items.length > 2 ? items[2] : items.first;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CulturalPipelineScreen(item: item)));
                        },
                        fontScale: fontScale,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGameTile(
                        title: '4. Rhythm & Recall',
                        subtitle: 'Overlapping Krama pairs',
                        icon: Icons.loop_rounded,
                        color: AppColors.primary,
                        bgColor: AppColors.terracottaSoft,
                        onTap: () {
                          final items = appState.culturalContentRepo.getAllItems();
                          final item = items.length > 3 ? items[3] : items.first;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CulturalPipelineScreen(item: item)));
                        },
                        fontScale: fontScale,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // =========================================================
                // CATEGORY 2: WESTERN / MODERN GAMES
                // =========================================================
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'CATEGORY 2: WESTERN / MODERN GAMES',
                        style: GoogleFonts.newsreader(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Contemporary cognitive exercises focusing on visual memory, spatial order, and story recall.',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 13 * fontScale,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Modern Games Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildGameTile(
                        title: '1. Sequential Order',
                        subtitle: 'Remember numeric sequence',
                        icon: Icons.format_list_numbered_rounded,
                        color: AppColors.secondary,
                        bgColor: AppColors.sageSoft,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SequenceRecallScreen())),
                        fontScale: fontScale,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGameTile(
                        title: '2. Story Teller',
                        subtitle: 'Folk tale event ordering',
                        icon: Icons.auto_stories_rounded,
                        color: AppColors.tertiary,
                        bgColor: const Color(0xFFFFF3E0),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryMemoryScreen())),
                        fontScale: fontScale,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Interactive Inline Memory Match Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.sageSecondary.withValues(alpha: 0.3)),
                    boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.style_rounded, color: AppColors.secondary),
                              const SizedBox(width: 8),
                              Text(
                                '3. Memory Match (Interactive)',
                                style: GoogleFonts.newsreader(
                                  fontSize: 18 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _resetMemoryMatch());
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reset Board'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pairs Found: $_matchedPairs / 4  •  Attempts: $_attempts',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 13 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Card Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pairs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, idx) {
                          final state = _cardState[idx];
                          final isFaceUp = state >= 0;

                          return GestureDetector(
                            onTap: () => _onCardTap(idx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: state == 1
                                    ? AppColors.sageSoft
                                    : isFaceUp
                                        ? AppColors.terracottaSoft
                                        : AppColors.surfaceCream,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: state == 1
                                      ? AppColors.secondary
                                      : isFaceUp
                                          ? AppColors.primary
                                          : AppColors.borderSubtle,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  isFaceUp ? _pairs[idx] : '❓',
                                  style: TextStyle(fontSize: 28 * fontScale),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required double fontScale,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.newsreader(
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 12 * fontScale,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
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
                'Play Challenge',
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
