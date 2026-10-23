import 'phonics_curriculum.dart';

/// Every sentence and letter sound Reading can speak. Each one has a bundled
/// recording listed in `assets/audio/reading/manifest.json`; regenerate the
/// clips after edits.
abstract final class ReadingNarration {
  static const findLetter = 'Find the lowercase letter we just met.';
  static const hearSoundChooseLetter =
      'Listen to the sound, then choose its letter.';
  static const oralBlend = 'Listen as the sounds are joined. You can try too.';
  static const modelBlend = 'Let’s slide the sounds together.';
  static const guidedBlend = 'Your turn. Start here and slide.';
  static const tryWord = 'Try reading this word.';
  static const amMeaning =
      'Am is a word we use when we talk about ourselves. I am happy.';
  static const correctChoice = 'You found the letter. Let’s keep exploring.';
  static const tryAgain = 'Let’s look together. Try again when you’re ready.';
  static const practiceThanks =
      'Thanks for practicing. Sliding or tapping is practice, not proof of reading.';
  static const soundHint =
      'Here is a sound hint. A grown-up can model each sound.';
  static const slideGuide = 'Watch the focus move from left to right.';
  static const amazingWork = 'Yay! You did it!';
  static const fantasticLearning = 'Woo-hoo! Great job!';
  static const wayToGo = 'Amazing! Way to go!';
  static const celebrations = [amazingWork, fantasticLearning, wayToGo];

  /// Short vowels are unclear when cut out on their own, so their sound is
  /// spoken inside a phrase ("a, a, apple") instead.
  static bool isShortVowel(PhonicsLetter letter) =>
      letter.soundDescription.startsWith('short ');

  static String introduction(PhonicsLetter letter) => isShortVowel(letter)
      ? 'This is uppercase ${letter.uppercase} and lowercase '
          '${letter.lowercase}. The letter name is ${letter.name}. '
          'We are learning the short ${letter.lowercase} sound. '
          'It sounds like ${_vowelPhrase(letter)}.'
      : 'This is uppercase ${letter.uppercase} and lowercase '
          '${letter.lowercase}. The letter name is ${letter.name}. '
          'We are learning ${letter.spokenSoundPhrase}.';

  static String _vowelPhrase(PhonicsLetter letter) =>
      '${letter.lowercase}, ${letter.lowercase}, ${letter.exampleWord}';

  static String letterName(PhonicsLetter letter) => letter.name;

  /// Key for the letter's sound clip, e.g. `/b/`. Letters sharing a sound (c
  /// and k) share one recording. Short-vowel clips say "a, a, apple".
  static String letterSound(PhonicsLetter letter) => letter.targetSound;

  /// Whether the introduction clip already includes the letter's sound.
  static bool introductionIncludesSound(PhonicsLetter letter) =>
      isShortVowel(letter);

  /// What a short-vowel sound clip says, for the audio generator.
  static String vowelSoundSpeech(PhonicsLetter letter) =>
      '${_vowelPhrase(letter)}.';

  static const shared = <String, String>{
    'find_letter': findLetter,
    'hear_sound_choose_letter': hearSoundChooseLetter,
    'oral_blend': oralBlend,
    'model_blend': modelBlend,
    'guided_blend': guidedBlend,
    'try_word': tryWord,
    'am_meaning': amMeaning,
    'correct_choice': correctChoice,
    'try_again': tryAgain,
    'practice_thanks': practiceThanks,
    'hint_prompt': soundHint,
    'slide_guide': slideGuide,
    'celebration_1': amazingWork,
    'celebration_2': fantasticLearning,
    'celebration_3': wayToGo,
  };

  /// Stable clip names mapped to the exact sentence each clip speaks.
  static Map<String, String> get all => {
        ...shared,
        for (final letter in phonicsLetters.values) ...{
          'intro_${letter.lowercase}': introduction(letter),
          'name_${letter.lowercase}': letterName(letter),
        },
        for (final MapEntry(key: lowercase, value: letter)
            in phonicsLetters.entries)
          if (phonicsLetters.values.firstWhere(
                  (other) => other.targetSound == letter.targetSound) ==
              letter)
            'sound_$lowercase': letterSound(letter),
        for (final word in phonicsWords.values)
          if (word.tryPrompt != tryWord) 'try_${word.text}': word.tryPrompt,
      };
}
