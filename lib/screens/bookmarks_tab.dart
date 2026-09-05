import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sample_data.dart';
import '../models/scripture.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'scripture_detail_screen.dart';

class BookmarksTab extends StatelessWidget {
  const BookmarksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        // Collect all bookmarked verses across all suktams
        final List<_BookmarkedItem> bookmarkedItems = [];
        for (var suktam in SampleData.suktams) {
          for (var verse in suktam.verses) {
            if (appState.isBookmarked(verse.id)) {
              bookmarkedItems.add(_BookmarkedItem(suktam: suktam, verse: verse));
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Bookmarks & Notes (स्मृति सङ्ग्रह)',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
            ),
          ),
          body: bookmarkedItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_border, size: 64, color: AppColors.primaryGold),
                        const SizedBox(height: 16),
                        Text(
                          'No Bookmarked Verses Yet',
                          style: GoogleFonts.cinzel(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the bookmark icon while reading any verse to save it for quick review and daily chanting.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookmarkedItems.length,
                  itemBuilder: (context, index) {
                    final item = bookmarkedItems[index];
                    final note = appState.getNote(item.verse.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.suktam.titleSanskrit,
                                  style: GoogleFonts.cinzel(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.bookmark, color: AppColors.primaryGold),
                                  onPressed: () => appState.toggleBookmark(item.verse.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.verse.sanskritText,
                              style: AppTheme.devanagariStyle(
                                fontSize: 18,
                                color: isDark ? Colors.white : AppColors.textLightPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.verse.englishMeaning,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySaffron.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Note: $note',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.primarySaffron,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScriptureDetailScreen(suktam: item.suktam),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('Go to Suktam'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _BookmarkedItem {
  final Suktam suktam;
  final Verse verse;

  _BookmarkedItem({required this.suktam, required this.verse});
}
