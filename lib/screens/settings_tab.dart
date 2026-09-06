import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
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
              'Settings & Profile (विन्यास)',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Account Profile Card
              _buildSectionTitle('ACTIVE PRACTITIONER PROFILE'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primarySaffron.withValues(alpha: 0.2),
                            child: Icon(
                              appState.userRole == 'Caregiver' ? Icons.family_restroom : Icons.elderly,
                              color: AppColors.primarySaffron,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appState.userName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${appState.credentialId} • Role: ${appState.userRole}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Language: ${appState.selectedLanguage.toUpperCase()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => appState.switchRole(),
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: Text('Switch Role (${appState.userRole == 'Patient' ? 'Caregiver' : 'Patient'})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primarySaffron,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => appState.logout(),
                            icon: const Icon(Icons.logout, size: 16),
                            label: const Text('Log Out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

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

              const SizedBox(height: 20),

              // DBMS & SQL Console Section
              _buildSectionTitle('LOCAL DBMS & SQL QUERY ENGINE'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storage, color: AppColors.terracottaPrimary),
                      title: Text(
                        'Open DBMS SQL Management Console',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Execute real SQL queries on patient records, files, and logs'),
                      trailing: const Icon(Icons.code),
                      onTap: () => _showSqlConsoleModal(context),
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
                    'Smriti Veda Platform v1.2.0',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('AI-Based Cognitive Gaming & Memory Assistance for Seniors'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSqlConsoleModal(BuildContext context) {
    final queryController = TextEditingController(text: 'SELECT * FROM patient_files;');
    String sqlResult = DbService().executeSql(queryController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.charcoalText,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.terminal, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Interactive SQL Language Engine',
                    style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              Text(
                'Enter SQL Query Statement:',
                style: GoogleFonts.atkinsonHyperlegible(fontSize: 12, color: Colors.greenAccent),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: queryController,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black,
                  hintText: 'SELECT * FROM patient_files;',
                  hintStyle: TextStyle(color: Colors.greenAccent.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setModalState(() {
                        sqlResult = DbService().executeSql(queryController.text);
                      });
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Execute SQL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      setModalState(() {
                        queryController.text = 'SELECT * FROM user_profile;';
                        sqlResult = DbService().executeSql(queryController.text);
                      });
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.amber),
                    child: const Text('Users Table'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      setModalState(() {
                        queryController.text = 'SELECT * FROM appointments;';
                        sqlResult = DbService().executeSql(queryController.text);
                      });
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.cyan),
                    child: const Text('Appointments'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'SQL Output Data Stream:',
                style: GoogleFonts.atkinsonHyperlegible(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    sqlResult,
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.amberAccent, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => queryController.dispose());
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
