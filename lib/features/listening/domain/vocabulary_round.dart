class VocabularyPicture {
  const VocabularyPicture(this.word, this.emoji);
  final String word;
  final String emoji;
}

class VocabularyRound {
  const VocabularyRound(this.target, this.choices);
  final String target;
  final List<VocabularyPicture> choices;
}

// Targets appear in different positions so location is not an answer cue.
const vocabularyRounds = [
  VocabularyRound('dog', [
    VocabularyPicture('dog', '🐶'),
    VocabularyPicture('cat', '🐱'),
    VocabularyPicture('rabbit', '🐰'),
  ]),
  VocabularyRound('apple', [
    VocabularyPicture('banana', '🍌'),
    VocabularyPicture('apple', '🍎'),
    VocabularyPicture('grapes', '🍇'),
  ]),
  VocabularyRound('bus', [
    VocabularyPicture('bicycle', '🚲'),
    VocabularyPicture('car', '🚗'),
    VocabularyPicture('bus', '🚌'),
  ]),
  VocabularyRound('cat', [
    VocabularyPicture('rabbit', '🐰'),
    VocabularyPicture('cat', '🐱'),
    VocabularyPicture('dog', '🐶'),
  ]),
  VocabularyRound('banana', [
    VocabularyPicture('banana', '🍌'),
    VocabularyPicture('grapes', '🍇'),
    VocabularyPicture('apple', '🍎'),
  ]),
];
