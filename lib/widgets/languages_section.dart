import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../locales/app_localizations.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class LanguagesSection extends StatelessWidget {
  final bool compact;

  const LanguagesSection({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final currentLang = appState.selectedLanguage;
    final fontScale = appState.fontScale;

    return Semantics(
      label: 'Language and Script selection section. Currently active language is $currentLang',
      child: Container(
        margin: EdgeInsets.symmetric(vertical: compact ? 8 : 14),
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.sandalwoodGold.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.terracottaSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    color: AppColors.terracottaPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('languages_section_title'),
                        style: GoogleFonts.newsreader(
                          fontSize: (compact ? 16 : 18) * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalText,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          context.tr('languages_section_subtitle'),
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 12 * fontScale,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: AppLocalizations.supportedLanguages.map((lang) {
                    final code = lang['code']!;
                    final isSelected = currentLang == code;
                    final nativeName = lang['nativeName']!;
                    final englishName = lang['englishName']!;
                    final subtitle = lang['subtitle']!;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (!isSelected) {
                            SoundService.playTap();
                            appState.setSelectedLanguage(code);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: itemWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.terracottaSoft.withValues(alpha: 0.7)
                                : const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.terracottaPrimary
                                  : AppColors.sandalwoodGold.withValues(alpha: 0.25),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? const [
                                    BoxShadow(
                                      color: Color(0x14B85028),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nativeName,
                                      style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 15 * fontScale,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppColors.terracottaPrimary
                                            : AppColors.charcoalText,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '$englishName • $subtitle',
                                      style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 11 * fontScale,
                                        color: isSelected
                                            ? AppColors.terracottaPrimary.withValues(alpha: 0.85)
                                            : AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.terracottaPrimary,
                                  size: 18,
                                ),
                            ],
                          ),
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
}
