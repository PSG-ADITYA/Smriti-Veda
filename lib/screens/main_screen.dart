import '../locales/app_localizations.dart';
import 'smritiveda_chatbot_screen.dart';
import '../widgets/smritiveda_assistant_fab.dart';
import 'caregiver_dashboard_screen.dart';
import 'connected_seniors_screen.dart';
import 'caregiver_insights_screen.dart';
import 'caregiver_profile_screen.dart';
import 'medical_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../services/db_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/top_right_user_menu.dart';
import 'ai_game_generator_screen.dart';
import 'everyday_memory_screen.dart';
import 'home_tab.dart';
import 'practice_tab.dart';
import 'progress_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final isCaregiver = appState.isCaregiverMode;
        final maxIndex = isCaregiver ? 4 : 3;
        final currentIndex = appState.currentTab.clamp(0, maxIndex);

        final List<Widget> tabs = isCaregiver
            ? [
                CaregiverDashboardScreen(onNavigateTab: (index) => appState.setCurrentTab(index)),
                ConnectedSeniorsScreen(onNavigateTab: (index) => appState.setCurrentTab(index)),
                const CaregiverInsightsScreen(),
                const MedicalReportsScreen(),
                CaregiverProfileScreen(onNavigateTab: (index) => appState.setCurrentTab(index)),
              ]
            : [
                HomeTab(onNavigateTab: (index) => appState.setCurrentTab(index)),
                const PracticeTab(),
                const EverydayMemoryScreen(),
                const ProgressTab(),
              ];

        return PopScope(
          canPop: currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (currentIndex != 0) {
              appState.setCurrentTab(0);
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.surface,
            extendBody: true,
            floatingActionButton: isCaregiver ? null : const SmritiVedaAssistantFab(),
            body: IndexedStack(
              index: currentIndex,
              children: tabs,
            ),
            bottomNavigationBar: _StitchBottomNav(
              currentIndex: currentIndex,
              fontScale: fontScale,
              isCaregiver: isCaregiver,
              onTap: (index) => appState.setCurrentTab(index),
            ),
          ),
        );
      },
    );
  }
}

class _StitchBottomNav extends StatelessWidget {
  final int currentIndex;
  final double fontScale;
  final bool isCaregiver;
  final ValueChanged<int> onTap;

  const _StitchBottomNav({
    required this.currentIndex,
    required this.fontScale,
    required this.isCaregiver,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasIvory,
        border: const Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A2D241C),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: isCaregiver
                ? [
                    _NavItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      fontScale: fontScale,
                      onTap: onTap,
                    ),
                    _NavItem(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.people_outline_rounded,
                      activeIcon: Icons.people_rounded,
                      label: 'Seniors',
                      fontScale: fontScale,
                      onTap: onTap,
                    ),
                    _NavItem(
                      index: 2,
                      currentIndex: currentIndex,
                      icon: Icons.insights_outlined,
                      activeIcon: Icons.insights_rounded,
                      label: 'Insights',
                      fontScale: fontScale,
                      onTap: onTap,
                    ),
                    _NavItem(
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.medical_services_outlined,
                      activeIcon: Icons.medical_services_rounded,
                      label: 'Medical',
                      fontScale: fontScale,
                      onTap: onTap,
                    ),
                    _NavItem(
                      index: 4,
                      currentIndex: currentIndex,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      fontScale: fontScale,
                      onTap: onTap,
                    ),
                  ]
                : [
                    _NavItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: context.tr('nav_home'),
                      fontScale: fontScale,
                      onTap: onTap,
                    ),
                    _NavItem(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.record_voice_over_outlined,
                      activeIcon: Icons.record_voice_over,
                      label: context.tr('nav_practice'),
                      fontScale: fontScale,
                      onTap: onTap,
                    ),
                    _NavItem(
                      index: 2,
                      currentIndex: currentIndex,
                      icon: Icons.event_note_outlined,
                      activeIcon: Icons.event_note_rounded,
                      label: context.tr('nav_everyday'),
                      fontScale: fontScale,
                      onTap: onTap,
                    ),
                    _NavItem(
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart_rounded,
                      label: context.tr('nav_progress'),
                      fontScale: fontScale,
                      onTap: onTap,
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final double fontScale;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.fontScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey(isActive),
                    size: 24,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 11 * fontScale,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                  child: Text(label),
                ),
                if (isActive)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(top: 2),
                    width: 18,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared top AppBar used across all elderly screens
/// Matches Stitch: logo + screen name (left), volume + font-size + avatar (right)
class SmritiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String screenLabel;
  final VoidCallback? onVolumePressed;
  final VoidCallback? onFontSizePressed;
  final VoidCallback? onAvatarPressed;

  const SmritiAppBar({
    super.key,
    required this.screenLabel,
    this.onVolumePressed,
    this.onFontSizePressed,
    this.onAvatarPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Container(
      height: 72 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: AppColors.canvasIvory,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A2D241C),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 410;
            return Row(
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (context, child, extra) => Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.terracottaSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology, color: AppColors.primary, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // App name + screen context
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'SmritiVeda',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.newsreader(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (DbService().isDemoModeActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.sandalwoodGold.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.sandalwoodGold, width: 1),
                              ),
                              child: Text(
                                'Demo',
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.terracottaPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        screenLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.03 * 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // SmritiVeda AI Assistant Quick Button
                _HeaderButton(
                  icon: Icons.smart_toy_rounded,
                  color: AppColors.terracottaPrimary,
                  bgColor: AppColors.terracottaSoft,
                  hoverColor: AppColors.terracottaSoft,
                  onPressed: () => _openAiAssistantDialog(context, appState),
                  tooltip: 'SmritiVeda AI Assistant',
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 6),
                  // Ambient BGM Music Toggle
                  ListenableBuilder(
                    listenable: SoundService(),
                    builder: (context, _) {
                      final isBgmOn = SoundService().isBgmActive;
                      return _HeaderButton(
                        icon: isBgmOn ? Icons.music_note : Icons.music_off,
                        color: isBgmOn ? AppColors.terracottaPrimary : AppColors.textSecondary,
                        bgColor: isBgmOn ? AppColors.terracottaSoft : AppColors.surfaceCream,
                        hoverColor: AppColors.terracottaSoft,
                        onPressed: () {
                          SoundService().toggleBgm();
                          SoundService.playTap();
                        },
                        tooltip: isBgmOn ? 'Mute Background Music' : 'Play Serene BGM Music',
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  // Volume / TTS button
                  _HeaderButton(
                    icon: Icons.volume_up_outlined,
                    color: AppColors.primary,
                    bgColor: AppColors.surfaceCream,
                    hoverColor: AppColors.terracottaSoft,
                    onPressed: onVolumePressed ?? () {},
                    tooltip: 'Listen to daily overview',
                  ),
                ],
                const SizedBox(width: 6),
                // Font size toggle
                _HeaderButton(
                  icon: Icons.format_size_outlined,
                  color: AppColors.secondary,
                  bgColor: AppColors.surfaceCream,
                  hoverColor: AppColors.sageSoft,
                  onPressed: onFontSizePressed ?? () {
                    final next = appState.fontScale >= 1.3 ? 1.0 : appState.fontScale + 0.1;
                    appState.setFontScale(next);
                  },
                  tooltip: 'Adjust text size',
                ),
                const SizedBox(width: 6),
                // Profile avatar & Top-Right Menu
                const TopRightUserMenu(),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openAiAssistantDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.smart_toy_rounded, color: AppColors.terracottaPrimary),
            const SizedBox(width: 8),
            Text(
              'SmritiVeda AI Assistant',
              style: GoogleFonts.newsreader(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.terracottaPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.terracottaSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.terracottaPrimary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Hello ${appState.userName}! Choose an AI service below:\n\n'
                  '• SmritiVeda Chatbot: Conversational AI with voice support, app guides, and wellness tips.\n'
                  '• AI Game Architect: Procedural brain game generator powered by cognitive science.',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 14,
                    color: AppColors.charcoalText,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    side: const BorderSide(color: AppColors.terracottaPrimary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.terracottaPrimary, size: 20),
                  label: Text(
                    'Open Full Chatbot',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.terracottaPrimary,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SmritiVedaChatbotScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.videogame_asset, size: 20),
                  label: Text(
                    '🎮 AI Game Architect',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiGameGeneratorScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color hoverColor;
  final VoidCallback onPressed;
  final String tooltip;

  const _HeaderButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.hoverColor,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed ? widget.hoverColor : widget.bgColor,
          ),
          child: Icon(widget.icon, color: widget.color, size: 22),
        ),
      ),
    );
  }
}
