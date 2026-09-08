import '../models/game_difficulty.dart';
import '../services/session_engine/memory_session_generator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_attempt.dart';
import '../providers/app_state.dart';
import '../services/motivational_quote_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class RoomScene {
  final String title;
  final String subtitle;
  final IconData sceneIcon;
  final Map<String, IconData> targetObjects;
  final Map<String, IconData> distractorObjects;

  const RoomScene({
    required this.title,
    required this.subtitle,
    required this.sceneIcon,
    required this.targetObjects,
    required this.distractorObjects,
  });
}

const List<RoomScene> kRoomScenes = [
  RoomScene(
    title: 'Reading Room & Study Table',
    subtitle: 'Memorize the items resting on grandfather\'s study table.',
    sceneIcon: Icons.menu_book_rounded,
    targetObjects: {
      'Reading Glasses': Icons.visibility_outlined,
      'Hardcover Book': Icons.menu_book_outlined,
      'Wrist Watch': Icons.watch_later_outlined,
      'Warm Tea Cup': Icons.coffee_outlined,
      'Brass Keyring': Icons.vpn_key_outlined,
    },
    distractorObjects: {
      'Smartphone': Icons.phone_android_rounded,
      'Umbrella': Icons.beach_access_outlined,
      'Flashlight': Icons.flashlight_on_outlined,
      'Headphones': Icons.headphones_outlined,
    },
  ),
  RoomScene(
    title: 'Morning Kitchen & Pantry Shelf',
    subtitle: 'Notice the cooking staples placed on the wooden shelf.',
    sceneIcon: Icons.kitchen_rounded,
    targetObjects: {
      'Spice Masala Box': Icons.grain_rounded,
      'Steel Water Jug': Icons.local_drink_rounded,
      'Mortar & Pestle': Icons.soup_kitchen_rounded,
      'Honey Bottle': Icons.sanitizer_rounded,
      'Clay Tea Pot': Icons.emoji_food_beverage_rounded,
    },
    distractorObjects: {
      'Microwave Oven': Icons.microwave_rounded,
      'Plastic Straw': Icons.straighten_rounded,
      'Ice Cream Bowl': Icons.icecream_rounded,
      'Sports Bottle': Icons.sports_bar_rounded,
    },
  ),
  RoomScene(
    title: 'Veranda & Tulsi Garden',
    subtitle: 'Observe the morning garden items on the veranda.',
    sceneIcon: Icons.yard_rounded,
    targetObjects: {
      'Watering Can': Icons.opacity_rounded,
      'Tulsi Clay Planter': Icons.local_florist_rounded,
      'Straw Sun Hat': Icons.face_retouching_natural_rounded,
      'Brass Prayer Bell': Icons.notifications_active_outlined,
      'Comfort Walking Cane': Icons.elderly_rounded,
    },
    distractorObjects: {
      'Lawn Mower': Icons.settings_rounded,
      'Car Battery': Icons.battery_alert_rounded,
      'Drone Toy': Icons.flight_takeoff_rounded,
      'Sunglasses': Icons.wb_sunny_outlined,
    },
  ),
  RoomScene(
    title: 'Weekly Market & Grocery Basket',
    subtitle: 'Remember the fresh provisions selected from the morning bazaar.',
    sceneIcon: Icons.shopping_basket_rounded,
    targetObjects: {
      'Rice Bag': Icons.shopping_bag_outlined,
      'Fresh Milk Bottle': Icons.liquor_outlined,
      'Turmeric Root': Icons.spa_outlined,
      'Green Apples': Icons.apple_outlined,
      'Ayurvedic Balm': Icons.medication_liquid_outlined,
    },
    distractorObjects: {
      'Laptop Charger': Icons.power_outlined,
      'Skateboard': Icons.roller_skating_outlined,
      'Gaming Mouse': Icons.mouse_outlined,
      'Cricket Bat': Icons.sports_cricket_outlined,
    },
  ),
];

enum ObjectGamePhase {
  study,
  recall,
  summary,
}

class ObjectMemoryScreen extends StatefulWidget {
  const ObjectMemoryScreen({super.key});

  @override
  State<ObjectMemoryScreen> createState() => _ObjectMemoryScreenState();
}

class _ObjectMemoryScreenState extends State<ObjectMemoryScreen> {
  int _sceneIndex = 0;
  ObjectGamePhase _phase = ObjectGamePhase.study;

  late Set<String> _targetSet;
  late List<MapEntry<String, IconData>> _choiceGrid;
  final Set<String> _userSelections = {};
  final Stopwatch _stopwatch = Stopwatch();

  int _correctCount = 0;
  int _falseCount = 0;
  double _scorePct = 0.0;


  @override
  void initState() {
    super.initState();
    _loadScene();
  }

  RoomScene? _dynamicScene;
  RoomScene get _activeScene => _dynamicScene ?? kRoomScenes.first;

  void _loadScene() {
    _phase = ObjectGamePhase.study;
    _userSelections.clear();
    final session = MemorySessionGenerator.generateObjectSession(GameDifficulty.medium);
    final targetMap = {for (final t in session.stimulus.targets) t.name: t.icon};
    final distractorMap = {for (final d in session.stimulus.distractors) d.name: d.icon};

    _dynamicScene = RoomScene(
      title: session.stimulus.roomTitle,
      subtitle: session.stimulus.roomSubtitle,
      sceneIcon: Icons.room_preferences_rounded,
      targetObjects: targetMap,
      distractorObjects: distractorMap,
    );

    _targetSet = Set.from(targetMap.keys);
    final allItems = [
      ...targetMap.entries,
      ...distractorMap.entries,
    ]..shuffle();

    _choiceGrid = allItems;
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {});
  }

  void _startRecall() {
    SoundService.playTap();
    setState(() {
      _phase = ObjectGamePhase.recall;
      _userSelections.clear();
    });
    SoundService.speak('Now tap the items that were in the ${_activeScene.title}.');
  }

  void _toggleSelection(String itemName) {
    if (_phase != ObjectGamePhase.recall) return;
    SoundService.playTap();

    setState(() {
      if (_userSelections.contains(itemName)) {
        _userSelections.remove(itemName);
      } else {
        _userSelections.add(itemName);
      }
    });
  }

  Future<void> _submit(AppState appState) async {
    _stopwatch.stop();

    _correctCount = 0;
    _falseCount = 0;

    for (final item in _userSelections) {
      if (_targetSet.contains(item)) {
        _correctCount++;
      } else {
        _falseCount++;
      }
    }

    final rawScore = (_correctCount - _falseCount).clamp(0, _targetSet.length).toDouble();
    final maxScore = _targetSet.length.toDouble();
    _scorePct = (rawScore / maxScore) * 100.0;

    setState(() {
      _phase = ObjectGamePhase.summary;
    });

    if (_scorePct >= 60.0) {
      SoundService.playFanfare();
      if (mounted) {
        ConfettiOverlay.show(
          context,
          title: 'Sharp Visual Recall! 👁️',
          subtitle: 'Identified $_correctCount of ${_targetSet.length} items correctly!',
        );
      }
    } else {
      SoundService.playError();
    }

    // Log attempt into repository
    await appState.attemptRepository.logAttempt(
      ExerciseAttempt(
        id: 'att_obj_${DateTime.now().millisecondsSinceEpoch}',
        userId: appState.credentialId,
        domain: ExerciseDomain.universalCognitive,
        cognitiveDomain: CognitiveDomain.visualMemory,
        type: ExerciseType.recognition,
        exerciseId: 'object_memory_scene_${_sceneIndex + 1}',
        responseMode: 'choice',
        rawScore: rawScore,
        maxScore: maxScore,
        timeTakenMs: _stopwatch.elapsedMilliseconds,
      ),
    );
  }

  void _nextSceneOrRestart() {
    if (_sceneIndex < kRoomScenes.length - 1) {
      _sceneIndex++;
    } else {
      _sceneIndex = 0;
    }
    _loadScene();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final fontScale = appState.fontScale;

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoalText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Object Recall Matrix',
          style: GoogleFonts.newsreader(
            fontSize: 20 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
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
                const Icon(Icons.visibility_rounded, size: 16, color: AppColors.terracottaPrimary),
                const SizedBox(width: 4),
                Text(
                  'Visual Memory',
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scene Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.4)),
                  boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.terracottaPrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_activeScene.sceneIcon, color: AppColors.terracottaPrimary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SCENE ${_sceneIndex + 1} OF ${kRoomScenes.length}',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 11 * fontScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppColors.terracottaPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _activeScene.title,
                            style: GoogleFonts.newsreader(
                              fontSize: 17 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _activeScene.subtitle,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 12 * fontScale,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Study Phase
              if (_phase == ObjectGamePhase.study) ...[
                Text(
                  'OBSERVE THESE ${_targetSet.length} OBJECTS CAREFULLY:',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.charcoalText,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activeScene.targetObjects.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, idx) {
                    final item = _activeScene.targetObjects.entries.elementAt(idx);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.5)),
                        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.sageSecondary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.value, color: AppColors.sageSecondary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.key,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13 * fontScale,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoalText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _startRecall,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                  label: Text(
                    'I Have Memorized Them ➔ Start Recall',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracottaPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],

              // Recall & Summary Phase
              if (_phase == ObjectGamePhase.recall || _phase == ObjectGamePhase.summary) ...[
                Text(
                  _phase == ObjectGamePhase.recall
                      ? 'WHICH OF THESE WERE IN THE SCENE? (SELECT ALL)'
                      : 'RESULTS FOR ${_activeScene.title.toUpperCase()}:',
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.charcoalText,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _choiceGrid.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, idx) {
                    final entry = _choiceGrid[idx];
                    final isSelected = _userSelections.contains(entry.key);
                    final isTarget = _targetSet.contains(entry.key);
                    final isSummary = _phase == ObjectGamePhase.summary;

                    Color bg = Colors.white;
                    Color border = Colors.black12;

                    if (!isSummary && isSelected) {
                      bg = AppColors.terracottaPrimary.withValues(alpha: 0.12);
                      border = AppColors.terracottaPrimary;
                    }

                    if (isSummary) {
                      if (isTarget && isSelected) {
                        bg = AppColors.sageSecondary.withValues(alpha: 0.18);
                        border = AppColors.sageSecondary;
                      } else if (!isTarget && isSelected) {
                        bg = AppColors.terracottaPrimary.withValues(alpha: 0.18);
                        border = AppColors.terracottaPrimary;
                      } else if (isTarget && !isSelected) {
                        bg = AppColors.sandalwoodGold.withValues(alpha: 0.15);
                        border = AppColors.sandalwoodGold;
                      }
                    }

                    return GestureDetector(
                      onTap: () => _toggleSelection(entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Icon(entry.value, color: AppColors.charcoalText, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 12 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoalText,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppColors.terracottaPrimary, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                if (_phase == ObjectGamePhase.recall)
                  ElevatedButton.icon(
                    onPressed: _userSelections.isNotEmpty ? () => _submit(appState) : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      'Submit Selections (${_userSelections.length})',
                      style: GoogleFonts.atkinsonHyperlegible(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sageSecondary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sandalwoodGold),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Score: ${_scorePct.toInt()}%',
                          style: GoogleFonts.newsreader(
                            fontSize: 22 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.terracottaPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Correctly recalled $_correctCount out of ${_targetSet.length} items.',
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 13 * fontScale, color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCream,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  MotivationalQuoteService.getRandomCelebrationQuote().text,
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 12 * fontScale,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _nextSceneOrRestart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracottaPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _sceneIndex < kRoomScenes.length - 1 ? 'Next Scene ➔' : 'Play From Scene 1',
                            style: GoogleFonts.atkinsonHyperlegible(fontSize: 15 * fontScale, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
