enum CountingSkill {
  countingSequence,
  numeralRecognition,
  countingObjects,
  understandingTotal,
  makingQuantity,
  tensAndOnes,
}

enum CountingEvidenceMethod {
  guidedIntroduction,
  objectTaps,
  totalChoice,
  group,
  placeValue,
}

class CountingEvidence {
  const CountingEvidence({
    required this.number,
    required this.skill,
    required this.method,
    required this.correct,
    this.assisted = false,
  });

  final int number;
  final CountingSkill skill;
  final CountingEvidenceMethod method;
  final bool correct;
  final bool assisted;
}

class CountingLesson {
  const CountingLesson(this.number, this.name);

  final int number;
  final String name;

  int get tens => number ~/ 10;
  int get ones => number % 10;
  bool get usesTens => number > 10;
  int get countingUnits => usesTens ? tens + ones : number;

  List<int> get totalChoices {
    if (number <= 10) return List.generate(10, (index) => index + 1);
    final start = (number - 2).clamp(1, 97);
    return List.generate(4, (index) => start + index);
  }
}

final List<CountingLesson> countingLessons = List.unmodifiable(
  List.generate(100, (index) {
    final number = index + 1;
    return CountingLesson(number, countingNumberName(number));
  }),
);

String countingNumberName(int number) {
  if (number < 1 || number > 100) {
    throw RangeError.range(number, 1, 100, 'number');
  }
  const small = [
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];
  if (number < 20) return small[number - 1];
  if (number == 100) return 'one hundred';
  const tens = [
    '',
    '',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety',
  ];
  return number % 10 == 0
      ? tens[number ~/ 10]
      : '${tens[number ~/ 10]}-${small[number % 10 - 1]}';
}
