import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/game_difficulty.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';

class DifficultySelector extends StatelessWidget {
  final GameDifficulty selected;
  final ValueChanged<GameDifficulty> onChanged;
  final List<GameDifficulty> supported;

  const DifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.supported = const [
      GameDifficulty.easy,
      GameDifficulty.medium,
      GameDifficulty.hard,
    ],
  });

  @override
  Widget build(BuildContext context) {
    double fontScale = 1.0;
    try {
      fontScale = AppStateScope.of(context).fontScale;
    } catch (_) {}

    return Semantics(
      label: 'Difficulty level selector: current difficulty is ',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: supported.map((diff) {
            final isSelected = diff == selected;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (!isSelected) {
                      SoundService.playTap();
                      onChanged(diff);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.terracottaPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.terracottaPrimary
                            : AppColors.sandalwoodGold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      diff.label,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.charcoalText,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          ),
        ),
      ),
    );
  }
}
