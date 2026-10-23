import 'counting_curriculum.dart';

abstract final class CountingNarration {
  static const countTogether = 'Let\'s count! Tap each star once.';
  static const howMany = 'How many stars altogether? Choose the number.';
  static const rearrange =
      'The stars moved! There are still the same number. Count them again.';
  static const tryTotal = 'Let\'s count together again, then choose how many.';
  static const tryGroup =
      'Not quite yet. Add or remove stars, then check your group again.';
  static const correctTotal = 'Yes! That is how many stars altogether!';
  static const correctGroup = 'You made the group! Great counting!';
  static const meetNumber = 'Meet this number.';
  static const countTens =
      'Each full frame has ten stars. Count the tens first, then the single stars.';
  static const starsAltogether = 'Stars altogether.';
  static const buildNumber =
      'Build this number with groups of ten and single stars.';
  static const tryBuild =
      'Try again. Use the matching tens and ones. Ten ones can be exchanged for one ten.';
  static const correctBuild = 'You built the number with tens and ones!';

  static String meet(CountingLesson lesson) => 'This is ${lesson.name}.';
  static String number(int number) => '${countingNumberName(number)}.';
  static String total(CountingLesson lesson) => lesson.number == 1
      ? 'One star altogether.'
      : '${lesson.name[0].toUpperCase()}${lesson.name.substring(1)} stars altogether.';
  static String give(CountingLesson lesson) => lesson.number == 1
      ? 'Give me one star. Tap a star to put it in the basket.'
      : 'Give me ${lesson.name} stars. Tap stars to put them in the basket.';

  static Map<String, String> get all => {
        'counting_together': countTogether,
        'counting_how_many': howMany,
        'counting_rearrange': rearrange,
        'counting_try_total': tryTotal,
        'counting_try_group': tryGroup,
        'counting_correct_total': correctTotal,
        'counting_correct_group': correctGroup,
        'counting_meet_number': meetNumber,
        'counting_tens': countTens,
        'counting_stars_altogether': starsAltogether,
        'counting_build': buildNumber,
        'counting_try_build': tryBuild,
        'counting_correct_build': correctBuild,
        for (final lesson in countingLessons)
          'counting_name_${lesson.number}': number(lesson.number),
        for (final lesson in countingLessons.take(10)) ...{
          'counting_meet_${lesson.number}': meet(lesson),
          'counting_total_${lesson.number}': total(lesson),
          'counting_give_${lesson.number}': give(lesson),
        },
      };
}
