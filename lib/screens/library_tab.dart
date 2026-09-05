import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import 'scripture_detail_screen.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredSuktams = SampleData.suktams.where((suktam) {
      final matchesCategory = _selectedCategoryId == 'all' || suktam.categoryId == _selectedCategoryId;
      final matchesSearch = _searchQuery.isEmpty ||
          suktam.titleSanskrit.contains(_searchQuery) ||
          suktam.titleTransliteration.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          suktam.titleEnglish.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          suktam.deity.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scripture Library (वेद शास्त्र)',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search mantras, suktams, deities, or Sanskrit...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
              ),
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Texts'),
                  selected: _selectedCategoryId == 'all',
                  onSelected: (selected) {
                    setState(() => _selectedCategoryId = 'all');
                  },
                ),
                const SizedBox(width: 8),
                ...SampleData.categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(cat.title),
                      selected: _selectedCategoryId == cat.id,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? cat.id : 'all';
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List of Suktams
          Expanded(
            child: filteredSuktams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: AppColors.primaryGold),
                        const SizedBox(height: 12),
                        Text(
                          'No scriptures found matching your query.',
                          style: GoogleFonts.outfit(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSuktams.length,
                    itemBuilder: (context, index) {
                      final suktam = filteredSuktams[index];
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
                                  Expanded(
                                    child: Text(
                                      suktam.titleSanskrit,
                                      style: AppTheme.devanagariStyle(
                                        fontSize: 22,
                                        color: AppColors.primaryGold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySaffron.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${suktam.verses.length} Verses',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primarySaffron,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                suktam.titleEnglish,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                suktam.summary,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rishi: ${suktam.rishi}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ScriptureDetailScreen(suktam: suktam),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.menu_book, size: 16),
                                    label: const Text('Read & Chant'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primarySaffron,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
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
  }
}
