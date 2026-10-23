enum PhonicsSkill {
  letterRecognition,
  letterSound,
  oralBlending,
  printedWordBlending,
  printedWordDecoding,
}

enum PhonicsActivityType {
  letterIntroduction,
  findLetter,
  hearSoundChooseLetter,
  oralBlend,
  modelBlend,
  guidedBlend,
  tryWord,
  wordMeaning,
}

enum ReadingAssistance { fullModel, soundHint, replay, none }

enum ReadingEvidenceMethod { choice, gesture, caregiverObserved }

class PhonicsLetter {
  const PhonicsLetter({
    required this.lowercase,
    required this.uppercase,
    required this.name,
    required this.targetSound,
    required this.soundDescription,
    required this.exampleWord,
    required this.lesson,
    this.educatorNote,
    this.nameAudioAsset,
    this.soundAudioAsset,
  });

  final String lowercase;
  final String uppercase;
  final String name;
  final String targetSound;
  final String soundDescription;
  final String exampleWord;
  final int lesson;
  final String? educatorNote;
  final String? nameAudioAsset;
  final String? soundAudioAsset;

  /// Child-facing phrase that completes “We are learning …”.
  String get spokenSoundPhrase {
    if (lowercase == 'x') return 'the sound at the end of $exampleWord';
    if (soundDescription.startsWith('short ') ||
        soundDescription.startsWith('hard ')) {
      final label = soundDescription.split(',').first;
      return 'the $label sound, as in $exampleWord';
    }
    return 'the sound at the start of $exampleWord';
  }
}

class PhonicsWord {
  const PhonicsWord({
    required this.text,
    required this.graphemes,
    required this.pattern,
    required this.lesson,
    this.meaningNote,
    this.wordAudioAsset,
    this.connectedBlendAudioAsset,
    this.tryPrompt = 'Try reading this word.',
    this.hints = const ['A grown-up can model each sound.'],
  });

  final String text;
  final List<String> graphemes;
  final String pattern;
  final int lesson;
  final String? meaningNote;
  final String? wordAudioAsset;
  final String? connectedBlendAudioAsset;
  final String tryPrompt;
  final List<String> hints;

  Set<String> get prerequisiteLetters => graphemes.toSet();
}

class PhonicsLesson {
  const PhonicsLesson({
    required this.number,
    required this.title,
    required this.focus,
    required this.newLetters,
    required this.reviewLetters,
    required this.words,
    this.oralBlend,
    this.meaningWord,
  });

  final int number;
  final String title;
  final String focus;
  final List<String> newLetters;
  final List<String> reviewLetters;
  final List<String> words;
  final String? oralBlend;
  final String? meaningWord;

  String get letter => newLetters.single;
}

class ReadingEvidence {
  const ReadingEvidence({
    required this.skill,
    required this.item,
    required this.assistance,
    required this.method,
    required this.correct,
  });

  final PhonicsSkill skill;
  final String item;
  final ReadingAssistance assistance;
  final ReadingEvidenceMethod method;
  final bool correct;

  String get assistanceLabel => switch (assistance) {
        ReadingAssistance.fullModel => 'full model',
        ReadingAssistance.soundHint => 'sound hint',
        ReadingAssistance.replay => 'replay',
        ReadingAssistance.none => 'no assistance',
      };
}

const alphabet = 'abcdefghijklmnopqrstuvwxyz';

const phonicsLetters = <String, PhonicsLetter>{
  'a': PhonicsLetter(
    lowercase: 'a',
    uppercase: 'A',
    name: 'ay',
    targetSound: '/æ/',
    soundDescription: 'short a',
    exampleWord: 'apple',
    lesson: 1,
  ),
  'b': PhonicsLetter(
    lowercase: 'b',
    uppercase: 'B',
    name: 'bee',
    targetSound: '/b/',
    soundDescription: 'the first sound in ball',
    exampleWord: 'ball',
    lesson: 2,
  ),
  'c': PhonicsLetter(
    lowercase: 'c',
    uppercase: 'C',
    name: 'see',
    targetSound: '/k/',
    soundDescription: 'hard c, as in cat',
    exampleWord: 'cat',
    lesson: 3,
    educatorNote: 'This lesson teaches hard c only, not soft c as in cent.',
  ),
  'd': PhonicsLetter(
    lowercase: 'd',
    uppercase: 'D',
    name: 'dee',
    targetSound: '/d/',
    soundDescription: 'the first sound in dog',
    exampleWord: 'dog',
    lesson: 4,
  ),
  'e': PhonicsLetter(
    lowercase: 'e',
    uppercase: 'E',
    name: 'ee',
    targetSound: '/ɛ/',
    soundDescription: 'short e',
    exampleWord: 'egg',
    lesson: 5,
  ),
  'f': PhonicsLetter(
    lowercase: 'f',
    uppercase: 'F',
    name: 'eff',
    targetSound: '/f/',
    soundDescription: 'the first sound in fish',
    exampleWord: 'fish',
    lesson: 6,
  ),
  'g': PhonicsLetter(
    lowercase: 'g',
    uppercase: 'G',
    name: 'jee',
    targetSound: '/g/',
    soundDescription: 'hard g, as in goat',
    exampleWord: 'goat',
    lesson: 7,
    educatorNote: 'This lesson teaches hard g only, not soft g as in gem.',
  ),
  'h': PhonicsLetter(
    lowercase: 'h',
    uppercase: 'H',
    name: 'aych',
    targetSound: '/h/',
    soundDescription: 'the first sound in hat',
    exampleWord: 'hat',
    lesson: 8,
  ),
  'i': PhonicsLetter(
    lowercase: 'i',
    uppercase: 'I',
    name: 'eye',
    targetSound: '/ɪ/',
    soundDescription: 'short i',
    exampleWord: 'insect',
    lesson: 9,
  ),
  'j': PhonicsLetter(
    lowercase: 'j',
    uppercase: 'J',
    name: 'jay',
    targetSound: '/dʒ/',
    soundDescription: 'the first sound in jam',
    exampleWord: 'jam',
    lesson: 10,
  ),
  'k': PhonicsLetter(
    lowercase: 'k',
    uppercase: 'K',
    name: 'kay',
    targetSound: '/k/',
    soundDescription: 'the first sound in kite',
    exampleWord: 'kite',
    lesson: 11,
  ),
  'l': PhonicsLetter(
    lowercase: 'l',
    uppercase: 'L',
    name: 'ell',
    targetSound: '/l/',
    soundDescription: 'the first sound in leaf',
    exampleWord: 'leaf',
    lesson: 12,
  ),
  'm': PhonicsLetter(
    lowercase: 'm',
    uppercase: 'M',
    name: 'em',
    targetSound: '/m/',
    soundDescription: 'the first sound in moon',
    exampleWord: 'moon',
    lesson: 13,
  ),
  'n': PhonicsLetter(
    lowercase: 'n',
    uppercase: 'N',
    name: 'en',
    targetSound: '/n/',
    soundDescription: 'the first sound in nest',
    exampleWord: 'nest',
    lesson: 14,
  ),
  'o': PhonicsLetter(
    lowercase: 'o',
    uppercase: 'O',
    name: 'oh',
    targetSound: '/ɑ/',
    soundDescription: 'short o',
    exampleWord: 'octopus',
    lesson: 15,
  ),
  'p': PhonicsLetter(
    lowercase: 'p',
    uppercase: 'P',
    name: 'pee',
    targetSound: '/p/',
    soundDescription: 'the first sound in pen',
    exampleWord: 'pen',
    lesson: 16,
  ),
  'q': PhonicsLetter(
    lowercase: 'q',
    uppercase: 'Q',
    name: 'cue',
    targetSound: '/kw/',
    soundDescription: 'q is usually written with u, as in queen',
    exampleWord: 'queen',
    lesson: 17,
    educatorNote:
        'Introduce qu as a common spelling pattern; do not present q as a stand-alone phoneme.',
  ),
  'r': PhonicsLetter(
    lowercase: 'r',
    uppercase: 'R',
    name: 'ar',
    targetSound: '/ɹ/',
    soundDescription: 'the first sound in red',
    exampleWord: 'red',
    lesson: 18,
  ),
  's': PhonicsLetter(
    lowercase: 's',
    uppercase: 'S',
    name: 'ess',
    targetSound: '/s/',
    soundDescription: 'the first sound in sun',
    exampleWord: 'sun',
    lesson: 19,
  ),
  't': PhonicsLetter(
    lowercase: 't',
    uppercase: 'T',
    name: 'tee',
    targetSound: '/t/',
    soundDescription: 'the first sound in top',
    exampleWord: 'top',
    lesson: 20,
  ),
  'u': PhonicsLetter(
    lowercase: 'u',
    uppercase: 'U',
    name: 'you',
    targetSound: '/ʌ/',
    soundDescription: 'short u',
    exampleWord: 'umbrella',
    lesson: 21,
  ),
  'v': PhonicsLetter(
    lowercase: 'v',
    uppercase: 'V',
    name: 'vee',
    targetSound: '/v/',
    soundDescription: 'the first sound in van',
    exampleWord: 'van',
    lesson: 22,
  ),
  'w': PhonicsLetter(
    lowercase: 'w',
    uppercase: 'W',
    name: 'double-you',
    targetSound: '/w/',
    soundDescription: 'the first sound in web',
    exampleWord: 'web',
    lesson: 23,
  ),
  'x': PhonicsLetter(
    lowercase: 'x',
    uppercase: 'X',
    name: 'ex',
    targetSound: '/ks/',
    soundDescription: 'x often spells /k/ and /s/ together, as in box',
    exampleWord: 'box',
    lesson: 24,
    educatorNote: 'The x example is final, not an initial sound.',
  ),
  'y': PhonicsLetter(
    lowercase: 'y',
    uppercase: 'Y',
    name: 'why',
    targetSound: '/j/',
    soundDescription: 'the first sound in yes',
    exampleWord: 'yes',
    lesson: 25,
  ),
  'z': PhonicsLetter(
    lowercase: 'z',
    uppercase: 'Z',
    name: 'zee',
    targetSound: '/z/',
    soundDescription: 'the first sound in zip',
    exampleWord: 'zip',
    lesson: 26,
  ),
};

const phonicsWords = <String, PhonicsWord>{
  'am': PhonicsWord(
    text: 'am',
    graphemes: ['a', 'm'],
    pattern: 'VC short-a',
    lesson: 13,
    meaningNote: 'A word we use when we talk about ourselves.',
  ),
  'at': PhonicsWord(
    text: 'at',
    graphemes: ['a', 't'],
    pattern: 'VC short-a',
    lesson: 20,
  ),
  'mat': PhonicsWord(
    text: 'mat',
    graphemes: ['m', 'a', 't'],
    pattern: 'CVC short-a',
    lesson: 20,
  ),
  'sat': PhonicsWord(
    text: 'sat',
    graphemes: ['s', 'a', 't'],
    pattern: 'CVC short-a',
    lesson: 20,
  ),
  'map': PhonicsWord(
    text: 'map',
    graphemes: ['m', 'a', 'p'],
    pattern: 'CVC short-a',
    lesson: 16,
  ),
  'pat': PhonicsWord(
    text: 'pat',
    graphemes: ['p', 'a', 't'],
    pattern: 'CVC short-a',
    lesson: 20,
  ),
  'tap': PhonicsWord(
    text: 'tap',
    graphemes: ['t', 'a', 'p'],
    pattern: 'CVC short-a',
    lesson: 20,
  ),
  'it': PhonicsWord(
    text: 'it',
    graphemes: ['i', 't'],
    pattern: 'VC short-i',
    lesson: 20,
  ),
  'sit': PhonicsWord(
    text: 'sit',
    graphemes: ['s', 'i', 't'],
    pattern: 'CVC short-i',
    lesson: 20,
  ),
  'in': PhonicsWord(
    text: 'in',
    graphemes: ['i', 'n'],
    pattern: 'VC short-i',
    lesson: 14,
  ),
  'pin': PhonicsWord(
    text: 'pin',
    graphemes: ['p', 'i', 'n'],
    pattern: 'CVC short-i',
    lesson: 16,
  ),
  'pan': PhonicsWord(
    text: 'pan',
    graphemes: ['p', 'a', 'n'],
    pattern: 'CVC short-a',
    lesson: 16,
  ),
  'man': PhonicsWord(
    text: 'man',
    graphemes: ['m', 'a', 'n'],
    pattern: 'CVC short-a',
    lesson: 14,
  ),
  'tin': PhonicsWord(
    text: 'tin',
    graphemes: ['t', 'i', 'n'],
    pattern: 'CVC short-i',
    lesson: 20,
  ),
  'fan': PhonicsWord(
    text: 'fan',
    graphemes: ['f', 'a', 'n'],
    pattern: 'CVC short-a',
    lesson: 14,
  ),
  'fin': PhonicsWord(
    text: 'fin',
    graphemes: ['f', 'i', 'n'],
    pattern: 'CVC short-i',
    lesson: 14,
  ),
  'fit': PhonicsWord(
    text: 'fit',
    graphemes: ['f', 'i', 't'],
    pattern: 'CVC short-i',
    lesson: 20,
  ),
};

final phonicsLessons = List<PhonicsLesson>.unmodifiable(
  List.generate(alphabet.length, (index) {
    final letter = alphabet[index];
    final words = phonicsWords.values
        .where((word) => word.lesson == index + 1)
        .map((word) => word.text)
        .toList();
    return PhonicsLesson(
      number: index + 1,
      title: 'Letter ${letter.toUpperCase()}',
      focus:
          'Learn the name and one common sound for $letter, then review earlier letters.',
      newLetters: [letter],
      reviewLetters: alphabet.substring(0, index).split(''),
      words: words,
      oralBlend: letter == 'm' ? 'am' : null,
      meaningWord: letter == 'm' ? 'am' : null,
    );
  }),
);

bool isDecodableByLesson(PhonicsWord word) => word.graphemes.every(
      (letter) =>
          phonicsLetters[letter] != null &&
          phonicsLetters[letter]!.lesson <= word.lesson,
    );
