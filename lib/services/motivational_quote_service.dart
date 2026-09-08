import 'dart:math';

class MotivationalQuote {
  final String text;
  final String author;
  final String category; // 'memory', 'daily_effort', 'peace', 'encouragement'
  final String? textTe;
  final String? textHi;
  final String? authorTe;
  final String? authorHi;

  const MotivationalQuote({
    required this.text,
    required this.author,
    this.category = 'encouragement',
    this.textTe,
    this.textHi,
    this.authorTe,
    this.authorHi,
  });

  String localizedText(String langCode) {
    if (langCode == 'te' && textTe != null && textTe!.isNotEmpty) return textTe!;
    if (langCode == 'hi' && textHi != null && textHi!.isNotEmpty) return textHi!;
    return text;
  }

  String localizedAuthor(String langCode) {
    if (langCode == 'te' && authorTe != null && authorTe!.isNotEmpty) return authorTe!;
    if (langCode == 'hi' && authorHi != null && authorHi!.isNotEmpty) return authorHi!;
    return author;
  }
}

class MotivationalQuoteService {
  static const List<MotivationalQuote> _quotes = [
    MotivationalQuote(
      text: 'Every memory is precious. Small steps taken every day nurture lasting clarity.',
      author: 'Smriti Veda Wisdom',
      category: 'memory',
      textTe: 'ప్రతి జ్ఞాపకం అమూల్యమైనది. రోజూ వేసే చిన్న అడుగులు శాశ్వత స్పష్టతను ఇస్తాయి.',
      authorTe: 'స్మృతివేద జ్ఞానం',
      textHi: 'प्रत्येक स्मृति अनमोल है। प्रतिदिन उठाए गए छोटे कदम चिरस्थायी स्पष्टता लाते हैं।',
      authorHi: 'स्मृतिवेद ज्ञान',
    ),
    MotivationalQuote(
      text: 'Take your time. Steady practice strengthens the mind like water shapes the stone.',
      author: 'Traditional Vedic Proverb',
      category: 'daily_effort',
      textTe: 'నిదానంగా సాధన చేయండి. నీరు రాయిని తీర్చిదిద్దినట్లు నిరంతర సాధన మనస్సును బలపరుస్తుంది.',
      authorTe: 'వేద సామెత',
      textHi: 'धैर्य रखें। निरंतर अभ्यास मन को वैसे ही मजबूत करता है जैसे जल पत्थर को आकार देता है।',
      authorHi: 'पारंपरिक कहावत',
    ),
    MotivationalQuote(
      text: 'Your effort today is a gift of awareness to your future self.',
      author: 'Cognitive Wellness Principle',
      category: 'encouragement',
      textTe: 'నేడు మీరు చేసే ప్రయత్నం మీ భవిష్యత్తు కోసం మీరు ఇచ్చే గొప్ప కానుక.',
      authorTe: 'మానసిక ఆరోగ్య సూత్రం',
      textHi: 'आज का आपका प्रयास आपके भविष्य के लिए एक सुंदर उपहार है।',
      authorHi: 'संज्ञानात्मक स्वास्थ्य',
    ),
    MotivationalQuote(
      text: 'A calm breath and a focused mind can remember mountains.',
      author: 'Ayurvedic Saying',
      category: 'peace',
      textTe: 'ప్రశాంతమైన శ్వాస మరియు ఏకాగ్రత కలిగిన మనస్సు కొండలనైనా గుర్తుంచుకోగలవు.',
      authorTe: 'ఆయుర్వేద వచనం',
      textHi: 'शांत श्वास और एकाग्र मन पर्वतों को भी स्मरण रख सकता है।',
      authorHi: 'आयुर्वेदिक सूक्ति',
    ),
    MotivationalQuote(
      text: 'Patience with yourself is the highest form of cognitive care.',
      author: 'Elder Care Guidance',
      category: 'encouragement',
      textTe: 'మీ పట్ల మీరు ఓపికగా ఉండటమే మెదడుకు చేసే అత్యున్నత రక్షణ.',
      authorTe: 'పెద్దల సంరక్షణ మార్గదర్శి',
      textHi: 'स्वयं के प्रति धैर्य रखना ही सबसे उत्तम संज्ञानात्मक देखभाल है।',
      authorHi: 'वरिष्ठ सेवा विचार',
    ),
    MotivationalQuote(
      text: 'Like rhythmic music, consistent recall keeps the mind in sweet harmony.',
      author: 'Smriti Veda',
      category: 'memory',
      textTe: 'లయబద్ధమైన సంగీతం వలె, నిరంతర జ్ఞాపకం మనస్సును మాధుర్యంలో ఉంచుతుంది.',
      authorTe: 'స్మృతివేద',
      textHi: 'लयबद्ध संगीत की भाँति, निरंतर स्मरण मन को मधुर सामंजस्य में रखता है।',
      authorHi: 'स्मृतिवेद',
    ),
    MotivationalQuote(
      text: 'Celebrate each small victory. Every exercise is a milestone in wellness.',
      author: 'Caregiver Circle',
      category: 'daily_effort',
      textTe: 'ప్రతి చిన్న విజయాన్ని ఆనందించండి. ప్రతి అభ్యాసం శ్రేయస్సుకు ఒక మైలురాయి.',
      authorTe: 'సంరక్షకుల సలహా',
      textHi: 'हर छोटी जीत का उत्सव मनाएँ। प्रत्येक अभ्यास मानसिक स्वास्थ्य का एक नया मील का पत्थर है।',
      authorHi: 'देखभालकर्ता संदेश',
    ),
    MotivationalQuote(
      text: 'The mind is like a sacred lamp; regular focus keeps the flame glowing bright.',
      author: 'Upanishadic Reflection',
      category: 'peace',
      textTe: 'మనస్సు ఒక పవిత్ర దీపం లాంటిది; నిత్య ఏకాగ్రత ఆ జ్యోతిని ప్రకాశవంతంగా ఉంచుతుంది.',
      authorTe: 'ఉపనిషత్ భావన',
      textHi: 'मन एक पवित्र दीपक के समान है; नियमित एकाग्रता से इसकी लौ सदैव प्रकाशित रहती है।',
      authorHi: 'उपनिषद विचार',
    ),
    MotivationalQuote(
      text: 'In the gentle rhythm of sacred verses, the soul discovers serene stillness.',
      author: 'Vedic Heritage',
      category: 'peace',
      textTe: 'శ్లోకాల మధుర లయలో, ఆత్మ ప్రశాంతమైన నిశ్చలతను కనుగొంటుంది.',
      authorTe: 'వేద సంప్రదాయం',
      textHi: 'पवित्र श्लोकों की मधुर लय में आत्मा को गहन शांति मिलती है।',
      authorHi: 'वैदिक परंपरा',
    ),
    MotivationalQuote(
      text: 'Joy in daily practice is the true fountain of youthful memory.',
      author: 'Modern Neuroplasticity',
      category: 'memory',
      textTe: 'రోజువారీ సాధనలో ఆనందం ఉండటమే యవ్వన జ్ఞాపకశక్తికి నిజమైన మూలం.',
      authorTe: 'న్యూరోసైన్స్ సూత్రం',
      textHi: 'दैनिक अभ्यास में मिलने वाला आनंद ही स्मृति को युवा और सतेज रखता है।',
      authorHi: 'आधुनिक न्यूरोसाइंस',
    ),
    MotivationalQuote(
      text: 'Cherish familiar faces and shared laughter; they are the anchors of the heart.',
      author: 'Family Harmony',
      category: 'encouragement',
      textTe: 'కుటుంబ సభ్యుల చిరునవ్వులు మరియు అనుబంధాలే హృదయానికి నిజమైన బలం.',
      authorTe: 'కుటుంబ బంధం',
      textHi: 'परिजनों की मुस्कान और आत्मीय बातें ही हृदय का सच्चा सहारा हैं।',
      authorHi: 'पारिवारिक सौहार्द',
    ),
    MotivationalQuote(
      text: 'Never rush. The beauty of the journey is felt one mindful step at a time.',
      author: 'Zen & Vedic Guidance',
      category: 'daily_effort',
      textTe: 'ఎప్పుడూ తొందరపడకండి. ఒక్కొక్క ప్రశాంతమైన అడుగులోనే ప్రయాణపు అందం ఉంది.',
      authorTe: 'శాంతి మార్గం',
      textHi: 'कभी जल्दबाजी न करें। यात्रा का सच्चा सौंदर्य हर शांत कदम में निहित है।',
      authorHi: 'शांति संदेश',
    ),
  ];

  static MotivationalQuote getQuoteOfTheDay() {
    final now = DateTime.now();
    final rng = Random(now.year * 1000 + now.month * 100 + now.day + now.hour);
    return _quotes[rng.nextInt(_quotes.length)];
  }

  static MotivationalQuote getRandomQuote() {
    final rng = Random();
    return _quotes[rng.nextInt(_quotes.length)];
  }

  static MotivationalQuote getRandomCelebrationQuote() {
    return getRandomQuote();
  }

  static List<MotivationalQuote> getAllQuotes() => List.unmodifiable(_quotes);
}
