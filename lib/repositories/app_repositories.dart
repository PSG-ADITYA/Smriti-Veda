import '../models/everyday_memory.dart';
import '../models/memory_content.dart';
import '../services/db_service.dart';

// 1. User Repository Interface
abstract class UserRepository {
  Future<Map<String, dynamic>?> getUserProfile();
  Future<void> saveUserProfile(Map<String, dynamic> profile);
}

class LocalUserRepository implements UserRepository {
  @override
  Future<Map<String, dynamic>?> getUserProfile() async {
    return DbService().getUserProfile();
  }

  @override
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    DbService().saveUserProfile(
      name: profile['name'] ?? 'Senior Patient',
      role: profile['role'] ?? 'Patient',
      credentialId: profile['credentialId'] ?? 'patient123',
      language: profile['language'] ?? 'en',
      age: profile['age'] ?? 72,
      emergencyContact: profile['emergencyContact'] ?? '',
      medicalNotes: profile['medicalNotes'] ?? '',
    );
  }
}

// 2. Reminder Repository Interface
abstract class ReminderRepository {
  List<EverydayReminder> getReminders();
  void addReminder(EverydayReminder reminder);
  void deleteReminder(String id);
  void toggleComplete(String id);
}

class LocalReminderRepository implements ReminderRepository {
  @override
  List<EverydayReminder> getReminders() => DbService().getReminders();

  @override
  void addReminder(EverydayReminder reminder) {
    DbService().saveReminder(reminder);
  }

  @override
  void deleteReminder(String id) {
    DbService().deleteReminder(id);
  }

  @override
  void toggleComplete(String id) {
    final list = DbService().getReminders();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final updated = list[idx].copyWith(isCompleted: !list[idx].isCompleted);
      DbService().saveReminder(updated);
    }
  }
}

// 3. Familiar Person Repository Interface
abstract class FamiliarPersonRepository {
  List<FamiliarPerson> getFamiliarPeople();
  void addFamiliarPerson(FamiliarPerson person);
  void deleteFamiliarPerson(String id);
}

class LocalFamiliarPersonRepository implements FamiliarPersonRepository {
  @override
  List<FamiliarPerson> getFamiliarPeople() => DbService().getFamiliarPeople();

  @override
  void addFamiliarPerson(FamiliarPerson person) {
    DbService().saveFamiliarPerson(person);
  }

  @override
  void deleteFamiliarPerson(String id) {
    DbService().deleteFamiliarPerson(id);
  }
}

// 4. Memory Content Repository Interface
abstract class MemoryContentRepository {
  List<MemoryContentItem> getAllItems();
  MemoryContentItem? getItemById(String id);
}

class LocalMemoryContentRepository implements MemoryContentRepository {
  final List<MemoryContentItem> _items = const [
    MemoryContentItem(
      id: 'gayatri_mantra',
      category: 'Verse',
      title: 'Gayatri Mantra',
      originalScriptText: 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्॥',
      transliteration: 'Oṁ Bhūr Bhuvaḥ Svaḥ Tat Savitur Vareṇyaṁ Bhargo Devasya Dhīmahi Dhiyo Yo Naḥ Pracodayāt',
      englishMeaning: 'We meditate on the divine illumination of the Sun Creator. May it awaken our intellect.',
      englishExplanation: 'A foundational 24-syllable rhythmic chant used to cultivate calm attention and auditory memory.',
      source: 'Rigveda 3.62.10',
      difficulty: 'Easy',
      cognitivePurpose: 'Auditory sequential working memory & 3-chunk rhythm retention.',
      chunks: ['ॐ भूर्भुवः स्वः', 'तत्सवितुर्वरेण्यं', 'भर्गो देवस्य धीमहि', 'धियो यो नः प्रचोदयात्'],
      languageCode: 'sa',
    ),
    MemoryContentItem(
      id: 'mahamrityunjaya',
      category: 'Verse',
      title: 'Mahamrityunjaya Mantra',
      originalScriptText: 'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्। उर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय माऽमृतात्॥',
      transliteration: 'Oṁ Tryambakaṁ Yajāmahe Sugandhiṁ Puṣṭi-Vardhanam Urvārukam-Iva Bandhanān Mṛtyor-Mukṣīya Mā\'mṛtāt',
      englishMeaning: 'We honor the three-eyed Lord Shiva who nourishes all beings. May He liberate us like a ripe cucumber from the vine.',
      englishExplanation: 'A traditional verse focused on resilience, deep breathing rhythm, and phrase recall.',
      source: 'Rigveda 7.59.12',
      difficulty: 'Medium',
      cognitivePurpose: 'Phrase isolation & overlapping sequence connection practice.',
      chunks: ['ॐ त्र्यम्बकं यजामहे', 'सुगन्धिं पुष्टिवर्धनम्', 'उर्वारुकमिव बन्धनात्', 'मृत्योर्मुक्षीय माऽमृतात्'],
      languageCode: 'sa',
    ),
    MemoryContentItem(
      id: 'kabir_doha_dheere',
      category: 'Proverb',
      title: 'Kabir Doha - Dheere Dheere Re Mana',
      originalScriptText: 'धीरे-धीरे रे मना, धीरे सब कुछ होय । माली सींचे सौ घड़ा, ॠतु आये फल होय ॥',
      transliteration: 'Dheere-dheere re mana, dheere sab kuchh hoy | Mali seenche sau ghada, ritu aaye phal hoy ||',
      englishMeaning: 'Slowly and steadily, O mind, everything comes to fruition. The gardener waters with a hundred pots, but fruit arrives only in season.',
      englishExplanation: 'Sant Kabir couplet encouraging patient practice and cognitive persistence.',
      source: 'Sant Kabir Das',
      difficulty: 'Easy',
      cognitivePurpose: 'Semantic memory retrieval & self-regulation.',
      chunks: ['धीरे-धीरे रे मना', 'धीरे सब कुछ होय', 'माली सींचे सौ घड़ा', 'ॠतु आये फल होय'],
      languageCode: 'hi',
    ),
    MemoryContentItem(
      id: 'vemana_padyam',
      category: 'Proverb',
      title: 'Vemana Padyam - Uppu Kappurambu (Telugu)',
      originalScriptText: 'ఉప్పు కప్పురంబు నొక్క పోలిక నుండు | చూడ చూడ రుచుల జాడ వేరు | పురుషులందు పుణ్య పురుషులు వేరయా | విశ్వదాభిరామ విनुర వేమ ॥',
      transliteration: 'Uppu kappurambu nokka polika nundu | Chuda chuda ruchula jada veru | Purushulandu punya purushulu veraya | Viswadhabhirama vinura Vema ||',
      englishMeaning: 'Salt and camphor look identical to the eye. But upon tasting, their true nature is revealed. Likewise, noble human beings stand out by their character.',
      englishExplanation: 'Famous Telugu moral poem by Yogi Vemana fostering sensory comparison and memory retention.',
      source: 'Yogi Vemana',
      difficulty: 'Medium',
      cognitivePurpose: 'Sensory discernment & cross-linguistic memory retrieval.',
      chunks: ['ఉప్పు కప్పురంబు', 'నొక్క పోలిక నుండు', 'చూడ చూడ రుచుల', 'జాడ వేరు', 'విశ్వదాభిరామ వినుర వేమ'],
      languageCode: 'te',
    ),
    MemoryContentItem(
      id: 'o_mor_apunar_desh',
      category: 'Song',
      title: 'O Mor Apunar Desh (Assamese Folk Anthem)',
      originalScriptText: 'অ\' মোৰ আপোনাৰ দেশ\nঅ\' মোৰ চিকুণী দেশ\nএনেখন সুৱলা, এনেখন সুফলা\nএনেখন মৰমৰ দেশ।',
      transliteration: 'O mor apunar desh\nO mor chikuni desh\nEnekhon suwola, enekhon sufola\nEnekhon moromor desh.',
      englishMeaning: 'O my endearing land, O my pristine land! Such a sweet land, such a fruitful land, such a beloved land of mine.',
      englishExplanation: 'Assamese state song by Sahityarathi Lakshminath Bezbaroa evoking North Eastern cultural identity.',
      source: 'Lakshminath Bezbaroa',
      difficulty: 'Easy',
      cognitivePurpose: 'Regional auditory emotion & speech fluency activation.',
      chunks: ['অ\' মোৰ আপোনাৰ দেশ', 'অ\' মোৰ চিকুণী দেশ', 'এনেখন সুৱলা, এনেখন সুফলা', 'এনেখন মৰমৰ দেশ'],
      languageCode: 'as',
    ),
    MemoryContentItem(
      id: 'amader_chhoto_nodi',
      category: 'Rhyme',
      title: 'Amader Chhoto Nodi (Bengali Poem)',
      originalScriptText: 'আমাদের ছোট নদী চলে বাঁকে বাঁকে\nবৈশাখ মাসে তার হাঁটু জল থাকে।\nপার হয়ে যায় গোরু, পার হয় গাড়ি,\nদুই ধার উঁচু তার, ঢালু তার পাড়ি।',
      transliteration: 'Amader chhoto nodi chole bake bake\nBoishakh mase tar hatu jol thake.\nPar hoye jay goru, par hoy gari,\nDui dhar uchu tar, dhalu tar pari.',
      englishMeaning: 'Our little river flows in twists and turns. In the month of Boishakh it has knee-deep water. Cows and carts cross over easily.',
      englishExplanation: 'Classic Rabindranath Tagore poem for childhood speech resonance and rhythm.',
      source: 'Rabindranath Tagore',
      difficulty: 'Easy',
      cognitivePurpose: 'Sequential auditory cadence & articulation fluidity.',
      chunks: ['আমাদের ছোট নদী चले বাঁকে বাঁকে', 'বৈশাখ মাসে তার হাঁটু জল থাকে', 'পার হয়ে যায় গোরু, পার হয় গাড়ি', 'দুই ধার উঁচু তার, ঢালু তার পাড়ি'],
      languageCode: 'bn',
    ),
  ];

  @override
  List<MemoryContentItem> getAllItems() => List.unmodifiable(_items);

  @override
  MemoryContentItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
