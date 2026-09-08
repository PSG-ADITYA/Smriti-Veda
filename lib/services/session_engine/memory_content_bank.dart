import 'package:flutter/material.dart';

class FruitStimulus {
  final String id;
  final String name;
  final String emoji;
  final Color color;

  const FruitStimulus({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });
}

class ObjectStimulus {
  final String id;
  final String name;
  final String category; // Pooja, Kitchen, Garden, Daily Life
  final IconData icon;

  const ObjectStimulus({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
  });
}

class FocusThemeStimulus {
  final String id;
  final String title;
  final String targetName;
  final String targetEmoji;
  final String distractorName;
  final String distractorEmoji;

  const FocusThemeStimulus({
    required this.id,
    required this.title,
    required this.targetName,
    required this.targetEmoji,
    required this.distractorName,
    required this.distractorEmoji,
  });
}

class SequenceStimulus {
  final String id;
  final String title;
  final String category;
  final List<String> items;

  const SequenceStimulus({
    required this.id,
    required this.title,
    required this.category,
    required this.items,
  });
}

class HeritageStoryStimulus {
  final String id;
  final String title;
  final String region;
  final String body;
  final List<Map<String, dynamic>> questions;

  const HeritageStoryStimulus({
    required this.id,
    required this.title,
    required this.region,
    required this.body,
    required this.questions,
  });
}

class RoutineScenarioStimulus {
  final String id;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> steps;

  const RoutineScenarioStimulus({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.steps,
  });
}

class WordStimulus {
  final String word;
  final String category; // Nature, Heritage, Food, Daily Life, Geography
  final String hint;

  const WordStimulus({
    required this.word,
    required this.category,
    required this.hint,
  });
}

class MemoryContentBank {
  // ── 1. Fruits Bank (16 traditional fruits) ───────────────────────────
  static const List<FruitStimulus> fruits = [
    FruitStimulus(id: 'mango', name: 'Mango', emoji: '🥭', color: Color(0xFFFFA000)),
    FruitStimulus(id: 'guava', name: 'Guava', emoji: '🍈', color: Color(0xFF81C784)),
    FruitStimulus(id: 'pomegranate', name: 'Pomegranate', emoji: '🫐', color: Color(0xFFE53935)),
    FruitStimulus(id: 'banana', name: 'Banana', emoji: '🍌', color: Color(0xFFFDD835)),
    FruitStimulus(id: 'papaya', name: 'Papaya', emoji: '🍑', color: Color(0xFFFF8A65)),
    FruitStimulus(id: 'jamun', name: 'Jamun', emoji: '🍇', color: Color(0xFF5E35B1)),
    FruitStimulus(id: 'coconut', name: 'Coconut', emoji: '🥥', color: Color(0xFF8D6E63)),
    FruitStimulus(id: 'amla', name: 'Amla', emoji: '🍏', color: Color(0xFF689F38)),
    FruitStimulus(id: 'sapota', name: 'Chiku', emoji: '🥔', color: Color(0xFF795548)),
    FruitStimulus(id: 'apple', name: 'Red Apple', emoji: '🍎', color: Color(0xFFD32F2F)),
    FruitStimulus(id: 'orange', name: 'Orange', emoji: '🍊', color: Color(0xFFFB8C00)),
    FruitStimulus(id: 'fig', name: 'Anjeer Fig', emoji: '🫒', color: Color(0xFF4E342E)),
    FruitStimulus(id: 'watermelon', name: 'Watermelon', emoji: '🍉', color: Color(0xFF43A047)),
    FruitStimulus(id: 'sweetlime', name: 'Sweet Lime', emoji: '🍋', color: Color(0xFFC0CA33)),
    FruitStimulus(id: 'pineapple', name: 'Pineapple', emoji: '🍍', color: Color(0xFFFFB300)),
    FruitStimulus(id: 'grapes', name: 'Green Grapes', emoji: '🍇', color: Color(0xFF7CB342)),
  ];

  // ── 2. Cultural & Household Objects (32 items) ────────────────────────
  static const List<ObjectStimulus> objects = [
    ObjectStimulus(id: 'bell', name: 'Brass Prayer Bell', category: 'Pooja', icon: Icons.notifications_active_outlined),
    ObjectStimulus(id: 'diya', name: 'Clay Oil Diya', category: 'Pooja', icon: Icons.local_fire_department_outlined),
    ObjectStimulus(id: 'tulsi', name: 'Tulsi Clay Planter', category: 'Garden', icon: Icons.local_florist_rounded),
    ObjectStimulus(id: 'tumbler', name: 'Copper Water Tumbler', category: 'Kitchen', icon: Icons.local_drink_rounded),
    ObjectStimulus(id: 'glasses', name: 'Reading Glasses', category: 'Daily Life', icon: Icons.visibility_outlined),
    ObjectStimulus(id: 'stick', name: 'Walking Cane', category: 'Daily Life', icon: Icons.elderly_rounded),
    ObjectStimulus(id: 'book', name: 'Hardcover Gita Book', category: 'Daily Life', icon: Icons.menu_book_outlined),
    ObjectStimulus(id: 'sandalwood', name: 'Sandalwood Paste Bowl', category: 'Pooja', icon: Icons.spa_outlined),
    ObjectStimulus(id: 'masala', name: 'Spice Masala Box', category: 'Kitchen', icon: Icons.grain_rounded),
    ObjectStimulus(id: 'mortar', name: 'Stone Mortar & Pestle', category: 'Kitchen', icon: Icons.soup_kitchen_rounded),
    ObjectStimulus(id: 'garland', name: 'Jasmine Garland', category: 'Pooja', icon: Icons.yard_rounded),
    ObjectStimulus(id: 'watch', name: 'Wrist Watch', category: 'Daily Life', icon: Icons.watch_later_outlined),
    ObjectStimulus(id: 'shawl', name: 'Khadi Handloom Shawl', category: 'Daily Life', icon: Icons.checkroom_rounded),
    ObjectStimulus(id: 'radio', name: 'Transistor Radio', category: 'Daily Life', icon: Icons.radio_rounded),
    ObjectStimulus(id: 'coin', name: 'Silver Puja Coin', category: 'Pooja', icon: Icons.monetization_on_outlined),
    ObjectStimulus(id: 'teapot', name: 'Clay Chai Teapot', category: 'Kitchen', icon: Icons.emoji_food_beverage_rounded),
    ObjectStimulus(id: 'keyring', name: 'Brass Keyring', category: 'Daily Life', icon: Icons.vpn_key_outlined),
    ObjectStimulus(id: 'honey', name: 'Pure Honey Jar', category: 'Kitchen', icon: Icons.sanitizer_rounded),
    ObjectStimulus(id: 'ricebag', name: 'Jute Rice Bag', category: 'Kitchen', icon: Icons.shopping_bag_outlined),
    ObjectStimulus(id: 'watercan', name: 'Garden Watering Can', category: 'Garden', icon: Icons.opacity_rounded),
    ObjectStimulus(id: 'hat', name: 'Straw Garden Hat', category: 'Garden', icon: Icons.face_retouching_natural_rounded),
    ObjectStimulus(id: 'umbrella', name: 'Black Umbrella', category: 'Daily Life', icon: Icons.beach_access_outlined),
    ObjectStimulus(id: 'torch', name: 'Handheld Flashlight', category: 'Daily Life', icon: Icons.flashlight_on_outlined),
    ObjectStimulus(id: 'conch', name: 'Sacred Shankh', category: 'Pooja', icon: Icons.volume_up_outlined),
    ObjectStimulus(id: 'jug', name: 'Steel Milk Jug', category: 'Kitchen', icon: Icons.liquor_outlined),
    ObjectStimulus(id: 'turmeric', name: 'Raw Turmeric Root', category: 'Kitchen', icon: Icons.healing_rounded),
    ObjectStimulus(id: 'balm', name: 'Herbal Pain Balm', category: 'Daily Life', icon: Icons.medication_liquid_outlined),
    ObjectStimulus(id: 'cushion', name: 'Velvet Meditation Cushion', category: 'Daily Life', icon: Icons.chair_rounded),
    ObjectStimulus(id: 'fan', name: 'Bamboo Hand Fan', category: 'Daily Life', icon: Icons.air_rounded),
    ObjectStimulus(id: 'locks', name: 'Iron Padlock & Key', category: 'Daily Life', icon: Icons.lock_outline_rounded),
    ObjectStimulus(id: 'beads', name: 'Rudraksha Japa Mala', category: 'Pooja', icon: Icons.fiber_manual_record_outlined),
    ObjectStimulus(id: 'calendar', name: 'Panchang Wall Calendar', category: 'Daily Life', icon: Icons.calendar_month_rounded),
  ];

  // ── 3. Visual Focus Themes (12 themes) ────────────────────────────────
  static const List<FocusThemeStimulus> focusThemes = [
    FocusThemeStimulus(id: 'th1', title: 'Morning Sky Focus', targetName: 'Golden Sun', targetEmoji: '☀️', distractorName: 'Rain Cloud', distractorEmoji: '☁️'),
    FocusThemeStimulus(id: 'th2', title: 'Spring Garden Search', targetName: 'Green Sprout', targetEmoji: '🌱', distractorName: 'Dry Leaf', distractorEmoji: '🍂'),
    FocusThemeStimulus(id: 'th3', title: 'Sacred River Bloom', targetName: 'Lotus Flower', targetEmoji: '🪷', distractorName: 'River Stone', distractorEmoji: '🪨'),
    FocusThemeStimulus(id: 'th4', title: 'Forest Canopy Scan', targetName: 'Singing Bird', targetEmoji: '🐦', distractorName: 'Pine Cone', distractorEmoji: '🪵'),
    FocusThemeStimulus(id: 'th5', title: 'Evening Courtyard Diya', targetName: 'Burning Flame', targetEmoji: '🪔', distractorName: 'Clay Pot', distractorEmoji: '🏺'),
    FocusThemeStimulus(id: 'th6', title: 'Spice Bazaar Counting', targetName: 'Cardamom Pod', targetEmoji: '🌿', distractorName: 'Clove Bud', distractorEmoji: '🌰'),
    FocusThemeStimulus(id: 'th7', title: 'Monsoon Village Pond', targetName: 'Swimming Fish', targetEmoji: '🐟', distractorName: 'Lily Pad', distractorEmoji: '🍃'),
    FocusThemeStimulus(id: 'th8', title: 'Mango Orchard Harvest', targetName: 'Ripe Mango', targetEmoji: '🥭', distractorName: 'Green Leaf', distractorEmoji: '☘️'),
    FocusThemeStimulus(id: 'th9', title: 'Temple Gate Petals', targetName: 'Marigold Flower', targetEmoji: '🌼', distractorName: 'Banyan Leaf', distractorEmoji: '🍁'),
    FocusThemeStimulus(id: 'th10', title: 'Night Constellation Walk', targetName: 'Bright Star', targetEmoji: '⭐', distractorName: 'Crescent Moon', distractorEmoji: '🌙'),
    FocusThemeStimulus(id: 'th11', title: 'Farmer Field Gleaning', targetName: 'Golden Wheat', targetEmoji: '🌾', distractorName: 'Wild Grass', distractorEmoji: '🌱'),
    FocusThemeStimulus(id: 'th12', title: 'Seashore Conch Search', targetName: 'Spiral Shell', targetEmoji: '🐚', distractorName: 'Pebble Stone', distractorEmoji: '🪨'),
  ];

  // ── 4. Thematic Sequences Bank (20 sequences) ─────────────────────────
  static const List<SequenceStimulus> sequences = [
    SequenceStimulus(id: 'seq1', title: 'Three Sacred Rivers', category: 'Geography', items: ['Ganga 🌊', 'Yamuna 🌿', 'Brahmaputra 🏔️']),
    SequenceStimulus(id: 'seq2', title: 'Five Morning Routine Steps', category: 'Routine', items: ['Dawn 🌅', 'Prayer 🪔', 'Water 💧', 'Walk 🚶', 'Tea ☕']),
    SequenceStimulus(id: 'seq3', title: 'Six Memory Digits', category: 'Numbers', items: ['7️⃣', '2️⃣', '9️⃣', '4️⃣', '1️⃣', '8️⃣']),
    SequenceStimulus(id: 'seq4', title: 'Five Natural Elements (Pancha Bhootas)', category: 'Philosophy', items: ['Earth 🌍', 'Water 💧', 'Fire 🔥', 'Air 💨', 'Space 🌌']),
    SequenceStimulus(id: 'seq5', title: 'Four Heritage Seasons', category: 'Nature', items: ['Vasant (Spring) 🌸', 'Grishma (Summer) ☀️', 'Varsha (Monsoon) 🌧️', 'Sharad (Autumn) 🍁']),
    SequenceStimulus(id: 'seq6', title: 'Traditional Masala Chai Preparation', category: 'Culinary', items: ['Boil Water 🫖', 'Crush Ginger 🧄', 'Add Tea Leaves 🍃', 'Pour Fresh Milk 🥛', 'Strain into Cup ☕']),
    SequenceStimulus(id: 'seq7', title: 'Five Classical Swaras', category: 'Music', items: ['Sa 🎶', 'Re 🎵', 'Ga 🎼', 'Ma 🎹', 'Pa 🎺']),
    SequenceStimulus(id: 'seq8', title: 'Four North Eastern River Towns', category: 'Heritage', items: ['Guwahati 🛶', 'Tezpur 🏯', 'Jorhat 🍵', 'Dibrugarh 🚂']),
    SequenceStimulus(id: 'seq9', title: 'Evening Temple Routine', category: 'Heritage', items: ['Remove Shoes 🥿', 'Wash Hands 🤲', 'Ring Temple Bell 🔔', 'Offer Garland 🌺', 'Receive Prasadam 🍬']),
    SequenceStimulus(id: 'seq10', title: 'Six Digit Heritage Code', category: 'Numbers', items: ['3️⃣', '8️⃣', '5️⃣', '1️⃣', '9️⃣', '6️⃣']),
    SequenceStimulus(id: 'seq11', title: 'Five Southern Sacred Peaks', category: 'Heritage', items: ['Tirumala ⛰️', 'Arunachala 🛕', 'Palani 🌿', 'Chamundi 🦁', 'Sabarimala 🌲']),
    SequenceStimulus(id: 'seq12', title: 'Four Stages of Sunlight', category: 'Nature', items: ['Brahma Muhurta 🌌', 'Sunrise Glow 🌅', 'Midday Radiance ☀️', 'Golden Sunset 🌇']),
    SequenceStimulus(id: 'seq13', title: 'Traditional Kitchen Grinding Steps', category: 'Culinary', items: ['Soak Lentils 🫘', 'Drain Water 💧', 'Add Cumin Seeds 🌾', 'Grind with Mortar 🥣', 'Check Smooth Texture ✨']),
    SequenceStimulus(id: 'seq14', title: 'Seven Musical Swaras (Sapta Swara)', category: 'Music', items: ['Sa 🔴', 'Re 🟠', 'Ga 🟡', 'Ma 🟢', 'Pa 🔵', 'Dha 🟣', 'Ni 🟤']),
    SequenceStimulus(id: 'seq15', title: 'Four Traditional Crafts Steps', category: 'Heritage', items: ['Spin Cotton 🧵', 'Dye Thread 🎨', 'Set Wooden Loom 🪵', 'Weave Border 🧣']),
    SequenceStimulus(id: 'seq16', title: 'Five Heritage Trees of India', category: 'Nature', items: ['Banyan 🌳', 'Neem 🌿', 'Peepal 🍃', 'Mango 🥭', 'Gulmohar 🌺']),
    SequenceStimulus(id: 'seq17', title: 'Morning Garden Care', category: 'Routine', items: ['Check Soil 🪴', 'Prune Leaves ✂️', 'Fill Watering Can 🚿', 'Water Roots 💧', 'Bask in Sunlight ☀️']),
    SequenceStimulus(id: 'seq18', title: 'Six Memory Digits Heritage', category: 'Numbers', items: ['5️⃣', '1️⃣', '7️⃣', '3️⃣', '8️⃣', '2️⃣']),
    SequenceStimulus(id: 'seq19', title: 'Four Heritage Ghats of Kashi', category: 'Heritage', items: ['Assi Ghat 🚣', 'Dashashwamedh 🪔', 'Manikarnika 🕯️', 'Panchganga 🌊']),
    SequenceStimulus(id: 'seq20', title: 'Five Steps of Letter Writing', category: 'Daily Life', items: ['Take Parchment 📜', 'Dip Ink Pen ✒️', 'Write Warm Wishes ✍️', 'Fold in Envelope ✉️', 'Drop in Mailbox 📮']),
  ];

  // ── 5. Everyday & Cultural Vocabulary Bank (48 words) ─────────────────
  static const List<WordStimulus> words = [
    WordStimulus(word: 'MANGO', category: 'Food', hint: 'Sweet summer fruit from the orchard'),
    WordStimulus(word: 'RIVER', category: 'Nature', hint: 'Flowing waters of life'),
    WordStimulus(word: 'TEMPLE', category: 'Heritage', hint: 'Place of prayer and bells'),
    WordStimulus(word: 'FLOWER', category: 'Nature', hint: 'Fragrant garden blossom'),
    WordStimulus(word: 'TRAIN', category: 'Travel', hint: 'Rhythmic journey along iron rails'),
    WordStimulus(word: 'BANYAN', category: 'Nature', hint: 'Ancient sacred sheltering tree'),
    WordStimulus(word: 'FLUTE', category: 'Heritage', hint: 'Bamboo melody played by Krishna'),
    WordStimulus(word: 'PEACOCK', category: 'Nature', hint: 'National bird dancing in rain'),
    WordStimulus(word: 'LAMP', category: 'Heritage', hint: 'Brass diya shedding gentle light'),
    WordStimulus(word: 'MONSOON', category: 'Nature', hint: 'Cooling seasonal rains and clouds'),
    WordStimulus(word: 'SITAR', category: 'Heritage', hint: 'Classical stringed instrument'),
    WordStimulus(word: 'COCONUT', category: 'Food', hint: 'Palm grove fruit with sweet water'),
    WordStimulus(word: 'BELL', category: 'Heritage', hint: 'Resonant brass chime in morning prayer'),
    WordStimulus(word: 'ELEPHANT', category: 'Nature', hint: 'Gentle royal tusker of temple festivals'),
    WordStimulus(word: 'WEAVER', category: 'Daily Life', hint: 'Artisan crafting handloom silk'),
    WordStimulus(word: 'LOOM', category: 'Daily Life', hint: 'Wooden frame spinning threads into cloth'),
    WordStimulus(word: 'FOREST', category: 'Nature', hint: 'Quiet woods filled with birdsong'),
    WordStimulus(word: 'MOUNTAIN', category: 'Nature', hint: 'Majestic snowy peaks reaching the sky'),
    WordStimulus(word: 'LAKE', category: 'Nature', hint: 'Serene still water reflecting pines'),
    WordStimulus(word: 'COURTYARD', category: 'Daily Life', hint: 'Open family veranda with tulsi pot'),
    WordStimulus(word: 'SUNRISE', category: 'Nature', hint: 'Dawn glow breaking over fields'),
    WordStimulus(word: 'JASMINE', category: 'Nature', hint: 'Sweet white blossoms strung in hair'),
    WordStimulus(word: 'SANDALWOOD', category: 'Heritage', hint: 'Fragrant paste for forehead blessing'),
    WordStimulus(word: 'CLAY', category: 'Daily Life', hint: 'Earth used by potter to shape pots'),
    WordStimulus(word: 'CARDAMOM', category: 'Food', hint: 'Aromatic green spice crushed into tea'),
    WordStimulus(word: 'HONEY', category: 'Food', hint: 'Sweet golden nectar from wild hives'),
    WordStimulus(word: 'COTTON', category: 'Daily Life', hint: 'Soft white crop spun into light kurtas'),
    WordStimulus(word: 'SHAWL', category: 'Daily Life', hint: 'Warm woolen drape for misty mornings'),
    WordStimulus(word: 'VILLAGE', category: 'Geography', hint: 'Close-knit rural community near fields'),
    WordStimulus(word: 'MARKET', category: 'Daily Life', hint: 'Morning bazaar selling fresh vegetables'),
    WordStimulus(word: 'BRIDGE', category: 'Travel', hint: 'Curved stone span crossing the stream'),
    WordStimulus(word: 'WELL', category: 'Daily Life', hint: 'Deep brick spring drawing fresh water'),
    WordStimulus(word: 'PRAYER', category: 'Heritage', hint: 'Morning chants for family peace'),
    WordStimulus(word: 'GARDEN', category: 'Nature', hint: 'Tended patch of flowering plants and mint'),
    WordStimulus(word: 'WALK', category: 'Daily Life', hint: 'Brisk healthy stroll under shady trees'),
    WordStimulus(word: 'PORRIDGE', category: 'Food', hint: 'Wholesome warm morning breakfast'),
    WordStimulus(word: 'GINGER', category: 'Food', hint: 'Spicy root brewed for warmth'),
    WordStimulus(word: 'CHAIR', category: 'Daily Life', hint: 'Comfortable wicker seat on the veranda'),
    WordStimulus(word: 'RADIO', category: 'Daily Life', hint: 'Transistor playing morning news and songs'),
    WordStimulus(word: 'POSTMAN', category: 'Daily Life', hint: 'Friendly visitor delivering handwritten letters'),
    WordStimulus(word: 'SUGARCANE', category: 'Food', hint: 'Tall sweet stalks pressed for fresh juice'),
    WordStimulus(word: 'PARROT', category: 'Nature', hint: 'Bright green bird perched on mango branch'),
    WordStimulus(word: 'LOTUS', category: 'Nature', hint: 'Pink sacred bloom rising above water'),
    WordStimulus(word: 'CONCH', category: 'Heritage', hint: 'Ocean shell blown at auspicious ceremonies'),
    WordStimulus(word: 'SPICE', category: 'Food', hint: 'Cinnamon and cloves seasoning family feast'),
    WordStimulus(word: 'CANAL', category: 'Travel', hint: 'Waterway carrying wooden boats through palms'),
    WordStimulus(word: 'HERON', category: 'Nature', hint: 'White bird standing patiently in paddy field'),
    WordStimulus(word: 'POTTERY', category: 'Daily Life', hint: 'Clay pots cooling drinking water naturally'),
  ];

  // ── 6. Heritage Stories Bank (10 stories) ─────────────────────────────
  static const List<HeritageStoryStimulus> stories = [
    HeritageStoryStimulus(
      id: 'st1',
      title: 'Grandfather Bhupen\'s Sunrise Walk',
      region: 'Assam & Brahmaputra',
      body: 'Every morning at sunrise, grandfather Bhupen walked past the misty tea slopes of Jorhat. '
          'He listened to the whistle of the Hill Myna bird perched atop the ancient banyan tree. '
          'At the crossroad tea stall, he shared a steaming glass of cardamom tea with his schoolmate Dhiren '
          'before returning home with fresh sweet jaggery.',
      questions: [
        {
          'question': 'Where was grandfather Bhupen walking at sunrise?',
          'options': ['Tea slopes of Jorhat', 'Railway station', 'Busy city market', 'River ferry'],
          'correctIdx': 0,
        },
        {
          'question': 'What kind of bird did he hear chirping?',
          'options': ['Peacock', 'Hill Myna', 'Sparrow', 'Pigeon'],
          'correctIdx': 1,
        },
        {
          'question': 'What did he share with his schoolmate Dhiren?',
          'options': ['Cardamom tea', 'Coconut water', 'Sugarcane juice', 'Lassi'],
          'correctIdx': 0,
        },
        {
          'question': 'What did he bring home at the end of the walk?',
          'options': ['Fresh sweet jaggery', 'Bamboo basket', 'Newspaper', 'Flowers'],
          'correctIdx': 0,
        },
      ],
    ),
    HeritageStoryStimulus(
      id: 'st2',
      title: 'The Rongali Bihu Silk Gamosa',
      region: 'Assamese Heritage',
      body: 'Before the spring Bihu festival, grandmother Manorama sat by the wooden loom under the shaded jackfruit tree. '
          'She wove a white and red cotton gamosa with woven floral patterns. '
          'Her seven-year-old grandson Ankur brought her a bowl of roasted puffed rice. '
          'In the afternoon, the village dhol drummers passed by playing rhythmic festival beats.',
      questions: [
        {
          'question': 'Under which tree did grandmother sit with her loom?',
          'options': ['Neem tree', 'Jackfruit tree', 'Banyan tree', 'Pine tree'],
          'correctIdx': 1,
        },
        {
          'question': 'What colors were used for the traditional gamosa?',
          'options': ['White and red', 'Blue and yellow', 'Green and gold', 'Purple and black'],
          'correctIdx': 0,
        },
        {
          'question': 'What snack did grandson Ankur bring to her?',
          'options': ['Roasted puffed rice', 'Sweet laddu', 'Cut papayas', 'Biscuits'],
          'correctIdx': 0,
        },
        {
          'question': 'What traditional instrument did the village drummers play?',
          'options': ['Dhol', 'Flute', 'Tabla', 'Harmonium'],
          'correctIdx': 0,
        },
      ],
    ),
    HeritageStoryStimulus(
      id: 'st3',
      title: 'Sunset at Shillong Pine Lake',
      region: 'Meghalaya & Hills',
      body: 'On a cool autumn evening, uncle Subroto visited the tranquil waters of Ward\'s Lake in Shillong. '
          'Yellow pine leaves floated near the curved wooden bridge. '
          'He watched white ducks paddling across the water while enjoying a warm roasted corn cob seasoned with lemon. '
          'The church bells rang six times as dusk settled over the hills.',
      questions: [
        {
          'question': 'Which lake did uncle Subroto visit in Shillong?',
          'options': ['Ward\'s Lake', 'Dal Lake', 'Chilika Lake', 'Hussain Sagar'],
          'correctIdx': 0,
        },
        {
          'question': 'What floating near the wooden bridge caught his eye?',
          'options': ['Yellow pine leaves', 'Paper boats', 'Red roses', 'Water lilies'],
          'correctIdx': 0,
        },
        {
          'question': 'What warm snack did he enjoy by the water?',
          'options': ['Roasted corn cob', 'Samosa', 'Momos', 'Hot tea'],
          'correctIdx': 0,
        },
        {
          'question': 'How many times did the church bells ring at dusk?',
          'options': ['Four times', 'Six times', 'Eight times', 'Ten times'],
          'correctIdx': 1,
        },
      ],
    ),
    HeritageStoryStimulus(
      id: 'st4',
      title: 'Dawn Bells of Kaveri Temple',
      region: 'South Heritage',
      body: 'At dawn along the banks of the Kaveri river, elder brother Raghavan walked barefoot to the temple. '
          'The priest was offering fragrant jasmine garlands to the deity. '
          'Raghavan received a copper spoon of holy basil water and sweet pongal prasadam on a banana leaf. '
          'He sat near the temple pillar listening to the nadaswaram flute until the sun cleared the coconut palms.',
      questions: [
        {
          'question': 'Along which sacred river was Raghavan walking?',
          'options': ['Kaveri river', 'Ganga river', 'Godavari river', 'Yamuna river'],
          'correctIdx': 0,
        },
        {
          'question': 'What kind of flowers were offered by the priest?',
          'options': ['Jasmine garlands', 'Marigolds', 'Roses', 'Hibiscus'],
          'correctIdx': 0,
        },
        {
          'question': 'What prasadam did he receive on a banana leaf?',
          'options': ['Sweet pongal', 'Laddu', 'Kheer', 'Jalebi'],
          'correctIdx': 0,
        },
        {
          'question': 'What musical instrument was being played in the courtyard?',
          'options': ['Nadaswaram flute', 'Veena', 'Mridangam', 'Violin'],
          'correctIdx': 0,
        },
      ],
    ),
    HeritageStoryStimulus(
      id: 'st5',
      title: 'Monsoon Chai in Darjeeling',
      region: 'Himalayan Foothills',
      body: 'Rain was drumming rhythmically on the corrugated tin roof of aunt Sunita\'s cottage in Kurseong. '
          'She boiled freshly plucked second-flush Darjeeling tea leaves with a slice of mountain ginger. '
          'Her niece Maya arrived carrying an emerald green umbrella. '
          'Together they watched the mountain toy train puff white steam through the misty cedar trees.',
      questions: [
        {
          'question': 'In which hill town was aunt Sunita\'s cottage located?',
          'options': ['Kurseong', 'Shimla', 'Ooty', 'Nainital'],
          'correctIdx': 0,
        },
        {
          'question': 'What spice did she slice into the freshly boiled tea?',
          'options': ['Mountain ginger', 'Black pepper', 'Clove', 'Cardamom'],
          'correctIdx': 0,
        },
        {
          'question': 'What color was niece Maya\'s umbrella?',
          'options': ['Emerald green', 'Bright yellow', 'Deep blue', 'Crimson red'],
          'correctIdx': 0,
        },
        {
          'question': 'What train did they observe puffing steam through the trees?',
          'options': ['Mountain toy train', 'High-speed express', 'Freight train', 'Metro train'],
          'correctIdx': 0,
        },
      ],
    ),
  ];

  // ── 7. Daily Routine Scenarios Bank (8 scenarios) ─────────────────────
  static const List<RoutineScenarioStimulus> routines = [
    RoutineScenarioStimulus(
      id: 'rt1',
      title: 'Morning Wellness & Medicine Routine',
      subtitle: 'Put the morning steps in their healthy chronological order.',
      steps: [
        {'order': 1, 'title': 'Wake Up & Deep Breathing', 'time': '06:30 AM', 'icon': Icons.wb_sunny_rounded, 'tip': 'Start the day calmly with fresh air.'},
        {'order': 2, 'title': 'Drink Warm Water / Herbal Tea', 'time': '07:00 AM', 'icon': Icons.local_drink_rounded, 'tip': 'Hydration supports circulation and focus.'},
        {'order': 3, 'title': 'Morning Medicine & Light Stretch', 'time': '07:30 AM', 'icon': Icons.medication_rounded, 'tip': 'Take prescribed morning blood pressure/sugar dose.'},
        {'order': 4, 'title': 'Wholesome Breakfast & Family Chat', 'time': '08:30 AM', 'icon': Icons.restaurant_rounded, 'tip': 'Nourish energy with porridge or idli/roti.'},
      ],
    ),
    RoutineScenarioStimulus(
      id: 'rt2',
      title: 'Afternoon & Active Engagement Routine',
      subtitle: 'Order the afternoon wellness and memory habits.',
      steps: [
        {'order': 1, 'title': 'Healthy Lunch with Greens', 'time': '01:00 PM', 'icon': Icons.lunch_dining_rounded, 'tip': 'Warm, easy-to-digest meal.'},
        {'order': 2, 'title': 'Gentle Afternoon Rest / Nap', 'time': '02:00 PM', 'icon': Icons.bed_rounded, 'tip': '20-30 minutes quiet rest rejuvenates memory.'},
        {'order': 3, 'title': 'Daily Cognitive Practice on Smriti Veda', 'time': '03:30 PM', 'icon': Icons.psychology_rounded, 'tip': 'Play Fruit Memory Path or Sequence Recall.'},
        {'order': 4, 'title': 'Hydration & Evening Tea / Snack', 'time': '04:30 PM', 'icon': Icons.emoji_food_beverage_rounded, 'tip': 'Roasted nuts or fruit slice with green tea.'},
      ],
    ),
    RoutineScenarioStimulus(
      id: 'rt3',
      title: 'Evening Sunset & Restorative Routine',
      subtitle: 'Arrange the relaxing evening sequence.',
      steps: [
        {'order': 1, 'title': 'Pleasant Shaded Walk in Park', 'time': '05:30 PM', 'icon': Icons.directions_walk_rounded, 'tip': 'Gentle 20-minute movement with neighbors.'},
        {'order': 2, 'title': 'Evening Prayer & Lamp Lighting', 'time': '06:45 PM', 'icon': Icons.local_fire_department_rounded, 'tip': 'Calming mindful gratitude.'},
        {'order': 3, 'title': 'Light Dinner & Nighttime Tablets', 'time': '07:30 PM', 'icon': Icons.soup_kitchen_rounded, 'tip': 'Simple khichdi or soup with night prescription.'},
        {'order': 4, 'title': 'Reading & Screen-Free Restful Sleep', 'time': '09:30 PM', 'icon': Icons.nights_stay_rounded, 'tip': 'Dark, cool bedroom promotes deep memory consolidation.'},
      ],
    ),
    RoutineScenarioStimulus(
      id: 'rt4',
      title: 'Doctor Appointment Preparation',
      subtitle: 'Order the steps for preparing a clinical checkup.',
      steps: [
        {'order': 1, 'title': 'Gather Recent Medical Reports', 'time': '09:00 AM', 'icon': Icons.folder_open_rounded, 'tip': 'Keep blood test and prescription files ready.'},
        {'order': 2, 'title': 'Note Down Any Recent Symptoms', 'time': '09:30 AM', 'icon': Icons.edit_note_rounded, 'tip': 'Write questions for the physician.'},
        {'order': 3, 'title': 'Carry Identification & Water Bottle', 'time': '10:00 AM', 'icon': Icons.badge_outlined, 'tip': 'Bring senior ID and hydration.'},
        {'order': 4, 'title': 'Reach Clinic with Caregiver', 'time': '10:30 AM', 'icon': Icons.local_hospital_rounded, 'tip': 'Arrive 15 minutes before scheduled consultation.'},
      ],
    ),
  ];
}
