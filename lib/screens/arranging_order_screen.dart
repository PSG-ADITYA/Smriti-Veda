import '../models/game_difficulty.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class OrderItem {
  final String id;
  final String title;
  final String emoji;
  final String description;

  const OrderItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ArrangingOrderRound {
  final String roundTitle;
  final String instruction;
  final String difficulty;
  final List<OrderItem> items;

  const ArrangingOrderRound({
    required this.roundTitle,
    required this.instruction,
    required this.difficulty,
    required this.items,
  });
}

const Map<GameDifficulty, ArrangingOrderRound> kArrangingOrderConfigs = {
  GameDifficulty.easy: ArrangingOrderRound(
    roundTitle: 'Morning Awakening Cycle (4 Steps)',
    instruction: 'Arrange the morning routine into the healthy chronological sequence.',
    difficulty: 'Easy',
    items: [
      OrderItem(id: 'step_dawn', title: 'Wake Up & Deep Breath', emoji: '🌅', description: 'Begin day calmly with morning fresh air'),
      OrderItem(id: 'step_water', title: 'Drink Warm Copper Water', emoji: '💧', description: 'Rehydrate body and awaken digestion'),
      OrderItem(id: 'step_medicine', title: 'Morning Medicine & Stretch', emoji: '💊', description: 'Take prescribed morning health dose'),
      OrderItem(id: 'step_breakfast', title: 'Wholesome Breakfast & Tea', emoji: '🥣', description: 'Nourish energy with fresh fruits or porridge'),
    ],
  ),
  GameDifficulty.medium: ArrangingOrderRound(
    roundTitle: 'Traditional Masala Chai Brew (5 Steps)',
    instruction: 'Arrange the step-by-step culinary method for preparing aromatic spiced tea.',
    difficulty: 'Medium',
    items: [
      OrderItem(id: 'step_water_boil', title: 'Boil Fresh Water in Pot', emoji: '🫖', description: 'Heat clean water to a gentle roll'),
      OrderItem(id: 'step_crush_spice', title: 'Add Crushed Ginger & Cardamom', emoji: '🌿', description: 'Release therapeutic aromas'),
      OrderItem(id: 'step_tea_leaves', title: 'Stir in Assam Tea Leaves', emoji: '🍃', description: 'Simmer until deep golden liquor appears'),
      OrderItem(id: 'step_milk_simmer', title: 'Pour Warm Milk & Jaggery', emoji: '🥛', description: 'Bring to a rich creamy boil'),
      OrderItem(id: 'step_serve', title: 'Filter into Warm Clay Cup', emoji: '☕', description: 'Sip slowly and savor the warmth'),
    ],
  ),
  GameDifficulty.hard: ArrangingOrderRound(
    roundTitle: 'Bumper Harvest Cycle (6 Steps)',
    instruction: 'Sequence the complete agricultural journey from seed to celebratory feast.',
    difficulty: 'Hard',
    items: [
      OrderItem(id: 'step_soil', title: 'Plough & Enrich Soil', emoji: '🚜', description: 'Prepare fertile earth before the monsoon'),
      OrderItem(id: 'step_sow', title: 'Sow Sacred Golden Seeds', emoji: '🌱', description: 'Plant tender grains with optimism'),
      OrderItem(id: 'step_rain', title: 'Monsoon Rains & Weeding', emoji: '🌧️', description: 'Nurture crops through lush growing season'),
      OrderItem(id: 'step_ripen', title: 'Golden Crop Matures in Sun', emoji: '🌾', description: 'Fields turn radiant under autumn sky'),
      OrderItem(id: 'step_harvest', title: 'Sickle Harvest & Winnowing', emoji: '🌾', description: 'Gather the heavy sheaves with gratitude'),
      OrderItem(id: 'step_feast', title: 'Community Harvest Festival', emoji: '🎉', description: 'Share the fresh harvest with loved ones'),
    ],
  ),
};

class ArrangingOrderScreen extends StatefulWidget {
  const ArrangingOrderScreen({super.key});

  @override
  State<ArrangingOrderScreen> createState() => _ArrangingOrderScreenState();
}

class _ArrangingOrderScreenState extends State<ArrangingOrderScreen> {
  GameDifficulty _difficulty = GameDifficulty.easy;
  late List<OrderItem> _correctOrder;
  late List<OrderItem> _currentOrder;
  bool _isSubmitted = false;
  int _correctPositions = 0;
  final Stopwatch _stopwatch = Stopwatch();
  int _cumulativeScore = 0;

  ArrangingOrderRound get _currentRound => kArrangingOrderConfigs[_difficulty]!;

  @override
  void initState() {
    super.initState();
    _initRound();
  }

  void _initRound() {
    _isSubmitted = false;
    _correctPositions = 0;
    _correctOrder = List<OrderItem>.from(_currentRound.items);

    // Shuffle ensuring it does not accidentally equal correctOrder
    final random = Random();
    List<OrderItem> shuffled = List<OrderItem>.from(_correctOrder);
    int attempts = 0;
    do {
      shuffled.shuffle(random);
      attempts++;
    } while (_isEqualOrder(shuffled, _correctOrder) && attempts < 10);

    _currentOrder = shuffled;
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {});
  }

  bool _isEqualOrder(List<OrderItem> a, List<OrderItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _moveItem(int oldIndex, int newIndex) {
    if (_isSubmitted) return;
    SoundService.playTap();
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
    });
  }

  void _shiftUp(int index) {
    if (_isSubmitted || index <= 0) return;
    SoundService.playTap();
    setState(() {
      final item = _currentOrder.removeAt(index);
      _currentOrder.insert(index - 1, item);
    });
  }

  void _shiftDown(int index) {
    if (_isSubmitted || index >= _currentOrder.length - 1) return;
    SoundService.playTap();
    setState(() {
      final item = _currentOrder.removeAt(index);
      _currentOrder.insert(index + 1, item);
    });
  }

  void _checkAnswer(AppState appState) async {
    if (_isSubmitted) return;
    _stopwatch.stop();

    int matches = 0;
    for (int i = 0; i < _currentOrder.length; i++) {
      if (_currentOrder[i].id == _correctOrder[i].id) {
        matches++;
      }
    }

    final total = _correctOrder.length;
    final accuracyPct = (matches / total * 100.0).round();
    _correctPositions = matches;
    _cumulativeScore += accuracyPct;

    setState(() {
      _isSubmitted = true;
    });

    if (matches == total) {
      SoundService.playFanfare();
      if (mounted) {
        ConfettiOverlay.show(
          context,
          title: 'Perfect Sequence! 🌟',
          subtitle: 'All $total positions arranged in exact chronological order!',
        );
      }
    } else if (matches >= total / 2) {
      SoundService.playSuccess();
    } else {
      SoundService.playError();
    }

    // Persist attempt into repository
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_order_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.universalCognitive,
        cognitiveDomain: CognitiveDomain.sequentialMemory,
        type: ExerciseType.sequenceRecall,
        exerciseId: 'arranging_order_${_difficulty.name}',
        responseMode: 'reorder',
        rawScore: matches.toDouble(),
        maxScore: total.toDouble(),
        timeTakenMs: _stopwatch.elapsedMilliseconds,
      ),
    );
  }

  void _resetCurrentRound() {
    SoundService.playTap();
    _initRound();
  }

  void _nextRound() {
    SoundService.playTap();
    if (_difficulty == GameDifficulty.easy) {
      setState(() => _difficulty = GameDifficulty.medium);
    } else if (_difficulty == GameDifficulty.medium) {
      setState(() => _difficulty = GameDifficulty.hard);
    }
    _initRound();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;
    final total = _correctOrder.length;
    final accuracy = total > 0 ? (_correctPositions / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.charcoalText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Arranging Order',
          style: GoogleFonts.newsreader(
            fontSize: 22 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoalText,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.terracottaPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.low_priority_rounded, size: 16, color: AppColors.terracottaPrimary),
                const SizedBox(width: 4),
                Text(
                  'Sequential Memory',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terracottaPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Information Card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.4)),
                  boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.terracottaSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_difficulty.label.toUpperCase()} DIFFICULTY • ${_correctOrder.length} STEPS',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 11 * fontScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.terracottaPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'Total Score: $_cumulativeScore',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sageSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentRound.roundTitle,
                      style: GoogleFonts.newsreader(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoalText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentRound.instruction,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        color: AppColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Subtitle / Visual Hint ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ARRANGE FROM TOP (FIRST) TO BOTTOM (LAST):',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 12 * fontScale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.charcoalText,
                      ),
                    ),
                  ),
                  if (!_isSubmitted)
                    TextButton.icon(
                      onPressed: _resetCurrentRound,
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.secondaryText),
                      label: Text(
                        'Shuffle',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 12 * fontScale,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Reorderable Interactive List ──
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _currentOrder.length,
                // ignore: deprecated_member_use
                onReorder: _moveItem,
                itemBuilder: (context, idx) {
                  final item = _currentOrder[idx];
                  final isPositionCorrect = _isSubmitted && item.id == _correctOrder[idx].id;
                  final isPositionWrong = _isSubmitted && item.id != _correctOrder[idx].id;

                  return Container(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isPositionCorrect
                          ? AppColors.sageSecondary.withValues(alpha: 0.12)
                          : isPositionWrong
                              ? AppColors.terracottaPrimary.withValues(alpha: 0.12)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPositionCorrect
                            ? AppColors.sageSecondary
                            : isPositionWrong
                                ? AppColors.terracottaPrimary
                                : AppColors.sandalwoodGold.withValues(alpha: 0.5),
                        width: isPositionCorrect || isPositionWrong ? 1.8 : 1.2,
                      ),
                      boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4)],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Position Number Badge
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: isPositionCorrect
                              ? AppColors.sageSecondary
                              : isPositionWrong
                                  ? AppColors.terracottaPrimary
                                  : AppColors.terracottaPrimary,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Item Emoji
                        Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(width: 12),

                        // Item Title & Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 15 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoalText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.description,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 12 * fontScale,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Evaluated Icon / Reorder Controls
                        if (_isSubmitted) ...[
                          Icon(
                            isPositionCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isPositionCorrect ? AppColors.sageSecondary : AppColors.terracottaPrimary,
                            size: 24,
                          ),
                        ] else ...[
                          // Accessible Up/Down Buttons for Elderly Touch Accessibility
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                                color: idx > 0 ? AppColors.charcoalText : Colors.black12,
                                tooltip: 'Move Up',
                                onPressed: idx > 0 ? () => _shiftUp(idx) : null,
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward_rounded, size: 20),
                                color: idx < _currentOrder.length - 1 ? AppColors.charcoalText : Colors.black12,
                                tooltip: 'Move Down',
                                onPressed: idx < _currentOrder.length - 1 ? () => _shiftDown(idx) : null,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 4),
                              ReorderableDragStartListener(
                                index: idx,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.drag_indicator_rounded,
                                    color: Colors.black54,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Action / Evaluation Section ──
              if (!_isSubmitted) ...[
                ElevatedButton.icon(
                  onPressed: () => _checkAnswer(appState),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
                  label: Text(
                    'Check Answer',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ] else ...[
                // Results Feedback Box
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _correctPositions == total
                          ? AppColors.sageSecondary
                          : AppColors.terracottaPrimary,
                      width: 1.5,
                    ),
                    boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)],
                  ),
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Icon(
                            _correctPositions == total
                                ? Icons.emoji_events_rounded
                                : Icons.psychology_rounded,
                            color: _correctPositions == total
                                ? AppColors.sageSecondary
                                : AppColors.terracottaPrimary,
                            size: 28,
                          ),
                          Text(
                            _correctPositions == total
                                ? 'Excellent! Perfect Order!'
                                : '$_correctPositions of $total positions correct.',
                            style: GoogleFonts.newsreader(
                              fontSize: 18 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Accuracy: $accuracy%',
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 14 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _resetCurrentRound,
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: Text(
                                'Try Again',
                                style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.charcoalText,
                                minimumSize: const Size.fromHeight(48),
                                side: const BorderSide(color: AppColors.sandalwoodGold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _nextRound,
                              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                              label: Text(
                                _difficulty != GameDifficulty.hard ? 'Try Next Difficulty' : 'Play Again',
                                style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.terracottaPrimary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
