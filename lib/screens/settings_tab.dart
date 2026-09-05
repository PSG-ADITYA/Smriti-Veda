import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Settings & Options (विन्यास)',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Section
              _buildSectionTitle('VISUAL THEME & APPEARANCE'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Temple Obsidian Dark Mode',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Deep dark obsidian background with golden accents'),
                      secondary: const Icon(Icons.dark_mode, color: AppColors.primaryGold),
                      value: appState.themeMode == ThemeMode.dark,
                      onChanged: (val) => appState.toggleTheme(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Font Size Scaler Section
              _buildSectionTitle('DEVANAGARI & TEXT SCALING'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sanskrit Font Scale',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${(appState.fontScale * 100).round()}%',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primarySaffron,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: appState.fontScale,
                        min: 0.9,
                        max: 1.8,
                        divisions: 9,
                        label: '${(appState.fontScale * 100).round()}%',
                        onChanged: (val) => appState.setFontScale(val),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं',
                          style: AppTheme.devanagariStyle(
                            fontSize: 18 * appState.fontScale,
                            color: AppColors.primaryGold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Reader Preferences
              _buildSectionTitle('READER DISPLAY PREFERENCES'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Show Devanagari Sanskrit'),
                      subtitle: const Text('Display original Devanagari script'),
                      value: appState.showDevanagari,
                      onChanged: (val) => appState.toggleDevanagari(),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Show Transliteration (IAST)'),
                      subtitle: const Text('Display Romanized Sanskrit phonetic script'),
                      value: appState.showTransliteration,
                      onChanged: (val) => appState.toggleTransliteration(),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Show English Translation'),
                      subtitle: const Text('Display verse meaning'),
                      value: appState.showTranslation,
                      onChanged: (val) => appState.toggleTranslation(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // About Section
              _buildSectionTitle('ABOUT SMRITI VEDA'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.primaryGold),
                  title: Text(
                    'Smriti Veda App v1.0.0',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Sacred Scripture Reader & Memorization Companion'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.cinzel(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.primaryGold,
        ),
      ),
    );
  }
}
