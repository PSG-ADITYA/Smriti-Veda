import '../models/cultural_content.dart';
import '../models/patient_info.dart';
import '../services/db_service.dart';

abstract class PatientFileRepository {
  List<PatientFile> getFiles();
  void addFile(PatientFile file);
  void deleteFile(String id);
}

class LocalPatientFileRepository implements PatientFileRepository {
  @override
  List<PatientFile> getFiles() => DbService().getPatientFiles();

  @override
  void addFile(PatientFile file) {
    DbService().savePatientFile(file);
  }

  @override
  void deleteFile(String id) {
    DbService().deletePatientFile(id);
  }
}

abstract class CulturalContentRepository {
  List<CulturalContentItem> getAllItems();
  CulturalContentItem? getItemById(String id);
}

class LocalCulturalContentRepository implements CulturalContentRepository {
  final List<CulturalContentItem> _items = [
    CulturalContentItem(
      id: 'vemana_padyam_1',
      category: 'Proverb',
      title: 'Vemana Padyam: Uppu Kappurambu (Telugu)',
      originalScriptText: 'ఉప్పు కప్పురంబు నొక్క పోలిక నుండు\nచూడ చూడ రుచుల జాడ వేరు\nపురుషులందు పుణ్య పురుషులు వేరయా\nవిశ్వదాభిరామ వినుర వేమ॥',
      transliteration: 'Uppu kappurambu nokka polika nundu | Chuda chuda ruchula jada veru | Purushulandu punya purushulu veraya | Viswadhabhirama vinura Vema ||',
      englishMeaning: 'Salt and camphor appear identical to the eye. But upon tasting, their true nature is revealed. Likewise, noble human beings stand out by their character.',
      englishExplanation: 'Famous Telugu moral poem by Yogi Vemana fostering sensory comparison and memory retention.',
      cognitivePurpose: 'Sensory discernment & cross-linguistic memory retrieval.',
      chunks: ['ఉప్పు కప్పురంబు', 'నొక్క పోలిక నుండు', 'చూడ చూడ రుచుల', 'జాడ వేరు', 'విశ్వదాభిరామ వినుర వేమ'],
      languageCode: 'te',
    ),
    CulturalContentItem(
      id: 'vamana_padyam',
      category: 'Verse',
      title: 'Vamana Padyam: Intha Thanayai (Telugu)',
      originalScriptText: 'ఇంత తనయై మఱి యింత యై\nనభంబంతయై నభోవీధికి నంతయై\nలక్ష్మికినంతయై దిశల కంతయై\nమఱియు నంతయై భాసిల్లెన్॥',
      transliteration: 'Intha thanayai mari intha yai | Nabhambanthayai nabhoveedhiki nanthayai | Lakshmikinanthayai dishala kanthayai | Mariyu nanthayai bhasillan ||',
      englishMeaning: 'He grew from a small form to encompass the earth, the sky, the cosmos, and beyond infinity.',
      englishExplanation: 'Classic Potana Bhagavatham verse celebrating expanding spatial visualization and auditory scale.',
      cognitivePurpose: 'Spatial expansion visualization & verbal rhythm precision.',
      chunks: ['ఇంత తనయై మఱి యింత యై', 'నభంబంతయై నభోవీధికి', 'లక్ష్మికినంతయై దిశల కంతయై', 'మఱియు నంతయై భాసిల్లెన్'],
      languageCode: 'te',
    ),
    CulturalContentItem(
      id: 'kabir_doha_dheere',
      category: 'Proverb',
      title: 'Kabir Doha: Dheere Dheere Re Mana (Hindi)',
      originalScriptText: 'धीरे-धीरे रे मना, धीरे सब कुछ होय।\nमाली सींचे सौ घड़ा, ॠतु आये फल होय॥',
      transliteration: 'Dheere-dheere re mana, dheere sab kuchh hoy | Mali seenche sau ghada, ritu aaye phal hoy ||',
      englishMeaning: 'Slowly and steadily, O mind, everything comes to fruition. The gardener waters with a hundred pots, but fruit arrives only in season.',
      englishExplanation: 'Sant Kabir couplet encouraging patient practice and cognitive persistence.',
      cognitivePurpose: 'Semantic memory retrieval & self-regulation.',
      chunks: ['धीरे-धीरे रे मना', 'धीरे सब कुछ होय', 'माली सींचे सौ घड़ा', 'ॠतु आये फल होय'],
      languageCode: 'hi',
    ),
    CulturalContentItem(
      id: 'tulsi_doha_daya',
      category: 'Proverb',
      title: 'Tulsi Doha: Daya Dharma Ka Mool Hai (Hindi)',
      originalScriptText: 'दया धर्म का मूल है, पाप मूल अभिमान।\nतुलसी दया न छोड़िये, जब लग घट में प्राण॥',
      transliteration: 'Daya dharma ka mool hai, paap mool abhimaan | Tulsi daya na chhodiye, jab lag ghat mein praan ||',
      englishMeaning: 'Compassion is the root of righteousness, while pride is the root of sin. Never abandon compassion as long as breath remains.',
      englishExplanation: 'Goswami Tulsidas doha emphasizing ethical anchor and rhythmic balance.',
      cognitivePurpose: 'Verbal anchor recall & moral phrase integration.',
      chunks: ['दया धर्म का मूल है', 'पाप मूल अभिमान', 'तुलसी दया न छोड़िये', 'जब लग घट में प्राण'],
      languageCode: 'hi',
    ),
    CulturalContentItem(
      id: 'thirukkural_1',
      category: 'Proverb',
      title: 'Thirukkural: Agara Mudhala (Tamil)',
      originalScriptText: 'அகர முதல எழுத்தெல்லாம் ஆதி\nபகவன் முதற்றே உலகு.',
      transliteration: 'Agara mudhala ezhutthellam aadhi | Bhagavan mudhattre ulagu.',
      englishMeaning: 'As the letter \'A\' is the beginning of all letters, so the Divine Primordial Lord is the origin of the universe.',
      englishExplanation: 'Opening verse of Thiruvalluvar\'s Thirukkural, widely recited across South India.',
      cognitivePurpose: 'Symbolic sequence origin recall & rhythm retention.',
      chunks: ['அகர முதல எழுத்தெல்லாம்', 'ஆதி பகவன்', 'முதற்றே உலகு'],
      languageCode: 'ta',
    ),
    CulturalContentItem(
      id: 'o_mor_apunar_desh',
      category: 'Song',
      title: 'O Mor Apunar Desh (Assamese Folk Song)',
      originalScriptText: 'অ\' মোৰ আপোনাৰ দেশ\nঅ\' মোৰ চিকුණী দেশ\nএনেখন সুৱলা, এনেখন সুফলা\nএনেখন মৰমৰ দেশ।',
      transliteration: 'O mor apunar desh | O mor chikuni desh | Enekhon suwola, enekhon sufola | Enekhon moromor desh.',
      englishMeaning: 'O my endearing land, O my pristine land! Such a sweet land, such a fruitful land, such a beloved land of mine.',
      englishExplanation: 'Assamese state song by Sahityarathi Lakshminath Bezbaroa evoking North Eastern cultural identity.',
      cognitivePurpose: 'Regional auditory emotion & speech fluency activation.',
      chunks: ['অ\' মোৰ আপোনাৰ দেশ', 'অ\' মোৰ চিকුණী দেশ', 'এনেখন সুৱলা, এনেখন সুফলা', 'এনেখন মৰমৰ দেশ'],
      languageCode: 'as',
    ),
    CulturalContentItem(
      id: 'amader_chhoto_nodi',
      category: 'Rhyme',
      title: 'Amader Chhoto Nodi (Bengali Poem)',
      originalScriptText: 'আমাদের ছোট নদী চলে বাঁকে বাঁকে\nবৈশাখ মাসে তার হাঁটু জল থাকে।\nপার হয়ে যায় গোরু, পার হয় গাড়ি,\nদুই ধার উঁচু তার, ঢালু তার পাড়ি।',
      transliteration: 'Amader chhoto nodi chole bake bake | Boishakh mase tar hatu jol thake. | Par hoye jay goru, par hoy gari, | Dui dhar uchu tar, dhalu tar pari.',
      englishMeaning: 'Our little river flows in twists and turns. In the month of Boishakh it has knee-deep water. Cows and carts cross over easily.',
      englishExplanation: 'Classic Rabindranath Tagore poem for childhood speech resonance and rhythm.',
      cognitivePurpose: 'Sequential auditory cadence & articulation fluidity.',
      chunks: ['আমাদের ছোট নদী चले বাঁকে বাঁকে', 'বৈশাখ মাসে তার হাঁটু জল থাকে', 'পার হয়ে যায় গোরু, পার হয় গাড়ি', 'দুই ধার উঁচু তার, ঢালু তার পাড়ি'],
      languageCode: 'bn',
    ),
    CulturalContentItem(
      id: 'twinkle_star',
      category: 'Rhyme',
      title: 'Twinkle Twinkle Little Star (Childhood Rhyme)',
      originalScriptText: 'Twinkle, twinkle, little star,\nHow I wonder what you are!\nUp above the world so high,\nLike a diamond in the sky.',
      transliteration: 'Twinkle, twinkle, little star, How I wonder what you are! Up above the world so high, Like a diamond in the sky.',
      englishMeaning: 'Universal childhood poem invoking early auditory neural patterns.',
      englishExplanation: 'Classic nursery rhyme for motor-auditory memory retrieval and sentence cadence.',
      cognitivePurpose: 'Early childhood auditory memory activation.',
      chunks: ['Twinkle, twinkle, little star', 'How I wonder what you are', 'Up above the world so high', 'Like a diamond in the sky'],
      languageCode: 'en',
    ),
    CulturalContentItem(
      id: 'family_memory_home',
      category: 'Story',
      title: 'Family Story: Grandfather\'s House in Vizag',
      originalScriptText: 'Our ancestral home stood near the beach in Vizag.\nEvery morning we walked along the coast at sunrise.\nGrandma cooked fresh coconut chutney and dosas.\nThe family gathered every festival under the banyan tree.',
      transliteration: 'Our ancestral home stood near the beach in Vizag. Every morning we walked along the coast at sunrise...',
      englishMeaning: 'Personalized family memory anchor for meaningful long-term recall.',
      englishExplanation: 'Caregiver-provided memory recall template for familiar personal identity grounding.',
      cognitivePurpose: 'Personal episodic memory & identity anchoring.',
      chunks: [
        'Our ancestral home stood near the beach in Vizag',
        'Every morning we walked along the coast at sunrise',
        'Grandma cooked fresh coconut chutney and dosas',
        'The family gathered every festival under the banyan tree'
      ],
      languageCode: 'en',
    ),
    CulturalContentItem(
      id: 'gayatri_mantra',
      category: 'Mantra',
      title: 'Gayatri Mantra (Universal Vedic Illumination)',
      originalScriptText: 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्॥',
      transliteration: 'Oṁ Bhūr Bhuvaḥ Svaḥ Tat Savitur Vareṇyaṁ Bhargo Devasya Dhīmahi Dhiyo Yo Naḥ Pracodayāt',
      englishMeaning: 'We meditate on the supreme effulgence of the Divine Sun. May that Divine Light awaken and guide our intellect.',
      englishExplanation: 'Rigveda 3.62.10. Foundational 24-syllable solar hymn used for auditory memory and 3-chunk rhythm retention.',
      cognitivePurpose: 'Auditory sequential working memory & 3-chunk rhythm retention.',
      chunks: ['ॐ भूर्भुवः स्वः', 'तत्सवितुर्वरेण्यं', 'भर्गो देवस्य धीमहि', 'धियो यो नः प्रचोदयात्'],
      languageCode: 'sa',
    ),
    CulturalContentItem(
      id: 'mahamrityunjaya_mantra',
      category: 'Mantra',
      title: 'Mahamrityunjaya Mantra (Healing & Vitality)',
      originalScriptText: 'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् । उर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय माऽमृतात् ॥',
      transliteration: 'Oṁ Tryambakaṁ Yajāmahe Sugandhiṁ Puṣṭi-Vardhanam | Urvārukam-Iva Bandhanān Mṛtyor-Mukṣīya Mā\'mṛtāt ||',
      englishMeaning: 'We worship the Three-Eyed Lord, who is fragrant and nourishes all beings. As a ripe melon detaches effortlessly from its vine, free us from mortality.',
      englishExplanation: 'Rigveda 7.59.12. Celebrated Vedic healing verse fostering breath pacing and rhythmic confidence.',
      cognitivePurpose: 'Rhythmic breath regulation & multi-syllable phoneme recall.',
      chunks: ['ॐ त्र्यम्बकं यजामहे', 'सुगन्धिं पुष्टिवर्धनम्', 'उर्वारुकमिव बन्धनात्', 'मृत्योर्मुक्षीय माऽमृतात्'],
      languageCode: 'sa',
    ),
    CulturalContentItem(
      id: 'shanti_mantra',
      category: 'Verse',
      title: 'Shanti Mantra: Saha Navavatu (Harmony & Peace)',
      originalScriptText: 'ॐ सह नाववतु सह नौ भुनक्तु सह वीर्यं करवावहै । तेजस्वि नावधीतमस्तु मा विद्विषावहै ॥ ॐ शान्तिः शान्तिः शान्तिः ॥',
      transliteration: 'Oṁ Saha Nāvavatu Saha Nau Bhunaktu Saha Vīryaṁ Karavāvahai | Tejasvi Nāvadhītam-Astu Mā Vidviṣāvahai || Oṁ Śāntiḥ Śāntiḥ Śāntiḥ ||',
      englishMeaning: 'May the Divine protect us both (teacher and student). May He nourish us both. May we work together with great energy. May our learning be brilliant. May there be no hatred between us.',
      englishExplanation: 'Taittiriya Upanishad peace invocation reinforcing paired auditory cadence and group memory.',
      cognitivePurpose: 'Paired auditory cadence & prosodic peace recall.',
      chunks: ['ॐ सह नाववतु', 'सह नौ भुनक्तु', 'सह वीर्यं करवावहै', 'तेजस्वि नावधीतमस्तु', 'मा विद्विषावहै', 'ॐ शान्तिः शान्तिः शान्तिः'],
      languageCode: 'sa',
    ),
    CulturalContentItem(
      id: 'vakratunda_mantra',
      category: 'Mantra',
      title: 'Vakratunda Mahakaya (Obstacle Removal & Focus)',
      originalScriptText: 'वक्रतुण्ड महाकाय सूर्यकोटिसमप्रभ । निर्विघ्नं कुरु मे देव सर्वकार्येषु सर्वदा ॥',
      transliteration: 'Vakratuṇḍa Mahākāya Sūryakoṭi Samaprabha | Nirvighnaṁ Kuru Me Deva Sarva-Kāryeṣu Sarvadā ||',
      englishMeaning: 'O Lord with the curved trunk and immense form, shining with the brilliance of a million suns, please make all my endeavors free of obstacles always.',
      englishExplanation: 'Classic Sanskrit verse recited before starting daily tasks to focus intention and working memory.',
      cognitivePurpose: 'Task-initiation mental focus & structured phrase articulation.',
      chunks: ['वक्रतुण्ड महाकाय', 'सूर्यकोटिसमप्रभ', 'निर्विघ्नं कुरु मे देव', 'सर्वकार्येषु सर्वदा'],
      languageCode: 'sa',
    ),
    CulturalContentItem(
      id: 'asato_ma_mantra',
      category: 'Verse',
      title: 'Asato Ma Sadgamaya (Lead Me From Darkness to Light)',
      originalScriptText: 'ॐ असतो मा सद्गमय । तमसो मा ज्योतिर्गमय । मृत्योर्मा अमृतं गमय ॥ ॐ शान्तिः शान्तिः शान्तिः ॥',
      transliteration: 'Oṁ Asato Mā Sad-Gamaya | Tamaso Mā Jyotir-Gamaya | Mṛtyor-Mā Amṛtaṁ Gamaya || Oṁ Śāntiḥ Śāntiḥ Śāntiḥ ||',
      englishMeaning: 'Lead me from falsehood to truth. Lead me from darkness to light. Lead me from death to immortality. Om peace, peace, peace.',
      englishExplanation: 'Brihadaranyaka Upanishad verse fostering philosophical recall and triple parallel structure memory.',
      cognitivePurpose: 'Triple-parallel semantic contrast & calm emotional resonance.',
      chunks: ['ॐ असतो मा सद्गमय', 'तमसो मा ज्योतिर्गमय', 'मृत्योर्मा अमृतं गमय', 'ॐ शान्तिः शान्तिः शान्तिः'],
      languageCode: 'sa',
    ),
    CulturalContentItem(
      id: 'purusha_suktam_opening',
      category: 'Verse',
      title: 'Purusha Suktam Opening (Cosmic Awareness)',
      originalScriptText: 'ॐ सहस्रशीर्षा पुरुषः सहस्राक्षः सहस्रपात् । स भूमिं विश्वतो वृत्वात्यतिष्ठद्दशाङ्गुलम् ॥',
      transliteration: 'Oṁ Sahasra-Śīrṣā Puruṣaḥ Sahasrākṣaḥ Sahasra-Pāt | Sa Bhūmiṁ Viśvato Vṛtvā-Tyatiṣṭhad Daśāṅgulam ||',
      englishMeaning: 'The Cosmic Being has thousands of heads, eyes, and feet. Encompassing the Earth on all sides, He transcends it by ten fingers.',
      englishExplanation: 'Rigveda 10.90 opening verse for advanced spatial-auditory memory and rhythmic chanting.',
      cognitivePurpose: 'Cosmic spatial expansion memory & complex compound phoneme recall.',
      chunks: ['ॐ सहस्रशीर्षा पुरुषः', 'सहस्राक्षः सहस्रपात्', 'स भूमिं विश्वतो वृत्वा', 'अत्यतिष्ठद्दशाङ्गुलम्'],
      languageCode: 'sa',
    ),
  ];

  @override
  List<CulturalContentItem> getAllItems() => List.unmodifiable(_items);

  @override
  CulturalContentItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
