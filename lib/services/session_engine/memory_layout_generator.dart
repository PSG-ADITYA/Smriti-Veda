import 'dart:math';

class Dice3DLayoutPosition {
  final int index;
  final double xOffset;
  final double yOffset;
  final double tiltX;
  final double tiltY;
  final double rotationZ;
  final double scale;

  const Dice3DLayoutPosition({
    required this.index,
    required this.xOffset,
    required this.yOffset,
    required this.tiltX,
    required this.tiltY,
    required this.rotationZ,
    this.scale = 1.0,
  });
}

class MemoryLayoutGenerator {
  static final Random _rng = Random();

  /// Generates a valid, non-overlapping sequence of grid indices for a path.
  /// Tries to generate adjacent walk steps when possible, falling back to distinct random cells.
  static List<int> generateGardenPath({
    required int gridSize,
    required int pathLength,
  }) {
    final totalCells = gridSize * gridSize;
    assert(pathLength <= totalCells);

    // Attempt adjacent random walk
    for (int attempt = 0; attempt < 10; attempt++) {
      final List<int> path = [];
      final Set<int> visited = {};

      int current = _rng.nextInt(totalCells);
      path.add(current);
      visited.add(current);

      bool walkSucceeded = true;
      for (int step = 1; step < pathLength; step++) {
        final r = current ~/ gridSize;
        final c = current % gridSize;

        final neighbors = <int>[];
        if (r > 0) neighbors.add((r - 1) * gridSize + c);
        if (r < gridSize - 1) neighbors.add((r + 1) * gridSize + c);
        if (c > 0) neighbors.add(r * gridSize + (c - 1));
        if (c < gridSize - 1) neighbors.add(r * gridSize + (c + 1));

        final unvisitedNeighbors = neighbors.where((n) => !visited.contains(n)).toList();
        if (unvisitedNeighbors.isEmpty) {
          walkSucceeded = false;
          break;
        }
        unvisitedNeighbors.shuffle(_rng);
        current = unvisitedNeighbors.first;
        path.add(current);
        visited.add(current);
      }

      if (walkSucceeded && path.length == pathLength) {
        return path;
      }
    }

    // Fallback: distinct shuffled indices
    final all = List<int>.generate(totalCells, (i) => i)..shuffle(_rng);
    return all.take(pathLength).toList();
  }

  /// Generates an illuminated pattern of tiles on a grid.
  static Set<int> generatePatternGrid({
    required int gridSize,
    required int activeTiles,
  }) {
    final totalCells = gridSize * gridSize;
    final all = List<int>.generate(totalCells, (i) => i)..shuffle(_rng);
    return all.take(activeTiles.clamp(1, totalCells)).toSet();
  }

  /// Generates balanced 3D tabletop coordinates for 2 to 6 dice.
  static List<Dice3DLayoutPosition> generateDiceTabletopLayout({
    required int diceCount,
  }) {
    final count = diceCount.clamp(2, 6);
    final List<Dice3DLayoutPosition> positions = [];

    // Base horizontal spacing along tabletop arc
    // Angles in radians for slight realistic tabletop scatter
    final baseAngles = [-0.12, 0.08, -0.05, 0.14, -0.09, 0.06];
    final baseTiltsX = [0.15, 0.18, 0.12, 0.20, 0.16, 0.14];
    final baseTiltsY = [-0.18, 0.12, -0.08, 0.15, -0.12, 0.10];

    for (int i = 0; i < count; i++) {
      // Horizontal positioning across tabletop
      final progress = count > 1 ? (i / (count - 1)) : 0.5; // 0.0 to 1.0
      // Arc curve: dice on edges are slightly higher/deeper
      final arcY = -12.0 * sin(progress * pi);
      final x = (progress - 0.5) * (count <= 3 ? 180.0 : 260.0);

      positions.add(Dice3DLayoutPosition(
        index: i,
        xOffset: x,
        yOffset: arcY,
        tiltX: baseTiltsX[i % baseTiltsX.length],
        tiltY: baseTiltsY[i % baseTiltsY.length],
        rotationZ: baseAngles[i % baseAngles.length],
        scale: 1.0,
      ));
    }

    return positions;
  }

  /// Distributes target objects and distractors onto grid cells.
  static Map<int, T> distributeItemsOnGrid<T>({
    required int gridSize,
    required List<T> items,
  }) {
    final total = gridSize * gridSize;
    final indices = List<int>.generate(total, (i) => i)..shuffle(_rng);

    final Map<int, T> map = {};
    for (int i = 0; i < items.length && i < total; i++) {
      map[indices[i]] = items[i];
    }
    return map;
  }
}
