import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../locales/app_localizations.dart';
import '../providers/app_state.dart';
import '../screens/smritiveda_chatbot_screen.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class SmritiVedaAssistantFab extends StatelessWidget {
  const SmritiVedaAssistantFab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.maybeOf(context);
    final fontScale = appState?.fontScale ?? 1.0;

    return Semantics(
      label: 'Ask SmritiVeda cognitive voice and text assistant button',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            SoundService.playTap();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SmritiVedaChatbotScreen()),
            );
          },
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.terracottaPrimary, Color(0xFFD46A43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x32B85028),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.tr('btn_ask_smritiveda'),
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 14 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
