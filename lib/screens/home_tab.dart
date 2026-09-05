import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sample_data.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'scripture_detail_screen.dart';

class HomeTab extends StatelessWidget {
  final Function(int) onNavigateTab;

  const HomeTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Default hero shloka: Gayatri Mantra
    final heroSuktam = SampleData.suktams.firstWhere(
      (s) => s.id == 'gayatri_mantra',
      orElse: () => SampleData.suktams.first,
    );
    final heroVerse = heroSuktam.verses.first;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'स्मृति वेद (Smriti Veda)',
              style: GoogleFonts.cinzel(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  appState.themeMode == ThemeMode.dark ? Icons.wb_sunny : Icons.nightlight_round,
                  color: AppColors.primaryGold,
                ),
                tooltip: 'Toggle Theme Mode',
                onPressed: () => appState.toggleTheme(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Chanting Streak Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primarySaffron, AppColors.deepAmber],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primarySaffron.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${appState.dailyStreak} Day Sacred Chanting Streak!',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${appState.versesMastered} Shlokas Mastered in Smriti Memory',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => onNavigateTab(2), // Jump to Smriti Trainer
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primarySaffron,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Practice'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Shloka of the Day Hero Section
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.primaryGold),
                    const SizedBox(width: 8),
                    Text(
                      'SHLOKA OF THE DAY',
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScriptureDetailScreen(suktam: heroSuktam),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGold.withValues(alpha: 0.1),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          heroSuktam.titleSanskrit,
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          heroVerse.sanskritText,
                          style: AppTheme.devanagariStyle(
                            fontSize: 19,
                            color: isDark ? Colors.white : AppColors.textLightPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          heroVerse.englishMeaning,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tap to chant & explore word breakdown',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.primarySaffron,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 14, color: AppColors.primarySaffron),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Sacred Collections
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SCRIPTURE CATEGORIES',
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => onNavigateTab(1), // Go to Library
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: SampleData.categories.length,
                  itemBuilder: (context, index) {
                    final cat = SampleData.categories[index];
                    return GestureDetector(
                      onTap: () => onNavigateTab(1),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getIconData(cat.iconName), color: AppColors.primarySaffron, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              cat.title,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                              ),
                            ),
                            Text(
                              '${cat.count} texts available',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Featured Vedic Suktams
                Text(
                  'FEATURED VEDIC HYMNS',
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                ...SampleData.suktams.where((s) => s.isFeatured).map((suktam) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        suktam.titleSanskrit,
                        style: AppTheme.devanagariStyle(
                          fontSize: 18,
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suktam.titleEnglish,
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Deity: ${suktam.deity} • ${suktam.verses.length} Verses',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.primaryGold),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScriptureDetailScreen(suktam: suktam),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'auto_stories':
        return Icons.auto_stories;
      case 'temple_hindu':
        return Icons.temple_hindu;
      case 'menu_book':
        return Icons.menu_book;
      case 'psychology':
        return Icons.psychology;
      case 'self_improvement':
        return Icons.self_improvement;
      default:
        return Icons.book;
    }
  }
}
